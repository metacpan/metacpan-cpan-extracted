###############################################################################
## ----------------------------------------------------------------------------
## Base package for helper classes.
##
###############################################################################

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

package MCE::Shared::Base;

our $VERSION = '1.886';

## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (Subroutines::ProhibitExplicitReturnUndef)

use Scalar::Util qw( looks_like_number );

##
#  Several methods in MCE::Shared::{ Array, Cache, Hash, Minidb, and Ordhash }
#  take a query string for an argument. The format of the string is described
#  below. The _compile function is where the query string is evaluated and
#  expanded into Perl code.
# 
#  In the context of sharing, the query mechanism is beneficial for the
#  shared-manager process. The shared-manager runs the query where the data
#  resides versus sending data in whole to the client process for traversing.
#  Only the data found is sent back.
# 
#  o Basic demonstration
# 
#    @keys = $oh->keys( "query string given here" );
#    @keys = $oh->keys( "val =~ /pattern/" );
# 
#  o Supported operators: =~ !~ eq ne lt le gt ge == != < <= > >=
#  o Multiple expressions delimited by :AND or :OR, mixed case allowed
# 
#    "key eq 'some key' :or (val > 5 :and val < 9)"
#    "key eq some key :or (val > 5 :and val < 9)"
#    "key =~ /pattern/i :And field =~ /pattern/i"
#    "key =~ /pattern/i :And index =~ /pattern/i"
#    "index eq 'foo baz' :OR key !~ /pattern/i"    # 9 eq 'foo baz'
#    "index eq foo baz :OR key !~ /pattern/i"      # 9 eq foo baz
# 
#    MCE::Shared::{ Array, Cache, Hash, Ordhash }
#    * key matches on keys in the hash or index in the array
#    * likewise, val matches on values
# 
#    MCE::Shared::{ Minidb }
#    * key   matches on primary keys in the hash (H)oH or (H)oA
#    * field matches on HoH->{key}{field} e.g. address
#    * index matches on HoA->{key}[index] e.g. 9
# 
#  o Quoting is optional inside the string
#
#    "key =~ /pattern/i :AND field eq 'foo bar'"   # address eq 'foo bar'
#    "key =~ /pattern/i :AND field eq foo bar"     # address eq foo bar
#
#  o See respective module in section labeled SYNTAX for QUERY STRING
#    for demonstrations
##

sub _compile {
   my ( $query ) = @_;
   my ( $len, @p ) = ( 0 );

   $query =~ s/^[\t ]+//;            # strip white-space
   $query =~ s/[\t ]+$//;
   $query =~ s/\([\t ]+/(/g;
   $query =~ s/[\t ]+\)/)/g;

   for ( split( /[\t ]:(?:and|or)[\t ]/i, $query ) ) {
      $len += length;

      if ( /([\(]*)([^\(]+)[\t ]+(=~|!~)[\t ]+(.*)/ ) {
         push @p, "$1($2 $3 $4)"
      }
      elsif ( /([\(]*)([^\(]+)[\t ]+(==|!=|<|<=|>|>=)[\t ]+([^\)]+)(.*)/ ) {
         push @p, "$1($2 $3 q($4) && looks_like_number($2))$5";
      }
      elsif ( /([\(]*)([^\(]+)[\t ]+(eq|ne|lt|le|gt|ge)[\t ]+([^\)]+)(.*)/ ) {
         ( $4 eq 'undef' )
            ? push @p, "$1(!ref($2) && $2 $3 undef)$5"
            : push @p, "$1(!ref($2) && $2 $3 q($4))$5";
      }
      else {
         push @p, $_;
      }

      $len += 6, push @p, " && " if ( lc ( substr $query, $len, 3 ) eq " :a" );
      $len += 5, push @p, " || " if ( lc ( substr $query, $len, 3 ) eq " :o" );
   }

   $query = join('', @p);
   $query =~ s/q\([\'\"]([^\(\)]*)[\'\"]\)/q($1)/g;

   $query;
}

###############################################################################
## ----------------------------------------------------------------------------
## Find items in ARRAY. Called by MCE::Shared::Array.
##
###############################################################################

sub _find_array {
   my ( $data, $params, $query ) = @_;
   my $q = _compile( $query );

   # array key
   $q =~ s/key[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$_ $1/gi;
   $q =~ s/(looks_like_number)\(key\)/$1(\$_)/gi;
   $q =~ s/(!ref)\(key\)/$1(\$_)/gi;

   # array value
   $q =~ s/val[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$data->[\$_] $1/gi;
   $q =~ s/(looks_like_number)\(val\)/$1(\$data->[\$_])/gi;
   $q =~ s/(!ref)\(val\)/$1(\$data->[\$_])/gi;

   local $SIG{__WARN__} = sub {
      print {*STDERR} "\nfind error: $_[0]\n  query: $query\n  eval : $q\n";
   };

   # wants keys
   if ( $params->{'getkeys'} ) {
      eval qq{ map { ($q) ? (\$_) : () } 0 .. \@{ \$data } - 1 };
   }
   # wants values
   elsif ( $params->{'getvals'} ) {
      eval qq{ map { ($q) ? (\$data->[\$_]) : () } 0 .. \@{ \$data } - 1 };
   }
   # wants pairs
   else {
      eval qq{ map { ($q) ? (\$_ => \$data->[\$_]) : () } 0 .. \@{ \$data } - 1 };
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## Find items in HASH.
## Called by MCE::Shared::{ Cache, Hash, Minidb, Ordhash }.
##
###############################################################################

sub _find_hash {
   my ( $data, $params, $query, $obj ) = @_;
   my $q = _compile( $query );
   my $grepvals = 0;

   # hash key
   $q =~ s/key[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$_ $1/gi;
   $q =~ s/(looks_like_number)\(key\)/$1(\$_)/gi;
   $q =~ s/(!ref)\(key\)/$1(\$_)/gi;

   # Minidb (HoH) field
   if ( exists $params->{'hfind'} ) {
      $q =~ s/\$_ /:%: /g;  # preserve $_ from hash key mods above
      $q =~ s/([^:%\(\t ]+)[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$data->{\$_}{'$1'} $2/gi;
      $q =~ s/:%: /\$_ /g;  # restore hash key mods
      $q =~ s/(looks_like_number)\(([^\$\)]+)\)/$1(\$data->{\$_}{'$2'})/gi;
      $q =~ s/(!ref)\(([^\$\)]+)\)/$1(\$data->{\$_}{'$2'})/gi;
   }

   # Minidb (HoA) field
   elsif ( exists $params->{'lfind'} ) {
      $q =~ s/\$_ /:%: /g;  # preserve $_ from hash key mods above
      $q =~ s/([^:%\(\t ]+)[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$data->{\$_}['$1'] $2/gi;
      $q =~ s/:%: /\$_ /g;  # restore hash key mods
      $q =~ s/(looks_like_number)\(([^\$\)]+)\)/$1(\$data->{\$_}['$2'])/gi;
      $q =~ s/(!ref)\(([^\$\)]+)\)/$1(\$data->{\$_}['$2'])/gi;
   }

   # Cache/Hash/Ordhash value
   elsif ( $params->{'getvals'} && $q !~ /\(\$_/ ) {
      $grepvals = 1;
      $q =~ s/val[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$_ $1/gi;
      $q =~ s/(looks_like_number)\(val\)/$1(\$_)/gi;
      $q =~ s/(!ref)\(val\)/$1(\$_)/gi;
   }
   else {
      $q =~ s/val[ ]+(==|!=|<|<=|>|>=|eq|ne|lt|le|gt|ge|=~|!~)/\$data->{\$_} $1/gi;
      $q =~ s/(looks_like_number)\(val\)/$1(\$data->{\$_})/gi;
      $q =~ s/(!ref)\(val\)/$1(\$data->{\$_})/gi;
   }

   local $SIG{__WARN__} = sub {
      print {*STDERR} "\nfind error: $_[0]\n  query: $query\n  eval : $q\n";
   };

   # wants keys
   if ( $params->{'getkeys'} ) {
      eval qq{
         map { ($q) ? (\$_) : () }
            ( \$obj ? \$obj->keys : CORE::keys \%{\$data} )
      };
   }
   # wants values
   elsif ( $params->{'getvals'} ) {
      $grepvals
         ? eval qq{
              grep { ($q) }
                 ( \$obj ? \$obj->vals : CORE::values \%{\$data} )
           }
         : eval qq{
              map { ($q) ? (\$data->{\$_}) : () }
                 ( \$obj ? \$obj->keys : CORE::keys \%{\$data} )
           };
   }
   # wants pairs
   else {
      eval qq{
         map { ($q) ? (\$_ => \$data->{\$_}) : () }
            ( \$obj ? \$obj->keys : CORE::keys \%{\$data} )
      };
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## Miscellaneous.
##
###############################################################################

sub _stringify { no overloading;    "$_[0]" }
sub _numify    { no overloading; 0 + $_[0]  }

# Croak handler.

sub _croak {
   if ( $INC{'MCE.pm'} ) {
      goto &MCE::_croak;
   }
   elsif ( $INC{'MCE::Signal.pm'} ) {
      $SIG{__DIE__}  = \&MCE::Signal::_die_handler;
      $SIG{__WARN__} = \&MCE::Signal::_warn_handler;

      $\ = undef; goto &Carp::croak;
   }
   else {
      require Carp unless $INC{'Carp.pm'};

      $\ = undef; goto &Carp::croak;
   }
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Base - Base package for helper classes

=head1 VERSION

This document describes MCE::Shared::Base version 1.886

=head1 DESCRIPTION

Common functions for L<MCE::Shared>. There is no public API.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut


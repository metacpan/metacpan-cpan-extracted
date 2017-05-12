use strict;
use warnings;

package File::Util::Interface::Modern;
$File::Util::Interface::Modern::VERSION = '4.161950';
# ABSTRACT: Modern call interface to File::Util

use lib 'lib';

use File::Util::Interface::Classic qw( _myargs );
use File::Util::Definitions qw( :all );

use vars qw(
   @ISA    $AUTHORITY
   @EXPORT_OK  %EXPORT_TAGS
);

use Exporter;

$AUTHORITY  = 'cpan:TOMMY';
@ISA        = qw( Exporter  File::Util::Interface::Classic );
@EXPORT_OK  = qw(
   _remove_opts
   _myargs
   _names_values
   _parse_in
); # some of the symbols above come from File::Util::Interface::Classic but
   # the _remove_opts/_names_values methods are specifically overriden in
   # this package

%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );


# --------------------------------------------------------
# File::Util::Interface::Modern::_names_values()
# --------------------------------------------------------
sub _names_values {

   # ignore $_[0] File::Util object reference

   if ( ref $_[1] eq 'HASH' ) {

      # method was called like $f->method( { name => val } )
      return $_[1]
   }

   # ...method called like $f->methd( name => val );

   goto \&File::Util::Interface::Classic::_names_values;
}


# --------------------------------------------------------
# File::Util::Interface::Modern::_remove_opts()
# --------------------------------------------------------
sub _remove_opts {

   shift; # we don't need "$this" here

   my $args = shift @_;

   return unless ref $args eq 'ARRAY';

   my @triage = @$args; @$args = ();
   my $opts   = { };

   while ( @triage ) {

      my $arg = shift @triage;

      # if an argument is '', 0, or undef, it's obviously not an --option ...
      push @$args, $arg and next unless $arg; # ...so give it back to the @$args

      if ( UNIVERSAL::isa( $arg, 'HASH' ) ) {

         # if we got hashref, then we were called with the new & improved syntax:
         #     e.g.- $ftl->method( arg => { opt => foo, opt2 => bar } );
         #
         # ...as oppsed to the classic syntax:
         #     e.g.- $ftl->method( arg => value, --opt1=value, --flag )
         #
         # the bit of code below makes it possible to support both call syntaxes

         @$opts{ keys %$arg } = values %$arg; # crane lower that rover (ahhhhh)
                                              # err, Perl flatcopy that hashref
      }
      elsif ( $arg =~ /^--/ ) { # got old school "--option" argument?

         # it's either a bare "--option", or it's an "--option=value" pair
         my ( $opt, $value ) = split /=/, $arg;

         # bare version
         $opts->{ $opt } = defined $value ? $value : 1;
                         # ^^^^^^^ if $value is undef it's a --flag, and value=1

         # sanitized version, remove leading "--" ...
         my $clean_name = substr $opt, 2;

         # ...and replace non-alnum chars with "_" so the names can be
         # referenced as hash keys without superfluous quoting and escaping
         $clean_name =~ s/[^[:alnum:]]/_/g;

         $opts->{ $clean_name } = defined $value ? $value : 1;
      }
      else {

         # but if it's not an "--option" type arg, or a hashref of options,
         # then give it back to the caller's @$args arrayref
         push @$args, $arg;
      }
   }

   return $opts;
}


# --------------------------------------------------------
# File::Util::Interface::Modern::_parse_in()
# --------------------------------------------------------
sub _parse_in {
   my ( $this, @in ) = @_;

   my $opts = $this->_remove_opts( \@in ); # always returns a hashref, given a listref
   my $in   = $this->_names_values( @in ); # always returns a hashref, given anything

   # merge two hashrefs
   @$in{ keys %$opts } = values %$opts;

   return $in;
}


# --------------------------------------------------------
# File::Util::Interface::Modern::DESTROY()
# --------------------------------------------------------
sub DESTROY { }

1;


__END__

=pod

=head1 NAME

File::Util::Interface::Modern - Modern call interface to File::Util

=head1 VERSION

version 4.161950

=head1 DESCRIPTION

Provides a ::Modern-style interface for argument passing to and between the
public and private methods of File::Util.

Whereas call syntax used to only work like this:

   some_method( main_arg => value, qw/ --opt=value --patern=^foo --flag / )

This module allows File::Util to work with calls that are more consistent
with current practices in Perl, like this:

   some_method( main_arg => { arg => value, opt => value, flag => 1 } );
      -or-
   some_method( '/var/log' => { match => [ qr/.*\.log/, qr/access|error/ ] } )

Users, don't use this module by itself.  It is intended for internal use only.

=cut

use strict;
use warnings;

package File::Util::Interface::Classic;
$File::Util::Interface::Classic::VERSION = '4.161950';
# ABSTRACT: Legacy call interface to File::Util

use Scalar::Util qw( blessed );

use lib 'lib';

use File::Util::Definitions qw( :all );

use vars qw(
   @ISA    $AUTHORITY
   @EXPORT_OK  %EXPORT_TAGS
);

use Exporter;

$AUTHORITY  = 'cpan:TOMMY';
@ISA        = qw( Exporter );
@EXPORT_OK  = qw(
   _myargs
   _remove_opts
   _names_values
);

%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );


# --------------------------------------------------------
# File::Util::Interface::Classic::_myargs()
# --------------------------------------------------------
sub _myargs {

   shift @_ if ( blessed $_[0] || ( $_[0] && $_[0] =~ /^File::Util/ ) );

   return wantarray ? @_ : $_[0]
}


# --------------------------------------------------------
# File::Util::Interface::Classic::_remove_opts()
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

      # hmmm.  looks like an "--option" argument, if:
      if ( $arg =~ /^--/ ) {

         # it's either a bare "--option", or it's an "--option=value" pair
         my ( $opt, $value ) = split /=/, $arg;

         # bare version
         $opts->{ $opt } = defined $value ? $value : 1;
                         # ^^^^^^^ if $value is undef, it was a --flag (true)

         # sanitized version, remove leading "--" ...
         my $clean_name = substr $opt, 2;

         # ...and replace non-alnum chars with "_" so the names can be
         # referenced as hash keys without superfluous quoting and escaping
         $clean_name =~ s/[^[:alnum:]]/_/g;

         $opts->{ $clean_name } = defined $value ? $value : 1;
      }
      else {

         # but if it's not an "--option" type arg, give it back to the @$args
         push @$args, $arg;
      }
   }

   return $opts;
}


# --------------------------------------------------------
# File::Util::Interface::Classic::_names_values()
# --------------------------------------------------------
sub _names_values {

   shift; # we don't need "$this" here

   my @in_pairs =  @_;
   my $out_pairs = { };

   # this code no longer tries to catch foolishness such as names that are
   # undef other than skipping over them, for lack of sane options to deal
   # with such insane input ;-)
   while ( my ( $name, $val ) = splice @in_pairs, 0, 2 ) {

      next unless defined $name;

      $out_pairs->{ $name } = $val;
   }

   return $out_pairs;
}


# --------------------------------------------------------
# File::Util::Interface::Classic::DESTROY()
# --------------------------------------------------------
sub DESTROY { }

1;


__END__

=pod

=head1 NAME

File::Util::Interface::Classic - Legacy call interface to File::Util

=head1 VERSION

version 4.161950

=head1 DESCRIPTION

Provides a classic interface for argument passing to and between the public
and private methods of File::Util.  It is as a subclass for File::Util
developers that want to use it, and provides some base methods that are
inherited by L<File::Util::Interface::Modern>, but the _remove_opts method
is overridden in that namespace, whose more progressive version of that
method supports both ::Classic and ::Modern call syntaxes.

Users, don't use this module by itself.  It is intended for internal use only.

=cut

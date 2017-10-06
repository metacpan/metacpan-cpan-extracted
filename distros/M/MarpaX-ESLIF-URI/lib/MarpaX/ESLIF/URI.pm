use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI;

# ABSTRACT: URI as per RFC3986/RFC6874

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.002'; # VERSION

use Carp qw/croak/;
use Class::Load qw/load_class/;
use MarpaX::ESLIF::URI::_generic;

my $re_scheme = qr/[A-Za-z][A-Za-z0-9+\-.]*/;


sub new {
  my ($class, $str, $scheme) = @_;

  croak '$str must be defined' unless defined($str);

  my $self;
  $str = "$str";
  if ($str =~ /^($re_scheme):/o) {
      $scheme = $1
  } elsif (defined($scheme) && ($scheme =~ /^$re_scheme$/o)) {
      $str = "$scheme:$str"
  }

  if (defined($scheme)) {
      #
      # If defined, $scheme is guaranteed to contain only ASCII characters
      #
      my $lc_scheme = lc($scheme);
      $self = eval { load_class("MarpaX::ESLIF::URI::$lc_scheme")->new($str) }
  }
  #
  # Fallback to _generic
  #
  $self //= MarpaX::ESLIF::URI::_generic->new($str)
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI - URI as per RFC3986/RFC6874

=head1 VERSION

version 0.002

=head2 $class->new($str, $scheme)

Returns a instance that is a MarpaX::ESLIF::URI::$scheme representation of C<$str>, when C<$scheme> defaults to C<_generic> if there is no specific C<$scheme> implementation, or if the later fails.

=head1 NOTES

Percent-encoded characters are decoded to ASCII characters corresponding to every percent-encoded byte.

=head1 SEE ALSO

L<MarpaX::ESLIF::URI::_generic>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 CONTRIBUTOR

=for stopwords Jean-Damien Durand

Jean-Damien Durand <Jean-Damien.Durand@newaccess.ch>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

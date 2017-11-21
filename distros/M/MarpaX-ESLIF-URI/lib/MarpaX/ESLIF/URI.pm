use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI;

# ABSTRACT: URI as per RFC3986/RFC6874

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.003'; # VERSION

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

version 0.003

=head1 SYNOPSIS

  use feature 'say';
  use Data::Dumper;
  use MarpaX::ESLIF::URI;

  my  $http_url = "http://[2001:db8:a0b:12f0::1%25Eth0]:80/index.html";
  my  $http_uri = MarpaX::ESLIF::URI->new($http_url);
  say $http_uri->scheme;            # http
  say $http_uri->host;              # [2001:db8:a0b:12f0::1%Eth0]
  say $http_uri->hostname;          # 2001:db8:a0b:12f0::1%Eth0
  say $http_uri->path;              # /index.html
  say $http_uri->ip;                # 2001:db8:a0b:12f0::1%Eth0
  say $http_uri->ipv6;              # 2001:db8:a0b:12f0::1
  say $http_uri->zone;              # Eth0

  my  $file_url = "file:/c|/path/to/file";
  my  $file_uri = MarpaX::ESLIF::URI->new($file_url);
  say $file_uri->scheme;            # file
  say $file_uri->string;            # file:/c|/path/to/file
  say $file_uri->drive;             # c
  say $file_uri->path;              # /c|/path/to/file
  say Dumper($file_uri->segments);  # [ 'c|', 'path', 'to', 'file' ]

  my  $mail_url = "mailto:bogus\@email.com,bogus2\@email.com?"
                  . "subject=test%20subject&"
                  . "body=This%20is%20the%20body%20of%20this%20message.";
  my  $mail_uri = MarpaX::ESLIF::URI->new($mail_url);
  say $mail_uri->scheme;            # mailto
  say Dumper($mail_uri->to);        # bogus\@email.com, bogus2\@email.com
  say Dumper($mail_uri->headers);   # { 'subject' => 'test subject', 'body' => 'This is the body of this message.' }

=head1 SUBROUTINES/METHODS

=head2 $class->new($str, $scheme)

Returns a instance that is a MarpaX::ESLIF::URI::$scheme representation of C<$str>, when C<$scheme> defaults to C<_generic> if there is no specific C<$scheme> implementation, or if the later fails.

All methods of L<MarpaX::ESLIF::URI::_generic> are available, sometimes extended or modified by specific scheme implementations.

=head1 NOTES

Percent-encoded characters are decoded to ASCII characters corresponding to every percent-encoded byte.

=head1 SEE ALSO

L<MarpaX::ESLIF::URI::_generic>, L<MarpaX::ESLIF::URI::file>, L<MarpaX::ESLIF::URI::ftp>, L<MarpaX::ESLIF::URI::http>, L<MarpaX::ESLIF::URI::https>, L<MarpaX::ESLIF::URI::mailto>

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

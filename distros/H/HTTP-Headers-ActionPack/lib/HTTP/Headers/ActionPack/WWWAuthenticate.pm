package HTTP::Headers::ActionPack::WWWAuthenticate;
# ABSTRACT: The WWW-Authenticate Header

use strict;
use warnings;

use parent 'HTTP::Headers::ActionPack::Core::BaseAuthHeader';

our $VERSION = '0.10';

sub realm { (shift)->params->{'realm'} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::WWWAuthenticate - The WWW-Authenticate Header

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::WWWAuthenticate;

  # create from string
  my $www_authen = HTTP::Headers::ActionPack::WWWAuthenticate->new_from_string(
      'Basic realm="WallyWorld"'
  );

  # create using parameters
  my $www_authen = HTTP::Headers::ActionPack::WWWAuthenticate->new(
      'Basic' => (
          realm => 'WallyWorld'
      )
  );

  # create from string
  my $www_authen = HTTP::Headers::ActionPack::WWWAuthenticate->new_from_string(
      q{Digest
          realm="testrealm@host.com",
          qop="auth,auth-int",
          nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
          opaque="5ccc069c403ebaf9f0171e9517f40e41"'}
  );

  # create using parameters
  my $www_authen = HTTP::Headers::ActionPack::WWWAuthenticate->new(
      'Digest' => (
          realm  => 'testrealm@host.com',
          qop    => "auth,auth-int",
          nonce  => "dcd98b7102dd2f0e8b11d0f600bfb0c093",
          opaque => "5ccc069c403ebaf9f0171e9517f40e41"
      )
  );

=head1 DESCRIPTION

This class represents the WWW-Authenticate header and all it's variations,
it is based on the L<HTTP::Headers::ActionPack::Core::BaseAuthHeader> class.

=head1 METHODS

=over 4

=item C<new ( %params )>

=item C<new_from_string ( $header_string )>

=item C<realm>

=item C<as_string>

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut

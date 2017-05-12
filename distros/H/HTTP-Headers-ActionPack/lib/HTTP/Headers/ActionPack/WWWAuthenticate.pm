package HTTP::Headers::ActionPack::WWWAuthenticate;
BEGIN {
  $HTTP::Headers::ActionPack::WWWAuthenticate::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::WWWAuthenticate::VERSION = '0.09';
}
# ABSTRACT: The WWW-Authenticate Header

use strict;
use warnings;

use parent 'HTTP::Headers::ActionPack::Core::BaseAuthHeader';

sub realm { (shift)->params->{'realm'} }

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::WWWAuthenticate - The WWW-Authenticate Header

=head1 VERSION

version 0.09

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

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

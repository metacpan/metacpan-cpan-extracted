package EPFL::Net::ipv6Test;

use 5.006;
use strict;
use warnings;

use JSON;
use Readonly;
use LWP::UserAgent;

=head1 NAME

EPFL::Net::ipv6Test - Website IPv6 accessibility validator API

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

Check IPv6 connectivity from a Website with ipv6-test.com

    use EPFL::Net::ipv6Test qw/getWebAAAA getWebServer getWebDns/;

    my $aaaa = getWebAAAA('google.com');
    print $aaaa->{dns_aaaa}; # => '2400:cb00:2048:1::6814:e52a'

    my $aaaa = getWebServer('google.com');
    print $aaaa->{dns_aaaa}; # => '2400:cb00:2048:1::6814:e52a'
    print $aaaa->{server}; # => 'gws'

    my $dns = getWebDns('google.com');
    print $dns->{dns_ok}; # => 1
    print @{$dns->{dns_servers}};
    # => 'ns3.google.comns2.google.comns1.google.comns4.google.com'

Via the command line epfl-net-ipv6-test

=head1 DESCRIPTION

A simple module to validate IPv6 accessibility of a Website

=cut

use base 'Exporter';
our @EXPORT_OK =
  qw/getWebAAAA getWebServer getWebDns p_createUserAgent p_getUrl p_buildUrl/;

Readonly::Scalar my $WEB_AAAA => 'http://ipv6-test.com/json/webaaaa.php';

Readonly::Scalar my $WEB_SERVER => 'http://ipv6-test.com/json/webserver.php';

Readonly::Scalar my $WEB_DNS => 'http://ipv6-test.com/json/webdns.php';

Readonly::Scalar my $MAX_REDIRECT => 10;

Readonly::Scalar my $TIMEOUT => 1200;

=head1 SUBROUTINES/METHODS

=head2 getWebAAAA( $domain )

Return the AAAA DNS record.

Example:

    {'dns_aaaa' => '2400:cb00:2048:1::6814:e52a'}

or

    {'dns_aaaa' => 'null', 'error' => 'no AAAA record'}

=cut

sub getWebAAAA {
  my $domain = shift;
  return if not defined $domain;

  return p_getWebAPI( $WEB_AAAA, $domain, 1 );
}

=head2 getWebServer( $domain )

Return the AAAA DNS record, the server and the title.

Example:

    {
      'dns_aaaa' => '2400:cb00:2048:1::6814:e42a',
      'server' => 'cloudflare',
      'title' => 'EPFL news'
    }

or

    {'dns_aaaa' => 'null', 'error' => 'no AAAA record'}

=cut

sub getWebServer {
  my $domain = shift;
  return if not defined $domain;

  return p_getWebAPI( $WEB_SERVER, $domain, 1 );
}

=head2 getWebDns( $domain )

Return DNS servers.

Example:

    {'dns_ok' => 1, 'dns_servers' => ['stisun1.epfl.ch', 'stisun2.epfl.ch']}

or

    {'dns_ok' => 0, 'dns_servers' => []}

=cut

sub getWebDns {
  my $domain = shift;
  return if not defined $domain;

  return p_getWebAPI( $WEB_DNS, $domain, 0 );
}

=head1 PRIVATE SUBROUTINES/METHODS

=head2 p_getWebAPI

Return the response from the API.

=cut

sub p_getWebAPI {
  my ( $api, $domain, $withScheme ) = @_;

  my $ua       = p_createUserAgent();
  my $url      = p_buildUrl( $api, $domain, $withScheme );
  my $response = p_getUrl( $ua, $url );
  if ( $response->is_success ) {
    my $struct = from_json( $response->decoded_content );
    return $struct;
  }
  return;
}

=head2 p_createUserAgent

Return a LWP::UserAgent.
LWP::UserAgent objects can be used to dispatch web requests.

=cut

sub p_createUserAgent {
  my $ua = LWP::UserAgent->new;

  $ua->timeout($TIMEOUT);
  $ua->agent('IDevelopBot - v1.0.0');
  $ua->env_proxy;
  $ua->max_redirect($MAX_REDIRECT);

  return $ua;
}

=head2 p_getUrl

Dispatch a GET request on the given $url
The return value is a response object. See HTTP::Response for a description
of the interface it provides.

=cut

sub p_getUrl {
  my ( $ua, $url ) = @_;

  return $ua->get($url);
}

=head2 p_buildUrl

Return the correct url to call for the API.

=cut

sub p_buildUrl {
  my ( $path, $domain, $withScheme ) = @_;

  my $url = $path . '?url=' . $domain;
  if ($withScheme) {
    $url .= '&scheme=http';
  }
  return $url;
}

=head1 AUTHOR

William Belle, C<< <william.belle at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests here
L<https://github.com/epfl-idevelop/epfl-net-ipv6Test/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EPFL::Net::ipv6Test

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EPFL-Net-ipv6Test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EPFL-Net-ipv6Test>

=item * Search CPAN

L<http://search.cpan.org/dist/EPFL-Net-ipv6Test/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;

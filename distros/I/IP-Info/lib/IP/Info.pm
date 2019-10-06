package IP::Info;

$IP::Info::VERSION = '0.18';
$IP::Info::AUTHOR  = 'cpan:MANWAR';

=head1 NAME

IP::Info - Interface to IP geographic and network data.

=head1 VERSION

Version 0.18

=cut

use JSON;
use Data::Dumper;

use IP::Info::Response;
use IP::Info::Response::Network;
use IP::Info::Response::Location;
use IP::Info::UserAgent;
use IP::Info::UserAgent::Exception;

use Digest::MD5 qw(md5_hex);
use Data::Validate::IP qw(is_ipv4);

use Moo;
use namespace::clean;
extends 'IP::Info::UserAgent';

has 'base_url' => (is => 'ro', default => sub { 'https://api.sec.neustar.biz/ipi/gpp/v1/ipinfo' });

=head1 DESCRIPTION

Neustar IP Intelligence RESTful API provides the  geographic location and network
data for any Internet Protocol address in the public address space.
The information includes:

=over 5

=item * Postal code, city, state, region, country, and continent

=item * Area code (US and Canada only) and time zone

=item * Longitude and latitude

=item * DMA (Designated Market Area) and MSA (Metropolitan Statistical Area)

=item * Network information, including type, speed, carrier, and registering
        organization

=back

To obtain "Free Developer Trial" API key and the shared secret, register your application L<here|https://www.neustar.biz/lp/ip-intelligence/trial.php>.

=head1 CONSTRUCTOR

The constructor requires the following parameters as listed below:

    +---------+----------+----------------------------------------+
    | Key     | Required | Description                            |
    +---------+----------+----------------------------------------+
    | api_key |   Yes    | API Key given by Quova.                |
    | secret  |   Yes    | Allocated share secret given by Quova. |
    +---------+----------+----------------------------------------+

    use strict; use warnings;
    use IP::Info;

    my $api_key = 'Your_API_Key';
    my $secret  = 'Your_shared_secret';
    my $info    = IP::Info->new({ api_key => $api_key, secret => $secret });

=head1 METHODS

=head2 ip_address($ip_address)

If  an  IP  address  is specified in the correct format, then the call returns an
object of type L<IP::Info::Response> object which can be queried further to  look
for specific information for that IP. In case it encounters any error it'll throw
an exception.

=over 2

=item * dot-decimal e.g. 4.2.2.2

=item * decimal notation e.g. 67240450

=back

    use strict; use warnings;
    use IP::Info;

    my $api_key  = 'Your_API_Key';
    my $secret   = 'Your_shared_secret';
    my $info     = IP::Info->new({ api_key => $api_key, secret => $secret });
    my $response = $info->ip_address('4.2.2.2');

    print "Carrier: ", $response->network->carrier , "\n";
    print "Country: ", $response->location->country, "\n";

=cut

sub ip_address {
    my ($self, $ip) = @_;

    die ("ERROR: Missing parameter IP Address.") unless defined $ip;
    die ("ERROR: Invalid IP Address [$ip].")     unless is_ipv4($ip);

    my $url      = sprintf("%s/%s?apikey=%s&sig=%s&format=json", $self->base_url(), $ip, $self->api_key, $self->_sig());
    my $response = $self->get($url);
    my $content  = from_json($response->{content});

    return IP::Info::Response->new({
        ip_address => $content->{ipinfo}->{ip_address},
        ip_type    => $content->{ipinfo}->{ip_type},
        network    => IP::Info::Response::Network->new($content->{ipinfo}->{Network}),
        location   => IP::Info::Response::Location->new($content->{ipinfo}->{Location})
    });
}

=head2 schema($file_name)

Saves the XML Schema Document in the given file (.xsd file).In case it encounters
any error it will throw an exception.

    use strict; use warnings;
    use IP::Info;

    my $api_key = 'Your_API_Key';
    my $secret  = 'Your_shared_secret';
    my $info    = IP::Info->new({ api_key => $api_key, secret => $secret });
    $info->schema('User_supplied_filename.xsd');

=cut

sub schema {
    my ($self, $file) = @_;

    die ("ERROR: Please supply the file name for the schema document.") unless defined $file;

    my $url      = sprintf("%s/schema?apikey=%s&sig=%s", $self->base_url(), $self->api_key, $self->_sig());
    my $response = $self->get($url);

    open(SCHEMA, ">$file") or die ("ERROR: Couldn't open file [$file] for writing: [$!]");
    print SCHEMA $response->{content};
    close(SCHEMA);
}

sub _sig {
    my ($self) = @_;

    my $time = time;
    return md5_hex($self->api_key . $self->secret . $time);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/IP-Info>

=head1 BUGS

Please  report  any  bugs or feature requests to C<bug-ip-info at rt.cpan.org> or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IP-Info>.
I will be notified and then you'll automatically be notified of  progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IP::Info

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IP-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IP-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IP-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/IP-Info/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of IP::Info

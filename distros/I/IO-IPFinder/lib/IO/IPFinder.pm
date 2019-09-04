package IO::IPFinder;

use 5.026001;
use strict;
use warnings;
use JSON qw(encode_json decode_json);
use URI::Escape; # FOR uri_escape($val)
use LWP::UserAgent; # call
use IO::Info; # FOR print
use IO::Validation::Asnvalidation;
use IO::Validation::Domainvalidation;
use IO::Validation::Firewallvalidation;
use IO::Validation::Ipvalidation;
use IO::Validation::Tokenvalidation;

our $VERSION = '1.0';

use constant DEFAULT_BASE_URL => 'https://api.ipfinder.io/v1/';

use constant DEFAULT_API_TOKEN => 'free';

use constant FORMAT => 'json';

use constant STATUS_PATH => 'info';

use constant RANGES_PATH => 'ranges/';

use constant FIREWALL_PATH => 'firewall/';

use constant DOMAIN_PATH => 'domain/';

use constant DOMAIN_H_PATH => 'domainhistory/';

use constant DOMAIN_BY_PATH => 'domainby/';



# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IO::IPFinder ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

# Preloaded methods go here.


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub new {
    my ($class, $token, $baseUrl) = @_;

    my $self = {};



	if (defined($token)) {
      IO::Validation::Tokenvalidation->validate($token);
	  $self->{token} = $token;
	}
	else {
	 $self->{token} = DEFAULT_API_TOKEN;
	}

	if (defined($baseUrl)) {
	  $self->{baseUrl} = $baseUrl;
	}
	else {
	  $self->{baseUrl} = DEFAULT_BASE_URL;
	}
    bless $self, $class;

    return $self;
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub call {

	my ($self, $path,$format) = @_;



	if (defined($format)) {
	  $self->{format} = $format;
	}
	else {
	 $self->{format} = FORMAT;
	}

	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->default_headers(HTTP::Headers->new(
	    Accept => 'application/json'
	));
	$self->{ua}->agent("IPFinder-Client/Perl/$VERSION");

	my $url = $self->{baseUrl}.$path;
	my $data = {
          token => $self->{token},
          format   => $self->{format},
	};
	my $fields = encode_json($data);

    my $response = $self->{ua}->post($url, Content => $fields);
	  if ($response->is_success)
	  {
	    $self->{body} =  decode_json($response->decoded_content);

	  }
	  else {
	  	$self->{body} = print("ERROR: " . $response->status_line() . $response->decoded_content);
	  }

	  return  IO::Info->new($self->{body});
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub Authentication {
	my ($self) = @_;
	return $self->call('', '');
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getAddressInfo {
	my ($self, $path) = @_;
    IO::Validation::Ipvalidation->validate($path);
	return $self->call($path);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getAsn {
	my ($self, $path) = @_;
    IO::Validation::Asnvalidation->validate($path);
	return $self->call($path);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getStatus {
	my ($self) = @_;
	return $self->call(STATUS_PATH);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getRanges {
	my ($self, $path) = @_;
	return $self->call(RANGES_PATH.uri_escape($path));
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getFirewall {
	my ($self, $path,$formats) = @_;
    IO::Validation::Firewallvalidation->validate($path,$formats);
	return $self->call(FIREWALL_PATH.$path,$formats);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getDomain {
	my ($self, $path) = @_;
    IO::Validation::Domainvalidation->validate($path);
	return $self->call(DOMAIN_PATH.$path);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getDomainHistory {
	my ($self, $path) = @_;
    IO::Validation::Domainvalidation->validate($path);
	return $self->call(DOMAIN_H_PATH.$path);
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
sub getDomainBy {
	my ($self, $by) = @_;
	return $self->call(DOMAIN_BY_PATH.$by);
}
#-------------------------------------------------------------------------------




1;
__END__

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

IO::IPFinder - The official Perl library for IPFinder ipfinder.io.
https://github.com/ipfinder-io/ip-finder-perl.

=head1 SYNOPSIS
The official Perl client library for the [IPFinder.io](https://ipfinder.io)

=head2 With `free` TOKEN

usage is quite simple:

    use Data::Dumper qw(Dumper);

    $ipfinder = IO::IPFinder->new(); #  emty token == free

    # lookup your IP address information
    $auth = $ipfinder->Authentication();

    print Dumper $auth;

=head2 Authentication

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # lookup your IP address information
    $auth = $ipfinder->Authentication();

    # lookup your IP address information
    $auth = $ipfinder->Authentication();

    print Dumper $auth;



=head2 Get IP address

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # GET Get details for 1.0.0.0

    $ip = $ipfinder->getAddressInfo('1.0.0.0');

    print $ip->{ip};

    print $ip->{country_code};

=head2 Get ASN
This API available as part of our Pro and enterprise [https://ipfinder.io/pricing](https://ipfinder.io/pricing).

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # lookup Asn information
    $asn = $ipfinder->getAsn('AS1');

    print $asn->{asn}; # AS number

    print $asn->{org_name}; # Organization name

=head2 Firewall
This API available as part of our  enterprise L<https://ipfinder.io/pricing/>
formats supported are :  `apache_allow`, `apache_deny`,`nginx_allow`,`nginx_deny`, `CIDR`, `linux_iptables`, `netmask`, `inverse_netmask`, `web_config_allow `, `web_config_deny`, `cisco_acl`, `peer_guardian_2`, `network_object`, `cisco_bit_bucket`, `juniper_junos`, `microtik`
sample:
    use IO::IPFinder;
    use Data::Dumper qw(Dumper);

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    $asn = 'as36947';

    # lookup Asn information

    $data = $ipfinder->getFirewall($asn, 'nginx_deny');

    print Dumper $data
=head2 Get IP Address Ranges
This API available as part of our  enterprise L<https://ipfinder.io/pricing/>
sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # Organization name
    $org = 'Telecom Algeria';

    # lookup Organization information
    $data = $ipfinder->getRanges($org);

    print $range->{num_ranges};

    print $range->{num_ipv4};

    print $range->{num_ipv6};

=head2 Get service status

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # lookup TOKEN information
    $data = $ipfinder->getStatus();

    print $ip->{queriesPerDay};

    print $ip->{queriesLeft};

    print $ip->{key_info};

=head2 Get Domain IP

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    #  domain name
    $name = 'google.com';

    $data = $ipfinder->getDomain($name);

    print $data->{domain_status };

    print $data->{ip};

    print $data->{country_code};

=head2 Get Domain IP history

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # domain name
    $name = 'google.com';

    $data = $ipfinder->getDomainHistory($name);

    print $data->{total_domain};

    print $data->{list_domain};
=head2 Get list Domain By ASN, Country,Ranges

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

    # list live domain by country DZ,US,TN,FR,MA
    $by = 'DZ';

    $dby = $ipfinder->getDomainBy($by);

    print $dby->{select_by}; # Returns Requested $select_by ASN,Country,Ranges

    print $dby->{total_domain}; # Returns number of domain

=head2 Add proxy

sample:
    use IO::IPFinder;

    $ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE','https://ipfinder.yourdomain.com');

=cut

=head1 DESCRIPTION

The official Perl client library for the [IPFinder.io](https://ipfinder.io) get details for :
-  IP address details (city, region, country, postal code, latitude and more ..)
-  ASN details (Organization name, registry,domain,comany_type, and more .. )
-  Firewall by supported formats details (apache_allow,  nginx_deny, CIDR , and more ..)
-  IP Address Ranges by the Organization name  details (list_asn, list_prefixes , and more ..)
-  service status details (queriesPerDay, queriesLeft, key_type, key_info)
- Get Domain IP (asn, organization,country_code ....)
- Get Domain IP history (total_ip, list_ip,organization,asn ....)
- Get list Domain By ASN, Country,Ranges (select_by , total_domain  , list_domain ....)

=head2 Documentation

=over 1

=item * official documentation

L<https://ipfinder.io/docs/>

=back


=head1 SUPPORT
You can find documentation for this module with the perldoc command.
    perldoc IO::IPFinder
You can also look for information at:

Sample codes under examples/ folder.

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO::IPFinder>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO::IPFinder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO::IPFinder>

=item * Search CPAN

L<http://search.cpan.org/dist/IO::IPFinder/>

=item * GitHub

L<https://github.com/ipfinder-io/ip-finder-perl>


=back


=head1 AUTHOR

Mohamed Ben rebia <mohamed@ipfinder.io>


=head1 COPYRIGHT AND LICENSE

Copyright 2019 Mohamed Benrebia <mohamed@ipfinder.io>

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

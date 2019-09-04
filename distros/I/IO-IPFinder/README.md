<img src='https://camo.githubusercontent.com/46886c3e689a0d4a3f6c0733d1cab5d9f9a3926d/68747470733a2f2f697066696e6465722e696f2f6173736574732f696d616765732f6c6f676f732f6c6f676f2e706e67' height='60' alt='IP Finder'></a>
#  IPFinder Perl Client Library

The official Perl client library for the [IPFinder.io](https://ipfinder.io) get details for :
-  IP address details (city, region, country, postal code, latitude and more ..)
-  ASN details (Organization name, registry,domain,comany_type, and more .. )
-  Firewall by supported formats details (apache_allow,  nginx_deny, CIDR , and more ..)
-  IP Address Ranges by the Organization name  details (list_asn, list_prefixes , and more ..)
-  service status details (queriesPerDay, queriesLeft, key_type, key_info)
- Get Domain IP (asn, organization,country_code ....)
- Get Domain IP history (total_ip, list_ip,organization,asn ....)
- Get list Domain By ASN, Country,Ranges (select_by , total_domain  , list_domain ....)


## Getting Started
singup for a free account at [https://ipfinder.io/auth/signup](https://ipfinder.io/auth/signup), for Free IPFinder API access token.

The free plan is limited to 4,000 requests a day, and doesn't include some of the data fields
To enable all the data fields and additional request volumes see [https://ipfinder.io/pricing](https://ipfinder.io/pricing).

## Documentation

See the [official documentation](https://ipfinder.io/docs).

## Installation
Installing using `cpanm`:
```shell
cpanm IO::IPFinder
```
If you'd like to install from source (not necessary for use in your application), download the source and run the following commands:

```shell
perl Makefile.PL
make
make test
make install
```


## How to Use
usage is quite simple:

## With `free` TOKEN

```perl
use IO::IPFinder;
use Data::Dumper qw(Dumper);

$ipfinder = IO::IPFinder->new(); #  emty token == free

# lookup your IP address information
$auth = $ipfinder->Authentication();

print Dumper $auth;
```

### Authentication

```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# lookup your IP address information
$auth = $ipfinder->Authentication();

print Dumper $auth;
```

### Get IP address

```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# GET Get details for 1.0.0.0

$ip = $ipfinder->getAddressInfo('1.0.0.0');

print $ip->{ip};

print $ip->{country_code};
```

### Get ASN
This API available as part of our Pro and enterprise [https://ipfinder.io/pricing](https://ipfinder.io/pricing).

```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# lookup Asn information
$asn = $ipfinder->getAsn('AS1');

print $asn->{asn}; # AS number

print $asn->{org_name}; # Organization name

```

### Firewall
This API available as part of our  enterprise [https://ipfinder.io/pricing](https://ipfinder.io/pricing).
formats supported are :  `apache_allow`, `apache_deny`,`nginx_allow`,`nginx_deny`, `CIDR`, `linux_iptables`, `netmask`, `inverse_netmask`, `web_config_allow `, `web_config_deny`, `cisco_acl`, `peer_guardian_2`, `network_object`, `cisco_bit_bucket`, `juniper_junos`, `microtik`

```perl
use IO::IPFinder;
use Data::Dumper qw(Dumper);

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

$asn = 'as36947';

# lookup Asn information

$data = $ipfinder->getFirewall($asn, 'nginx_deny');

print Dumper $data
```

### Get IP Address Ranges
This API available as part of our  enterprise [https://ipfinder.io/pricing](https://ipfinder.io/pricing).


```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# Organization name
$org = 'Telecom Algeria';

# lookup Organization information
$data = $ipfinder->getRanges($org);

print $range->{num_ranges};

print $range->{num_ipv4};

print $range->{num_ipv6};
```

### Get service status

```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# lookup TOKEN information
$data = $ipfinder->getStatus();

print $ip->{queriesPerDay};

print $ip->{queriesLeft};

print $ip->{key_info};
```

### Get Domain IP

```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

#  domain name
$name = 'google.com';

$data = $ipfinder->getDomain($name);

print $data->{domain_status };

print $data->{ip};

print $data->{country_code};
```

### Get Domain IP history



```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# domain name
$name = 'google.com';

$data = $ipfinder->getDomainHistory($name);

print $data->{total_domain};

print $data->{list_domain};

```

### Get list Domain By ASN, Country,Ranges


```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE');

# list live domain by country DZ,US,TN,FR,MA
$by = 'DZ';

$dby = $ipfinder->getDomainBy($by);

print $dby->{select_by}; # Returns Requested $select_by ASN,Country,Ranges

print $dby->{total_domain}; # Returns number of domain

```

### Add proxy
```perl
use IO::IPFinder;

$ipfinder = IO::IPFinder->new('YOUR_TOKEN_GOES_HERE','https://ipfinder.yourdomain.com');
```

### Error handling

```perl
use IO::IPFinder;

eval {
	# do something
}
or do {
	# error
};

```

Sample codes under **examples/** folder.


## Contact

Contact Us With Additional Questions About Our API, if you would like more information about our API that isn’t available in our IP geolocation API developer documentation, simply [contact](https://ipfinder.io/contact) us at any time and we’ll be able to help you find what you need.

## License

----
[![GitHub license](https://img.shields.io/github/license/ipfinder-io/ip-finder-perl.svg)](https://github.com/ipfinder-io/ip-finder-perl)

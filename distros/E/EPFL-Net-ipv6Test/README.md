EPFL-Net-ipv6Test
=================

[![Build Status][travis-image]][travis-url]
[![Apache License 2.0][license-image]][license-url]
[![CPAN Version][cpan-image]][cpan-url]

Install
-------

Via CPAN with :

```bash
cpan install EPFL::Net::ipv6Test
```

Usage
-----

### Command Line

```bash
epfl-net-ipv6-test --help

Usage:
  epfl-net-ipv6-test --help
  epfl-net-ipv6-test --domain=actu.epfl.ch
```

### Module

```perl
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
```

Contributing
------------

Contributions are always welcome.

See [Contributing](CONTRIBUTING.md).

Developer
---------

  * [William Belle](https://github.com/williambelle)

License
-------

Apache License 2.0

(c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.

See the [LICENSE](LICENSE) file for more details.


[travis-image]: https://travis-ci.org/epfl-idevelop/epfl-net-ipv6Test.svg?branch=master
[travis-url]: https://travis-ci.org/epfl-idevelop/epfl-net-ipv6Test
[license-image]: https://img.shields.io/badge/license-Apache%202.0-blue.svg
[license-url]: https://raw.githubusercontent.com/epfl-idevelop/epfl-net-ipv6Test/master/LICENSE
[cpan-image]: https://img.shields.io/cpan/v/EPFL-Net-ipv6Test.svg
[cpan-url]: https://metacpan.org/release/EPFL-Net-ipv6Test

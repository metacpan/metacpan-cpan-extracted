<p align="center">
  <img alt="EPFL Service Open" src="https://raw.githubusercontent.com/epfl-devrun/epfl-service-open/master/docs/readme/readme-logo.png">
</p>

<p align="center">
  Open the EPFL website (service) associated with the Git repo.
</p>

<p align="center">
  <a href="https://travis-ci.org/epfl-devrun/epfl-service-open">
    <img alt="Travis Status" src="https://travis-ci.org/epfl-devrun/epfl-service-open.svg?branch=master">
  </a>
  <a href="https://coveralls.io/github/epfl-devrun/epfl-service-open?branch=master">
    <img alt="Coverage Status" src="https://coveralls.io/repos/github/epfl-devrun/epfl-service-open/badge.svg?branch=master"/>
  </a>
  <a href="https://raw.githubusercontent.com/epfl-devrun/epfl-service-open/master/LICENSE">
    <img alt="Apache License 2.0" src="https://img.shields.io/badge/license-Apache%202.0-blue.svg">
  </a>
  <a href="https://metacpan.org/release/EPFL-Service-Open">
    <img alt="CPAN Version" src="https://img.shields.io/cpan/v/EPFL-Service-Open.svg">
  </a>
</p>

---

Install
-------

Via CPAN with:

```bash
cpan install EPFL::Service::Open
```

Usage
-----

### Command Line

```bash
epfl-service-open --help
Usage:
  epfl-service-open --help
  epfl-service-open
```

### Module

```perl
use EPFL::Service::Open qw( getService );

my $serviceUrl = getService('git@github.com:epfl-devrun/epfl-news-reader.git');
print $serviceUrl; # https://epfl-devrun.github.io/epfl-news-reader/
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

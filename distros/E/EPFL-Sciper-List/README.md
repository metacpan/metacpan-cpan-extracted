<p align="center">
  <img alt="EPFL Sciper List" src="https://raw.githubusercontent.com/innovativeinnovation/epfl-sciper-list/master/docs/readme/readme-logo.png">
</p>

<p align="center">
  Get a list of all public active sciper from EPFL.
</p>

<p align="center">
  <a href="https://travis-ci.org/innovativeinnovation/epfl-sciper-list">
    <img alt="Travis Status" src="https://travis-ci.org/innovativeinnovation/epfl-sciper-list.svg?branch=master">
  </a>
  <a href="https://coveralls.io/github/innovativeinnovation/epfl-sciper-list?branch=master">
    <img alt="Coverage Status" src="https://coveralls.io/repos/github/innovativeinnovation/epfl-sciper-list/badge.svg?branch=master"/>
  </a>
  <a href="https://raw.githubusercontent.com/innovativeinnovation/epfl-sciper-list/master/LICENSE">
    <img alt="Apache License 2.0" src="https://img.shields.io/badge/license-Apache%202.0-blue.svg">
  </a>
  <a href="https://metacpan.org/release/EPFL-Sciper-List">
    <img alt="CPAN Version" src="https://img.shields.io/cpan/v/EPFL-Sciper-List.svg">
  </a>
</p>

---

Install
-------

Via CPAN with:

```bash
cpan install EPFL::Sciper::List
```

Usage
-----

### Command Line

```bash
epfl-sciper-list --help
Usage:
  epfl-sciper-list
  epfl-sciper-list --output=json > sciper.json
  epfl-sciper-list --output=tsv > sciper.tsv

Options:
  --output=tsv|json
    Output format in TSV or Json.
```

### Module

```perl
use EPFL::Sciper::List qw/retrieveSciper toJson toTsv/;

my @listPersons = retrieveSciper();
print toJson(@listPersons);
print toTsv(@listPersons);
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

Original work (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2017-2018.  
Modified work (c) William Belle, 2018.

See the [LICENSE](LICENSE) file for more details.

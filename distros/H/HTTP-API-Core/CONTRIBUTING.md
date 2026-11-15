# Contributing

Thanks for considering a contribution to HTTP::API::Core.

Bug reports, documentation fixes, tests, and focused feature proposals are welcome. Before proposing a larger change, please open an issue so the design can be discussed first.

## Development setup

Clone the repository, then run:

```console
perl Makefile.PL
make
make test
```

The project supports Perl 5.10 and later. Please avoid introducing dependencies or language features that unnecessarily raise the minimum supported Perl version.

## Pull requests

Keep changes focused and include tests for behavior changes when practical. Update documentation when a change affects the public API or documented behavior.

Before opening a pull request, make sure the test suite passes:

```console
make test
```

## Design direction

HTTP::API::Core aims to remain small, predictable, dependency-light, transport-independent, and safe for production use. Please read [DESIGN.md](DESIGN.md) before proposing changes that significantly expand the project's scope.

## Security issues

Please do not report security vulnerabilities in a public issue. See [SECURITY.md](SECURITY.md) for reporting guidance.

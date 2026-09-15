# Fugu

Generic OpenBSD-style daemon utilities for Perl. Fugu gives a Perl daemon the
plumbing that OpenBSD daemons share. The parts are daemonize, privilege drop,
signals, logging, process control, and pledge(2) and unveil(2).

It adds an event loop, a caching HTTP proxy, SSH and MQTT clients, an mdnsd(8)
control client, and signify(1) key generation, signing and verification. Fugu
needs core Perl only (v5.34), and each CPAN module is an optional feature. See
[INSTALL.md](INSTALL.md) to install it.

## Commands

```sh
make deps-test   # install the runtime and the test dependencies
make check       # run every gate; run it before each commit
make test        # run every test tier
make format-fix  # fix the Perl, Markdown, JSON and YAML formatting
make dist        # build the release tarball
make install     # install the modules under the site_perl tree
```

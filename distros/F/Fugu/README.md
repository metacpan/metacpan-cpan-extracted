# Fugu

Generic OpenBSD-style daemon utilities for Perl.

Fugu gives a Perl daemon the plumbing that OpenBSD daemons share: daemonize,
privilege drop, signal handling, logging, process control, PID files, state
files, pledge(2)/unveil(2), an event loop, a caching HTTP proxy, SSH and MQTT
clients, and a native mdnsd(8) control client. The distribution also ships
`Protocol::Imsg`, a sans-IO codec for the imsg(3) frame.

Fugu needs core Perl only (v5.36). Every CPAN module it can use is an optional
feature, loaded lazily.

## Quick start

```sh
make deps-test
make check
doas make install
```

`make install` puts the modules and their `.pod` sidecars under the site_perl
tree, found by `perldoc Fugu::Daemon`.

Each release also carries a standard Perl distribution tarball. Install it with
cpanm:

```sh
cpanm --notest https://github.com/FuguBSD/Fugu/releases/latest/download/Fugu.tar.gz
```

See [INSTALL.md](INSTALL.md) for full instructions.

## Documentation

Each module documents its API in a `.pod` sidecar. Start with:

- `perldoc Fugu::Daemon` — daemonize a process
- `perldoc Fugu::Log` — the unified logger
- `perldoc Fugu::EventLoop` — one IO::Select loop for a single-process daemon

## Consumers

Fugu is the base library of the FuguBSD repositories:

- [OpenHAP](https://github.com/dickolsson/OpenHAP) — a HomeKit Accessory
  Protocol server for OpenBSD
- [FuguVM](https://github.com/FuguBSD/FuguVM) — installs and manages OpenBSD VMs
  under QEMU
- [FuguWeb](https://github.com/FuguBSD/FuguWeb) — builds a documentation website
  for a Perl project

## Development

See [CLAUDE.md](CLAUDE.md) for the development guide: style, testing,
documentation placement, and the release flow.

## License

ISC. See [LICENSE](LICENSE).

# Installation

## Dependencies

| CPAN module                          | FreeBSD pkg     | Debian pkg           |
|--------------------------------------|-----------------|----------------------|
| App::Cmd                             | p5-App-Cmd      | libapp-cmd-perl      |
| Error::Helper                        | p5-Error-Helper | (cpanm)              |
| JSON::MaybeXS                        | p5-JSON-MaybeXS | libjson-maybexs-perl |
| Net::Firewall::BlockerHelper         | (cpanm)         | (cpanm)              |
| Net::Server (Net::Server::Daemonize) | p5-Net-Server   | libnet-server-perl   |
| POE                                  | p5-POE          | libpoe-perl          |
| POE::Component::Server::JSONUnix     | (cpanm)         | (cpanm)              |
| Regexp::IPv4                         | (cpanm)         | (cpanm)              |
| Regexp::IPv6                         | p5-Regexp-IPv6  | libregexp-ipv6-perl  |
| TOML::Tiny                           | (cpanm)         | libtoml-tiny-perl    |

Package names are current as of writing. Anything marked `(cpanm)` —
or missing from your release — installs cleanly from CPAN via
[cpanminus](https://metacpan.org/pod/App::cpanminus).

## From source

From a checkout or an unpacked release tarball...

```shell
cpanm --installdeps .
perl Makefile.PL
make
make test
make install
```

## FreeBSD

```shell
pkg install p5-App-Cmd p5-Error-Helper p5-JSON-MaybeXS p5-Net-Server \
    p5-POE p5-Regexp-IPv6 p5-App-cpanminus
cpanm TOML::Tiny Regexp::IPv4 Net::Firewall::BlockerHelper \
    POE::Component::Server::JSONUnix
```

## Debian

```shell
apt-get install libapp-cmd-perl libjson-maybexs-perl libnet-server-perl \
    libpoe-perl libregexp-ipv6-perl libtoml-tiny-perl cpanminus \
    build-essential
cpanm Error::Helper Regexp::IPv4 Net::Firewall::BlockerHelper \
    POE::Component::Server::JSONUnix
```

## First run

Write a config (see [configuration](configuration.md) — the
`dummy` backend is good for a first try), then...

```shell
ereshkigal start
ereshkigal status
```

`start` reads `/usr/local/etc/ereshkigal.toml`, daemonizes, and raises
the underworlds. The firewall backends need root; see
[security](security.md) for what that implies.

## Running at boot

`ereshkigal start` daemonizes itself and writes
`/var/run/ereshkigal/pid`, so it fits both worlds easily. Ready-made
startup scripts ship in the source tree's `rc/` directory —
`make install` does not install them, so copy the one for your system
into place.

### FreeBSD rc.d

The rc.d script ships at `rc/freebsd/ereshkigal`...

```shell
cp rc/freebsd/ereshkigal /usr/local/etc/rc.d/ereshkigal
chmod 555 /usr/local/etc/rc.d/ereshkigal
sysrc ereshkigal_enable=YES
service ereshkigal start

# to use a config file other than the default
sysrc ereshkigal_config=/usr/local/etc/foo.toml
```

### Debian systemd

The unit ships at `rc/systemd/ereshkigal.service`...

```shell
cp rc/systemd/ereshkigal.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now ereshkigal
```

It is `Type=forking` against `/var/run/ereshkigal/pid`; edit the
`ExecStart` line for a non-default config path.

On systems where `/var/run` is a tmpfs, `/var/run/ereshkigal` is
created automatically at startup — but if you point `run_base_dir`
somewhere deeper, make sure the parents exist at boot (a
`RuntimeDirectory=` line or a tmpfiles.d entry does it on systemd).
Unix socket paths are limited to roughly 104 characters on the BSDs,
so keep `run_base_dir` short.

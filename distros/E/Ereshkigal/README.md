# Ereshkigal

Ereshkigal is the Sumerian goddess of Kur, the underworld. She decides
who is sent below, how long they stay, and who is permitted to return
to the world above.

In the world above, Ereshkigal is a ban manager for firewalls, sorta akin to fail2ban, but
just handling the FW stuff and not log stuff. An `ereshkigal` manager daemon rules over
every `kur` beneath it, each kur an underworld of its own holding the IPs banished to
it. Inside each sits a single
[Net::Firewall::BlockerHelper](https://metacpan.org/pod/Net::Firewall::BlockerHelper)
instance, which does the actual talking to the firewall — one of 37 backends, from local
packet filters (pf, ipfw, iptables, nftables...) through network gear (OpenWrt, MikroTik,
OPNsense...) and cloud edges to a dummy for testing. Sending an IP below and calling it
back looks like this...

```shell
# raise the underworlds
ereshkigal start

# banish an IP to the sshd underworld for an hour
ereshkigal ban --kur sshd --ban-time 3600 1.2.3.4

# read the rolls of who dwells below
ereshkigal banned

# call one back to the world above
ereshkigal unban 1.2.3.4
```

Banishments may be timed sentences — served and then automatically
released by the sweeper — or eternal (`--ban-time 0`). Every kur
records its residents to a CSV clay tablet, so the underworld survives
a restart intact.

## Install

### From source

Dependencies are declared in Makefile.PL, so with
[cpanminus](https://metacpan.org/pod/App::cpanminus)...

```shell
cpanm --installdeps .
perl Makefile.PL
make
make test
make install
```

### FreeBSD

```shell
pkg install p5-App-Cmd p5-Error-Helper p5-JSON-MaybeXS p5-Net-Server \
    p5-POE p5-Regexp-IPv6 p5-App-cpanminus
cpanm TOML::Tiny Net::Firewall::BlockerHelper \
    POE::Component::Server::JSONUnix Ereshkigal
```

A startup script for running at boot ships at
[rc/freebsd/ereshkigal](rc/freebsd/ereshkigal).

### Debian

```shell
apt-get install libapp-cmd-perl libjson-maybexs-perl libnet-server-perl \
    libpoe-perl libregexp-ipv6-perl libtoml-tiny-perl cpanminus \
    build-essential
cpanm Error::Helper Net::Firewall::BlockerHelper \
    POE::Component::Server::JSONUnix Ereshkigal
```

A systemd unit for running at boot ships at
[rc/systemd/ereshkigal.service](rc/systemd/ereshkigal.service).

## Documentation

To continue your descent, go to [docs/index.md](docs/index.md).

Also...

- [`Ereshkigal`](https://metacpan.org/pod/Ereshkigal)
- [`Ereshkigal::Kur`](https://metacpan.org/pod/Ereshkigal::Kur)
- [`Ereshkigal::Client`](https://metacpan.org/pod/Ereshkigal::Client)

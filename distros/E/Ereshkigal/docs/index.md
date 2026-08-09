# Ereshkigal documentation

Ereshkigal is the Sumerian goddess of Kur, the underworld. She decides
who is sent below, how long they stay, and who is permitted to return
to the world above.

- [architecture](architecture.md) :: the words, and how the manager
  and the kur underworlds fit together — processes, sockets, the
  protocol, sentences, the sweeper, the clay tablets, and the unbans
  a firewall would not take

- [install](install.md) :: dependencies in detail, per-OS install, and
  running at boot

- [configuration](configuration.md) :: the ereshkigal.toml reference
  and a complete example

- [kurs](kurs.md) :: every kind of underworld — shared settings and a
  page per kur under [kurs/](kurs/) detailing each backend, its
  options, and what the host must provide

- [usage](usage.md) :: communing with Ereshkigal via CLI or socket

- [security](security.md) :: the trust model, Neti at the gate, and
  why you probably want `kill = 1`

- [examples](examples.md) :: worked configs to copy from — per-service
  underworlds, eternal blocklists, log watchers, and an unprivileged
  playground

Also...

- [`Ereshkigal`](https://metacpan.org/pod/Ereshkigal)
- [`Ereshkigal::Kur`](https://metacpan.org/pod/Ereshkigal::Kur)
- [`Ereshkigal::Client`](https://metacpan.org/pod/Ereshkigal::Client)

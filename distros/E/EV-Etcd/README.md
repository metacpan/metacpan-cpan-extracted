# EV::Etcd

Async etcd v3 client for Perl using native gRPC Core C API and EV/libev.

## Synopsis

```perl
use EV;
use EV::Etcd;

my $client = EV::Etcd->new(
    endpoints => ['127.0.0.1:2379'],
);

# Put
$client->put('/my/key', 'value', sub {
    my ($resp, $err) = @_;
    die $err->{message} if $err;
    say "Revision: $resp->{header}{revision}";
});

# Get
$client->get('/my/key', sub {
    my ($resp, $err) = @_;
    die $err->{message} if $err;
    say "Value: $resp->{kvs}[0]{value}";
});

# Watch
$client->watch('/my/key', sub {
    my ($resp, $err) = @_;
    for my $event (@{$resp->{events}}) {
        say "$event->{type} on $event->{kv}{key}";
    }
});

EV::run;
```

## Features

- **KV**: get, put, delete, range, transactions (compare-and-swap)
- **Watch**: bidirectional streaming with auto-reconnect
- **Lease**: grant, revoke, keepalive, time-to-live
- **Lock**: distributed locking tied to leases
- **Election**: leader campaign, observe, proclaim, resign
- **Cluster**: member list/add/remove/update/promote
- **Maintenance**: status, compact, defragment, alarm, hash_kv, move_leader
- **Auth**: user/role management, authenticate, enable/disable
- **TLS** and mutual TLS
- **Failover** across multiple endpoints
- **Health monitoring** with configurable interval and callback
- **Automatic reconnection** of watch, keepalive and observe streams

## Architecture

```
┌─────────────────────────┐
│   EV::Etcd (Perl API)   │
├─────────────────────────┤
│      Etcd.xs (XS)       │
├─────────────────────────┤
│  gRPC Core + protobuf-c │
├─────────────────────────┤
│   libev (event loop)    │
└─────────────────────────┘
```

A dedicated pthread polls the gRPC completion queue and signals the main EV event loop via `ev_async`. All Perl callbacks run in the main thread.

## Requirements

- Perl >= 5.10
- [EV](https://metacpan.org/pod/EV)
- libgrpc (gRPC Core C library)
- libprotobuf-c
- pkg-config

### System packages

**Debian/Ubuntu:**
```
apt install libgrpc-dev libgrpc++-dev libprotobuf-c-dev pkg-config
```

**macOS:**
```
brew install grpc protobuf-c pkg-config
```

**FreeBSD:**
```
pkg install grpc protobuf-c pkgconf
```

## Install

```bash
cpanm EV
perl Makefile.PL
make
make test
make install
```

## Documentation

Full API documentation is in the module POD:

```bash
perldoc EV::Etcd
```

## License

Same terms as Perl itself.

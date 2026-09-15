# Socket configuration

Linux::Event applies Linux socket policy to the concrete socket leaves below
`Linux::Event::IO::Sock`. Omitted policy leaves the kernel value untouched.
Live setters are exposed only where changing an established socket has clear
kernel semantics.

## Public socket leaves

Socket policy applies to:

- `Linux::Event::IO::Sock::Stream` for connected `SOCK_STREAM` sockets;
- `Linux::Event::IO::Sock::Listener` for listening `SOCK_STREAM` sockets;
- `Linux::Event::IO::Sock::Dgram` for `SOCK_DGRAM` sockets.

Socket type and address family are separate. A Unix-domain stream socket is
still `IO::Sock::Stream`; a Unix-domain datagram is still `IO::Sock::Dgram`.
Options are validated against both the socket type and selected family.

## Precedence

For connected stream-socket and datagram policy, precedence is:

1. constructor/connect option for one object;
2. cached `socket_options()` or datagram class policy;
3. the existing Linux kernel value when both are omitted.

Linux::Event does not invent a parallel set of network defaults. System tuning,
container policy, and adopted-handle configuration therefore remain visible
unless an application explicitly overrides them.

## Connected stream socket policy

A `IO::Sock::Stream` subclass can cache established socket policy once:

```perl
package ClientConnection;
use parent 'Linux::Event::IO::Sock::Stream';

sub socket_options ($class) {
    return (
        tcp_nodelay        => 1,
        keepalive          => 1,
        keepalive_idle     => 60,
        keepalive_interval => 10,
        keepalive_count    => 5,
        tcp_user_timeout   => 15,
        send_buffer        => 262_144,
        receive_buffer     => 262_144,
    );
}
```

The same supported names can override policy for one outbound connection:

```perl
my $connection = ClientConnection->connect(
    host        => '198.51.100.20',
    port        => 443,
    tcp_nodelay => 0,
    send_buffer => 524_288,
);
```

or for an adopted established descriptor where the constructor supports that
option.

TCP-only options are rejected for Unix-domain stream sockets. Send and receive
buffer sizing is meaningful for both Internet and Unix-domain stream sockets.
`tcp_user_timeout` is expressed publicly in seconds and converted to Linux
milliseconds; a positive duration below one millisecond is rounded up.

The complete `socket_options()` set is:

| Option | Value and scope |
| --- | --- |
| `tcp_nodelay` | Boolean `TCP_NODELAY`; TCP only |
| `keepalive` | Boolean `SO_KEEPALIVE`; TCP only |
| `keepalive_idle` | Positive integer seconds; TCP only |
| `keepalive_interval` | Positive integer seconds; TCP only |
| `keepalive_count` | Positive integer probe count; TCP only |
| `tcp_user_timeout` | Finite non-negative seconds; TCP only |
| `send_buffer` | Positive integer requested `SO_SNDBUF` |
| `receive_buffer` | Positive integer requested `SO_RCVBUF` |

Unspecified values leave kernel defaults intact. Positive integers are at most
2,147,483,647. `bind_device` is deliberately a constructor option rather than
a `socket_options()` key.

## Local source binding

For an outbound Internet stream socket, remote `host` and `port` identify the
peer. Most clients should provide only those and let Linux select the local
source address and ephemeral port.

Optional source binding is explicit:

```perl
my $connection = ClientConnection->connect(
    host       => '203.0.113.10',
    port       => 8443,
    local_host => '192.0.2.20',
    local_port => 0,
);
```

`local_host` is numeric so source binding does not trigger a second DNS lookup.
`local_port` alone binds the wildcard address for the candidate family. Local
and remote families must match.

`bind_device => 'eth0'` applies Linux `SO_BINDTODEVICE` before local bind or
connect. The kernel may require privilege. Interface binding and source-address
binding are independent constraints.

## Listener policy

The listening socket owns its own creation/bind/listen policy:

```perl
my $listener = Linux::Event::IO::Sock::Listener->new(
    host        => '0.0.0.0',
    port        => 9443,
    reuseaddr   => 1,
    reuseport   => 0,
    bind_device => 'eth0',
    stream      => {
        class => 'ServerConnection',
    },
);
```

Listener policy configures the listening descriptor only. It does not stand in
for accepted-connection policy.

Each accepted `ServerConnection` independently applies its resolved
ordered-byte tuning, established socket policy, and optional `configure_socket`
hook before plain readiness or TLS startup.

## Datagram policy

`IO::Sock::Dgram` has packet-socket creation policy:

| Option | Applicability | Default or omission behavior |
| --- | --- | --- |
| `reuseaddr` | created Internet socket | `0` |
| `reuseport` | created Internet socket | `0` |
| `broadcast` | IPv4 | `0` |
| `v6only` | IPv6 | kernel value when omitted |
| `bind_device` | Internet socket | no interface constraint when omitted |
| `send_buffer` | Internet, Unix, adopted | kernel value when omitted |
| `receive_buffer` | Internet, Unix, adopted | kernel value when omitted |

Filesystem Unix-domain datagrams additionally use path policy such as
`unlink`, `unlink_on_close`, and `permissions`.

Source-specific options are rejected even when set to a false value. An option
that has no semantic effect for the chosen socket type/family should fail rather
than appear to be supported.

## Controlled socket hook

A stream-socket or datagram subclass can define cached low-level socket policy
for options Linux::Event does not expose directly:

```perl
use Socket qw(IPPROTO_TCP TCP_QUICKACK);

sub configure_socket ($class, $fh, $role, $address) {
    setsockopt($fh, IPPROTO_TCP, TCP_QUICKACK, pack('i', 1))
        or die "setsockopt(TCP_QUICKACK): $!";
}
```

For stream sockets, roles include `connect`, `accepted`, and `adopted`.
Datagram roles include the applicable connect/adopted paths.

Built-in policy runs first. For outbound stream sockets the hook runs before
local bind and connect. For accepted or adopted stream sockets it runs before
transport startup. A hook exception becomes a structured
`socket_configuration` error and is not silently treated as a candidate
fallback.

## Live values

An established `IO::Sock::Stream` supports live access to meaningful options,
including:

- `tcp_nodelay`;
- `keepalive`, `keepalive_idle`, `keepalive_interval`, and `keepalive_count`;
- `tcp_user_timeout`;
- `send_buffer` and `receive_buffer`.

`IO::Sock::Dgram` supports live packet-socket values such as send/receive
buffers and IPv4 broadcast where applicable.

Setters return the value read back from Linux. Socket buffer sizes may be
rounded or internally adjusted by the kernel.

## TLS and framing order

Socket policy sits below TLS and ordered-byte framing:

```text
socket creation
  -> socket policy
  -> local bind/connect or accept
  -> TLS handshake when declared
  -> plaintext ordered-byte buffering/framing
  -> application callbacks
```

TLS is transport policy on `IO::Sock::Stream`; it is not a framer. A framer
operates on plaintext byte-stream content and has no socket configuration of its
own.

`transition_to()` changes application protocol/framing policy on an existing
ordered-byte resource. It does not recreate the socket, reapply acquisition
policy, change address family, or replace the active TLS transport.

## Errors

System and hook failures use `Linux::Event::Error` with type
`socket_configuration`. `operation` identifies work such as `setsockopt`,
`getsockopt`, `bind`, or `configure_socket`; `option` identifies the affected
policy where known.

Unsupported socket type/family combinations fail explicitly rather than being
skipped.

## Internal implementation

Common conversion and validation currently live in private historical socket
implementation packages. Those package names are not the public application
API. The public contract is the concrete `Linux::Event::IO::Sock::*` leaf.

Keeping policy conversion on a cold acquisition/configuration path ensures the
public semantic cleanup does not add dispatch overhead to steady-state I/O.

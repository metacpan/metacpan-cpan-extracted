package EV::cares;
use 5.012;
use strict;
use warnings;
use EV;

BEGIN {
    our $VERSION = '0.02';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

use Exporter 'import';

our @EXPORT_OK;
our %EXPORT_TAGS;

$EXPORT_TAGS{status} = [qw(
    ARES_SUCCESS ARES_ENODATA ARES_EFORMERR ARES_ESERVFAIL ARES_ENOTFOUND
    ARES_ENOTIMP ARES_EREFUSED ARES_EBADQUERY ARES_EBADNAME ARES_EBADFAMILY
    ARES_EBADRESP ARES_ECONNREFUSED ARES_ETIMEOUT ARES_EOF ARES_EFILE
    ARES_ENOMEM ARES_EDESTRUCTION ARES_EBADSTR ARES_EBADFLAGS ARES_ENONAME
    ARES_EBADHINTS ARES_ENOTINITIALIZED ARES_ECANCELLED ARES_ESERVICE
    ARES_ENOSERVER
)];

$EXPORT_TAGS{types} = [qw(
    T_A T_NS T_CNAME T_SOA T_PTR T_MX T_TXT T_AAAA T_SRV T_NAPTR
    T_DS T_RRSIG T_DNSKEY T_TLSA T_SVCB T_HTTPS T_CAA T_ANY
)];

$EXPORT_TAGS{classes} = [qw(C_IN C_CHAOS C_HS C_ANY)];

$EXPORT_TAGS{flags} = [qw(
    ARES_FLAG_USEVC ARES_FLAG_PRIMARY ARES_FLAG_IGNTC ARES_FLAG_NORECURSE
    ARES_FLAG_STAYOPEN ARES_FLAG_NOSEARCH ARES_FLAG_NOALIASES ARES_FLAG_NOCHECKRESP
    ARES_FLAG_EDNS ARES_FLAG_NO_DFLT_SVR ARES_FLAG_DNS0x20
)];

$EXPORT_TAGS{ai} = [qw(
    ARES_AI_CANONNAME ARES_AI_NUMERICHOST ARES_AI_PASSIVE ARES_AI_NUMERICSERV
    ARES_AI_V4MAPPED ARES_AI_ALL ARES_AI_ADDRCONFIG ARES_AI_NOSORT
)];

$EXPORT_TAGS{ni} = [qw(
    ARES_NI_NOFQDN ARES_NI_NUMERICHOST ARES_NI_NAMEREQD ARES_NI_NUMERICSERV
    ARES_NI_DGRAM ARES_NI_TCP ARES_NI_UDP
)];

$EXPORT_TAGS{families} = [qw(AF_INET AF_INET6 AF_UNSPEC)];

{
    my %seen;
    @EXPORT_OK = grep { !$seen{$_}++ } map { @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{all} = [@EXPORT_OK];
}

# ptr_name($ip) -> reverse-lookup name (.in-addr.arpa for IPv4, .ip6.arpa for IPv6)
# Pure-Perl, no resolver needed.
sub ptr_name {
    my ($ip) = @_;
    require Carp;
    Carp::croak("ptr_name: missing IP") unless defined $ip;
    if (my @oct = $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/) {
        for my $o (@oct) {
            Carp::croak("ptr_name: leading-zero octet '$o' is ambiguous (octal vs decimal)")
                if length($o) > 1 && $o =~ /^0/;
            Carp::croak("ptr_name: invalid IPv4 octet '$o'") if $o > 255;
        }
        return "$oct[3].$oct[2].$oct[1].$oct[0].in-addr.arpa";
    }
    if ($ip =~ /:/) {
        require Socket;
        my $packed = Socket::inet_pton(Socket::AF_INET6(), $ip)
            or Carp::croak("ptr_name: invalid IPv6 '$ip'");
        my @nibbles = CORE::reverse(split //, unpack 'H*', $packed);
        return join('.', @nibbles) . '.ip6.arpa';
    }
    Carp::croak("ptr_name: not a recognized IPv4/IPv6 address: '$ip'");
}

# parse_header($buf) -> hashref of DNS header fields
# Useful for inspecting query() raw responses (AD/CD/AA/TC/RA/RD/QR + counts).
sub parse_header {
    my ($buf) = @_;
    require Carp;
    Carp::croak("parse_header: buffer too short") if length($buf) < 12;
    my ($id, $w, $qd, $an, $ns, $ar) = unpack 'nnnnnn', $buf;
    return {
        id      => $id,
        qr      => ($w >> 15) & 1,
        opcode  => ($w >> 11) & 0xf,
        aa      => ($w >> 10) & 1,
        tc      => ($w >>  9) & 1,
        rd      => ($w >>  8) & 1,
        ra      => ($w >>  7) & 1,
        z       => ($w >>  6) & 1,
        ad      => ($w >>  5) & 1,
        cd      => ($w >>  4) & 1,
        rcode   =>  $w        & 0xf,
        qdcount => $qd,
        ancount => $an,
        nscount => $ns,
        arcount => $ar,
    };
}

sub resolve_all {
    my ($self, $names, $cb) = @_;
    require Carp;
    Carp::croak("resolve_all: first argument must be an arrayref")
        unless ref $names eq 'ARRAY';
    Carp::croak("resolve_all: callback must be a CODE reference")
        unless ref $cb eq 'CODE';
    Carp::croak("resolve_all: resolver is destroyed") if $self->is_destroyed;
    return $cb->({}) unless @$names;
    my %seen;
    my @unique = grep { !$seen{$_}++ } @$names;
    my %res;
    my $pending = @unique;
    for my $name (@unique) {
        $self->resolve($name, sub {
            my ($status, @addrs) = @_;
            $res{$name} = { status => $status, addrs => \@addrs };
            $cb->(\%res) if --$pending == 0;
        });
    }
    return;
}

sub resolve_ttl_all {
    my ($self, $names, $cb) = @_;
    require Carp;
    Carp::croak("resolve_ttl_all: first argument must be an arrayref")
        unless ref $names eq 'ARRAY';
    Carp::croak("resolve_ttl_all: callback must be a CODE reference")
        unless ref $cb eq 'CODE';
    Carp::croak("resolve_ttl_all: resolver is destroyed") if $self->is_destroyed;
    return $cb->({}) unless @$names;
    my %seen;
    my @unique = grep { !$seen{$_}++ } @$names;
    my %res;
    my $pending = @unique;
    for my $name (@unique) {
        $self->resolve_ttl($name, sub {
            my ($status, @records) = @_;
            $res{$name} = { status => $status, records => \@records };
            $cb->(\%res) if --$pending == 0;
        });
    }
    return;
}

sub reverse_all {
    my ($self, $ips, $cb) = @_;
    require Carp;
    Carp::croak("reverse_all: first argument must be an arrayref")
        unless ref $ips eq 'ARRAY';
    Carp::croak("reverse_all: callback must be a CODE reference")
        unless ref $cb eq 'CODE';
    Carp::croak("reverse_all: resolver is destroyed") if $self->is_destroyed;
    return $cb->({}) unless @$ips;
    my %seen;
    my @unique = grep { !$seen{$_}++ } @$ips;
    # validate every IP upfront.  reverse() croaks on invalid input; if we
    # discovered that mid-loop we would have already dispatched queries 1..k
    # whose inner callbacks hold $cb and decrement $pending, but $pending
    # would never reach 0 (we never dispatched k+1..N) -- the completion
    # callback would be silently orphaned.
    require Socket;
    for my $ip (@unique) {
        Carp::croak("reverse_all: invalid IP '$ip'")
            unless Socket::inet_pton(Socket::AF_INET(),  $ip)
                || Socket::inet_pton(Socket::AF_INET6(), $ip);
    }
    my %res;
    my $pending = @unique;
    for my $ip (@unique) {
        $self->reverse($ip, sub {
            my ($status, @hosts) = @_;
            $res{$ip} = { status => $status, hosts => \@hosts };
            $cb->(\%res) if --$pending == 0;
        });
    }
    return;
}

sub getaddrinfo_all {
    my ($self, $nodes, $service, $hints, $cb) = @_;
    require Carp;
    Carp::croak("getaddrinfo_all: first argument must be an arrayref")
        unless ref $nodes eq 'ARRAY';
    Carp::croak("getaddrinfo_all: callback must be a CODE reference")
        unless ref $cb eq 'CODE';
    Carp::croak("getaddrinfo_all: resolver is destroyed") if $self->is_destroyed;
    return $cb->({}) unless @$nodes;
    my %seen;
    my @unique = grep { !$seen{$_}++ } @$nodes;
    my %res;
    my $pending = @unique;
    for my $node (@unique) {
        $self->getaddrinfo($node, $service, $hints, sub {
            my ($status, @addrs) = @_;
            $res{$node} = { status => $status, addrs => \@addrs };
            $cb->(\%res) if --$pending == 0;
        });
    }
    return;
}

# is_busy: true iff there are pending queries on this resolver.  Cheap
# wrapper for the most common active_queries comparison.
sub is_busy { $_[0]->active_queries > 0 }

# wait_idle($timeout_seconds): pump the EV loop until either all of this
# resolver's pending queries complete or the timeout elapses.  Returns
# true if the channel drained, false on timeout.  Useful in mostly-
# synchronous scripts that want to ensure callbacks have run before
# proceeding.  Returns immediately if the resolver is already idle.
#
# Picks up a custom EV::Loop passed to new(loop => $loop): the timer and
# the run() call are dispatched on the same loop the resolver's watchers
# are armed on.  Without this, custom-loop resolvers would hang because
# EV::run/EV::timer always target the default loop.
sub wait_idle {
    my ($self, $timeout) = @_;
    require Carp;
    Carp::croak("wait_idle: resolver is destroyed") if $self->is_destroyed;
    return 1 unless $self->active_queries;
    $timeout //= 30;
    my $expired;
    my $loop = $self->loop // EV::default_loop;
    my $timer = $loop->timer($timeout, 0, sub { $expired = 1 });
    while ($self->active_queries && !$expired) {
        $loop->run(EV::RUN_ONCE);
    }
    # Look at the resolver's state rather than $expired: if the timer and
    # the last query callback both fire in the same RUN_ONCE iteration,
    # $expired is set but the channel did drain.  Don't lie about that.
    return $self->active_queries ? 0 : 1;
}

sub search_all {
    my ($self, $names, $type, $class_or_cb, $cb) = @_;
    require Carp;
    # search_all($names, $type, $cb)         -> 4 args (class default C_IN)
    # search_all($names, $type, $class, $cb) -> 5 args
    my $class;
    if (@_ == 4) {
        $cb = $class_or_cb;
    } elsif (@_ == 5) {
        $class = $class_or_cb;
        require Scalar::Util;
        Carp::croak("search_all: class must be an integer (C_IN, C_CHAOS, ...)")
            unless Scalar::Util::looks_like_number($class);
    } else {
        Carp::croak("search_all: usage: \$r->search_all(\\\@names, \$type, [\$class,] \$cb)");
    }
    Carp::croak("search_all: first argument must be an arrayref")
        unless ref $names eq 'ARRAY';
    Carp::croak("search_all: callback must be a CODE reference")
        unless ref $cb eq 'CODE';
    Carp::croak("search_all: resolver is destroyed") if $self->is_destroyed;
    return $cb->({}) unless @$names;
    my %seen;
    my @unique = grep { !$seen{$_}++ } @$names;
    my %res;
    my $pending = @unique;
    for my $name (@unique) {
        my $inner = sub {
            my ($status, @records) = @_;
            $res{$name} = { status => $status, records => \@records };
            $cb->(\%res) if --$pending == 0;
        };
        defined $class
            ? $self->search($name, $type, $class, $inner)
            : $self->search($name, $type, $inner);
    }
    return;
}

1;

__END__

=head1 NAME

EV::cares - high-performance async DNS resolver using c-ares and EV

=head1 SYNOPSIS

    use EV;
    use EV::cares qw(:status :types :classes);

    my $r = EV::cares->new(
        servers => ['8.8.8.8', '1.1.1.1'],
        timeout => 5,
        tries   => 3,
    );

    # simple A + AAAA resolve
    $r->resolve('example.com', sub {
        my ($status, @addrs) = @_;
        if ($status == ARES_SUCCESS) {
            print "resolved: @addrs\n";
        } else {
            warn "failed: " . EV::cares::strerror($status) . "\n";
        }
    });

    # auto-parsed DNS search
    $r->search('example.com', T_MX, sub {
        my ($status, @mx) = @_;
        printf "MX %d %s\n", $_->{priority}, $_->{host} for @mx;
    });

    # raw DNS query
    $r->query('example.com', C_IN, T_A, sub {
        my ($status, $buf) = @_;
        # $buf is the raw DNS response packet
    });

    EV::run;

=head1 DESCRIPTION

EV::cares integrates the L<c-ares|https://c-ares.org/> asynchronous DNS
library directly with the L<EV> event loop at the C level.  Socket I/O
and timer management happen entirely in XS with zero Perl-level event
processing overhead.

c-ares drives server rotation, retries, timeouts, and search-domain
appending.  Multiple queries on the same channel run concurrently.

Requires c-ares E<gt>= 1.24 (provided by L<Alien::cares>).
HTTPS/SVCB/TLSA/DS/DNSKEY/RRSIG parsing requires c-ares E<gt>= 1.28;
on older builds those types fall through to the raw response buffer.

=head1 CONSTRUCTOR

=head2 new

    my $r = EV::cares->new(%opts);

All options are optional.

=over 4

=item servers => \@addrs | "addr1,addr2,..."

DNS server addresses.  Default: system resolv.conf servers.

=item timeout => $seconds

Per-try timeout (fractional seconds).

=item maxtimeout => $seconds

Maximum total timeout across all tries.

=item tries => $n

Number of query attempts.

=item ndots => $n

Threshold for treating a name as absolute (skip search suffixes).

=item flags => $flags

Bitmask of C<ARES_FLAG_*> constants.  Flags missing from the linked
c-ares build are exported as C<0> (silent no-op when combined).
C<ARES_FLAG_STAYOPEN> is a no-op here because socket lifecycle is
managed by libev via C<ARES_OPT_SOCK_STATE_CB>.

=item lookups => $string

Lookup order: C<"b"> for DNS, C<"f"> for /etc/hosts.

=item rotate => 1

Round-robin among servers.  Silently ignored on c-ares builds where
C<ARES_OPT_ROTATE> is unavailable.

=item tcp_port => $port

=item udp_port => $port

Non-standard DNS port.

=item ednspsz => $bytes

EDNS0 UDP payload size.

=item resolvconf => $path

Path to an alternative resolv.conf.

=item hosts_file => $path

Path to an alternative hosts file.

=item udp_max_queries => $n

Max queries per UDP connection before reconnect.

=item qcache => $max_ttl

Enable query result cache; C<$max_ttl> is the upper TTL bound in seconds.
0 disables the cache.

=item loop => $ev_loop

L<EV::Loop> for I/O and timer watchers.  Defaults to the EV default
loop.

=back

=head1 QUERY METHODS

Every query method takes a callback as the last argument.  The first
argument to the callback is always a status code (C<ARES_SUCCESS> on
success).

=head2 resolve

    $r->resolve($name, sub { my ($status, @addrs) = @_ });

Resolves C<$name> via C<ares_getaddrinfo> with C<AF_UNSPEC>, returning
both IPv4 and IPv6 address strings.

=head2 resolve_ttl

    $r->resolve_ttl($name, sub {
        my ($status, @records) = @_;
        # @records = ({addr, family, ttl, timeouts, [canonname]}, ...)
    });

Like L</resolve>, but each result is a hashref carrying the per-record
TTL reported by the answering nameserver.  Useful for application-level
caching that respects authoritative TTLs.  When the resolver returned
a CNAME chain, C<canonname> holds the final canonical name.  C<timeouts>
is the c-ares retry count for the underlying query.

=head2 resolve_all

    $r->resolve_all(\@names, sub {
        my ($results) = @_;
        # $results->{$name} = { status => $s, addrs => [...] }
    });

Convenience helper that fires one concurrent C<resolve()> per unique
name and invokes C<$cb> once with a hashref keyed by name.  Duplicate
names are deduplicated before issuing queries.  Calls C<$cb>
synchronously with an empty hashref if the name list is empty.

=head2 reverse_all

    $r->reverse_all(\@ips, sub {
        my ($results) = @_;
        # $results->{$ip} = { status => $s, hosts => [...] }
    });

Bulk reverse-DNS lookup.  One C<reverse()> per unique IP (deduplicated).
Useful for log enrichment.  An invalid IP in the input croaks (same
as the underlying L</reverse>); validate inputs upfront if your data
isn't trusted.

=head2 resolve_ttl_all

    $r->resolve_ttl_all(\@names, sub {
        my ($results) = @_;
        # $results->{$name} = { status => $s, records => [...] }
        # records are {addr, family, ttl, timeouts, [canonname]} hashrefs
    });

Like L</resolve_all>, but each result entry's C<records> contains the
full hashref form (with TTL etc.) produced by L</resolve_ttl>.

=head2 search_all

    $r->search_all(\@names, $type, sub {
        my ($results) = @_;
        # $results->{$name} = { status => $s, records => [...] }
    });
    $r->search_all(\@names, $type, $class, sub { ... });   # explicit class

Like L</resolve_all>, but issues one C<search()> per unique name for
the given record type.  Class defaults to C<C_IN>; pass an explicit
class as the optional fourth argument.  Each result hashref carries
the same C<records> arrayref shape that the underlying L</search>
returns for that type.  Useful for bulk MX, TXT, or HTTPS lookups.

=head2 getaddrinfo_all

    $r->getaddrinfo_all(\@nodes, $service, \%hints, sub {
        my ($results) = @_;
        # $results->{$node} = { status => $s, addrs => [...] }
    });

Bulk L</getaddrinfo>: issues one query per unique node with the same
C<$service>/C<\%hints>, fires the callback once with a hashref keyed by
node when every query has returned.  C<$service> and C<\%hints> may be
C<undef>.  Result entries' C<addrs> reflect whatever the underlying
L</getaddrinfo> would return for those hints (scalars by default, or
TTL hashrefs when C<ttl =E<gt> 1> is set).

=head2 getaddrinfo

    $r->getaddrinfo($node, $service, \%hints, $cb);

Full getaddrinfo.  C<$service> and C<\%hints> may be C<undef>.
Hint keys: C<family>, C<socktype>, C<protocol>, C<flags> (C<ARES_AI_*>),
plus C<ttl =E<gt> 1> to receive
C<{addr, family, ttl, timeouts, [canonname]}> hashrefs instead of bare
strings.  C<canonname> is included only when the answer followed a
CNAME chain.  Callback receives C<($status, @ip_strings)> by default,
or C<@hashrefs> when C<ttl> is set.

C<socktype> defaults to C<SOCK_STREAM> to coalesce duplicate addresses;
pass C<socktype =E<gt> 0> only if you want a separate result entry for
each socktype the resolver returns.

=head2 search

    $r->search($name, $type, sub { my ($status, @records) = @_ });
    $r->search($name, $type, $class, sub { ... });   # explicit class

DNS search (appends search domains from resolv.conf).  Class defaults
to C<C_IN>; pass an explicit class (e.g. C<C_CHAOS> for queries like
C<version.bind>) as the optional third argument.  Results are auto-parsed based on C<$type>:

    T_A, T_AAAA       @ip_strings
    T_NS, T_PTR       @hostnames
    T_TXT             @strings
    T_MX              @{ {priority, host} }
    T_SRV             @{ {priority, weight, port, target} }
    T_SOA             {mname, rname, serial, refresh, retry,
                       expire, minttl}
    T_NAPTR           @{ {order, preference, flags, service,
                          regexp, replacement} }
    T_CAA             @{ {critical, property, value} }
    T_HTTPS, T_SVCB   @{ {priority, target, params => \%p} }
    T_TLSA            @{ {cert_usage, selector,
                          matching_type, data} }
    T_DS              @{ {key_tag, algorithm,
                          digest_type, digest} }
    T_DNSKEY          @{ {flags, protocol, algorithm,
                          public_key} }
    T_RRSIG           @{ {type_covered, algorithm, labels,
                          original_ttl, sig_expiration,
                          sig_inception, key_tag,
                          signer_name, signature} }
    T_CNAME, T_ANY,
    other             $raw_dns_response_buffer (a wire-format DNS
                      packet -- feed it to e.g. Net::DNS::Packet
                      to decode further)

For TLSA (DANE, RFC 6698), C<data> is the raw fingerprint / certificate
bytes; the integer fields are C<cert_usage> (0..3), C<selector> (0..1),
and C<matching_type> (0..2).  TLSA parsing requires c-ares E<gt>= 1.28.

For DS / DNSKEY / RRSIG (DNSSEC, RFC 4034) binary fields are raw
wire-format bytes; integer fields use host byte order.  C<digest>,
C<public_key>, and C<signature> are unmodified base64-able blobs.
C<signer_name> is the uncompressed dotted owner name (RFC 4034 sec 3.1.7).
Some recursive resolvers strip these records unless EDNS is enabled
(C<< flags => ARES_FLAG_EDNS >>); a validating upstream may also be
required if the default refuses to forward them.

For HTTPS/SVCB, C<%p> may contain C<alpn> (arrayref of protocol IDs),
C<no_default_alpn> (1 if set), C<port> (integer), C<ipv4hint> /
C<ipv6hint> (arrayrefs of address strings), C<ech> (opaque bytes),
C<dohpath> (string), and any unrecognized SVCB param as
C<keyN =E<gt> $bytes>.  Parsing requires c-ares E<gt>= 1.28; on older
c-ares HTTPS/SVCB falls through to the raw buffer like unknown types.

=head2 query

    $r->query($name, $class, $type, sub { my ($status, $buf) = @_ });

Raw DNS query without search-domain appending.  Returns the unmodified
DNS response packet.

=head2 gethostbyname

    $r->gethostbyname($name, $family, sub { my ($status, @addrs) = @_ });

Legacy resolver.  C<$family> is C<AF_INET> or C<AF_INET6>.

=head2 reverse

    $r->reverse($ip, sub { my ($status, @hostnames) = @_ });

Reverse DNS (PTR) lookup for an IPv4 or IPv6 address string.

=head2 getnameinfo

    $r->getnameinfo($packed_sockaddr, $flags, sub {
        my ($status, $node, $service) = @_;
    });

Full getnameinfo.  C<$packed_sockaddr> comes from
L<Socket/pack_sockaddr_in> or L<Socket/pack_sockaddr_in6>.
C<$flags> is a bitmask of C<ARES_NI_*> constants.  Note that
C<ARES_NI_TCP> is C<0> (TCP is the default); pass C<ARES_NI_DGRAM>
or equivalently C<ARES_NI_UDP> (both denote the same value) to select
datagram-mode lookups.

=head1 CHANNEL METHODS

=head2 cancel

Cancel all pending queries.  Each outstanding callback fires with
C<ARES_ECANCELLED>.  Safe to call from within a callback.  Croaks
if called on a destroyed resolver -- guard with L</is_destroyed> if
you may race a destroy.

=head2 set_servers

    $r->set_servers('8.8.8.8', '1.1.1.1');
    $r->set_servers(['8.8.8.8', '1.1.1.1:5353']);
    $r->set_servers([
        { host => '1.1.1.1' },
        { host => '8.8.8.8', port => 53 },
    ]);

Replace the DNS server list.  Accepts a flat list, an arrayref of
strings (each may be C<"host:port">), or an arrayref of
C<< { host => ..., port => ... } >> hashrefs.  Croaks if no server is
given.

=head2 set_sortlist

    $r->set_sortlist('192.168.0.0/255.255.0.0 ::1/128');

Set the address-sortlist for ordering returned addresses.  See c-ares'
C<ares_set_sortlist> for the format (CIDR / netmask pairs separated by
whitespace).  Croaks on parse error.

=head2 servers

    my $csv = $r->servers;   # "8.8.8.8,1.1.1.1"

Returns the current server list as a comma-separated string.

=head2 set_local_dev

    $r->set_local_dev('eth0');

Bind outgoing queries to a network device.

=head2 set_local_ip4

    $r->set_local_ip4('192.168.1.100');

Bind outgoing queries to a local IPv4 address.

=head2 set_local_ip6

    $r->set_local_ip6('::1');

Bind outgoing queries to a local IPv6 address.

=head2 loop

    my $loop = $r->loop;   # EV::Loop ref, or undef for default loop

Returns the C<EV::Loop> the resolver's watchers are armed on, as passed
to C<new(loop =E<gt> ...)>.  Returns C<undef> when the resolver runs on
EV's default loop, and also C<undef> after C<destroy> (the loop
reference is released as part of cleanup).  Read-only.

=head2 active_queries

    my $n = $r->active_queries;

Returns the number of outstanding queries.  Remains callable after
C<destroy>; returns C<0> in that case (during interpreter global
destruction the count may reflect whatever was pending, since
C<ares_destroy> is intentionally skipped on the global-destruction
path).

=head2 is_busy

    if ($r->is_busy) { ... }

Convenience wrapper for C<< $r->active_queries > 0 >>.

=head2 wait_idle

    my $drained = $r->wait_idle;          # default 30s timeout
    my $drained = $r->wait_idle($seconds);

Pumps the EV loop until every pending query on this resolver has fired
its callback, or until the timeout elapses.  Returns true if the
channel drained, false on timeout.  Returns immediately when the
resolver is already idle.  Croaks on a destroyed resolver.

Intended for mostly-synchronous scripts that issue a batch of queries
and want to ensure their callbacks have run before continuing.  Inside
a long-running event-driven program you generally don't need this -- let
the existing C<EV::run> drive callbacks.

Must not be called recursively on the same resolver: invoking
C<wait_idle> from inside a query callback whose enclosing C<wait_idle>
is still pumping the loop can let the outer timeout timer fire during
the nested pump and report a spurious timeout.

=head2 is_destroyed

    if ($r->is_destroyed) { ... }

Returns 1 if C<destroy> has been called on this resolver, 0 otherwise.
Useful in long-running daemons that want to skip work without croaking
on a torn-down channel.  Remains callable after C<destroy>.

=head2 next_timeout

    my $secs = $r->next_timeout;

Returns the seconds until c-ares' next internal timer (e.g. retry
window for an in-flight query), or C<-1> if no timer is pending.
Useful for wiring EV::cares into custom scheduling or for diagnosing
a slow upstream.  Croaks on a destroyed resolver.

=head2 last_query_timeouts

    my $n = $r->last_query_timeouts;

Returns the c-ares retry/timeout count of the most recently completed
callback.  Useful for tuning per-server timeouts; note that with
multiple in-flight queries this is whichever callback fired most
recently and races accordingly.  Remains callable after C<destroy>.

=head2 reinit

    $r->reinit;

Re-read system DNS configuration (resolv.conf, hosts file) without
destroying the channel.  Useful for long-running daemons where the
resolver configuration may change at runtime.

=head2 destroy

    $r->destroy;

Explicitly release the c-ares channel and stop all watchers.  Pending
callbacks fire with C<ARES_EDESTRUCTION>.  Safe to call from within a
callback or twice in a row.  Also called automatically when the object
is garbage-collected.

=head1 FUNCTIONS

=head2 strerror

    my $msg = EV::cares::strerror($status);
    my $msg = EV::cares->strerror($status);   # also works

Returns a human-readable string for a status code.

=head2 lib_version

    my $ver = EV::cares::lib_version();   # e.g. "1.34.6"

Returns the c-ares library version string.

=head2 ptr_name

    my $arpa = EV::cares::ptr_name('192.0.2.1');   # 1.2.0.192.in-addr.arpa
    my $arpa = EV::cares::ptr_name('2001:db8::1'); # ...ip6.arpa

Pure-Perl utility that converts an IPv4 or IPv6 literal to its reverse
DNS name (C<.in-addr.arpa> or C<.ip6.arpa>).  No DNS query is issued;
useful when you want to look up the reverse zone yourself via C<query>
or C<search>.

=head2 parse_header

    my $h = EV::cares::parse_header($raw_dns_response);

Decode the 12-byte DNS header.  Returns a hashref with C<id>, C<qr>,
C<opcode>, C<aa>, C<tc>, C<rd>, C<ra>, C<z>, C<ad>, C<cd>, C<rcode>,
C<qdcount>, C<ancount>, C<nscount>, C<arcount>.  Useful on the raw
buffer from C<query> or unrecognized C<search> types -- e.g. check
C<ad> for the upstream resolver's DNSSEC validation claim.

=head1 CALLBACK SAFETY

Callbacks fire from within C<ares_process_fd>, driven by EV I/O and
timer watchers.  Exceptions are caught (C<G_EVAL>) and emitted as
warnings; they do not propagate to the caller.

C<cancel>, C<destroy>, and dropping the last reference to the resolver
are all safe from inside a callback.  Outstanding queries on the same
channel receive C<ARES_ECANCELLED> or C<ARES_EDESTRUCTION>.

Local-only lookups (C<< lookups => 'f' >>, hosts-file matches, cached
results) may complete synchronously inside the initiating method call;
write your code so it tolerates that.

=head1 SECURITY

=over 4

=item Plain DNS is unauthenticated

The default UDP/TCP transport carries no integrity or origin
authentication; an on-path attacker can spoof responses.  Do not treat
any DNS reply as a trust anchor by itself.

=item DNSSEC records are parsed but I<not> validated

This module parses C<DS>, C<DNSKEY>, C<RRSIG>, and C<TLSA> wire-format
records into Perl hashrefs (see L</search>) so you can inspect their
fields.  It does I<not> verify the cryptographic chain of trust.  If
your application depends on validated DNSSEC, run a validating
recursive resolver and rely on the C<AD> bit in the response header
(extract via L</parse_header> on a raw L</query> response).

=item The AD bit is the upstream resolver's claim

The C<AD> bit returned by L</parse_header> reflects what the recursive
resolver tells you about validation.  It is not a cryptographic
guarantee from this code.  Use only over a trusted transport (loopback
to a local validator, or DoT/DoH where supported by your platform's
c-ares build).

=item No DoT/DoH in c-ares 1.34's CSV parser

As of c-ares 1.34 only the C<dns://> URI scheme is accepted by
C<ares_set_servers_csv> (which this module calls).  C<dns+tls://> and
C<dns+https://> URI forms are not yet supported.  Track c-ares releases
for upstream availability.

=back

=head1 EXPORT TAGS

    :status    ARES_SUCCESS  ARES_ENODATA  ARES_ETIMEOUT  ...
    :types     T_A  T_AAAA  T_MX  T_SRV  T_TXT  T_NS  T_SOA  ...
    :classes   C_IN  C_CHAOS  C_HS  C_ANY
    :flags     ARES_FLAG_USEVC  ARES_FLAG_EDNS  ARES_FLAG_DNS0x20  ...
    :ai        ARES_AI_CANONNAME  ARES_AI_ADDRCONFIG  ARES_AI_NOSORT  ...
    :ni        ARES_NI_NOFQDN  ARES_NI_NUMERICHOST  ...
    :families  AF_INET  AF_INET6  AF_UNSPEC
    :all       all of the above

=head1 SEE ALSO

L<EV>, L<Alien::cares>, L<https://c-ares.org/>.

The F<eg/> directory has runnable examples: a dig-style CLI, HTTPS/SVCB
and TLSA/DANE inspection, DNSSEC zone trace, email-posture checks,
MX-to-SMTP probe, log-IP enrichment, a minimal UDP DNS proxy, Mojo
interop, and a L<Future>-based parallel resolve.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

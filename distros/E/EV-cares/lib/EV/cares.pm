package EV::cares;
use strict;
use warnings;
use EV;

BEGIN {
    our $VERSION = '0.01';
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
    T_A T_NS T_CNAME T_SOA T_PTR T_MX T_TXT T_AAAA T_SRV T_NAPTR T_CAA T_ANY
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

1;

__END__

=head1 NAME

EV::cares - high-performance async DNS resolver using c-ares and EV

=head1 SYNOPSIS

    use EV;
    use EV::cares qw(:status :types);

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

Multiple queries run concurrently.  c-ares handles server rotation,
retries, timeouts, and search-domain appending.

Requires c-ares E<gt>= 1.22.0 (provided automatically by L<Alien::cares>).

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

Bitmask of C<ARES_FLAG_*> constants.

=item lookups => $string

Lookup order: C<"b"> for DNS, C<"f"> for /etc/hosts.

=item rotate => 1

Round-robin among servers.

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

=back

=head1 QUERY METHODS

Every query method takes a callback as the last argument.  The first
argument to the callback is always a status code (C<ARES_SUCCESS> on
success).

=head2 resolve

    $r->resolve($name, sub { my ($status, @addrs) = @_ });

Resolves C<$name> via C<ares_getaddrinfo> with C<AF_UNSPEC>, returning
both IPv4 and IPv6 address strings.

=head2 getaddrinfo

    $r->getaddrinfo($node, $service, \%hints, $cb);

Full getaddrinfo.  C<$service> and C<\%hints> may be C<undef>.
Hint keys: C<family>, C<socktype>, C<protocol>, C<flags> (C<ARES_AI_*>).
Callback receives C<($status, @ip_strings)>.

=head2 search

    $r->search($name, $type, sub { my ($status, @records) = @_ });

DNS search (appends search domains from resolv.conf), always using
C<C_IN> class.  Results are auto-parsed based on C<$type>:

    T_A, T_AAAA    ($status, @ip_strings)
    T_MX           ($status, @{ {priority, host} })
    T_SRV          ($status, @{ {priority, weight, port, target} })
    T_TXT          ($status, @strings)
    T_NS           ($status, @hostnames)
    T_SOA          ($status, {mname, rname, serial, refresh,
                              retry, expire, minttl})
    T_PTR          ($status, @hostnames)
    T_NAPTR        ($status, @{ {order, preference, flags,
                                 service, regexp, replacement} })
    T_CAA          ($status, @{ {critical, property, value} })
    T_CNAME etc.   ($status, $raw_buffer)

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
C<$flags> is a bitmask of C<ARES_NI_*> constants.

=head1 CHANNEL METHODS

=head2 cancel

Cancel all pending queries.  Each outstanding callback fires with
C<ARES_ECANCELLED>.

=head2 set_servers

    $r->set_servers('8.8.8.8', '1.1.1.1');

Replace the DNS server list.

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

=head2 active_queries

    my $n = $r->active_queries;

Returns the number of outstanding queries.

=head2 reinit

    $r->reinit;

Re-read system DNS configuration (resolv.conf, hosts file) without
destroying the channel.  Useful for long-running daemons where the
resolver configuration may change at runtime.

=head2 destroy

    $r->destroy;

Explicitly release the c-ares channel and stop all watchers.
Pending callbacks fire with C<ARES_ECANCELLED> or C<ARES_EDESTRUCTION>.
Safe to call from within a callback.  Also called automatically when
the object is garbage-collected.

=head1 FUNCTIONS

=head2 strerror

    my $msg = EV::cares::strerror($status);
    my $msg = EV::cares->strerror($status);   # also works

Returns a human-readable string for a status code.

=head2 lib_version

    my $ver = EV::cares::lib_version();   # e.g. "1.34.6"

Returns the c-ares library version string.

=head1 CALLBACK SAFETY

Callbacks are invoked from within C<ares_process_fd>, called from EV I/O
and timer watchers.  Exceptions thrown inside callbacks are caught
(C<G_EVAL>) and emitted as warnings; they do not propagate to the caller.

It is safe to call C<cancel>, C<destroy>, or C<undef> the resolver from
within a callback.  Remaining pending queries will receive
C<ARES_ECANCELLED>.

Lookups that use only local sources (C<< lookups => 'f' >>) may complete
synchronously during the initiating method call.

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

L<EV>, L<Alien::cares>, L<https://c-ares.org/>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

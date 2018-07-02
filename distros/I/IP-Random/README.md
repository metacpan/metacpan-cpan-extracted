# NAME

IP::Random - Generate IP Addresses Randomly

# VERSION

version 1.006

# SYNOPSIS

    use IP::Random qw(random_ipv4);

    my $ipv4 = random_ipv4();

# DESCRIPTION

This provides a random IP (IPv4 only currently) address, with some
extensability to exclude undesired IPv4 addresses (I.E. don't return
IP addresses that are in the multicast or RFC1918 ranges).

By default, the IP returned is a valid, publicly routable IP address,
but this behavior can be adjusted.

# FUNCTIONS

## random\_ipv4()

Returns a random IPv4 address to the caller (as a scalar string - I.E.
in the format "1.2.3.4").  There are several named optional parameters
available:

- rand

    This allows replacement of the random number generator.  By default, the
    generator used is:

        sub { int(rand(shift() + 1)) }

    The code referenced passed as rand is called as a function with two
    arguments.  The first argument is the maximum integer to generate (it
    must accept values up to at least 255).  This will always be 255 when
    called by `random_ipv4()`, but is allowed to be specified to allow a
    generic routine to be used for future IPv4 and IPv6 address generation.

    The second argument (which probably won't be used by most generators)
    is the octet number starting at 1, from the left to right.

        my $rand = sub { int( rand( ( shift() +1 ) / 2 ) * 2 ) };
        my $ipv4 = random_ipv4( rand => $rand );

    The above code would return only even numbers for all 4 octets of the
    IPv4 address (this is probably not terribly useful).

    If you want to modify various arguments, perhaps excluding IP addresses
    ending in `.0` and `255`, you could do something like:

        my $rand = sub {
          my ( $max, $octet ) = @_;

          if ( $octet == 3 ) {    # Last (least significant) Octet
            return int( rand( $max / 2 - 1 ) * 2 ) + 2;
          } else {
            return int( rand( shift() +1 ) );
          }
        }
        my $ipv4 = random_ipv4( rand => $rand );

- exclude

    This is an array reference of CIDRs (in string format) to exclude from
    the results.  See `default_exclude()` for the default list, which
    excludes addresses such as RFC1918 (private) IP addresses.  If passed an
    empty list reference such as `[]`, it will not exclude any IPs.  This is
    almost certainly not what you desire (since it may return IPs in class D and
    class E space - such as `224.1.1.1` or `255.254.253.252`).

    You might be better served by looking at `additional_types_allowed`.

    By default, the default exclude list will include all IP addresses that
    can, with certainty, be considered non-global IP addresses - for
    instance, RFC1918 addresses.  It may include IP addresses that are not
    actually on the internet, however.  A use might be to exclude an
    organization's own internal IPs.  In that case, you should take the
    default excludes and add an additional exclude:

        my $ipv4 = random_ipv4(
          exclude => [ default_exclude(), '4.2.2.1/32' ] );

    Of course this particular example can also be done with
    the `additional_exclude` optional parameter.

    Note that `exclude` cannot be used with `additional_types_allowed`.

- additional\_exclude

    Adds a list of exclude items, similar to exclude, but without removing
    the default exclude list.  See the `exclude` parameter above.  Like
    the `exclude` parameter, this expects to be a list reference.

    Example, to exclude a signle IP:

        my $ipv4 = rand_ipv4( additional_exclude => [ '4.2.2.1/32' ] );

- additional\_types\_allowed

    This is an array refence of strings that contain the "groups" you do
    not want to exclude by default.  For instance, you may want to use
    some/all RFC1918 addresses.

    Valid groups:

    - rfc919

        Limited broadcast address (`255.255.255.255/32`).

    - rfc1112

        Multicast addresses (`240.0.0.0/4`)

    - rfc1122

        Basic protocol design (`0.0.0.0/8`, `127.0.0.0/8`)

    - rfc1918

        Private-use networks (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`)

    - rfc2544

        Network interconnect device benchmark testing (`198.18.0.0/15`)

    - rfc3068

        6to4 relay anycast (`192.88.99.0/24`)

    - rfc3171

        Multicast (`224.0.0.0/4`)

    - rfc3927

        Link local (`169.254.0.0/16`)

    - rfc5736

        IETF protocol assignments (`192.0.0.0/24`)

    - rfc5737

        Documentation Addresses (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`)

    - rfc6598

        Shared address space / Carrier NAT (`100.64.0.0/10`)

    A typical use might be to include `10.x.x.x` RFC1918 addresses among
    possible addresses to return.  This example allows addresses in the
    `10.x.x.x` range while continuing to exclude `172.16.0.0/12` and
    `192.168.0.0/16`:

        my $ipv4 = random_ipvr(
          additional_types_allowed => [ 'rfc1918' ],
          additional_exclude       => [ '172.16.0.0/20', '192.168.0.0/16' ]
        );

## in\_ipv4\_subnet($subnet\_cidr, $ip)

This is a helper function that tests whether an IP (passed as a string
in the format "192.0.2.1") is in a subnet passed in string CIDR
notation (for instance, "192.0.2.0/24").

Returns a true value if the IP is contained in the subnet, otherwise
returns false.

Example, which returns a true value:

    if (in_ipv4_subnet('127.0.0.0/8', '127.0.0.1')) {
      say "Is loopback!";
    }

## default\_ipv4\_exclude()

Returns the default exclude list for IPv4, as a list reference
containing CIDR strings.

Additional CIDRs may be added to future versions, but in no case will
standard Unicast publicly routable IPs be added.

This list contains:

- 0.0.0.0/8

    "This" Network (RFC1122, Section 3.2.1.3)

- 10.0.0.0/8

    Private-Use Networks (RFC1918)

- 100.64.0.0/10

    Shared Address Space (RFC6598)

- 127.0.0.0/8

    Loopback (RFC1122, Section 3.2.1.3)

- 169.254.0.0/16

    Link Local (RFC 3927)

- 172.16.0.0/12

    Private-Use Networks (RFC1918)

- 192.0.0.0/24

    IETF Protocol Assignments (RFC5736)

- 192.0.2.0/24

    TEST-NET-1 (RFC5737)

- 192.88.99.0/24

    6-to-4 Anycast (RFC3068)

- 192.168.0.0/16

    Private-Use Networks (RFC1918)

- 198.18.0.0/15

    Network Interconnect Device Benchmark Testing (RFC2544)

- 198.51.100.0/24

    TEST-NET-2 (RFC5737)

- 203.0.113.0/24

    TEST-NET-3 (RFC5737)

- 224.0.0.0/4

    Multicast (RFC3171)

- 240.0.0.0/4

    Reserved for Future Use (RFC 1112, Section 4)

# SECURITY WARNING

The default random number generator used in this code is not
cryptographically secure.  See the `rand` option to `random_ipv4()`
for information on how to substitute a different random number function.

# TODO AND BUGS

This version uses a pretty ugly algorithm to generate the IP addresses.
It's basically generating a unique IP address and then testing against
the exclude list.  It'll probably be a lot nicer to call the random
function in a way that minimizes the amount of unnecessary calls (I.E.
the first call shoudln't generally ask for an integer between zero and
255 since only 1 to 223 is actually allowable).  A better approach
would be to figure out how many IP addresses are available to be returned
and then select a random one of those (basically a pick).

Methods to efficiently select non-duplicate IPs should be available.  If
the above is done, this should be reasonably feasible.

An OO interface may be nice to minimize per-call processing each time the
above are done.

It should be possible to provide ranges that are acceptable to use for
the generated IPs.  Basically the opposite of "exclude" (but excludes
should be applied afterwards still).

IPv6 support must be added.  IPv4 is a subset of IPv6, so there should
be one set of pick functions and the like, with wrappers to handle
conversion of IPv4 to IPv6 and back, when needed.

I have plans to port this to Perl 6.

# AUTHOR

Joelle Maslak <jmaslak@antelope.net>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Joelle Maslak.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

#!/usr/bin/perl

#
# Copyright (C) 2016 J. C. Maslak
# All Rights Reserved - See License
#

package IP::Random;
$IP::Random::VERSION = '1.003';
# ABSTRACT: Generate IP Addresses Randomly


# Some boilerplate
use v5.20;
use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Carp;
use List::Util qw(none notall pairs);
use Socket qw(inet_aton);

my $DEFAULT_IPV4_EXCLUDE = {
    '0.0.0.0/8'          => 'rfc1122',
    '10.0.0.0/8'         => 'rfc1918',
    '100.64.0.0/10'      => 'rfc6598',
    '127.0.0.0/8'        => 'rfc1122',
    '169.254.0.0/16'     => 'rfc3927',
    '172.16.0.0/12'      => 'rfc1918',
    '192.0.0.0/24'       => 'rfc5736',
    '192.0.2.0/24'       => 'rfc5737',
    '192.88.99.0/24'     => 'rfc3068',
    '192.168.0.0/16'     => 'rfc1918',
    '198.18.0.0/15'      => 'rfc2544',
    '198.51.100.0/24'    => 'rfc5737',
    '203.0.113.0/24'     => 'rfc5737',
    '224.0.0.0/4'        => 'rfc3171',
    '240.0.0.0/4'        => 'rfc1112',
    '255.255.255.255/32' => 'rfc919',
};


sub random_ipv4 ( %args ) {
    $args{rand} //= sub { int( rand( shift() + 1 ) ) };

    # Can't have exclude and additional_types_allowed both existing
    if ( exists( $args{exclude} ) && exists( $args{additional_types_allowed} ) )
    {
        croak(  "Cannot define both 'exclude' and "
              . "'additional_types_allowed' parameters" );
    }

    # This saves us some later branches
    # Define defaults
    $args{additional_types_allowed} //= [];
    $args{additional_exclude}       //= [];

    # What are valid option names?
    my $optre = qr/\A(?:rand|exclude|additional_(?:types_allowed|exclude))\z/;

    # Make sure all options are valid
    if ( notall { m/$optre/ } keys %args ) {
        my (@bad) = grep { !m/$optre/ } keys %args;
        croak( "unknown named argument passed to random_ipv4: " . $bad[0] );
    }

    # Get default excludes
    if ( !defined( $args{exclude} ) ) {
        $args{exclude} =
          _get_ipv4_excludes( $args{additional_types_allowed} );
    }

    # Build a closure for checking to see if an address is excluded
    my (@exclude_all) = ( @{ $args{exclude} }, @{ $args{additional_exclude} } );
    my $is_not_excluded = sub($addr) {
        none { in_ipv4_subnet( $_, $addr ) } @exclude_all;
    };

    my $addr;
    do {
        my @parts;
        for my $octet ( 1 .. 4 ) {
            push @parts, $args{rand}->( 255, $octet );
        }
        $addr = join '.', @parts;
    } until $is_not_excluded->($addr);

    return $addr;
}

# Private sub to build the default list of excludes, when passed a list
# of additional types allowed
#
# Returns a list ref
sub _get_ipv4_excludes( $addl_types ) {
    my @ret = grep {
        my $k = $_;
        none { $DEFAULT_IPV4_EXCLUDE->{$k} eq $_ } @{ $addl_types }
    } keys %{ $DEFAULT_IPV4_EXCLUDE };

    return \@ret;
}


sub in_ipv4_subnet ( $sub_cidr, $ip ) {
    if ( !defined($sub_cidr) ) { confess("subnet_cidr is not defined"); }
    if ( !defined($ip) )       { confess("ip is not defined"); }

    if ( $sub_cidr !~ m/\A(?:[\d\.]+)(?:\/(?:\d+))?\z/ ) {
        confess("$sub_cidr is not in the format A.B.C.D/N");
    }
    my ( $sub_net, $sub_mask ) = $sub_cidr =~ m/\A([\d\.]+)(?:\/(\d+))?\z/ms;
    $sub_mask //= 32;

    my $addr = unpack( 'N', inet_aton( $ip ) );
    my $sub  = unpack( 'N', inet_aton( $sub_net ) );

    my $mask = 0;
    for ( 1 .. $sub_mask ) {
        $mask = $mask >> 1;
        $mask = $mask | ( 1 << 31 );
    }

    if ( ( $addr & $mask ) == ( $sub & $mask ) ) {
        return 1;
    }

    return undef;
}


sub default_ipv4_exclude() {
    return _get_ipv4_excludes( [] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IP::Random - Generate IP Addresses Randomly

=head1 VERSION

version 1.003

=head1 SYNOPSIS

  use IP::Random qw(random_ipv4);

  my $ipv4 = random_ipv4();

=head1 DESCRIPTION

This provides a random IP (IPv4 only currently) address, with some
extensability to exclude undesired IPv4 addresses (I.E. don't return
IP addresses that are in the multicast or RFC1918 ranges).

By default, the IP returned is a valid, publicly routable IP address,
but this behavior can be adjusted.

=head1 FUNCTIONS

=head2 random_ipv4()

Returns a random IPv4 address to the caller (as a scalar string - I.E.
in the format "1.2.3.4").  There are several named optional parameters
available:

=over 4

=item rand

This allows replacement of the random number generator.  By default, the
generator used is:

  sub { int(rand(shift() + 1)) }

The code referenced passed as rand is called as a function with two
arguments.  The first argument is the maximum integer to generate (it
must accept values up to at least 255).  This will always be 255 when
called by C<random_ipv4()>, but is allowed to be specified to allow a
generic routine to be used for future IPv4 and IPv6 address generation.

The second argument (which probably won't be used by most generators)
is the octet number starting at 1, from the left to right.

  my $rand = sub { int( rand( ( shift() +1 ) / 2 ) * 2 ) };
  my $ipv4 = random_ipv4( rand => $rand );

The above code would return only even numbers for all 4 octets of the
IPv4 address (this is probably not terribly useful).

If you want to modify various arguments, perhaps excluding IP addresses
ending in C<.0> and C<255>, you could do something like:

  my $rand = sub {
    my ( $max, $octet ) = @_;

    if ( $octet == 3 ) {    # Last (least significant) Octet
      return int( rand( $max / 2 - 1 ) * 2 ) + 2;
    } else {
      return int( rand( shift() +1 ) );
    }
  }
  my $ipv4 = random_ipv4( rand => $rand );

=item exclude

This is an array reference of CIDRs (in string format) to exclude from
the results.  See C<default_exclude()> for the default list, which
excludes addresses such as RFC1918 (private) IP addresses.  If passed an
empty list reference such as C<[]>, it will not exclude any IPs.  This is
almost certainly not what you desire (since it may return IPs in class D and
class E space - such as C<224.1.1.1> or C<255.254.253.252>).

You might be better served by looking at C<additional_types_allowed>.

By default, the default exclude list will include all IP addresses that
can, with certainty, be considered non-global IP addresses - for
instance, RFC1918 addresses.  It may include IP addresses that are not
actually on the internet, however.  A use might be to exclude an
organization's own internal IPs.  In that case, you should take the
default excludes and add an additional exclude:

  my $ipv4 = random_ipv4(
    exclude => [ default_exclude(), '4.2.2.1/32' ] );

Of course this particular example can also be done with
the C<additional_exclude> optional parameter.

Note that C<exclude> cannot be used with C<additional_types_allowed>.

=item additional_exclude

Adds a list of exclude items, similar to exclude, but without removing
the default exclude list.  See the C<exclude> parameter above.  Like
the C<exclude> parameter, this expects to be a list reference.

Example, to exclude a signle IP:

  my $ipv4 = rand_ipv4( additional_exclude => [ '4.2.2.1/32' ] );

=item additional_types_allowed

This is an array refence of strings that contain the "groups" you do
not want to exclude by default.  For instance, you may want to use
some/all RFC1918 addresses.

Valid groups:

=over 4

=item rfc919

Limited broadcast address (C<255.255.255.255/32>).

=item rfc1122

Basic protocol design (C<0.0.0.0/8>, C<127.0.0.0/8>, C<240.0.0.0/4>)

=item rfc1918

Private-use networks (C<10.0.0.0/8>, C<172.16.0.0/12>, C<192.168.0.0/16>)

=item rfc2544

Network interconnect device benchmark testing (C<198.18.0.0/15>)

=item rfc3068

6to4 relay anycast (C<192.88.99.0/24>)

=item rfc3171

Multicast (C<224.0.0.0/4>)

=item rfc3927

Link local (C<169.254.0.0/16>)

=item rfc5736

IETF protocol assignments (C<192.0.0.0/24>)

=item rfc5737

Documentation Addresses (C<192.0.2.0/24>, C<198.51.100.0/24>, C<203.0.113.0/24>)

=item rfc6598

Shared address space / Carrier NAT (C<100.64.0.0/10>)

=back

A typical use might be to include C<10.x.x.x> RFC1918 addresses among
possible addresses to return.  This example allows addresses in the
C<10.x.x.x> range while continuing to exclude C<172.16.0.0/12> and
C<192.168.0.0/16>:

  my $ipv4 = random_ipvr(
    additional_types_allowed => [ 'rfc1918' ],
    additional_exclude       => [ '172.16.0.0/20', '192.168.0.0/16' ]
  );

=back

=head2 in_ipv4_subnet($subnet_cidr, $ip)

This is a helper function that tests whether an IP (passed as a string
in the format "192.0.2.1") is in a subnet passed in string CIDR
notation (for instance, "192.0.2.0/24").

Returns a true value if the IP is contained in the subnet, otherwise
returns false.

Example, which returns a true value:

  if (in_ipv4_subnet('127.0.0.0/8', '127.0.0.1')) {
    say "Is loopback!";
  }

=head2 default_ipv4_exclude()

Returns the default exclude list for IPv4, as a list reference
containing CIDR strings.

Additional CIDRs may be added to future versions, but in no case will
standard Unicast publicly routable IPs be added.

This list contains:

=over 4

=item 0.0.0.0/8

"This" Network (RFC 1122, Section 3.2.1.3)

=item 10.0.0.0/8

Private-Use Networks (RFC1918)

=item 100.64.0.0/10

Shared Address Space (RFC6598)

=item 127.0.0.0/8

Loopback (RFC 1122, Section 3.2.1.3)

=item 169.254.0.0/16

Link Local (RFC 3927)

=item 172.16.0.0/12

Private-Use Networks (RFC1918)

=item 192.0.0.0/24

IETF Protocol Assignments (RFC5736)

=item 192.0.2.0/24

TEST-NET-1 (RFC5737)

=item 192.88.99.0/24

6-to-4 Anycast (RFC3068)

=item 192.168.0.0/16

Private-Use Networks (RFC1918)

=item 198.18.0.0/15

Network Interconnect Device Benchmark Testing (RFC2544)

=item 198.51.100.0/24

TEST-NET-2 (RFC5737)

=item 203.0.113.0/24

TEST-NET-3 (RFC5737)

=item 224.0.0.0/4

Multicast (RFC3171)

=item 240.0.0.0/4

Reserved for Future Use (RFC 1112, Section 4)

=back

=head1 SECURITY WARNING

The default random number generator used in this code is not
cryptographically secure.  See the C<rand> option to C<random_ipv4()>
for information on how to substitute a different random number function.

=head1 TODO AND BUGS

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

=head1 AUTHOR

J. Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by J. Maslak.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

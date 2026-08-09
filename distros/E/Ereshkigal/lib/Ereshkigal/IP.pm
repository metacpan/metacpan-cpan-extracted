package Ereshkigal::IP;

use 5.006;
use strict;
use warnings;
use Exporter     qw( import );
use Regexp::IPv4 qw( $IPv4_re );
use Regexp::IPv6 qw( $IPv6_re );
use Socket       qw( AF_INET6 inet_ntop inet_pton );

=pod

=head1 NAME

Ereshkigal::IP - Exportable IP validation and normalization helper shared by the Ereshkigal modules.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

our @EXPORT_OK = qw( normalize_ip normalize_cidr );

=head1 SYNOPSIS

    use Ereshkigal::IP qw( normalize_ip normalize_cidr );

    my $ip = normalize_ip('2001:0DB8:0000:0000:0000:0000:0000:0001');
    # $ip is now '2001:db8::1'

    if ( !defined( normalize_ip($raw_ip) ) ) {
        die( '"' . $raw_ip . '" does not appear to be an IPv4 or IPv6 IP' );
    }

    my $cidr = normalize_cidr('1.2.3.4/24');
    # $cidr is now '1.2.3.0/24' with the host bits masked off

=head1 DESCRIPTION

This holds the C<normalize_ip> and C<normalize_cidr> subs used for validating
IPs and CIDR ranges and reducing them to a single canonical string form, so
variant spellings of the same IP, most notably IPv6 long form vs short form
as well as case, cannot be mistaken for differing IPs. C<normalize_cidr>
additionally masks the host bits off, so C<1.2.3.4/24> and C<1.2.3.0/24> are
one range rather than two. Anything unparseable comes back as undef, letting
garbage be bounced at the point of entry instead of being passed along for
something further down to bounce.

=head1 EXPORTS

Nothing is exported by default. L</normalize_ip> and L</normalize_cidr> are
available via C<@EXPORT_OK>.

=head1 FUNCTIONS

=head2 normalize_ip

Returns the canonical string form of the passed IP. If it does not validate
as either an IPv4 or IPv6 IP, undef is returned. undef and refs also return
undef.

    my $ip = normalize_ip($raw_ip);

Validation is done via L<Regexp::IPv4> and L<Regexp::IPv6>, the same as
L<Net::Firewall::BlockerHelper> uses, so anything accepted here is also
acceptable to the backends. On top of that IPv4 with leading zero octets,
such as 010.0.0.1, which the regex permits, is explicitly refused rather
than the octal vs decimal ambiguity being guessed at.

Only IPv6 IPs the regex has already validated are handed to inet_pton and
inet_ntop, which are used purely for reducing them to the canonical form.
IPv4 IPs that validate are already in canonical form and are returned as is.

=cut

sub normalize_ip {
	my ($ip) = @_;

	if ( !defined($ip) || ref($ip) ne '' ) {
		return undef;
	}

	if ( $ip =~ /\A$IPv4_re\z/ ) {
		# the regex permits leading zero octets, but whether those are octal
		# or decimal depends on what is reading them, so they are refused
		# rather than guessed at
		foreach my $octet ( split( /\./, $ip ) ) {
			if ( $octet =~ /\A0[0-9]/ ) {
				return undef;
			}
		}
		# a valid dotted quad without leading zero octets is already
		# canonical
		return $ip;
	} ## end if ( $ip =~ /\A$IPv4_re\z/ )

	if ( $ip =~ /\A$IPv6_re\z/ ) {
		my $packed = inet_pton( AF_INET6, $ip );
		if ( defined($packed) ) {
			my $canonical = inet_ntop( AF_INET6, $packed );
			if ( defined($canonical) ) {
				return $canonical;
			}
		}
		# valid per the regex, but the inet functions could not round trip
		# it... refusing it beats passing along a form that could not be
		# canonicalized
		return undef;
	} ## end if ( $ip =~ /\A$IPv6_re\z/ )

	return undef;
} ## end sub normalize_ip

=head2 normalize_cidr

Returns the canonical string form of the passed IPv4 or IPv6 CIDR range. If it
does not validate, undef is returned. undef and refs also return undef.

    my $cidr = normalize_cidr($raw_cidr);

A CIDR is an address, validated the same way L</normalize_ip> validates it,
followed by C</> and a prefix length that is a non-negative integer within the
range valid for its family, 0 to 32 for IPv4 and 0 to 128 for IPv6. A bare IP
with no prefix is refused, as are prefixes with leading zeros, since those are
not canonical. The prefix range matches what L<Net::Firewall::BlockerHelper>
accepts, so anything accepted here is also acceptable to the backends.

The host bits below the prefix are masked off so the network address is
returned, meaning C<1.2.3.4/24> and C<1.2.3.0/24> both reduce to C<1.2.3.0/24>
and variant spellings of the same range cannot be mistaken for differing
ranges. The address portion is canonicalized the same as L</normalize_ip>, so
IPv6 long form and case variants reduce to the same short form.

=cut

sub normalize_cidr {
	my ($cidr) = @_;

	if ( !defined($cidr) || ref($cidr) ne '' ) {
		return undef;
	}

	# exactly one slash, an address on the left and a run of digits on the
	# right... a bare IP with no prefix does not match and is refused
	if ( $cidr !~ m!\A([^/]+)/([0-9]+)\z! ) {
		return undef;
	}
	my ( $raw_addr, $prefix ) = ( $1, $2 );

	# a leading zero prefix, such as /024, is not canonical and its intent is
	# ambiguous, so it is refused rather than guessed at, the same as is done
	# with leading zero IPv4 octets
	if ( length($prefix) > 1 && $prefix =~ /\A0/ ) {
		return undef;
	}

	# validate and canonicalize the address portion via the same path a bare
	# IP takes, bouncing leading zero octets and the like here too
	my $addr = normalize_ip($raw_addr);
	if ( !defined($addr) ) {
		return undef;
	}

	if ( $addr =~ /\A$IPv4_re\z/ ) {
		if ( $prefix > 32 ) {
			return undef;
		}
		my @octets = split( /\./, $addr );
		my $int    = ( $octets[0] << 24 ) | ( $octets[1] << 16 ) | ( $octets[2] << 8 ) | $octets[3];
		# for a /0 the shift is by 32, which on Perl's wider ints leaves the
		# high bits set, so the trailing mask brings it back to 32 bits and a
		# all zero network
		my $mask    = ( 0xFFFFFFFF << ( 32 - $prefix ) ) & 0xFFFFFFFF;
		my $network = $int & $mask;
		return
			  ( ( $network >> 24 ) & 0xFF ) . '.'
			. ( ( $network >> 16 ) & 0xFF ) . '.'
			. ( ( $network >> 8 ) & 0xFF ) . '.'
			. ( $network & 0xFF ) . '/'
			. $prefix;
	} ## end if ( $addr =~ /\A$IPv4_re\z/ )

	# IPv6, already canonicalized and validated by normalize_ip above
	if ( $prefix > 128 ) {
		return undef;
	}
	my $packed = inet_pton( AF_INET6, $addr );
	if ( !defined($packed) ) {
		return undef;
	}
	my @bytes      = unpack( 'C16', $packed );
	my $full_bytes = int( $prefix / 8 );
	my $rem_bits   = $prefix % 8;
	for ( my $index = 0; $index < 16; $index++ ) {
		if ( $index < $full_bytes ) {
			# wholly within the prefix, kept as is
		} elsif ( $index == $full_bytes && $rem_bits ) {
			# straddles the prefix, keep the leading $rem_bits of this byte
			$bytes[$index] &= ( 0xFF << ( 8 - $rem_bits ) ) & 0xFF;
		} else {
			# wholly host bits, zeroed
			$bytes[$index] = 0;
		}
	} ## end for ( my $index = 0; $index < 16; $index++ )
	my $canonical = inet_ntop( AF_INET6, pack( 'C16', @bytes ) );
	if ( !defined($canonical) ) {
		return undef;
	}
	return $canonical . '/' . $prefix;
} ## end sub normalize_cidr

1;

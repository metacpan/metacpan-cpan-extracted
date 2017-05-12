#
# Mail::SPF::Util
# Mail::SPF utility class.
#
# (C) 2005-2012 Julian Mehnle <julian@mehnle.net>
#     2005      Shevek <cpan@anarres.org>
# $Id: Util.pm 57 2012-01-30 08:15:31Z julian $
#
##############################################################################

package Mail::SPF::Util;

=head1 NAME

Mail::SPF::Util - Mail::SPF utility class

=cut

use warnings;
use strict;

use utf8;  # Hack to keep Perl 5.6 from whining about /[\p{}]/.

use base 'Mail::SPF::Base';

use Mail::SPF::Exception;

use Error ':try';
use Sys::Hostname ();
use NetAddr::IP;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant ipv4_mapped_ipv6_address_pattern =>
    qr/^::ffff:(\p{IsXDigit}{1,4}):(\p{IsXDigit}{1,4})/i;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Mail::SPF::Util;

    $hostname = Mail::SPF::Util->hostname;

    $ipv6_address_v4mapped =
        Mail::SPF::Util->ipv4_address_to_ipv6($ipv4_address);

    $ipv4_address =
        Mail::SPF::Util->ipv6_address_to_ipv4($ipv6_address_v4mapped);

    $is_v4mapped =
        Mail::SPF::Util->ipv6_address_is_ipv4_mapped($ipv6_address);

    $ip_address_string  = Mail::SPF::Util->ip_address_to_string($ip_address);
    $reverse_name       = Mail::SPF::Util->ip_address_reverse($ip_address);

    $validated_domain = Mail::SPF::Util->valid_domain_for_ip_address(
        $spf_server, $request,
        $ip_address, $domain,
        $find_best_match,       # defaults to false
        $accept_any_domain      # defaults to false
    );

    $sanitized_string = Mail::SPF::Util->sanitize_string($string);

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

B<Mail::SPF::Util> is Mail::SPF's utility class.

=head2 Class methods

The following class methods are provided:

=over

=item B<hostname>: returns I<string>

Returns the fully qualified domain name (FQDN) of the local host.

=cut

my $hostname;

sub hostname {
    my ($self) = @_;
    return $hostname ||= (gethostbyname(Sys::Hostname::hostname))[0];
        # Thanks to Sys::Hostname::FQDN for that trick!
}

=item B<ipv4_address_to_ipv6($ipv4_address)>: returns I<NetAddr::IP>; throws
I<Mail::SPF::EInvalidOptionValue>

Converts the specified I<NetAddr::IP> IPv4 address into an IPv4-mapped IPv6
address.  Throws a I<Mail::SPF::EInvalidOptionValue> exception if the specified
IP address is not an IPv4 address.

=cut

sub ipv4_address_to_ipv6 {
    my ($self, $ipv4_address) = @_;
    UNIVERSAL::isa($ipv4_address, 'NetAddr::IP') and
    $ipv4_address->version == 4
        or throw Mail::SPF::EInvalidOptionValue('NetAddr::IP IPv4 address expected');
    return NetAddr::IP->new(
        '::ffff:' . $ipv4_address->addr,   # address
        $ipv4_address->masklen - 32 + 128  # netmask length
    );
}

=item B<ipv6_address_to_ipv4($ipv6_address)>: returns I<NetAddr::IP>; throws
I<Mail::SPF::EInvalidOptionValue>

Converts the specified I<NetAddr::IP> IPv4-mapped IPv6 address into a proper
IPv4 address.  Throws a I<Mail::SPF::EInvalidOptionValue> exception if the
specified IP address is not an IPv4-mapped IPv6 address.

=cut

sub ipv6_address_to_ipv4 {
    my ($self, $ipv6_address) = @_;
    UNIVERSAL::isa($ipv6_address, 'NetAddr::IP') and
    $ipv6_address->version == 6 and
    $ipv6_address->short =~ $self->ipv4_mapped_ipv6_address_pattern
        or throw Mail::SPF::EInvalidOptionValue('NetAddr::IP IPv4-mapped IPv6 address expected');
    return NetAddr::IP->new(
        join('.', unpack('C4', pack('H8', sprintf('%04s%04s', $1, $2)))),           # address
        $ipv6_address->masklen >= 128 - 32 ? $ipv6_address->masklen - 128 + 32 : 0  # netmask length
    );
}

=item B<ipv6_address_is_ipv4_mapped($ipv6_address)>: returns I<boolean>

Returns B<true> if the specified I<NetAddr::IP> IPv6 address is an IPv4-mapped
address, B<false> otherwise.

=cut

sub ipv6_address_is_ipv4_mapped {
    my ($self, $ipv6_address) = @_;
    return (
        UNIVERSAL::isa($ipv6_address, 'NetAddr::IP') and
        $ipv6_address->version == 6 and
        $ipv6_address->short =~ $self->ipv4_mapped_ipv6_address_pattern
    );
}

=item B<ip_address_to_string($ip_address)>: returns I<string>;
throws I<Mail::SPF::EInvalidOptionValue>

Returns the given I<NetAddr::IP> IPv4 or IPv6 address compactly formatted as a
I<string>.  For IPv4 addresses, this is equivalent to calling L< NetAddr::IP's
C<addr> |NetAddr::IP/addr> method.  For IPv6 addresses, this is equivalent to
calling L< NetAddr::IP's C<short> |NedAddr::IP/short> method.  Throws a
I<Mail::SPF::EInvalidOptionValue> exception if the specified object is not a
I<NetAddr::IP> IPv4 or IPv6 address object.

=cut

sub ip_address_to_string {
    my ($self, $ip_address) = @_;
    UNIVERSAL::isa($ip_address, 'NetAddr::IP') and
    ($ip_address->version == 4 or $ip_address->version == 6)
        or throw Mail::SPF::EInvalidOptionValue('NetAddr::IP IPv4 or IPv6 address expected');
    return $ip_address->version == 4 ? $ip_address->addr : lc($ip_address->short);
}

=item B<ip_address_reverse($ip_address)>: returns I<string>;
throws I<Mail::SPF::EInvalidOptionValue>

Returns the C<in-addr.arpa.>/C<ip6.arpa.> reverse notation of the given
I<NetAddr::IP> IPv4 or IPv6 address.  Throws a I<Mail::SPF::EInvalidOptionValue>
exception if the specified object is not a I<NetAddr::IP> IPv4 or IPv6 address
object.

=cut

sub ip_address_reverse {
    my ($self, $ip_address) = @_;
    UNIVERSAL::isa($ip_address, 'NetAddr::IP') and
    ($ip_address->version == 4 or $ip_address->version == 6)
        or throw Mail::SPF::EInvalidOptionValue('NetAddr::IP IPv4 or IPv6 address expected');
    try {
        # Treat IPv4-mapped IPv6 addresses as IPv4 addresses:
        $ip_address = $self->ipv6_address_to_ipv4($ip_address);
    }
    catch Mail::SPF::EInvalidOptionValue with {};
        # ...deliberately ignoring conversion errors.
    if ($ip_address->version == 4) {
        my @octets  = split(/\./, $ip_address->addr);
           @octets  = @octets[0 .. int($ip_address->masklen / 8) - 1];
        return join('.', reverse(@octets)) . '.in-addr.arpa.';
    }
    elsif ($ip_address->version == 6) {
        my @nibbles = split(//, unpack("H32", $ip_address->aton));
           @nibbles = @nibbles[0 .. int($ip_address->masklen / 4) - 1];
        return join('.', reverse(@nibbles)) . '.ip6.arpa.';
    }
}

=item B<valid_domain_for_ip_address($server, $request, $ip_address, $domain,
$find_best_match = false, $accept_any_domain = false)>:
returns I<string> or B<undef>

Finds a valid domain name for the given I<NetAddr::IP> IP address that matches
the given domain or a sub-domain thereof.  A domain name is valid for the given
IP address if the IP address reverse-maps to that domain name in DNS, and the
domain name in turn forward-maps to the IP address.  Uses the given
I<Mail::SPF::Server> and I<Mail::SPF::Request> objects to perform DNS look-ups.
Returns the validated domain name.

If C<$find_best_match> is B<true>, the one domain name is selected that best
matches the given domain name, preferring direct matches over sub-domain
matches.  Defaults to B<false>.

If C<$accept_any_domain> is B<true>, I<any> domain names are considered
acceptable, even if they differ completely from the given domain name (which
is then effectively unused unless a best match is requested).  Defaults to
B<false>.

=cut

use constant valid_domain_match_none        => 0;
use constant valid_domain_match_subdomain   => 1;
use constant valid_domain_match_identical   => 2;

sub valid_domain_for_ip_address {
    my ($self, $server, $request, $ip_address, $domain, $find_best_match, $accept_any_domain) = @_;

    my $addr_rr_type    = $ip_address->version == 4 ? 'A' : 'AAAA';

    my $reverse_ip_name = $self->ip_address_reverse($ip_address);
    my $ptr_packet      = $server->dns_lookup($reverse_ip_name, 'PTR');
    my @ptr_rrs         = $ptr_packet->answer
        or $server->count_void_dns_lookup($request);

    # Respect the PTR mechanism lookups limit (RFC 4408, 5.5/3/4):
    @ptr_rrs = splice(@ptr_rrs, 0, $server->max_name_lookups_per_ptr_mech)
        if defined($server->max_name_lookups_per_ptr_mech);

    my $best_match_type;
    my $valid_domain;

    # Check PTR records:
    foreach my $ptr_rr (@ptr_rrs) {
        if ($ptr_rr->type eq 'PTR') {
            my $ptr_domain = $ptr_rr->ptrdname;

            my $match_type;
            if ($ptr_domain =~ /^\Q$domain\E$/i) {
                $match_type = valid_domain_match_identical;
            }
            elsif ($ptr_domain =~ /\.\Q$domain\E$/i) {
                $match_type = valid_domain_match_subdomain;
            }
            else {
                $match_type = valid_domain_match_none;
            }

            # If we're not accepting _any_ domain, and the PTR domain does not match
            # the requested domain at all, ignore this PTR domain (RFC 4408, 5.5/5):
            next if not $accept_any_domain and $match_type == valid_domain_match_none;

            my $is_valid_domain = FALSE;

            try {
                my $addr_packet = $server->dns_lookup($ptr_domain, $addr_rr_type);
                my @addr_rrs    = $addr_packet->answer
                    or $server->count_void_dns_lookup($request);
                foreach my $addr_rr (@addr_rrs) {
                    if ($addr_rr->type eq $addr_rr_type) {
                        $is_valid_domain = TRUE, last
                            if $ip_address == NetAddr::IP->new($addr_rr->address);
                            # IP address reverse and forward mapping match,
                            # PTR domain validated!
                    }
                    elsif ($addr_rr->type =~ /^(CNAME|A|AAAA)$/) {
                        # A CNAME (which has hopefully been resolved by the server
                        # for us already), or an address RR of an unrequested type.
                        # Silently ignore any of those.
                        # FIXME Silently ignoring address RRs of an "unrequested"
                        # FIXME type poses a disparity with how the "ip{4,6}", "a",
                        # FIXME and "mx" mechanisms tolerantly handle alien but
                        # FIXME convertible IP address types.
                    }
                    else {
                        # Unexpected RR type.
                        # TODO Generate debug info or ignore silently.
                    }
                }
            }
            catch Mail::SPF::EDNSError with {};
                # Ignore DNS errors on doing A/AAAA RR lookups (RFC 4408, 5.5/5/5).

            if ($is_valid_domain) {
                # If we're not looking for the _best_ match, any acceptable validated
                # domain will do (RFC 4408, 5.5/5):
                return $ptr_domain if not $find_best_match;

                # Otherwise, is this PTR domain the best possible match?
                return $ptr_domain if $match_type == valid_domain_match_identical;

                # Lastly, record this match as the best one as of yet:
                if (
                    not defined($best_match_type) or
                    $match_type > $best_match_type
                ) {
                    $valid_domain    = $ptr_domain;
                    $best_match_type = $match_type;
                }
            }
        }
        else {
            # Unexpected RR type.
            # TODO Generate debug info or ignore silently.
        }
    }

    # Return best match, possibly none (undef):
    return $valid_domain;
}

=item B<sanitize_string($string)>: returns I<string> or B<undef>

Replaces all non-printable or non-ascii characters in a string with their
hex-escaped representation (e.g., C<\x00>).

=cut

sub sanitize_string {
    my ($self, $string) = @_;

    return undef if not defined($string);

    $string =~ s/([\x00-\x1f\x7f-\xff])/sprintf("\\x%02x",   ord($1))/gex;
    $string =~ s/([\x{0100}-\x{ffff}]) /sprintf("\\x{%04x}", ord($1))/gex;

    return $string;
}

=back

=head1 SEE ALSO

L<Mail::SPF>

For availability, support, and license information, see the README file
included with Mail::SPF.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>, Shevek <cpan@anarres.org>

=cut

TRUE;

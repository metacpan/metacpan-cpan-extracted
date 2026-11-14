package InternetData::Result;

use strict;
use warnings;

use Carp ();

our $VERSION = '1.13.1';

our @FLAGS = qw(
    is_vpn is_tor is_relay is_resproxy is_dcproxy is_mobproxy is_pubproxy is_hosting is_cdn
    is_anycast is_carrier is_satellite is_ssh is_smtp is_web is_dns_resolver is_bittorrent
);
# Each flag's detail: an object, or for Web IP a list of the web servers found.
our @DETAILS = qw(
    vpn tor relay resproxy dcproxy mobproxy pubproxy hosting cdn carrier satellite ssh smtp web
    dns_resolver bittorrent
);
# Where the address is and who holds it, copied as served: objects, and the
# reverse-DNS hostname's string.
our @OBJECTS = qw(location asn company hostname abuse whois rwhois hosted_domains);
# The members of each shared object. Those the spec does not require are paid,
# and absent from an answer whose plan leaves them out.
our %MEMBERS = (
    location => [qw(
        continent continent_name country country_name timezone currency_code currency_name
        currency_symbol flag_emoji flag_unicode region region_code city postal_code latitude
        longitude accuracy_radius geoname_id dma_code last_changed
    )],
    asn => [qw(asn name domain type prefix country rpki_status)],
    company => [qw(name domain type country)],
    abuse => [qw(email name phone address country network validated unvalidated_since)],
    whois => [qw(id name org country status source domain abuse_email asn)],
    rwhois => [qw(id name country source domain abuse_email)],
);
# On answers to a key on the free plan only, and so never on a bogon's: false
# while its organization's daily trial lasts (every field for the first 100
# lookups each UTC day), true once the answer has Unlimited's.
our @MARKERS = qw(trial_expired);

my %KNOWN = map { $_ => 1 } 'ip', 'is_bogon', @FLAGS, @DETAILS, @OBJECTS, @MARKERS;

# The one place a wire body becomes a result. Every field is copied on key
# PRESENCE and never on truthiness: a plan that includes `is_hosting` and
# answers false must keep it, and a plan that does not include it must not gain
# it. In Perl those two are one careless `if` apart, since undef, 0, '' and a
# missing key are all false.
sub from_wire {
    my ($class, $body) = @_;
    my %answer = (ip => $body->{ip});
    # A served null stays undef, as a detail's does: read as 0 it would say the
    # address is no hosting server, or that the trial lasts, when nothing was said.
    for my $flag ('is_bogon', @FLAGS, @MARKERS) {
        next unless exists $body->{$flag};
        $answer{$flag} = defined $body->{$flag} ? ($body->{$flag} ? 1 : 0) : undef;
    }
    for my $detail (@DETAILS, @OBJECTS) {
        $answer{$detail} = $body->{$detail} if exists $body->{$detail};
    }
    return $class->_new(\%answer, $body);
}

# Whether your plan carries this field at all, which is a different question
# from what the field says. `has` is the only honest answer to "is this address
# hosting?" when the field may not have been served: absent is not false.
sub has {
    my ($self, $field) = @_;
    Carp::croak("InternetData::Result::has: unknown field '$field'") unless $KNOWN{$field};
    return exists $self->{$field} ? 1 : 0;
}

# The fields this answer actually carried, in wire order. Useful for seeing what
# a key is entitled to without reading the plan table.
sub fields {
    my ($self) = @_;
    return grep { exists $self->{$_} } 'is_bogon', @FLAGS, @DETAILS, @OBJECTS, @MARKERS;
}

# The response exactly as it came off the wire, with its original names and its
# JSON booleans intact. Empty for a bogon, which was never served.
sub raw {
    return $_[0]->{_raw};
}

sub _new {
    my ($class, $answer, $raw) = @_;
    $answer->{_raw} = $raw;
    return bless $answer, $class;
}

# One reader per field rather than AUTOLOAD, so a typo is a compile-adjacent
# "Can't locate object method" rather than a silent undef.
for my $field ('ip', 'is_bogon', @FLAGS, @DETAILS, @OBJECTS, @MARKERS) {
    no strict 'refs';
    *{__PACKAGE__ . "::$field"} = sub { $_[0]->{$field} };
}

1;

__END__

=head1 NAME

InternetData::Result - what an address lookup answers

=head1 SYNOPSIS

    my $result = $client->lookup('146.70.116.130');

    $result->ip;                    # '146.70.116.130'
    $result->is_anycast;            # 0
    $result->location->{country};   # the ISO 3166 country code
    $result->asn->{name};           # who runs the announcing network
    $result->company->{name};       # who holds the address

    $result->is_hosting;            # 1, 0, or undef when your plan omits it
    $result->is_hosting // 0;       # read an absent field as false
    $result->has('is_hosting');     # 1 if your plan carries it at all

=head1 ABSENT IS NOT FALSE

An B<absent> field is one your plan does not include. It never means "we checked
and found nothing", so C<undef> and C<0> are genuinely different answers.

This is the one place Perl makes it easy to get wrong, because C<undef>, C<0>,
C<''> and a missing hash key are all false:

    if ($result->is_hosting) { ... }        # WRONG: absent and false look alike

    if (($result->is_hosting // 0)) { ... } # right: absent reads as false
    if ($result->has('is_hosting')) { ... } # right: asks whether it was served

C<//> (defined-or) is the reader for "treat absent as false", and C<has> is the
reader for "was this served at all". A result is also a plain hash reference, so
C<exists $result-E<gt>{is_hosting}> is C<has> spelled out and
C<defined $result-E<gt>{is_hosting}> is the same test one level down.

A paid member inside a shared object is absent the same way, so ask with
C<exists>: C<exists $result-E<gt>location-E<gt>{city}>.

A detail object that is present but B<empty> (C<{}>, and C<[]> for C<web>) means
the flag above it is false. A populated one always carries every one of its keys.

=head1 METHODS

=head2 ip, is_bogon

Always present. C<is_bogon> is set for reserved space, which the client answers
itself without a request.

=head2 is_tor, is_relay, is_anycast, is_carrier, is_satellite, is_ssh, is_smtp, is_web, is_dns_resolver, is_bittorrent

On every answer, with a key or without one: C<1> or C<0>.

=head2 is_vpn, is_resproxy, is_dcproxy, is_mobproxy, is_pubproxy, is_hosting, is_cdn

The paid flags: C<1>, C<0>, or C<undef> when your plan omits the field.

=head2 vpn, tor, relay, resproxy, dcproxy, mobproxy, pubproxy, hosting, cdn, carrier, satellite, ssh, smtp, web, dns_resolver, bittorrent

The detail behind each flag, as plain hash references (C<web> an array reference
of the web servers found), or C<undef> when your plan omits them. Unlimited
answers C<tor> and C<relay>; every paid plan answers them all.

=head2 location, asn, company, hostname, abuse

On every answer, with a key or without one. C<location>, C<asn>, C<company> and
C<abuse> are plain hash references whose paid members are absent on Unlimited:
C<location> carries the country there and the city, coordinates and the rest on a
paid plan, C<asn> its C<country> and C<rpki_status>, C<company> its C<type> and
C<country>, and C<abuse> everything past C<email>. C<hostname> is the reverse-DNS
name, an empty string where there is none.

=head2 whois, rwhois, hosted_domains

Paid: the WHOIS and RWHOIS records for the range, and how many domains point at
the address, or C<undef> when your plan omits them.

=head2 trial_expired

On answers to a key on the free plan only: C<0> while its organization's daily
trial lasts (every field for the first 100 lookups each UTC day), C<1> once the
answer has Unlimited's, and C<undef> on any other answer.

=head2 has($field)

Whether your plan carries C<$field>. Croaks on a name that is not a field.

=head2 fields

The field names this answer carried, in wire order.

=head2 raw

The decoded response body, untouched. Treat it, and the result itself, as read
only: the cache hands the same object to every later caller of an address.

=cut

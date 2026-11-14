package InternetData::AsnResult;

use strict;
use warnings;

use Carp ();

our $VERSION = '1.13.1';

# Copied as served. Those the spec does not require are paid, and absent from an
# answer whose plan leaves them out.
our @MEMBERS = qw(
    name country registry allocated domain type num_ips num_prefixes4 num_prefixes6 rpki_valid
    rpki_invalid rpki_not_found whois prefixes
);
our @MARKERS = qw(trial_expired);

my %KNOWN = map { $_ => 1 } 'asn', @MEMBERS, @MARKERS;

# Copied on key PRESENCE, never on truthiness, as InternetData::Result is.
sub from_wire {
    my ($class, $body) = @_;
    my %answer = (asn => $body->{asn});
    for my $marker (@MARKERS) {
        next unless exists $body->{$marker};
        $answer{$marker} = defined $body->{$marker} ? ($body->{$marker} ? 1 : 0) : undef;
    }
    for my $member (@MEMBERS) {
        $answer{$member} = $body->{$member} if exists $body->{$member};
    }
    return bless { %answer, _raw => $body }, $class;
}

sub has {
    my ($self, $field) = @_;
    Carp::croak("InternetData::AsnResult::has: unknown field '$field'") unless $KNOWN{$field};
    return exists $self->{$field} ? 1 : 0;
}

sub fields {
    my ($self) = @_;
    return grep { exists $self->{$_} } @MEMBERS, @MARKERS;
}

sub raw {
    return $_[0]->{_raw};
}

for my $field ('asn', @MEMBERS, @MARKERS) {
    no strict 'refs';
    *{__PACKAGE__ . "::$field"} = sub { $_[0]->{$field} };
}

1;

__END__

=head1 NAME

InternetData::AsnResult - what an AS lookup answers

=head1 SYNOPSIS

    my $as = $client->lookup_asn(9009);

    $as->asn;                # 9009
    $as->name;               # 'M247 Europe SRL'
    $as->type;               # 'hosting', or undef when your plan omits it
    $as->has('prefixes');    # 1 if your plan carries it at all

=head1 DESCRIPTION

Absent is not false here either: a member your plan does not include has no key
at all, so read it with C<has> or C<//>, as L<InternetData::Result/ABSENT IS NOT
FALSE> explains.

=head1 METHODS

=head2 asn, name, country, registry, allocated, domain

On every answer, with a key or without one: the AS number, its operator, the
country and registry that allocated it, when, and the operator's domain.

=head2 type, num_ips, num_prefixes4, num_prefixes6, rpki_valid, rpki_invalid, rpki_not_found

Paid: the kind of network it runs, the IPv4 addresses and the prefixes it
announces, and how many of its announcements RPKI calls valid, invalid or
unrecorded. C<undef> when your plan omits them.

=head2 whois, prefixes

Paid: the AS's WHOIS record as a hash reference of strings, and the prefixes it
announces as an array reference, each a hash reference with C<prefix>,
C<peer_count>, C<rpki_status>, C<first_seen>, C<country>, C<size> and
C<other_origins>.

=head2 trial_expired

On answers to a key on the free plan only, as on L<InternetData::Result>.

=head2 has($field), fields, raw

As on L<InternetData::Result>.

=cut

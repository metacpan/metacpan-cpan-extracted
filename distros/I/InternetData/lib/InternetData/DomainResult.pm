package InternetData::DomainResult;

use strict;
use warnings;

use Carp ();

our $VERSION = '1.13.1';

our @FLAGS = qw(is_registered is_disposable has_a has_aaaa has_mx has_ns has_cname);
# Copied as served, and paid: absent from an answer whose plan leaves them out.
our @MEMBERS = qw(dns ip_ranges disposable);
our @MARKERS = qw(trial_expired);

my %KNOWN = map { $_ => 1 } 'domain', @FLAGS, @MEMBERS, @MARKERS;

# Copied on key PRESENCE, never on truthiness, as InternetData::Result is.
sub from_wire {
    my ($class, $body) = @_;
    my %answer = (domain => $body->{domain});
    for my $flag (@FLAGS, @MARKERS) {
        next unless exists $body->{$flag};
        $answer{$flag} = defined $body->{$flag} ? ($body->{$flag} ? 1 : 0) : undef;
    }
    for my $member (@MEMBERS) {
        $answer{$member} = $body->{$member} if exists $body->{$member};
    }
    return bless { %answer, _raw => $body }, $class;
}

sub has {
    my ($self, $field) = @_;
    Carp::croak("InternetData::DomainResult::has: unknown field '$field'") unless $KNOWN{$field};
    return exists $self->{$field} ? 1 : 0;
}

sub fields {
    my ($self) = @_;
    return grep { exists $self->{$_} } @FLAGS, @MEMBERS, @MARKERS;
}

sub raw {
    return $_[0]->{_raw};
}

for my $field ('domain', @FLAGS, @MEMBERS, @MARKERS) {
    no strict 'refs';
    *{__PACKAGE__ . "::$field"} = sub { $_[0]->{$field} };
}

1;

__END__

=head1 NAME

InternetData::DomainResult - what a domain lookup answers

=head1 SYNOPSIS

    my $domain = $client->lookup_domain('example.com');

    $domain->is_registered;       # 1
    $domain->has_mx;              # 1, 0
    $domain->is_disposable;       # 0, or undef when your plan omits it
    $domain->has('dns');          # 1 if your plan carries the records at all

=head1 DESCRIPTION

Absent is not false here either: a member your plan does not include has no key
at all, so read it with C<has> or C<//>, as L<InternetData::Result/ABSENT IS NOT
FALSE> explains.

=head1 METHODS

=head2 domain, is_registered, has_a, has_aaaa, has_mx, has_ns, has_cname

On every answer, with a key or without one: the domain, whether it is
registered, and whether it has each type of DNS record, C<1> or C<0>.

=head2 is_disposable, disposable

Paid: whether the domain is in Disposable Domain, a throwaway email provider's,
and the detail behind it, C<{}> when it is not. C<undef> when your plan omits
them.

=head2 dns, ip_ranges

Paid: the records themselves (C<a>, C<aaaa>, C<mx>, C<ns> and C<cname>, each an
array reference), and the IP ranges its organization holds. C<undef> when your
plan omits them.

=head2 trial_expired

On answers to a key on the free plan only, as on L<InternetData::Result>.

=head2 has($field), fields, raw

As on L<InternetData::Result>.

=cut

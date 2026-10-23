package Logic::Probabilistic::Distribution::Outcome;

use v5.38;
use experimental 'signatures';
use Carp         qw(croak);
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

use overload
  '""' => sub ( $self, $, $ ) { ${$self}->{key} },
  '0+' => sub ( $self, $, $ ) {
    looks_like_number( ${$self}->{key} ) ? ( 0 + ${$self}->{key} ) : 0;
  },
  '@{}' => sub ( $self, $, $ ) {
    my $raw = ${$self}->{raw};
    return $raw if ref($raw) eq 'ARRAY';
    croak "Outcome '"
      . ${$self}->{key}
      . "' cannot be dereferenced as an ARRAY";
  },
  '%{}' => sub ( $self, $, $ ) {
    my $raw = ${$self}->{raw};
    return $raw if ref($raw) eq 'HASH';
    croak "Outcome '" . ${$self}->{key} . "' cannot be dereferenced as a HASH";
  },
  fallback => 1;

sub new ( $class, %args ) {
    my $key  = $args{key}         // croak "key is required";
    my $prob = $args{probability} // 0.0;
    my $raw  = exists $args{raw} ? $args{raw} : $key;

    my $data = {
        key          => "$key",
        raw          => $raw,
        probability  => 0.0 + $prob,
        distribution => $args{distribution},
    };

    return bless \$data, $class;
}

sub key ($self) {
    return ${$self}->{key};
}

sub raw ($self) {
    return ${$self}->{raw};
}

sub value ($self) {
    return ${$self}->{raw};
}

sub probability ($self) {
    return ${$self}->{probability};
}

sub prob ($self) {
    return ${$self}->{probability};
}

sub pmf ($self) {
    return ${$self}->{probability};
}

sub percentage ($self) {
    return ${$self}->{probability} * 100.0;
}

sub pct ($self) {
    return ${$self}->{probability} * 100.0;
}

sub distribution ($self) {
    return ${$self}->{distribution};
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Distribution::Outcome - Smart outcome container with transparent dereferencing.

=head1 SYNOPSIS

    fresh my $listing;
    query_dist MovieListings::search_listing('adventure', 'Westwood', $listing) -> my $dist;

    for my $outcome ($dist->outcomes) {
        # Stringifies cleanly as "[Four Feathers, Music Hall]"
        say "Outcome: $outcome with P = " . $outcome->probability;

        # Direct array dereferencing when outcome is a list/tuple:
        say "Film: " . $outcome->[0] . ", Theater: " . $outcome->[1];

        # Direct raw Perl data structure:
        my $pair = $outcome->raw; # ['Four Feathers', 'Music Hall']
    }

=head1 DESCRIPTION

C<Logic::Probabilistic::Distribution::Outcome> represents a discrete outcome from a
probability distribution query.

It implements operator overloading so that:

=over 4

=item * B<Stringification (C<"">)> returns the canonical display key (e.g. C<"[Four Feathers, Music Hall]">).

=item * B<Array dereferencing (C<@{{}}>)> delegates directly to the underlying array reference if the raw outcome is an array/tuple (e.g. C<< $outcome->[0] >>).

=item * B<Hash dereferencing (C<%{{}}>)> delegates directly to the underlying hash reference if the raw outcome is a dictionary (e.g. C<< $outcome->{field} >>).

=item * B<Numeric conversion (C<0+>)> converts numeric keys to numbers (e.g. for dice outcomes).

=back

=head1 METHODS

=head2 key

Returns the stringified canonical outcome key.

=head2 raw / value

Returns the underlying, unblessed Perl data structure (scalar, arrayref, or hashref).

=head2 probability / prob / pmf

Returns the numeric probability of this outcome in the distribution.

=head2 percentage / pct

Returns the probability multiplied by 100.

=head2 distribution

Returns the parent L<Logic::Probabilistic::Distribution> instance.

=cut

package HTTP::API::Core::RateLimit;

use strict;
use warnings;
use Time::HiRes qw(time);

sub new {
    my $class = shift;
    die "rate-limit constructor options must be key/value pairs\n" if @_ % 2;
    die "constructor option names must be scalars\n"
        if grep { ref($_) ne '' } @_[ grep { $_ % 2 == 0 } 0 .. $#_ ];
    my %args = @_;

    for my $name (qw(limit remaining used reset reset_epoch retry_after)) {
        die "rate-limit $name must be a non-negative number or undef\n"
            if defined($args{$name})
            && (ref($args{$name}) ne ''
                || $args{$name} !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/);
    }
    for my $name (qw(resource source)) {
        die "rate-limit $name must be a scalar or undef\n"
            if defined($args{$name}) && ref($args{$name}) ne '';
    }

    return bless {
        limit       => $args{limit},
        remaining   => $args{remaining},
        used        => $args{used},
        reset       => $args{reset},
        reset_epoch => $args{reset_epoch},
        retry_after => $args{retry_after},
        resource    => $args{resource},
        source      => $args{source},
    }, $class;
}

sub from_headers {
    my ($class, $headers) = @_;
    $headers = {} if !defined $headers;
    die "rate-limit headers must be a hash reference\n"
        if ref($headers) ne 'HASH';
    for my $value (values %$headers) {
        next if !defined($value) || ref($value) eq '';
        die "rate-limit header values must be scalars, arrays of scalars, or undef\n"
            if ref($value) ne 'ARRAY'
            || grep { defined($_) && ref($_) ne '' } @$value;
    }
    # Duplicate spellings with conflicting values are ambiguous, not
    # arbitrarily chosen according to Perl hash iteration order.
    my (%h, %conflicts);
    for my $name (keys %$headers) {
        my $key = lc $name;
        my $value = _scalar_header_value($headers->{$name});
        if (exists $h{$key}) {
            my $previous = $h{$key};
            $conflicts{$key} = 1
                if (!defined($previous) && defined($value))
                || (defined($previous) && !defined($value))
                || (defined($previous) && defined($value) && $previous ne $value);
        }
        $h{$key} = $value;
    }
    $h{$_} = undef for keys %conflicts;

    my $source = exists $h{'ratelimit-limit'} || exists $h{'ratelimit-remaining'} || exists $h{'ratelimit-reset'}
        ? 'ratelimit'
        : exists $h{'x-ratelimit-limit'} || exists $h{'x-ratelimit-remaining'} || exists $h{'x-ratelimit-reset'}
            ? 'x-ratelimit'
            : undef;

    return $class->new(
        limit       => _number(exists $h{'ratelimit-limit'} ? $h{'ratelimit-limit'} : $h{'x-ratelimit-limit'}),
        remaining   => _number(exists $h{'ratelimit-remaining'} ? $h{'ratelimit-remaining'} : $h{'x-ratelimit-remaining'}),
        used        => _number(exists $h{'ratelimit-used'} ? $h{'ratelimit-used'} : $h{'x-ratelimit-used'}),
        reset       => _number($h{'ratelimit-reset'}),
        reset_epoch => _number($h{'x-ratelimit-reset'}),
        retry_after => _number($h{'retry-after'}),
        resource    => exists $h{'ratelimit-resource'} ? $h{'ratelimit-resource'} : $h{'x-ratelimit-resource'},
        source      => $source,
    );
}

sub limit       { $_[0]->{limit} }
sub remaining   { $_[0]->{remaining} }
sub used        { $_[0]->{used} }
sub reset       { $_[0]->{reset} }
sub reset_epoch { $_[0]->{reset_epoch} }
sub retry_after { $_[0]->{retry_after} }
sub resource    { $_[0]->{resource} }
sub source      { $_[0]->{source} }

sub exhausted {
    my ($self) = @_;
    return defined($self->{remaining}) && $self->{remaining} <= 0 ? 1 : 0;
}

sub wait_seconds {
    my $self = shift;
    die "rate-limit wait_seconds options must be key/value pairs\n" if @_ % 2;
    die "rate-limit wait_seconds option names must be scalars\n"
        if grep { ref($_) ne '' } @_[ grep { $_ % 2 == 0 } 0 .. $#_ ];
    my %args = @_;
    my $now = exists $args{now} ? delete($args{now}) : time;
    die "unknown rate-limit wait_seconds option: $_\n" for sort keys %args;
    die "rate-limit now must be a non-negative number\n"
        if !defined($now)
        || ref($now) ne ''
        || $now !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;

    return $self->{retry_after} if defined $self->{retry_after};
    return $self->{reset} if defined $self->{reset};

    if (defined $self->{reset_epoch}) {
        my $wait = $self->{reset_epoch} - $now;
        return $wait > 0 ? $wait : 0;
    }

    return undef;
}

sub as_hash {
    my ($self) = @_;
    return {
        limit       => $self->{limit},
        remaining   => $self->{remaining},
        used        => $self->{used},
        reset       => $self->{reset},
        reset_epoch => $self->{reset_epoch},
        retry_after => $self->{retry_after},
        resource    => $self->{resource},
        source      => $self->{source},
    };
}

# Conflicting repetitions are ambiguous; never choose a value for retry policy.
sub _scalar_header_value {
    my ($value) = @_;
    return $value if ref($value) ne 'ARRAY';
    return undef if !@$value;

    my $first = $value->[0];
    for my $item (@$value) {
        return undef if defined($first) != defined($item);
        return undef if defined($first) && $first ne $item;
    }
    return $first;
}

sub _number {
    my ($value) = @_;
    return undef if !defined($value) || ref($value) ne ''
        || $value !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;
    return 0 + $value;
}

1;

__END__

=head1 NAME

HTTP::API::Core::RateLimit - Normalized HTTP API rate-limit metadata

=head1 DESCRIPTION

Represents rate-limit information parsed from the C<RateLimit-Limit>,
C<RateLimit-Remaining>, and C<RateLimit-Reset> header family used by earlier
IETF rate-limit drafts, plus the widely-used C<X-RateLimit-*> family.
C<Retry-After> is also captured.

=head1 METHODS

=head2 new

    my $quota = HTTP::API::Core::RateLimit->new(
        remaining => 0,
        reset     => 10,
    );

Constructs normalized metadata directly. Numeric fields accept
non-negative decimal numbers or C<undef>. C<resource> and C<source> are
scalar values or C<undef>.

=head2 from_headers

    my $quota = HTTP::API::Core::RateLimit->from_headers($headers);

Parses a header hash reference using case-insensitive names. Missing or
undefined headers yield unknown metadata. Repeated values are accepted
when identical; conflicting values are treated as unknown. For limit,
remaining, used and resource, a present C<RateLimit-*> field takes
precedence over its legacy C<X-RateLimit-*> counterpart even if the
standard value cannot be parsed.

=head2 retry_after

Numeric C<Retry-After> delay when available. HTTP-date parsing belongs
to the client's retry policy rather than this accessor.

=head2 source

Returns C<ratelimit> or C<x-ratelimit> when the corresponding limit,
remaining or reset header family is present; otherwise C<undef>.
The standard family takes precedence.

=head2 as_hash

Returns a new hash reference containing the eight normalized fields,
including undefined values.

=head2 limit, remaining, used, resource

Normalized quota metadata when present.

=head2 reset

Seconds until reset from C<RateLimit-Reset>.

=head2 reset_epoch

UTC epoch reset timestamp from C<X-RateLimit-Reset>.

=head2 wait_seconds

Returns the preferred delay before retrying. C<Retry-After> takes precedence,
then C<RateLimit-Reset>, then C<X-RateLimit-Reset> converted from epoch time.
An elapsed reset timestamp yields zero; unavailable delay information yields
C<undef>. Pass C<now =E<gt> $epoch> to use a specified non-negative epoch
rather than the current time.

=head2 exhausted

True when a numeric remaining value is present and is zero or less.

=cut

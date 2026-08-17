package HTTP::API::Core::RateLimit;

use strict;
use warnings;
use Time::HiRes qw(time);

sub new {
    my ($class, %args) = @_;
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
    $headers ||= {};
    my %h = map { lc($_) => $headers->{$_} } keys %$headers;

    my $source = exists $h{'ratelimit-limit'} || exists $h{'ratelimit-remaining'} || exists $h{'ratelimit-reset'}
        ? 'ratelimit'
        : exists $h{'x-ratelimit-limit'} || exists $h{'x-ratelimit-remaining'} || exists $h{'x-ratelimit-reset'}
            ? 'x-ratelimit'
            : undef;

    return $class->new(
        limit       => _number($h{'ratelimit-limit'} // $h{'x-ratelimit-limit'}),
        remaining   => _number($h{'ratelimit-remaining'} // $h{'x-ratelimit-remaining'}),
        used        => _number($h{'ratelimit-used'} // $h{'x-ratelimit-used'}),
        reset       => _number($h{'ratelimit-reset'}),
        reset_epoch => _number($h{'x-ratelimit-reset'}),
        retry_after => _number($h{'retry-after'}),
        resource    => $h{'ratelimit-resource'} // $h{'x-ratelimit-resource'},
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
    my ($self, %args) = @_;
    my $now = exists $args{now} ? $args{now} : time;

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

sub _number {
    my ($value) = @_;
    return undef if !defined($value) || $value !~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/;
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

=head2 limit, remaining, used, resource

Normalized quota metadata when present.

=head2 reset

Seconds until reset from C<RateLimit-Reset>.

=head2 reset_epoch

UTC epoch reset timestamp from C<X-RateLimit-Reset>.

=head2 wait_seconds

Returns the preferred delay before retrying. C<Retry-After> takes precedence,
then C<RateLimit-Reset>, then C<X-RateLimit-Reset> converted from epoch time.

=head2 exhausted

True when a numeric remaining value is present and is zero or less.

=cut

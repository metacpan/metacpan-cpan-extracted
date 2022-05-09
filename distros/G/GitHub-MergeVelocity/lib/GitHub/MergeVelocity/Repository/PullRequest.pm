package GitHub::MergeVelocity::Repository::PullRequest;
use Moo;

our $VERSION = '0.000009';

use DateTime ();
use GitHub::MergeVelocity::Types qw( Datetime );
use Math::Round qw( round );
use MooX::StrictConstructor;
use Types::Standard qw( Bool Int Str );

has age => (
    is       => 'ro',
    init_arg => undef,
    isa      => Int,
    lazy     => 1,
    builder  => '_build_age',
);

has closed_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'is_closed',
    coerce    => 1,
);

has created_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'has_created_at',
    coerce    => 1,
    required  => 1,
);

has is_work_in_progress => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    default => sub {
        return shift->title =~ m{\A\[?WIP\]?};
    },
);

has merged_at => (
    is        => 'ro',
    isa       => Datetime,
    predicate => 'is_merged',
    coerce    => 1,
);

has number => (
    is            => 'ro',
    isa           => Int,
    required      => 1,
    documentation => 'issue number in the GitHub url'
);

has title => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has state => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_state',
);

has velocity => (
    is       => 'ro',
    isa      => Int,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_velocity',
);

sub is_open {
    my $self = shift;
    return $self->state eq 'open';
}

sub _build_age {
    my $self = shift;

    my $upper_bound
        = $self->is_merged ? $self->merged_at
        : $self->is_closed ? $self->closed_at
        :                    DateTime->now;

    return $upper_bound->delta_days( $self->created_at )->delta_days;
}

sub _build_state {
    my $self = shift;
    return
          $self->is_merged ? 'merged'
        : $self->is_closed ? 'closed'
        :                    'open';
}

# add points for merges in the first 30 days
# merges in 31 - 45 are neutral
# subtract after 45 days

sub _build_velocity {
    my $self = shift;

    return 0 if $self->is_work_in_progress;

    if ( $self->is_open ) {
        return $self->age > 45 ? 45 - $self->age : 0;
    }

    my $score = 0;
    if ( $self->age < 31 ) {
        $score += round( 1.2**( 31 - $self->age ) );
    }
    elsif ( $self->age > 45 ) {
        $score = 45 - $self->age;
    }
    return $score;
}

1;

=pod

=encoding UTF-8

=head1 NAME

GitHub::MergeVelocity::Repository::PullRequest - Encapsulate select data about GitHub pull requests

=head1 VERSION

version 0.000009

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Encapsulate select data about GitHub pull requests

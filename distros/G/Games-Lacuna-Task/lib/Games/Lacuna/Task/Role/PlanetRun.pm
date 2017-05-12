package Games::Lacuna::Task::Role::PlanetRun;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;
requires qw(process_planet);

has 'exclude_planet' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    documentation   => 'Do not process given planets',
    traits          => ['Array'],
    default         => sub { [] },
    handles         => {
        'has_exclude_planet' => 'count',
    }
);

has 'only_planet' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    documentation   => 'Only process given planets',
    traits          => ['Array'],
    default         => sub { [] },
    handles         => {
        'has_only_planet' => 'count',
    }
);

sub run {
    my ($self) = @_;

    foreach my $planet_stats ($self->get_planets) {
        $self->log('info',"Processing planet %s",$planet_stats->{name});
        $self->process_planet($planet_stats);
    }
}

sub get_planets {
    my ($self) = @_;
    
    my @planets;
    
    # Only selected planets
    if ($self->has_only_planet) {
        foreach my $only_planet (@{$self->only_planet}) {
            my $planet = $self->my_body_status($only_planet);
            push(@planets,$planet)
                if $planet;
        }
    # All but selected planets
    } elsif ($self->has_exclude_planet) {
        my @exclude_planets;
        foreach my $planet (@{$self->exclude_planet}) {
            my $planet_id = $self->my_body_id($planet);
            push(@exclude_planets,$planet_id)
                if $planet_id;
        }
        foreach my $planet_stats ($self->my_planets) {
            push(@planets,$planet_stats)
                unless $planet_stats->{id} ~~ \@exclude_planets;
        }
    # All planets
    } else {
        @planets = $self->my_planets;
    }
    
    return @planets;
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Role::PlanetRun - Helper role for all planet-centric actions

=head1 SYNOPSIS

    package Games::Lacuna::Task::Action::MyTask;
    use Moose;
    extends qw(Games::Lacuna::Task::Action);
    with qw(Games::Lacuna::Task::Role::RPCLimit);
    
    sub process_planet {
        my ($self,$planet_stats) = @_;
        ...
    }

=cut
package Games::Lacuna::Task::Action::EvaluateColony;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use Games::Lacuna::Task::Utils qw(distance);
use Games::Lacuna::Task::Table;

sub description {
    return q[Evaluate colonizeable worlds];
}

has 'max_distance' => (
    is              => 'rw',
    isa             => 'Int',
    default         => 75,
    required        => 1,
    documentation   => 'Maximum distance from home planet [Default: 75]',
);

has 'min_orbit' => (
    is              => 'rw',
    isa             => 'Int',
    lazy_build      => 1,
    documentation   => 'Min orbit. Defaults to your species min orbit',
);

has 'max_orbit' => (
    is              => 'rw',
    isa             => 'Int',
    lazy_build      => 1,
    documentation   => 'Max orbit. Defaults to your species max orbit',
);

has 'min_size' => (
    is              => 'rw',
    isa             => 'Int',
    default         => 55,
    documentation   => 'Min habitable planet size [Default: 55]',
);

has 'min_gas_giant_size' => (
    is              => 'rw',
    isa             => 'Int',
    default         => 105,
    documentation   => 'Min gas giant size [Default: 105]',
);

has 'gas_giant' => (
    is              => 'rw',
    isa             => 'Bool',
    default         => 0,
    documentation   => 'Consider gas giants [Flag, Default: false]',
);

sub _build_min_orbit {
    my ($self) = @_;
    return $self->_get_orbit->{min};
}

sub _build_max_orbit {
    my ($self) = @_;
    return $self->_get_orbit->{max};
}

sub _get_orbit {
    my ($self) = @_;
    
    my $species_stats = $self->request(
        object  => $self->build_object('Empire'),
        method  => 'view_species_stats',
    )->{species};
    
    
    $self->min_orbit($species_stats->{min_orbit})
        unless $self->meta->get_attribute('min_orbit')->has_value($self);
    $self->max_orbit($species_stats->{max_orbit})
        unless $self->meta->get_attribute('max_orbit')->has_value($self);
    
    return {
        min => $species_stats->{min_orbit},
        max => $species_stats->{max_orbit},
    }
}

sub run {
    my ($self) = @_;
    
    my $planet_stats = $self->my_body_status($self->home_planet_id);
    
    my @bodies;
    
    $self->search_stars_callback(
        sub {
            my ($star_data) = @_;
            
            return 1
                unless scalar @{$star_data->{bodies}};
            
            my $boost = 1;
            
            # Distance boost
            $boost += (0.3) * (1-($star_data->{distance} / $self->max_distance));
            
            # Evaluate neighbourhood
            foreach my $body (@{$star_data->{bodies}}) {
                if (defined $body->{empire}) {
                    # No inhabited systems - SAWs might kill our colony ship
                    return 1
                        if (($body->{type} eq 'habitable planet' || $body->{type} eq 'gas giant')
                        && $body->{empire}{alignment} =~ /^hostile/);
                    
                    # Neighbour boost
                    if ($body->{empire}{alignment} eq 'self') {
                        $boost += 0.1;
                    } elsif ($body->{empire}{alignment} eq 'ally') {
                        $boost += 0.05;
                    }
                }
            }
            
            # Evaluate bodies
            foreach my $body (@{$star_data->{bodies}}) {
                next
                    if defined $body->{empire};
                next
                    unless $body->{type} eq 'habitable planet' || ($body->{type} eq 'gas giant' && $self->gas_giant);
                next
                    if $body->{orbit} < $self->min_orbit;
                next
                    if $body->{orbit} > $self->max_orbit;
                
                if ($body->{type} eq 'habitable planet') {
                    next
                        if $body->{size} < $self->min_size;
                } elsif ($body->{type} eq 'gas giant') {
                    next
                        if $body->{size} < $self->min_gas_giant_size;
                }
                
                my $score = $self->calculate_score($body,$boost);
                
                push(@bodies,[$body,$score]);
                
                $self->log('debug','Found candidate %s in %s (score %i)',$body->{name},$body->{star_name},$score);
            }
            
            return 1;
        },
        x           => $planet_stats->{x},
        y           => $planet_stats->{y},
        max_distance=> $self->max_distance,
        is_probed   => 1,
        distance    => 1,
    );
    
    $self->log('info','Found %i candidates',scalar(@bodies));
    
    my $table = Games::Lacuna::Task::Table->new({
        columns     => ['Name','X','Y','Orbit','Score','Size','Water','Distance'],
    });
    
    foreach my $element (sort { $b->[1] <=> $a->[1] } @bodies) {
        my $body = $element->[0];
        my $score = $element->[1];
        $table->add_row({
            (map { ($_ => $body->{$_}) } qw(name x y orbit size water)),
            score       => $score,
            distance    => int(distance($planet_stats->{x},$planet_stats->{y},$body->{x},$body->{y})),
        });
    }
    
    say $table->render_text;
}

sub calculate_score {
    my ($self,$body,$boost) = @_;
    
    $boost //= 1;
    my $score = 0;
    
    # See examples/colony_worlds.pl in Game-Lacuna-Client
    if ($body->{type} eq 'habitable planet') {
        $score += ($body->{water} - 5000) / 70;
        $score += (($body->{size} > 50 ? 50 : $body->{size} ) - 30) * 6;
    } else {
        $score += (($body->{size} > 100 ? 100 : $body->{size} ) - 70) * 6;
    }
    $score += (scalar grep { $body->{ore}->{$_} > 1 } keys %{$body->{ore}}) * 5;
    
    $score *= $boost 
        if $boost;
    
    return int($score);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
package Games::Lacuna::Task::Action::Defence;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Ships
    Games::Lacuna::Task::Role::PlanetRun);

use List::Util qw(min);
use Games::Lacuna::Task::Utils qw(parse_date);

has 'min_defender_combat' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
    default         => 10000,
    documentation   => 'Only defenders above or equal to this combat level will be considered [Default: 10000]',
);

has '_planet_attack' => (
    is              => 'rw',
    isa             => 'HashRef',
    default         => sub { {} },
    traits          => ['Hash','NoGetopt'],
    handles         => {
        _add_planet_attack  => 'set',
        _list_planet_attack => 'keys',
        _has_planet_attack  => 'defined',
    }
);

sub description {
    return q[Defend against enemy attacks by dispatching fighters and sweepers];
}

after 'run' => sub {
    my ($self) = @_;
    
    my @dispatch_ships;
    foreach my $body_id ($self->_list_planet_attack) {
        my $planet_attack = $self->_list_planet_attack->{$body_id};
        
        
        DISPATCH_PLANETS:
        foreach my $dispatch_planet_stats ($self->my_planets) {
            my $count = $planet_attack->{attacker} - $planet_attack->{defender};
            
            last DISPATCH_PLANETS
                if $count <= 0;
            
            next DISPATCH_PLANETS
                if $dispatch_planet_stats->{id} == $body_id;
            
            my $available = 100;
            # Check if other planet is being attacked too
            if ($self->_has_planet_attack($dispatch_planet_stats->{id})) {
                my $dispatch_planet_attack = $self->_get_planet_attack($dispatch_planet_stats->{id});
                next DISPATCH_PLANETS
                    if $dispatch_planet_attack->{attacker} > $dispatch_planet_attack->{defender};
                $available = $dispatch_planet_attack->{defender} - $dispatch_planet_attack->{attacker};
            }
            
            my $dispatch_count = $self->dispatch_defender($body_id,$dispatch_planet_stats->{id},min($count,$available));
            
            if ($dispatch_count) {
                $planet_attack->{defender} += $dispatch_count;
                $self->_list_planet_attack->{$body_id}{defender} -= $dispatch_count;
                
                my $body_status = $self->my_body_status($body_id);
                push(@dispatch_ships,{
                    from_id     => $dispatch_planet_stats->{id},
                    from_name   => $dispatch_planet_stats->{name},
                    to_id       => $body_id,
                    to_name     => $body_status->{name},
                    count       => $dispatch_count,
                });
                $self->log('info','Dispatching %i defending units from %s to %s',$dispatch_count,$dispatch_planet_stats->{name},$body_status->{name});
            }
        }
    }
    
    if (scalar @dispatch_ships) {
        my $body = sprintf("We have dispatched defending ships:\n%s",
            join("\n", map {
                sprintf("%i ships from {Planet %i %s} to {Planet %i %s}",
                    $_->{count},
                    $_->{from_id},
                    $_->{from_name},
                    $_->{to_id},
                    $_->{to_name},
                );
            } @dispatch_ships)
        );
        $self->send_message('Dispatched defenders',$body);
    }
};

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Check incoming ships
    return
        unless defined($planet_stats->{incoming_enemy_ships});
    
    # Get space port
    my $spaceport = $self->find_building($planet_stats->{id},'SpacePort');
    
    return 
        unless $spaceport;
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get all incoming ships
    my $ships_data = $self->paged_request(
        object  => $spaceport_object,
        method  => 'view_foreign_ships',
        total   => 'number_of_ships',
        data    => 'ships',
    );
    
    my $attacker_count = 0;
    my $defender_count = 0;
    my $first_attacker_arrive;
    
    my @possible_attacking_ships;
    foreach my $ship (@{$ships_data->{ships}}) {
        if (defined $ship->{from}
            && defined $ship->{from}{empire}) {
            # My own ship
            next 
                if ($ship->{from}{empire}{id} == $planet_stats->{empire}{id});
        }
        
        # Ignore cargo ships
        next
            if ($ship->{type} ~~ [qw(dory galleon hulk cargo_ship barge freighter smuggler_ship)]);
        
        my $arrives = parse_date($ship->{date_arrives});
        
        next
            if (time() - $arrives) > (60 * 60 * 6); # six hours
        
        $first_attacker_arrive ||= $arrives;
        $first_attacker_arrive = $arrives
            if $arrives < $first_attacker_arrive;
        $attacker_count++;
    }
    
    return
        if $attacker_count == 0;
    
    $self->log('info','%i attacking ships detected on %s',$attacker_count,$planet_stats->{name});
    
    # Count SAWs
    $defender_count += $self->get_saws($planet_stats->{star_id});
    
    # Count local fighters & sweepers
    $defender_count += $self->get_local_defending_ships($planet_stats->{id},$first_attacker_arrive);
    
    # Count orbiting fighters
    $defender_count += $self->get_orbiting_defending_ships($planet_stats->{id},$first_attacker_arrive);
    
    # Recall foreign orbiting ships
    if ($attacker_count > $defender_count) {
        $defender_count += $self->recall_defender($planet_stats->{id},$first_attacker_arrive);
    }
    
    # Store attacker & defender
    $self->_add_planet_attack($planet_stats->{id},{
        attacker    => $attacker_count,
        defender    => $defender_count,
        arrive      => $first_attacker_arrive,
        free_slots  => $self->get_spaceport_slots($planet_stats->{id}),
    });
    
    $self->log('info','%i defending units available on %s',$defender_count,$planet_stats->{name});
}

sub get_orbiting_defending_ships {
    my ($self,$body_id,$first_attacker_arrive) = @_;
    
    my $spaceport = $self->find_building($body_id,'SpacePort');
    return 0
        unless $spaceport;
    my $spaceport_object = $self->build_object($spaceport);
    
    my $count = 0;
    
    # Get all available ships
    my $ships_data = $self->paged_request(
        object  => $spaceport_object,
        method  => 'view_ships_orbiting',
        total   => 'number_of_ships',
        data    => 'ships',
    );
    
    ORBITING_SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        next ORBITING_SHIPS
            unless $ship->{type} eq 'fighter'
            || $ship->{type} eq 'sweeper';
        
        # TODO check if orbiting ship is ally
        next ORBITING_SHIPS
            unless $ship->{from}{empire}{id} == $ships_data->{status}{empire}{id};
        
        $count++;
    }
    
    return $count;
}

sub get_spaceport_slots {
    my ($self,$body_id) = @_;
    
    my $spaceport = $self->find_building($body_id,'SpacePort');
    
    return 0
        unless scalar $spaceport;
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get all available ships
    my $spaceport_data = $self->request(
        object  => $spaceport_object,
        method  => 'view',
    );
    
    return $spaceport_data->{docks_available};
}

sub get_local_defending_ships {
    my ($self,$body_id,$first_attacker_arrive) = @_;
    
    my $spaceport = $self->find_building($body_id,'SpacePort');
    return 0
        unless $spaceport;
    my $spaceport_object = $self->build_object($spaceport);
    
    my $count = 0;
    
    # Get all available ships
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 }, { tag => [ 'War' ] } ],
    );
    
    LOCAL_SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        
        next LOCAL_SHIPS
            unless $ship->{type} eq 'fighter'
            || $ship->{type} eq 'sweeper';
        
        next LOCAL_SHIPS
            if $ship->{combat} < $self->min_defender_combat;
        
        given ($ship->{task}) {
            when('Travelling') {
                # Travelling home
                next LOCAL_SHIPS
                    unless $ship->{to}{type} eq 'body'
                    && $ship->{to}{id} == $body_id;
                
                # Check arrival time
                my $arrives = parse_date($ship->{date_arrives});
                next LOCAL_SHIPS
                    if $arrives > $first_attacker_arrive;
            }
            when('Building') {
                warn $ship;
                # Check arrival time
                my $arrives = parse_date($ship->{date_arrives});
                next LOCAL_SHIPS
                    if $arrives > $first_attacker_arrive;
            }
            when('Docked') {
                # do nothing
            }
            default {
                next LOCAL_SHIPS;
            }
        }
        
        $count++;
    }
    
    return $count;
}

sub get_saws {
    my ($self,$star_id,$first_attacker_arrive) = @_;
    
    my $count = 0;
    
    SYSTEM_PLANETS:
    foreach my $planet_stats ($self->my_planets) {
        next SYSTEM_PLANETS
            if $planet_stats->{star_id} != $star_id;
        my @saws = $self->find_building($planet_stats->{id},'SAW');
        SAWS:
        foreach my $saw (@saws) {
            # Check SAW level
            next SAWS
                unless ($saw->{level} * 1000 * $saw->{efficiency} / 100)  >= $self->min_defender_combat;
            
            # Check SAW availability
            if (defined $saw->{work}) {
                my $available = parse_date($saw->{work}{end});
                next SAWS
                    if $available > $first_attacker_arrive;
            }
            
            $count++;
        }
    }
    
    return $count;
}

sub dispatch_defender {
    my ($self,$to_body_id,$from_body_id,$count) = @_;
    
    my $spaceport = $self->find_building($from_body_id,'SpacePort');
    return 0
        unless $spaceport;
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get all available ships
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 }, { tag => [ 'War' ] } ],
    );
    
    my @relocate_ship;
    my $dispatch_ship = 0;
    
    # Loop all war ships
    LOCAL_SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        next LOCAL_SHIPS
            unless $ship->{type} eq 'fighter'
            || $ship->{type} eq 'sweeper';
        
        next LOCAL_SHIPS
            if $ship->{name} =~ m/\!/;
        
        next LOCAL_SHIPS
            if $ship->{type} eq 'sweeper'
            && $ship->{name} !~ m/(dispatch|\$|\+)/;
        
        next LOCAL_SHIPS
            if $ship->{combat} < $self->min_defender_combat;
        
        next LOCAL_SHIPS
            unless $ship->{task} eq 'Docked';
        
        # Dispatch fighter directly
        if ($ship->{type} eq 'fighter') {
            $dispatch_ship++;
            $self->request(
                object  => $spaceport_object,
                method  => 'send_ship',
                params  => [ $ship->{id}, { body_id => $to_body_id } ],
            );
        # Add sweeper to list of dispatchable units
        } elsif ($ship->{type} eq 'sweeper') {
            push(@relocate_ship,$ship->{id});
        }
        
        # Check if we have enough defenders
        return $dispatch_ship
            if $dispatch_ship >= $count;
    }
    
    # Relocate sweepers via push
    my $relocateable_ships = min( ($count-$dispatch_ship) , scalar(@relocate_ship), $self->_planet_attack->{$to_body_id}{free_slots} );
    if ($relocateable_ships > 0) {
        my @relocate_ships_final = @relocate_ship[0..($relocateable_ships-1)];
        $dispatch_ship += $self->push_ships($from_body_id,$to_body_id,\@relocate_ships_final);
    }
    
    return $dispatch_ship;
}

sub recall_defender {
    my ($self,$body_id,$first_attacker_arrive) = @_;
    
    my $spaceport = $self->find_building($body_id,'SpacePort');
    return 0
        unless $spaceport;
    my $spaceport_object = $self->build_object($spaceport);
    
    my $count = 0;
    
    # Get all available ships
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'recall_all',
    );
    
    RECALL_SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        # Check if ship arrives on time 
        my $arrive = parse_date($ship->{ship}{date_arrives});
        next RECALL_SHIPS
            if $arrive > $first_attacker_arrive;
        $count++;
    }
    
    return $count;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
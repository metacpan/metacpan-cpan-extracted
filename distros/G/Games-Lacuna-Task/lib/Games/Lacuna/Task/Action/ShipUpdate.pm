package Games::Lacuna::Task::Action::ShipUpdate;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
# -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun
    Games::Lacuna::Task::Role::Ships);

our @ATTRIBUTES = qw(hold_size combat speed stealth);

use List::Util qw(min max);
use Games::Lacuna::Task::Utils qw(normalize_name);

has 'handle_ships' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    documentation   => "List of ships which should be handled [Multiple]",
    default         => sub {
        return [qw(barge cargo_ship dory fighter freighter galleon hulk observatory_seeker scow security_ministry_seeker smuggler_ship snark spaceport_seeker sweeper)];
    },
);

has 'best_ships' => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => ['NoGetopt','Hash'],
    lazy_build      => 1,
    handles         => {
        available_best_ships    => 'count',
        get_best_ship           => 'get',
        best_ship_types         => 'keys',
    },
);

has 'best_planets' => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => ['NoGetopt','Hash'],
    lazy_build      => 1,
    handles         => {
        get_best_planet         => 'get',
        remove_best_planet      => 'delete',
        has_best_planet         => 'count',
        best_planet_ids         => 'keys',
    },
);

has 'threshold' => (
    is              => 'rw',
    isa             => 'Int',
    required        => 1,
    default         => 20,
    documentation   => "Threshold for ship attributes [Default: 20%]",
);

sub description {
    return q[Keep fleet up to date by building new ships and scuttling old ones. Best used in conjunction with ship_dispatch];
}

sub run {
    my ($self) = @_;
    
    unless ($self->available_best_ships) {
        $self->log('notice','No sphipyard slots available. Cannot proceed');
        return;
    }
    
    foreach my $planet_stats ($self->get_planets) {
        $self->check_best_planets();
        last 
            unless $self->has_best_planet;
        $self->log('info',"Processing planet %s",$planet_stats->{name});
        $self->process_planet($planet_stats);
    }
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Get space port
    my $spaceport_object = $self->get_building_object($planet_stats->{id},'SpacePort');
    
    return 
        unless $spaceport_object;
    
    # Get all available ships
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 } ],
    );
    
    my $old_ships = {};
    my $threshold = $self->threshold / 100 + 1;
    
    # Loop all shios
    SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        my $ship_type = $ship->{type};
        $ship_type =~ s/\d$//;
        
        # Filter ships by name, type and task
        next
            if $ship->{name} =~ m/\b scuttle \b/ix;
        next
            if $ship->{task} ~~ [qw(Waiting On Trade Building)];
        next
            unless $ship_type ~~ $self->handle_ships;
        next
            unless defined $self->best_ships->{$ship_type};
        
        my $best_ship = $self->get_best_ship($ship_type);
        
        my $ship_is_ok = 1;
        
        foreach my $attribute (@ATTRIBUTES) {
            if ($ship->{$attribute} > $best_ship->{$attribute}) {
                next SHIPS;
            }
            if ($ship->{$attribute} < ($best_ship->{$attribute} / $threshold)) {
                $ship_is_ok = 0;
            }
        }
        
        next
            if $ship_is_ok;
        
        $self->log('debug','Ship %s on %s is outdated',$ship->{name},$planet_stats->{name});
        
        $old_ships->{$ship_type} ||= [];
        push (@{$old_ships->{$ship_type}},$ship);
    }
    
    foreach my $ship_type (sort { scalar @{$old_ships->{$b}} <=> scalar @{$old_ships->{$a}} } keys %{$old_ships}) {
        my $old_ships = $old_ships->{$ship_type};
        my $best_ships = $self->get_best_ship($ship_type);
        my $build_planet_id = $best_ships->{planet};
        my $build_planet_stats = $self->get_best_planet($build_planet_id);
        next
            if ! defined $build_planet_stats 
            ||$build_planet_stats->{total_slots} <= 0;
            
        my $build_spaceport = $self->find_building($build_planet_id,'SpacePort');
        my $build_spaceport_object = $self->build_object($build_spaceport);
        
        my (@ships_mining,@ships_general);
        foreach my $old_ship (@{$old_ships}) {
            if ($old_ship->{task} eq 'Mining') {
                push(@ships_mining,$old_ship);    
            } else {
                push(@ships_general,$old_ship); 
            }
        }
        
        my $name_prefix = ($build_planet_id == $planet_stats->{id} ) ? '' : $planet_stats->{name};
        
        my @new_building = $self->build_ships(
            planet              => $self->my_body_status($build_planet_id),
            quantity            => scalar(@{$old_ships}),
            type                => $best_ships->{type},
            spaceports_slots    => $build_planet_stats->{spaceport_slots},
            shipyard_slots      => $build_planet_stats->{shipyard_slots},
            shipyards           => $build_planet_stats->{shipyards},
            name_prefix         => $name_prefix,
        );
        
        my $new_building_count = scalar @new_building;
        $build_planet_stats->{spaceport_slots} -= $new_building_count;
        $build_planet_stats->{shipyard_slots} -= $new_building_count;
        $build_planet_stats->{total_slots} -= $new_building_count;
        
        foreach my $new_ship (@new_building) {
            my $old_ship;
            if ($old_ship = pop(@ships_mining)) {
                $self->name_ship(
                    spaceport   => $build_spaceport_object,
                    ship        => $new_ship,
                    prefix      => [ $planet_stats->{name},'Mining' ],
                    name        => $new_ship->{type_human},
                );
            } else {
                $old_ship = pop(@ships_general)   
            }
            
            $self->name_ship(
                spaceport   => $spaceport_object,
                ship        => $old_ship,
                prefix      => 'Scuttle',
                ignore      => 1,
            );
        }
        
        #$self->check_best_planets;
    }
}

sub _build_best_ships {
    my ($self) = @_;
    
    my $best_ships = {};
    foreach my $planet_stats ($self->get_planets) {
        $self->log('info',"Checking best ships at planet %s",$planet_stats->{name});
        my ($buildable_ships,$docks_available) = $self->get_buildable_ships($planet_stats);
        
        BUILDABLE_SHIPS:
        while (my ($type,$data) = each %{$buildable_ships}) {
            $data->{planet} = $planet_stats->{id};
            $best_ships->{$type} ||= $data;
            foreach my $attribute (@ATTRIBUTES) {
                if ($best_ships->{$type}{$attribute} < $data->{$attribute}) {
                    
                    $best_ships->{$type} = $data;
                    next BUILDABLE_SHIPS;
                }
            }
        }
    }
    
    return $best_ships;
}

sub _build_best_planets {
    my ($self) = @_;
    
    my $best_planets = {};
    foreach my $best_ship ($self->best_ship_types) {
        my $planet_id = $self->get_best_ship($best_ship)->{planet};
        
        unless (defined $best_planets->{$planet_id}) {
            my ($available_shipyard_slots,$available_shipyards) = $self->shipyard_slots($planet_id);
            my ($available_spaceport_slots) = $self->spaceport_slots($planet_id);
            
            my $shipyard_slots = max($available_shipyard_slots,0);
            my $spaceport_slots = max($available_spaceport_slots,0);
            my $total_slots = min($shipyard_slots,$spaceport_slots);
            
            $best_planets->{$planet_id} = {
                shipyard_slots  => $shipyard_slots,
                spaceport_slots => $spaceport_slots,
                total_slots     => $total_slots,
                shipyards       => $available_shipyards,
            };
        }
        
        $self->log('info',"Best %s can be buildt at %s",$best_ship,$self->my_body_status($planet_id)->{name});
    }
    
    return $best_planets;
}

sub check_best_planets {
    my ($self) = @_;
    
    foreach my $planet_id ($self->best_planet_ids) {
        $self->remove_best_planet($planet_id)
            if $self->get_best_planet($planet_id)->{total_slots} <= 0;
    }
    return;
}

sub get_buildable_ships {
    my ($self,$planet_stats) = @_;
    
    my $shipyard = $self->find_building($planet_stats->{id},'Shipyard');
    
    return
        unless defined $shipyard;
    
    my $shipyard_object = $self->build_object($shipyard);
    
    my $ship_buildable = $self->request(
        object  => $shipyard_object,
        method  => 'get_buildable',
    );
    
    my $ships = {};
    while (my ($type,$data) = each %{$ship_buildable->{buildable}}) {
        my $ship_type = $type;
        $ship_type =~ s/\d$//;
        
        next
            unless $ship_type ~~ $self->handle_ships;
        next
            if $data->{can} == 0 
            && $data->{reason}[1] !~ m/^You can only have \d+ ships in the queue at this shipyard/i
            && $data->{reason}[1] !~ m/^You do not have \d docks available at the Spaceport/i;
        next
            if defined $ships->{$ship_type}
            && grep { $data->{attributes}{$_} < $ships->{$ship_type}{$_} } @ATTRIBUTES;
        
        $ships->{$ship_type} = {
            (map { $_ => $data->{attributes}{$_} } @ATTRIBUTES),
            type    => $type,
        };
    }
    
    #,$ship_buildable->{docks_available}
    return $ships;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

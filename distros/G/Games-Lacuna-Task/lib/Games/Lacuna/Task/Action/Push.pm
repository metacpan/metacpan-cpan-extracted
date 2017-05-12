package Games::Lacuna::Task::Action::Push;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Ships',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['mytarget_planet','home_planet'] };

use List::Util qw(sum min max);
use Games::Lacuna::Client::Types qw(ore_types food_types is_ore_type is_food_type);

our @RESOURCES_FULL = (@Games::Lacuna::Task::Constants::RESOURCES_ALL,ore_types(),food_types());

has 'auto' => (
    is              => 'rw',
    isa             => 'Bool',
    documentation   => 'Automatically determine required ressources',
    default         => 0,
);

has 'auto_target' => (
    is              => 'rw',
    isa             => 'Int',
    documentation   => 'Storage fill percentage target in auto mode',
    default         => 80,
);

has 'auto_hours' => (
    is              => 'rw',
    isa             => 'Int',
    documentation   => 'Plan for n-hours if running in auto mode',
    default         => 1,
);


foreach my $resource (@RESOURCES_FULL) {
    has $resource=> (
        is              => 'rw',
        isa             => 'Int',
        documentation   => ucfirst($resource).' quantity',
        predicate       => 'has_'.$resource,
    );
}

sub description {
    return q[Push goods between your colonies];
}

sub run {
    my ($self) = @_;
    
    my $planet_home = $self->home_planet_data();
    my $planet_target = $self->target_planet_data();
    
    my $trade_object = $self->get_building_object($planet_home,'Trade');
    my $spaceport_object = $self->get_building_object($planet_home,'SpacePort');
    
    return $self->abort('Could not find trade ministry')
        unless $trade_object;
    return $self->abort('Could not find spaceport')
        unless $spaceport_object;
    
    
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 },{ tag => 'Trade', task => 'Docked' } ],
    );
    
    my $available_hold_size = 0;
    my $available_ships = [];
    
    # Find all avaliable ships
    SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        # No reserved ships
        next SHIPS
            if $ship->{name} =~ m/!/;
        next SHIPS
            if $ship->{type} eq 'scow';
        
        $available_hold_size += $ship->{hold_size};
        
        push(@{$available_ships},$ship);
    }
    
    # Get searchable ores
    my $resources_stored_response = $self->request(
        object  => $trade_object,
        method  => 'get_stored_resources',
    );
    
    # Cacl food & ore totals
    my %resources_stored = %{$resources_stored_response->{resources}};
    $resources_stored{ore} = 0;
    $resources_stored{food} = 0;
    foreach my $resource (keys %resources_stored) {
        if (is_ore_type($resource)) {
            $resources_stored{ore} += $resources_stored{$resource};
        } elsif (is_food_type($resource)) {
            $resources_stored{food} += $resources_stored{$resource};
        }
    }
    
    # Calc resources we need to push
    my $resource_total;
    my %resources_push;
    my $resources_take = sub {
        my ($resource,$quantity_required) = @_;
        my $quantity_stored = $resources_stored{$resource} // 0;
        
        $self->abort('%s does not have enough %s (%i required, %i stored)',$planet_home->{name},$resource,$quantity_required,$quantity_stored)
            if ($quantity_stored < $quantity_required);
        
        if (is_food_type($resource)) {
            $resources_stored{'food'} -= $quantity_required;
        } elsif (is_ore_type($resource)) {
            $resources_stored{'ore'} -= $quantity_required;
        }
        
        $resources_push{$resource} ||= 0;
        $resources_stored{$resource} -= $quantity_required;
        $resources_push{$resource} += $quantity_required;
        $resource_total += $quantity_required;
    };
    
    # Get requested resources
    my %resources_requested;
    if ($self->auto) {
        my $resource_auto_total = 0;
        foreach my $resource (@Games::Lacuna::Task::Constants::RESOURCES) {
            my $resource_required = int(
                ($planet_target->{$resource.'_capacity'} * ($self->auto_target / 100)) - 
                $planet_target->{$resource.'_stored'} + 
                ($planet_target->{$resource.'_hour'} * $self->auto_hours)
            );
            if ($resource_required > 0) {
                $resource_required = min(int($planet_home->{$resource.'_stored'} * 0.8),$resource_required);
                $resources_requested{$resource} = $resource_required;
                $resource_auto_total += $resource_required;
            }
        }
        if ($resource_auto_total > $available_hold_size) {
            my $resource_coeficient = $available_hold_size/$resource_auto_total;
            foreach my $resource (@Games::Lacuna::Task::Constants::RESOURCES) {
                $resources_requested{$resource} = int($resource_coeficient * $resources_requested{$resource});
            }
        }
    }  else {
        foreach my $resource (@RESOURCES_FULL) {
            my $predicate_method = 'has_'.$resource;
            if ($self->$predicate_method
                && $self->$resource > 0) {
                $resources_requested{$resource} = $self->$resource;
            }
        }
    }
    
    # Take requested resources
    foreach my $resource (keys %resources_requested) {
        given ($resource) {
            when ([qw(ore food)]) {
                my $quantity_stored = $resources_stored{$resource} // 0;
                my $resource_percentage = $resources_requested{$resource} / $quantity_stored;
                no strict 'refs';
                my @resource_sub = &{$_.'_types'}();
                foreach my $resource_sub (@resource_sub) {
                    next
                        unless defined $resources_stored{$resource_sub};
                    $resources_take->($resource_sub,int($resource_percentage * $resources_stored{$resource_sub} + 0.5 // 0));
                }
            }
            default {
                $resources_take->($resource,$resources_requested{$resource});
            }
        }
    }
    
    if ($resource_total > $available_hold_size) {
        $self->abort('%s does not have enough cargo fleet capacity (%i required, %i available)',$planet_home->{name},$resource_total,$available_hold_size);
    }
    
    my $resource_push_ship = sub {
        my ($ship) = @_;
        my @resources_push_ship;
        my $resource_push_ship_quantity = 0;
        foreach my $resource (keys %resources_push) {
            next
                if $resources_push{$resource} == 0;
            my $quantity = min($resources_push{$resource},$ship->{hold_size}-$resource_push_ship_quantity);
            $resource_push_ship_quantity += $quantity;
            $resources_push{$resource} -= $quantity;
            push(@resources_push_ship,{
                type    => $resource,
                quantity=> $quantity,
            });
            last
                if $resource_push_ship_quantity >= $ship->{hold_size};
        }
        $self->log('notice','Sending %i resources from %s to %s with %s',$resource_push_ship_quantity,$planet_home->{name},$planet_target->{name},$ship->{name});
        
        $self->request(
            object  => $trade_object,
            method  => 'push_items',
            params  => [ $planet_target->{id}, \@resources_push_ship, { 
                ship_id => $ship->{id},
                stay    => 0,
            } ]
        );
    };
    
    # Try to find single ship with enough cargo space
    foreach my $ship (sort  { $a->{hold_size} <=> $b->{hold_size} } @{$available_ships}) {
        if ($ship->{hold_size} > $resource_total) {
            $resource_push_ship->($ship);
            return;
        }
    }
    
    foreach my $ship (sort  { $b->{hold_size} <=> $a->{hold_size} } @{$available_ships}) {
        $resource_push_ship->($ship);
        return
            if sum(values %resources_push) == 0;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
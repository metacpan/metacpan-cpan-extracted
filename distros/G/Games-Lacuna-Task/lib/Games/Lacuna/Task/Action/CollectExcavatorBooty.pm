package Games::Lacuna::Task::Action::CollectExcavatorBooty;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Ships',
    'Games::Lacuna::Task::Role::PlanetRun',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['home_planet'] };

has 'plans' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    required        => 1,
    documentation   => 'Automatic plans to be transported',
    default         => sub {
        [
            'Grove of Trees',
            'Algae Pond',
            'Amalgus Meadow',
            'Beach [1]',
            'Beach [2]',
            'Beach [3]',
            'Beach [4]',
            'Beach [5]',
            'Beach [6]',
            'Beach [7]',
            'Beach [8]',
            'Beach [9]',
            'Beach [10]',
            'Beach [11]',
            'Beach [12]',
            'Beach [13]',
            'Beeldeban Nest',
            'Crater',
            'Denton Brambles',
            'Geo Thermal Vent',
            'Grove of Trees',
            'Lagoon',
            'Lake',
            'Lapis Forest',
            'Malcud Field',
            'Natural Spring',
            'Patch of Sand',
            'Ravine',
            'Rocky Outcropping',
            'Volcano',
            
            'Citadel of Knope',
            'Black Hole Generator',
            'Oracle of Anid',
            'Temple of the Drajilites',
            'Library of Jith',
            'Kalavian Ruins',
            'Interdimensional Rift',
            'Gratch\'s Gauntlet',
            'Crashed Ship Site',
            'Pantheon of Hagness',
            
        ]
    }
);

has 'extra_build_level' => (
    is              => 'rw',
    isa             => 'Int',
    required        => 1,
    documentation   => 'Ignore plans with extra build level above this value [Default: 2]',
    default         => 2,
);

has 'min_items' => (
    is              => 'rw',
    isa             => 'Int',
    required        => 1,
    documentation   => 'Only send ship if we have n-items to be sent [Default: 1]',
    default         => 1,
);


sub description {
    return q[Ship excavator booty to a selected planet];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    return
        if $planet_stats->{id} == $self->home_planet_data->{id};
        
    # Get trade ministry
    my $tradeministry = $self->find_building($planet_stats->{id},'Trade');
    return 
        unless $tradeministry;
    my $tradeministry_object = $self->build_object($tradeministry);
    
    # Get glyphs
    my $available_glyphs = $self->request(
        object  => $tradeministry_object,
        method  => 'get_glyphs',
    );
    
    # Get plans
    my $available_plans = $self->request(
        object  => $tradeministry_object,
        method  => 'get_plans',
    );
    
    my $total_cargo;
    my @cargo;
    
    # Get all glyphs
    foreach my $glyph (@{$available_glyphs->{glyphs}}) {
        push(@cargo,{
            "type"      => "glyph",
            "glyph_id"  => $glyph->{id},
        });
        $total_cargo += $available_glyphs->{cargo_space_used_each};
    }
    
    # Get all plans
    PLANS:
    foreach my $plan (@{$available_plans->{plans}}) {
        next PLANS
            unless $plan->{level} == 1;
        next PLANS
            unless $plan->{name} ~~ $self->plans;
        next PLANS
            if $plan->{extra_build_level} > $self->{extra_build_level};
        
        push(@cargo,{
            "type"      => "plan",
            "plan_id"  => $plan->{id},
        });
        $total_cargo += $available_plans->{cargo_space_used_each};
    }
    
    return
        unless scalar @cargo;
    
    return
        if scalar @cargo < $self->min_items;
    
    # Get trade ships
    my $available_trade_ships = $self->request(
        object  => $tradeministry_object,
        method  => 'get_trade_ships',
        params  => [ $self->home_planet_data->{id} ],
    );
    
    return
        unless scalar @{$available_trade_ships->{ships}};
    
    my $trade_ship_id;
    TRADE_SHIP:
    foreach my $ship (sort { $b->{speed} <=> $a->{speed} } @{$available_trade_ships->{ships}}) {
        # TODO send multiple ships if cargo requirements exceed capacity of single ship
        next TRADE_SHIP
            if $ship->{hold_size} < $total_cargo;
        next TRADE_SHIP
            if $ship->{name} =~ m/!/;
        $trade_ship_id = $ship->{id};
        last TRADE_SHIP; 
    }
    
    my $response = $self->request(
        object  => $tradeministry_object,
        method  => 'push_items',
        params  => [ $self->home_planet_data->{id} , \@cargo, { ship_id => $trade_ship_id } ]
    );
    
    $self->log('notice','Sending %i item(s) from %s to %s',scalar(@cargo),$planet_stats->{name},$self->home_planet_data->{name});
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
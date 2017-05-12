package Games::Lacuna::Task::Action::Mining;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars
    Games::Lacuna::Task::Role::Ships
    Games::Lacuna::Task::Role::PlanetRun);

use List::Util qw(sum);
use Games::Lacuna::Client::Types qw(ore_types);

sub description {
    return q[Deploy mining platforms to best available asteroids];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
        
    # Get observatory
    my $mining = $self->find_building($planet_stats->{id},'MiningMinistry');
    
    # Get space port
    my $spaceport = $self->find_building($planet_stats->{id},'SpacePort');
    
    return 
        unless $mining && $spaceport;
    
    # Get observatory probed stars
    my $mining_object = $self->build_object($mining);
    my $mining_data = $self->request(
        object  => $mining_object,
        method  => 'view_platforms',
    );
    
    # Check if we can have more platforms
    my $available_platforms = ($mining_data->{max_platforms} - scalar @{$mining_data->{platforms}});
    
    return
        if $available_platforms == 0;
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get available mining ships
    my @avaliable_miningships = $self->get_ships(
        planet          => $planet_stats,
        quantity        => $available_platforms,
        type            => 'mining_platform_ship',
        travelling      => 1,
    );
    
    return
        unless scalar @avaliable_miningships;
    
    my %ores_production;
    my %ores_coeficient;
    my %asteroids;
    my $ores_planet_total = sum(values %{$planet_stats->{ore}});
    
    # Get planet ore production
    while (my ($ore,$quantity) = each %{$planet_stats->{ore}}) {
        $ores_production{$ore} ||= 0;
        $ores_production{$ore} += int(($quantity / $ores_planet_total) * $planet_stats->{ore_hour});
    }
    
    # Get platforms ore production
    foreach my $platform (@{$mining_data->{platforms}}) {
        my $asteroid_id = $platform->{asteroid}{id};
        $asteroids{$asteroid_id} ||= 0;
        $asteroids{$asteroid_id} ++;
        foreach my $ore (ore_types()) {
            my $quantity = $platform->{$ore.'_hour'};
            $ores_production{$ore} += $quantity;
        }
    }
    # Total ore production
    my $ores_production_total = sum(values %ores_production);
    
    # Calc which ores are underrepresented
    my $ore_type_count = scalar ore_types();
    foreach my $ore (ore_types()) {
        $ores_coeficient{$ore} = -1*( ($ores_production{$ore} / $ores_production_total) - (1/$ore_type_count));
    }
    
    # Get closest asteroids
    my @asteroids = $self->closest_asteroids($planet_stats->{x},$planet_stats->{y},25);
    
    foreach my $asteroid (@asteroids) {
        my $asteroid_quality = 1;
        my $asteroid_id = $asteroid->{id};
        while (my ($ore,$quantity) = each %{$asteroid->{ore}}) {
            next
                if $quantity <= 1;
            $asteroid_quality += $ores_coeficient{$ore} * ($quantity*2)
                if $ores_coeficient{$ore} > 0;
        }
        
        # Calc asteroid quality based on ore quantity, number of different ores and exclusive ores (TODO make this better)
        my $ore_count = $asteroid->{ore_total};
        $ore_count /= 2;
        $ore_count = 1
            if $ore_count < 1;
        $asteroid->{quality} = int($asteroid_quality * $asteroid->{ore_total} * $asteroid->{ore_count});
        $asteroid->{quality} *= (1 - (0.1 * $asteroids{$asteroid_id}))
            if defined $asteroids{$asteroid_id};
        $self->log('debug','Calculated asteroid quality for %s is %i',$asteroid->{name},$asteroid->{quality})
    }
    
    my @asteroids_sorted = sort { $b->{quality} <=> $a->{quality} } @asteroids;
    
    # Get all minings ships
    MINING_SHIP:
    foreach my $mining_ship (@avaliable_miningships) {
        # Find best asteroid
        ASTEROID_CANDIDATE:
        while (scalar @asteroids_sorted) {
            my $asteroid = shift(@asteroids_sorted);
            my $asteroid_data = $self->request(
                object  => $spaceport_object,
                method  => 'get_ships_for',
                params  => [ $planet_stats->{id}, { "body_id" => $asteroid->{id} } ],
            );
            
            next ASTEROID_CANDIDATE
                if scalar(@{$asteroid_data->{incoming}}) > 0;
            next ASTEROID_CANDIDATE
                if scalar(@{$asteroid_data->{available}}) == 0;
            next ASTEROID_CANDIDATE
                if defined $asteroid_data->{mining_platforms}
                && scalar(@{$asteroid_data->{mining_platforms}}) == $asteroid->{size};
            
            $self->log('notice',"Sending mining platform to %s",$asteroid->{name});
            
            # Send mining platform to best asteroid
            
            my $send_data = $self->request(
                object  => $spaceport_object,
                method  => 'send_ship',
                params  => [ $mining_ship,{ "body_id" => $asteroid->{id} } ],
            );
            
            next MINING_SHIP;
        }
    }
    
    # TODO check transport ships

    return;
}

sub closest_asteroids {
    my ($self,$x,$y,$limit) = @_;
    
    $limit //= 1;
    
    my @asteroids;
    
    $self->search_stars_callback(
        sub {
            my ($star_data) = @_;
            
            foreach my $body (@{$star_data->{bodies}}) {
                next 
                    unless $body->{type} eq 'asteroid';
                $body->{ore_total} = sum(values %{$body->{ore}});
                $body->{ore_count} = scalar(grep { $_ > 1 } values %{$body->{ore}});
                push(@asteroids,$body);
            }
            
            return 0
                if scalar(@asteroids) >= $limit;
            
            return 1;
        },
        x           => $x,
        y           => $y,
        is_known    => 1,
        distance    => 1,
    );

    return @asteroids;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

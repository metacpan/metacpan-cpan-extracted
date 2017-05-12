package Games::Lacuna::Task::Action::UpgradeBuilding;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Building',
    'Games::Lacuna::Task::Role::PlanetRun',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['start_building_at'] };

use List::Util qw(max min);
use Games::Lacuna::Task::Utils qw(parse_date);

has 'upgrade_buildings' => (
    isa     => 'HashRef[ArrayRef[Str]]',
    is      => 'rw',
    default => sub {
        {
            'WasteSequestration'    => ['waste','storage'],
            
            'OreStorage'            => ['ore','storage'],
            'WaterStorage'          => ['water','storage','max20'],
            'FoodReserve'           => ['food','storage','max20'],
            'EnergyReserve'         => ['energy','storage','max20'],
            
            'Stockpile'             => ['global','storage'],
            'PlanetaryCommand'      => ['global','storage'],
            'DistributionCenter'    => ['global','storage','max18'],
            
            'AtmosphericEvaporator' => ['water','production'],
            'WaterProduction'       => ['water','production'],
            'WaterPurification'     => ['water','production'],
            'WaterReclamation'      => ['water','waste','production'],
            
            'Mine'                  => ['ore','production'],
            'MiningMinistry'        => ['ore','production'],
            'OreRefinery'           => ['ore','production'],
            'WasteDigester'         => ['ore','waste','production'],
            
            'Hydrocarbon'           => ['energy','production'],
            'Geo'                   => ['energy','production'],
            'Fission'               => ['energy','production'],
            'Fusion'                => ['energy','production'],
            'Singularity'           => ['energy','production'],
            'WasteEnergy'           => ['energy','waste','production'],
            
            'Algae'                 => ['food','production'],
            'Apple'                 => ['food','production'],
            'Bean'                  => ['food','production'],
            'Beeldeban'             => ['food','production'],
            'Corn'                  => ['food','production'],
            'Dairy'                 => ['food','production'],
            'Beeldeban'             => ['food','production'],
            'Lapis'                 => ['food','production'],
            'Malcud'                => ['food','production'],
            'Potato'                => ['food','production'],
            'Wheat'                 => ['food','production'],
            
            'WasteTreatment'        => ['global','waste','production'],
            'WasteExchanger'        => ['global','waste','production'],
            
            'Shipyard'              => ['extra','maxother'],
            'SpacePort'             => ['extra','maxother'],
            'SAW'                   => ['extra','maxother'],
            
            'Sand'                  => ['extra'],
            'Grove'                 => ['extra'],
            'Lagoon'                => ['extra'],
            (map {
                 'lcot'.$_          => ['global','extra'],
            } qw(a..i)),
        }
    },
    documentation => 'Building uprade preferences',
);

sub description {
    return q[Upgrade buildings if the build queue is empty];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my @buildings = $self->buildings_body($planet_stats->{id});
    my $timestamp = time();
    my $build_queue_size = $self->build_queue_size($planet_stats->{id});
    
    # Check if build queue is filled
    return
        if ($build_queue_size > $self->start_building_at);
    
    my @upgradeable_buildings;
    
    # Check if waste production > 0
    if ($planet_stats->{'waste_hour'} > 0) {
        push(@upgradeable_buildings,$self->find_upgrade_buildings($planet_stats,'waste','production'));
    }
    
    # Check if storage is overflowing
    if (scalar @upgradeable_buildings == 0) {
        foreach my $element (qw(waste ore water food energy)) {
            my $available_storage = $planet_stats->{$element.'_capacity'};
            my $free_storage = $available_storage-$planet_stats->{$element.'_stored'};
            if (($free_storage / $available_storage) < 0.01) {
                push(@upgradeable_buildings,$self->find_upgrade_buildings($planet_stats,$element,'storage'));
            }
        }
    }
    
    # Check production buildings
    if (scalar @upgradeable_buildings == 0) {
        my @production = 
            sort { $planet_stats->{$a.'_hour'} cmp $planet_stats->{$b.'_hour'} } @Games::Lacuna::Task::Constants::RESOURCES;
        my $min_production = min map { $planet_stats->{$_.'_hour'} } @production;
        foreach my $element (@Games::Lacuna::Task::Constants::RESOURCES) {
            my $limit_production = $planet_stats->{$element.'_hour'} * 0.8;
            next
                if $limit_production > $min_production;
            push(@upgradeable_buildings,$self->find_upgrade_buildings($planet_stats,$element,'production'));
            last
                if scalar(@upgradeable_buildings) > 0;
        }
    }
    
    # Find any other upgradeable building
    for my $tag (qw(storage waste global extra)) {
        last
            if (scalar @upgradeable_buildings > 0);
        @upgradeable_buildings = $self->find_upgrade_buildings($planet_stats,$tag);
    }
    
    if (scalar @upgradeable_buildings) {
        @upgradeable_buildings = sort { $a->{level} <=> $b->{level} } 
            @upgradeable_buildings;
            
        foreach my $building_data (@upgradeable_buildings) {
            
            my $upgrade = $self->upgrade_building($planet_stats,$building_data);
            
            $build_queue_size ++
                if $upgrade;
            return
                if ($build_queue_size > $self->start_building_at);
        }
    }
    
    warn \@upgradeable_buildings;
    
    return;
}

sub find_upgrade_buildings {
    my ($self,$planet_stats,@tags) = @_;
    
    my @upgrade_buildings;
    my @buildings = $self->buildings_body($planet_stats->{id});
    
    my $max_ressouce_level = $self->max_resource_building_level($planet_stats->{id});
    my $max_building_level = $self->university_level() + 1;
    my $max_building_type_level = {};
    my $timestamp = time();
    
    BUILDING:
    foreach my $building_data (sort { $b->{level} <=> $a->{level} } @buildings) {
        my $building_class = Games::Lacuna::Client::Buildings::type_from_url($building_data->{url});
        my $building_level = $building_data->{level};
        
        $max_building_type_level->{$building_class} ||= $building_level;
        
        next BUILDING
            unless exists $self->upgrade_buildings->{$building_class};
        
        foreach my $tag (@tags) {
            next BUILDING
                unless $tag ~~ $self->upgrade_buildings->{$building_class};
        }
        
        foreach my $tag (@{$self->upgrade_buildings->{$building_class}}) {
            next BUILDING
                if $tag =~ m/max(?<level>\d+)$/ && $building_level >= $+{level};
        }
        
        next BUILDING
            if $building_level >= $max_building_level;
        
        next BUILDING
            if 'production' ~~ $self->upgrade_buildings->{$building_class}
            && $building_level >= $max_ressouce_level;
            
        next BUILDING
            if 'maxother' ~~ $self->upgrade_buildings->{$building_class}
            && $building_level >= $max_building_type_level->{$building_class};
        
        if (defined $building_data->{pending_build}) {
            my $date_end = parse_date($building_data->{pending_build}{end});
            next BUILDING
                if $timestamp < $date_end;
        }
        
        next BUILDING
            unless $self->check_upgrade_building($planet_stats,$building_data);
        
        push(@upgrade_buildings,$building_data);
    }
    
    return @upgrade_buildings;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

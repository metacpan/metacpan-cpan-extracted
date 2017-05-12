package Games::Lacuna::Task::Action::WasteRecycle;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Waste',
    'Games::Lacuna::Task::Role::PlanetRun';

use List::Util qw(min);
use Games::Lacuna::Task::Utils qw(parse_date);

our @RESOURCES_RECYCLEABLE = qw(water ore energy);

sub description {
    return q[Recycle waste with the Waste Recycling Center and Waste Exchanger];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my $timestamp = time();
    my %resources;
    my @recycling_buildings;
    
    push (@recycling_buildings,$self->find_building($planet_stats->{id},'WasteRecycling'));
    push (@recycling_buildings,$self->find_building($planet_stats->{id},'WasteExchanger'));
    
    return
        unless scalar @recycling_buildings;
    
    my $waste_stored = $planet_stats->{waste_stored};
    my $waste_capacity = $planet_stats->{waste_capacity};
    my $waste_filled = ($waste_stored / $waste_capacity) * 100;
    my $waste_disposeable = $self->disposeable_waste($planet_stats);
    
    my $total_resources = 0;
    my $total_resources_coeficient = 0;
    my $total_waste_coeficient = 0;
    
    return
        if $waste_disposeable <= 0;
    
    # Get stored resources
    foreach my $resource (@RESOURCES_RECYCLEABLE) {
        my $stored = $planet_stats->{$resource.'_stored'}+0;
        my $capacity = $planet_stats->{$resource.'_capacity'}+0;
        $resources{$resource} = [ $capacity-$stored, 0, 0];
        $total_resources += $capacity-$stored;
    }
    
    # Fallback if storage is full
    if ($total_resources == 0) {
        foreach my $resource (@RESOURCES_RECYCLEABLE) {
            my $capacity = $planet_stats->{$resource.'_capacity'}+0;
            $resources{$resource}[0] = $capacity;
            $total_resources += $capacity;
        }
    }
    
    # Calculate ressouces
    foreach my $resource (@RESOURCES_RECYCLEABLE) {
        $resources{$resource}[1] =  ($resources{$resource}[0] / $total_resources);
        if ($resources{$resource}[1] > 0
            && $resources{$resource}[1] < 1) {
            $resources{$resource}[1] = 1-($resources{$resource}[1]);
        }
        $total_resources_coeficient += $resources{$resource}[1];
    }
    
    # Calculate recycling relations
    foreach my $resource (@RESOURCES_RECYCLEABLE) {
        $resources{$resource}[2] = ($resources{$resource}[1] / $total_resources_coeficient);
    }
    
    # Loop all recycling buildings
    foreach my $recycling_building (@recycling_buildings) {
        
        last
            if $waste_disposeable <= 0;
        
        # Check recycling is busy
        if (defined $recycling_building->{work}) {
            my $work_end = parse_date($recycling_building->{work}{end});
            if ($work_end > $timestamp) {
                next;
            }
        }
        
        my $recycling_object = $self->build_object($recycling_building);
        my $recycling_data = $self->request(
            object  => $recycling_object,
            method  => 'view',
        );
        
        my $recycle_quantity = min($waste_disposeable,$recycling_data->{recycle}{max_recycle});
        
        my %recycle = (map { $_ => int($resources{$_}[2] * $recycle_quantity) } keys %resources);
        
        $self->log('notice',"Recycling %i %s, %i %s, %i %s on %s",(map { ($recycle{$_},$_) } @RESOURCES_RECYCLEABLE),$planet_stats->{name});
        
        $self->request(
            object  => $recycling_object,
            method  => 'recycle',
            params  => [ (map { $recycle{$_} } @RESOURCES_RECYCLEABLE) ],
        );
        
        $waste_disposeable -= $recycle_quantity;
        
        $self->clear_cache('body/'.$planet_stats->{id}.'/buildings');
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
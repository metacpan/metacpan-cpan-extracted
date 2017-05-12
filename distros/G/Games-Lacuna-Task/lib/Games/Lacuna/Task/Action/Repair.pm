package Games::Lacuna::Task::Action::Repair;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun);

sub description {
    return q[Repair damaged buildings];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my @buildings = $self->buildings_body($planet_stats->{id});
    my $waste_hour = $planet_stats->{waste_hour}+0;
    my $waste_stored = $planet_stats->{waste_stored}+0;
    
    # Loop all buildings
    foreach my $building_data (@buildings) {
        # Check if building needs to be repaired
        next
            if $building_data->{efficiency} == 100;
        
        my $building_object = $self->build_object($building_data);
        my $building_detail = $self->request(
            object  => $building_object,
            method  => 'view',
        );
        
        # Check if building really needs repair
        next
            if $building_detail->{building}{efficiency} == 100;

        # Check if we can afford repair
        next
            unless $self->can_afford($planet_stats,$building_detail->{building}{repair_costs});
        
        # Calc buildings repair impact on waste
        my $waste_hour_calc = $waste_hour + ($building_detail->{building}{waste_hour} * (100 - $building_detail->{building}{efficiency}));

        # Check if repair of waste recycling building is sustainable
        return
            if $building_detail->{id} ~~ [qw(WaterReclamation WasteDigester WasteEnergy WasteRecycling)]
            && $waste_hour_calc < 0
            && $waste_stored < ($waste_hour_calc * 24);
        
        # Repair building
        $self->log('notice',"Repairing %s on %s",$building_data->{name},$planet_stats->{name});
        
        $self->request(
            object  => $building_object,
            method  => 'repair',
        );

        $waste_hour = $waste_hour_calc;
        
        $self->clear_cache('body/'.$planet_stats->{id}.'/buildings');
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

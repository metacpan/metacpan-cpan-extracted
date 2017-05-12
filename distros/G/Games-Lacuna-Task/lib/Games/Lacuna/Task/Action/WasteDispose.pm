package Games::Lacuna::Task::Action::WasteDispose;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Waste',
    'Games::Lacuna::Task::Role::PlanetRun',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['dispose_percentage','keep_waste_hours'] };

sub description {
    return q[Dispose overflowing waste with scows];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Get stored waste
    my $waste_stored = $planet_stats->{waste_stored};
    my $waste_capacity = $planet_stats->{waste_capacity};
    my $waste_filled = ($waste_stored / $waste_capacity) * 100;
    my $waste_disposeable = $self->disposeable_waste($planet_stats);
    
    # Check if waste is overflowing
    return 
        if ($waste_filled < $self->dispose_percentage);
    
    # Get space port
    my ($spaceport) = $self->find_building($planet_stats->{id},'SpacePort');
    
    return
        unless $spaceport;
        
    my $spaceport_object = $self->build_object($spaceport);
    my $spaceport_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 } ],
    );
    
    # Get all available scows
    foreach my $ship (@{$spaceport_data->{ships}}) {
        next
            unless $ship->{task} eq 'Docked';
        next
            unless $ship->{type} eq 'scow';
        next
            if $ship->{name} =~ m/\!/;
        next
            if $ship->{hold_size} > $waste_disposeable;
            
        $self->log('notice',"Disposing %s waste on %s",$ship->{hold_size},$planet_stats->{name});
        
        # Send scow to closest star
        my $spaceport_data = $self->request(
            object  => $spaceport_object,
            method  => 'send_ship',
            params  => [ $ship->{id},{ "star_id" => $planet_stats->{star_id} } ],
        );
        
        $waste_disposeable -= $ship->{hold_size};
        $waste_stored -= $ship->{hold_size};
        $waste_filled = ($waste_stored / $waste_capacity) * 100;
        
        # Check if waste is overflowing
        return 
            if ($waste_filled < $self->dispose_percentage);
        
        $self->clear_cache('body/'.$planet_stats->{id});
    }
    
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
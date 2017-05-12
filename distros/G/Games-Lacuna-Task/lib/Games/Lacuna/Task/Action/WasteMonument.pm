package Games::Lacuna::Task::Action::WasteMonument;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with 'Games::Lacuna::Task::Role::Building',
    'Games::Lacuna::Task::Role::Waste',
    'Games::Lacuna::Task::Role::PlanetRun',
    'Games::Lacuna::Task::Role::CommonAttributes' => { attributes => ['dispose_percentage','start_building_at'] };

our @WASTE_MONUMENTS = (
    'Junk Henge Sculpture',
    'Great Ball of Junk',
    'Metal Junk Arches',
    'Space Junk Park',
    'Pyramid Junk Sculpture',
);

sub description {
    return q[Demolish and rebuild waste monuments];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Check min university level
    return
        if $self->university_level < 21;
    
    my $timestamp = time();
    my $build_queue_size = $self->build_queue_size($planet_stats->{id});
    
    # Check if build queue is filled
    return
        if ($build_queue_size > $self->start_building_at);
    
    # Get stored waste
    my $waste_stored = $planet_stats->{waste_stored};
    my $waste_capacity = $planet_stats->{waste_capacity};
    my $waste_filled = ($waste_stored / $waste_capacity) * 100;
    my $waste_disposeable = $self->disposeable_waste($planet_stats);
    
    # Check if waste is overflowing
    return 
        if ($waste_filled < $self->dispose_percentage);
    
    my (@existing_monuments);
    foreach my $monument_type (reverse @WASTE_MONUMENTS) {
        my ($existing_monument) = $self->find_building($planet_stats->{id},$monument_type);
        next
            unless defined $existing_monument;
        next
            if defined $existing_monument->{pending_build};
        # Ignore buildings that have already have been upgraded
        next
            if $existing_monument->{level} > 1;
        push(@existing_monuments,$existing_monument);
    }
    
    # We have no waste monument yet
    return 
        unless (scalar @existing_monuments);
    
    # Check if monument is buildable
    my $buildable_spots = $self->find_buildspot($planet_stats);
    
    return 
        if scalar @{$buildable_spots} == 0;
    
    my $build_spot =  $buildable_spots->[int(rand(scalar @{$buildable_spots}))];
    my $body_object = $self->build_object('Body', id => $planet_stats->{id});
    
    my $buildable_data = $self->request(
        object  => $body_object,
        method  => 'get_buildable',
        params  => [ $build_spot->[0],$build_spot->[1],'Waste' ],
    );
    
    BUILDABLE:
    foreach my $existing_monument (@existing_monuments) {
        next BUILDABLE
            unless $buildable_data->{buildable}{$existing_monument->{name}};
        
        my $buildable_data_monument = $buildable_data->{buildable}{$existing_monument->{name}};
        
        next BUILDABLE
            if $buildable_data_monument->{build}{cost}{waste} >= 0
            || ($buildable_data_monument->{build}{cost}{waste} * -1) > $waste_disposeable;
        
        next BUILDABLE
            unless $buildable_data_monument->{build}{reason}[0] == 1009;
        
        my $existing_monument_object = $self->build_object($existing_monument);
        
        $self->log('notice',"Demolish %s on %s",$existing_monument->{name},$planet_stats->{name});
        $self->request(
            object  => $existing_monument_object,
            method  => 'demolish',
        );

        my $new_monument_object = $self->build_object($buildable_data_monument->{url});
        
        $self->log('notice',"Building %s on %s",$existing_monument->{name},$planet_stats->{name});
        
        $self->request(
            object  => $new_monument_object,
            method  => 'build',
            params  => [ $planet_stats->{id}, $existing_monument->{x},$existing_monument->{y}],
        );
        
        $build_queue_size ++;
        $waste_disposeable += $buildable_data_monument->{build}{cost}{waste};
        
        # Check if build queue is filled
        return
            if ($build_queue_size > $self->start_building_at);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
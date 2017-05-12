package Games::Lacuna::Task::Action::SpyTraining;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun);

use List::Util qw(min shuffle);

has 'rename_spies' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 1,
    documentation   => 'Rename spies if they carry the default name [Default: true]',
);

has 'max_training' => (
    isa             => 'Int',
    is              => 'rw',
    default         => 10,
    documentation   => 'Max number of spies in training [Default: 10]',
);

our @SPY_SKILLS = qw(intel theft politics mayhem);

sub description {
    return q[This task automates the training of spies];
}

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    my $timestamp = time();
    
    # Get intelligence ministry
    my ($intelligence_ministry) = $self->find_building($planet_stats->{id},'Intelligence');
    return
        unless $intelligence_ministry;
    my $intelligence_ministry_object = $self->build_object($intelligence_ministry);
    
    my $spy_data = $self->paged_request(
        object  => $intelligence_ministry_object,
        method  => 'view_spies',
        total   => 'spy_count',
        data    => 'spies',
    );
    
    my @spies_available;
    my $spies_count = 0;
    my $spies_in_training = 0;
    
    foreach my $spy (@{$spy_data->{spies}}) {
        $spies_count ++;
        $spies_in_training ++
            if $spy->{assignment} eq 'Training';
        if ($self->rename_spies
            && $spy->{name} eq 'Agent Null') {
            my $spy_name = 'Agent '.$spies_count.' '.substr($planet_stats->{name},0,1);
            $self->log('notice',"Rename spy on %s to %s",$planet_stats->{name},$spy_name);
            my $response = $self->request(
                object  => $intelligence_ministry_object,
                method  => 'name_spy',
                params  => [$spy->{id},$spy_name],
            );
        }
        if ($spy->{is_available}
            && $spy->{assigned_to}{body_id} == $planet_stats->{id}
            && $spy->{name} !~ m/!/) {
            push (@spies_available,$spy);
        }
    }
    
    # Check if we can have more spies
    my $spy_slots = $intelligence_ministry->{level} - $spies_count;
    
    # Train new spies
    if ($spy_slots > 0) {
        $spy_slots = min($spy_slots,5);
        #&& $self->can_afford($planet_stats,$ministry_data->{spies}{training_costs})
        $self->log('notice',"Training %i spy/spies on %s",$spy_slots,$planet_stats->{name});
        my $response = $self->request(
            object  => $intelligence_ministry_object,
            method  => 'train_spy',
            params  => [$spy_slots]
        );
        $spies_in_training += $spy_slots;
    }
    
    # Check max spies in training
    return 
        if $spies_in_training >= $self->max_training
        || scalar @spies_available == 0;
    
    my @training_available;
    my %training_buildings;
    
    # Get trainable spies
    SPY_SKILL:
    foreach my $skill (@SPY_SKILLS) {
        my $building_name = ucfirst($skill).'Training';
        my $training_building = $self->find_building($planet_stats->{id},$building_name);
        next
            unless $training_building;
        
        $training_buildings{$skill} = $self->build_object($training_building);
        
        foreach my $spy (@spies_available) {
            push(@training_available,{ 
                id      => $spy->{id},
                name    => $spy->{name},
                skill   => $skill,
                points  => $spy->{$skill},
            });
        }
    }
    
    my @spies_in_training;
    SPY_TRAINING:
    foreach my $spy_data (sort { $a->{points} <=> $b->{points} } @training_available) {
        
        next SPY_TRAINING
            if $spy_data->{id} ~~ \@spies_in_training;
        
        $self->log('notice',"Training spy %s on %s in %s",$spy_data->{name},$planet_stats->{name},$spy_data->{skill});
        $self->request(
            object  => $training_buildings{$spy_data->{skill}},
            method  => 'train_spy',
            params  => [$spy_data->{id}],
        );
        push(@spies_in_training,$spy_data->{id});
        $spies_in_training ++;
        
        last SPY_TRAINING
            if $spies_in_training >= $self->max_training;
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

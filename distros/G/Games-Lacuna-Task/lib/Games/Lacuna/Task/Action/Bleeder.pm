package Games::Lacuna::Task::Action::Bleeder;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Notify
    Games::Lacuna::Task::Role::PlanetRun);

sub description {
    return q[Report deployed bleeders];
}

has 'known_bleeder' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    lazy_build      => 1,
    traits          => ['Array','NoGetopt'],
    handles         => {
        add_known_bleeder  => 'push',
    }
);

has 'new_bleeder' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    default         => sub { [] },
    traits          => ['Array','NoGetopt'],
    handles         => {
        add_new_bleeder    => 'push',
        has_new_bleeder   => 'count',
    }
);

sub _build_known_bleeder {
    my ($self) = @_;
    
    my $bleeder = $self->get_cache('report/known_bleeder');
    $bleeder ||= [];
    
    return $bleeder;
}

after 'run' => sub {
    my ($self) = @_;
    
    if ($self->has_new_bleeder) {
        
        $self->add_known_bleeder(map { $_->{id} } @{$self->new_bleeder});
        
        my $message = join ("\n",map { 
            sprintf('%s: Found deployed bleeder level %i',$_->{planet},$_->{level})
        } @{$self->new_bleeder});
        
        my $empire_name = $self->empire_name;
        
        $self->notify(
            "[$empire_name] Bleeders detected!",
            $message
        );
        
        $self->set_cache(
            key     => 'report/known_bleeder',
            value   => $self->known_bleeder,
            max_age => (60*60*24*7), # Cache one week
        );
    }
};

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Get space port
    my @bleeders = $self->find_building($planet_stats->{id},'DeployedBleeder');
    
    return 
        unless scalar @bleeders;
    
    foreach my $bleeder (@bleeders) {
        $self->log('warn','Found deployed bleeder at %s',$planet_stats->{name});
        
        # Check if we already know this ship
        next
            if $bleeder->{id} ~~ $self->known_bleeder;
        
        $self->add_new_bleeder({
            planet  => $planet_stats->{name},
            id      => $bleeder->{id},
            level   => $bleeder->{level},
        });
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
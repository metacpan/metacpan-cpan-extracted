package Games::Lacuna::Task::Action::ReportIncoming;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Notify
    Games::Lacuna::Task::Role::PlanetRun);

use Games::Lacuna::Task::Utils qw(parse_date format_date);

sub description {
    return q[Report incoming foreign ships];
}

has 'known_incoming' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    lazy_build      => 1,
    traits          => ['Array','NoGetopt'],
    handles         => {
        add_known_incoming  => 'push',
    }
);

has 'new_incoming' => (
    is              => 'rw',
    isa             => 'ArrayRef',
    default         => sub { [] },
    traits          => ['Array','NoGetopt'],
    handles         => {
        add_new_incoming    => 'push',
        has_new_incoming   => 'count',
    }
);

sub _build_known_incoming {
    my ($self) = @_;
    
    my $incoming = $self->get_cache('report/known_incoming');
    $incoming ||= [];
    
    return $incoming;
}

after 'run' => sub {
    my ($self) = @_;
    
    if ($self->has_new_incoming) {
        
        $self->add_known_incoming(map { $_->{id} } @{$self->new_incoming});
        
        my $message = join ("\n",map { 
            sprintf('%s: %s from %s arrives at %s',$_->{planet},$_->{ship},$_->{from_empire},format_date($_->{arrives}))
        } @{$self->new_incoming});
        
        my $empire_name = $self->empire_name;
        
        $self->notify(
            "[$empire_name] Incoming ship(s) detected!",
            $message
        );
        
        $self->set_cache(
            key     => 'report/known_incoming',
            value   => $self->known_incoming,
            max_age => (60*60*24*7), # Cache one week
        );
    }
};

sub process_planet {
    my ($self,$planet_stats) = @_;
    
    return
        unless defined($planet_stats->{incoming_enemy_ships});
    
    # Get space port
    my $spaceport = $self->find_building($planet_stats->{id},'SpacePort');
    
    return 
        unless $spaceport;
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get all incoming ships
    my $ships_data = $self->paged_request(
        object  => $spaceport_object,
        method  => 'view_foreign_ships',
        total   => 'number_of_ships',
        data    => 'ships',
    );
    
    my @incoming_ships;
    
    foreach my $ship (@{$ships_data->{ships}}) {
        my $from;
        if (defined $ship->{from}
            && defined $ship->{from}{empire}) {
            # My own ship
            next 
                if ($ship->{from}{empire}{id} == $planet_stats->{empire}{id});
            $from = $ship->{from}{empire}{name};
        }
        
        # Ignore cargo ships since they are probably carrying out a trade
        # (not dories since they can be quite stealthy and therefore can be used to carry spies)
        next
            if ($ship->{type} ~~ [qw(hulk cargo_ship galleon barge freighter)]);
        
        my $arrives = parse_date($ship->{date_arrives});
        
        my $incoming = {
            arrives_delta   => ((time() - $arrives) / 60),
            arrives         => $arrives,
            planet          => $planet_stats->{name},
            ship            => $ship->{type},
            from_empire     => ($from || 'unknown'),
            id              => $ship->{id},
        };
        
        $self->log('warn','Incoming %s ship from %s arriving in %s minutes detected on %s',$incoming->{ship},$incoming->{from_empire},$incoming->{arrives_delta} ,$planet_stats->{name});
        
        # Check if we already know this ship
        next
            if $ship->{id} ~~ $self->known_incoming;
        
        $self->add_new_incoming($incoming);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
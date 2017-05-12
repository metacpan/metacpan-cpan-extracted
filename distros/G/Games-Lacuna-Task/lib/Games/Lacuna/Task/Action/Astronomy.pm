package Games::Lacuna::Task::Action::Astronomy;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars
    Games::Lacuna::Task::Role::Ships
    Games::Lacuna::Task::Role::PlanetRun
    Games::Lacuna::Task::Role::RPCLimit);

sub description {
    return q[Explore solar systems in your vincity];
}

before 'run' => sub {
    my $self = shift;
    $self->check_for_destroyed_probes();
};

sub process_planet {
    my ($self,$planet_stats) = @_;
        
    # Get observatory
    my $observatory = $self->find_building($planet_stats->{id},'Observatory');
    
    # Get space port
    my $spaceport = $self->find_building($planet_stats->{id},'SpacePort');
    
    return 
        unless $observatory && $spaceport;
    
    # Max probes controllable
    my $max_probes = $observatory->{level} * 3;
    
    # Get observatory probed stars
    my $observatory_object = $self->build_object($observatory);
    my $observatory_data = $self->request(
        object  => $observatory_object,
        method  => 'get_probed_stars',
        params  => [1],
    );
    
    my $can_send_probes = $max_probes - $observatory_data->{star_count};
    
    # Reached max probed stars
    return
        if $can_send_probes <= 0;
    
    # Get available probes
    my @avaliable_probes = $self->get_ships(
        planet          => $planet_stats,
        quantity        => $can_send_probes,
        type            => 'probe',
        travelling      => 1,
    );
    
    return 
        if (scalar @avaliable_probes == 0);
    
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get unprobed stars
    my @unprobed_stars = $self->closest_unprobed_stars($planet_stats->{x},$planet_stats->{y},scalar(@avaliable_probes));
    
    # Send available probes to stars
    STARS:
    foreach my $star (@unprobed_stars) {
        my $probe = pop(@avaliable_probes);
        if (defined $probe) {
            # Send probe to star
            my $response = $self->request(
                object  => $spaceport_object,
                method  => 'send_ship',
                params  => [ $probe,{ "star_id" => $star } ],
                catch   => [
                    [1009,sub {
                        return;
                    }]
                ]
            );
            
            last STARS
                unless defined $response;
            
            $self->log('notice',"Sending probe from from %s to %s",$planet_stats->{name},$response->{ship}{to}{name});
        }
    }
}

sub check_for_destroyed_probes {
    my ($self) = @_;
    
    my $inbox_object = $self->build_object('Inbox');
    
    # Get inbox for attacks
    my $inbox_data = $self->request(
        object  => $inbox_object,
        method  => 'view_inbox',
        params  => [{ tags => ['Attack','Probe'],page_number => 1 }],
    );
    
    my @archive_messages;
    
    foreach my $message (@{$inbox_data->{messages}}) {
        next
            unless $message->{from_id} == $message->{to_id};
        
        if ($message->{subject} ~~ ['Probe Destroyed','Lost Contact With Probe']) {
            # Get message
            my $message_data = $self->request(
                object  => $inbox_object,
                method  => 'read_message',
                params  => [$message->{id}],
            );
            
            # Parse star id,x,y
            next
                unless $message_data->{message}{body} =~ m/\{Starmap\s(?<x>-*\d+)\s(?<y>-*\d+)\s(?<star_name>[^}]+)\}/;
            
            my $star_name = $+{star_name};
            my $star_data = $self->get_star_by_xy($+{x},$+{y});
            
            next
                unless $star_data;
            next
                unless $message_data->{message}{body} =~ m/{Empire\s(?<empire_id>\d+)\s(?<empire_name>[^}]+)}/;
            
            $self->log('warn','A probe in the %s system was destroyed by %s',$star_name,$+{empire_name});
            
            # Fetch star data from api and check if solar system is still probed
            $self->_get_star_api($star_data->{id},$star_data->{x},$star_data->{y});
            
            push(@archive_messages,$message->{id});
        }
    }
    
    # Archive
    if (scalar @archive_messages) {
        $self->log('notice',"Archiving %i messages",scalar @archive_messages);
        
        $self->request(
            object  => $inbox_object,
            method  => 'archive_messages',
            params  => [\@archive_messages],
        );
    }
}

sub closest_unprobed_stars {
    my ($self,$x,$y,$limit) = @_;
    
    $limit //= 1;
    
    my @unprobed_stars;
    
    $self->log('debug','Trying to find %i unprobed solar systems',$limit);
    
    my $count = 0;
    
    $self->search_stars_callback(
        sub {
            my ($star_data) = @_;
            
            # Fetch star data from api and check if solar system is still unprobed
            $star_data = $self->_get_star_api($star_data->{id},$star_data->{x},$star_data->{y});
            
            next
                if $star_data->{is_probed};
            
            # Get incoming probe info
            my $star_incomming = $self->request(
                object  => $self->build_object('Map'),
                params  => [ $star_data->{id} ],
                method  => 'check_star_for_incoming_probe',
            );
            
            return 1
                if (defined $star_incomming->{incoming_probe}
                && $star_incomming->{incoming_probe} ne '0');
            
            # Add to todo list
            push(@unprobed_stars,$star_data->{id});
            
            return 0
                if scalar(@unprobed_stars) >= $limit;
            
            return 1;
        },
        x           => $x,
        y           => $y,
        is_probed   => 0,
        distance    => 1,
    );

    return @unprobed_stars;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
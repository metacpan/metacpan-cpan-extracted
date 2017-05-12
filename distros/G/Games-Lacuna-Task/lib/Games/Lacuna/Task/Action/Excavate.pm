package Games::Lacuna::Task::Action::Excavate;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars
    Games::Lacuna::Task::Role::Ships
    Games::Lacuna::Task::Role::PlanetRun);

use List::Util qw(sum);
use Games::Lacuna::Client::Types qw(ore_types);

has 'min_ore' => (
    is              => 'rw',
    isa             => 'Int',
    documentation   => 'Only select bodies with mininimal ore quantities [Default 5000]',
    default         => 5000,
    required        => 1,
);

has 'ores' => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => ['Hash','NoGetopt'],
    default         => sub {
        return {
            map { $_ => 0 } ore_types()
        }
    },
    required        => 1,
    handles         => {
        get_ore         => 'get',
    }
);

has 'excavated_bodies' => (
    is          => 'rw',
    isa         => 'ArrayRef[Int]',
    traits      => [qw(NoGetopt Array)],
    traits          => ['Array','NoGetopt'],
    handles         => {
        add_excavated_body => 'push',
    }
);

sub description {
    return q[Building and dispatch excavators to best suited bodies];
}

sub process_planet {}

sub run {
    my ($self) = @_;
    
    my %planets;
    
    foreach my $planet_stats ($self->get_planets) {
        $self->log('info',"Processing planet %s",$planet_stats->{name});
        my $available = $self->current_excavators($planet_stats);
        
        if ($available) {
            $planets{$planet_stats->{id}} = $available;
        }
    }
    
    my $ore_type_count = scalar ore_types();
    my $total_ores = sum(values %{$self->ores});
    while (my ($key,$value) = each %{$self->ores}) {
        $self->ores->{$key} = (1/$ore_type_count) / ($value / $total_ores);
    }
    
    while (my ($key,$value) = each %planets) {
        my $planet_stats = $self->my_body_status($key);
        $self->dispatch_excavators($planet_stats,$value);
    }
    
}

sub current_excavators {
    my ($self,$planet_stats) = @_;
    
    # Get archaeology ministry
    my $archaeology_ministry = $self->find_building($planet_stats->{id},'Archaeology');
    
    return
        unless defined $archaeology_ministry;
    return
        unless $archaeology_ministry->{level} >= 11;
    
    my $archaeology_ministry_object = $self->build_object($archaeology_ministry);
    
    my $response = $self->request(
        object  => $archaeology_ministry_object,
        method  => 'view_excavators',
    );
    
    my $possible_excavators = $response->{max_excavators} - scalar @{$response->{excavators}} - 1 - $response->{travelling};
    
    # Get all excavated bodies
    foreach my $excavator (@{$response->{excavators}}) {
        while (my ($key,$value) = each %{$excavator->{body}{ore}}) {
            $self->ores->{$key} += $value * ($excavator->{glyph} / 100);
        }
        next
            if $excavator->{id} == 0;
        
        $self->add_excavated_body($excavator->{body}{id});
    }
    
    return $possible_excavators;
}

sub dispatch_excavators {
    my ($self,$planet_stats,$possible_excavators) = @_;
    
    # Get space port
    my $spaceport = $self->find_building($planet_stats->{id},'Space Port');
    
    return 
        unless defined $spaceport;
    
    my $spaceport_object = $self->build_object($spaceport);
    
    # Get available excavators
    my @avaliable_excavators = $self->get_ships(
        planet          => $planet_stats,
        quantity        => $possible_excavators,
        travelling      => 1,
        type            => 'excavator',
        build           => 1,
    );
    
    # Check if we have available excavators
    return
        unless (scalar @avaliable_excavators);
    
    $self->log('debug','%i excavators available at %s',(scalar @avaliable_excavators),$planet_stats->{name});
    
    my @available_bodies;
    
    $self->search_stars_callback(
        sub {
            my ($star_data) = @_;
            
            my @possible_bodies;
            # Check all bodies
            foreach my $body (@{$star_data->{bodies}}) {
                # Check if solar system is inhabited by hostile empires
                return 1
                    if defined $body->{empire}
                    && $body->{empire}{alignment} =~ m/hostile/;
                
                # Check if body is inhabited
                next
                    if defined $body->{empire};
                
                # Check if already excavated
                next
                    if defined $body->{is_excavated}
                    && $body->{is_excavated};
                
                next
                    if $body->{id} ~~ $self->excavated_bodies;
                
                # Check body type
                next 
                    unless ($body->{type} eq 'asteroid' || $body->{type} eq 'habitable planet');
                
                my $total_ore = sum values %{$body->{ore}};
                
                # Check min ore
                next
                    if $total_ore < $self->min_ore;
                
                push(@possible_bodies,$body);
            }
            
            # All possible bodies
            foreach my $body (@possible_bodies) {
                my $weighted_ores = 0;
                foreach my $ore (keys %{$body->{ore}}) {
                    $weighted_ores += $body->{ore}{$ore} * $self->get_ore($ore);
                }
                push(@available_bodies,[ $weighted_ores, $body ]);
            }
            
            return 0
                if scalar @available_bodies > 30;

            return 1;
        },
        x           => $planet_stats->{x},
        y           => $planet_stats->{y},
        is_known    => 1,
        distance    => 1,
    );
    
    foreach my $body_data (sort { $b->[0] <=> $a->[0] } @available_bodies) {
        
        my $body = $body_data->[1];
        my $excavator = pop(@avaliable_excavators);
        
        return
            unless defined $excavator;
        
        $self->log('notice',"Sending excavator from %s to %s",$planet_stats->{name},$body->{name});
        
        $self->add_excavated_body($body->{id});
        
        # Send excavator to body
        my $response = $self->request(
            object  => $spaceport_object,
            method  => 'send_ship',
            params  => [ $excavator,{ "body_id" => $body->{id} } ],
            catch   => [
                [
                    1010,
                    qr/already has an excavator from your empire or one is on the way/,
                    sub {
                        $self->log('debug',"Could not send excavator to %s",$body->{name});
                        push(@avaliable_excavators,$excavator);
                        return 0;
                    }
                ],
                [
                    1009,
                    qr/Can only be sent to asteroids and uninhabited planets/,
                    sub {
                        $self->log('debug',"Could not send excavator to %s",$body->{name});
                        push(@avaliable_excavators,$excavator);
                        return 0;
                    }
                ]
            ],
        );
        
        # Set body exacavated
        $self->set_body_excavated($body->{id});
    }
}

after 'run' => sub {
    my ($self) = @_;
    
    my $excavated = join(',',@{$self->excavated_bodies});
    
    $self->log('debug',"Updating excavator cache");
    
    $self->storage_do('UPDATE body SET is_excavated = 0 WHERE is_excavated = 1 AND id NOT IN ('.$excavated.')');
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;
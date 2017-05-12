package Games::Lacuna::Task::Action::ShipDispatch;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
# -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun
    Games::Lacuna::Task::Role::Ships);

use Games::Lacuna::Task::Utils qw(normalize_name);

sub description {
    return q[Dispatch ships based on their name];
}

has '_planet_re' => (
    is              => 'rw',
    isa             => 'RegexpRef',
    lazy_build      => 1,
    builder         => '_build_planet_re',
    traits          => ['NoGetopt'],
);

sub _build_planet_re {
    my ($self) = @_;
    
    my @list;
    foreach my $body ($self->my_planets) {
        push(@list,$body->{id});
        push(@list,uc($body->{name}));
        push(@list,normalize_name($body->{name}));
    }
    
    my $string = join('|', map { "\Q$_\E" } @list);
    return qr/\b ($string) \b/x;
}


sub process_planet {
    my ($self,$planet_stats) = @_;
    
    # Get space port
    my $spaceport_object = $self->get_building_object($planet_stats->{id},'SpacePort');
    
    return 
        unless $spaceport_object;
    
    # Get all available ships
    my $ships_data = $self->request(
        object  => $spaceport_object,
        method  => 'view_all_ships',
        params  => [ { no_paging => 1 }, { task => [ 'Docked' ] } ],
    );
    
    my %dispatch;
    
    SHIPS:
    foreach my $ship (@{$ships_data->{ships}}) {
        # Dispatch to another planet
        if ( uc($ship->{name}) =~ $self->_planet_re ) {
            my $target_planet = $self->my_body_status($1);
            unless ($target_planet->{id} == $planet_stats->{id}) {
                $dispatch{$target_planet->{id}} ||= [];
                push (@{$dispatch{$target_planet->{id}}},$ship);
                
                $self->log('notice','Dispatching ship %s from %s to %s',$ship->{name},$planet_stats->{name},$target_planet->{name});
                next SHIPS;
            }
        }
        
        # Scuttle
        if ( $ship->{name} =~ m/\b scuttle \b/ix) {
            $self->log('notice','Scuttling ship %s on %s',$ship->{name},$planet_stats->{name});
            
            $self->request(
                object  => $spaceport_object,
                method  => 'scuttle_ship',
                params  => [$ship->{id}],
            );
        # Start mining
        } elsif ( $ship->{name} =~ m/\b(mining|miner)\b/i) {
            next
                unless $ship->{hold_size} > 0;
            $self->log('notice','Starting to mine with ship %s on %s',$ship->{name},$planet_stats->{name});
            
            my $mining_object = $self->get_building_object($planet_stats->{id},'MiningMinistry');
            
            $self->request(
                object  => $mining_object,
                method  => 'add_cargo_ship_to_fleet',
                params  => [$ship->{id}],
            );
        }
    }
    
    foreach my $body_id (sort { scalar(@{$dispatch{$a}}) <=> scalar(@{$dispatch{$b}}) }keys %dispatch) {
        my $target_planet = $self->my_body_status($body_id);
        $self->log('debug','Dispatching %i ships from %s to %s',scalar(@{$dispatch{$body_id}}), $planet_stats->{name},$target_planet->{name});
        $self->push_ships($planet_stats->{id},$body_id,$dispatch{$body_id});
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
package Games::Lacuna::Task::Role::Helper;

use utf8;
use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use List::Util qw(max min);

use Games::Lacuna::Task::Constants;
use Data::Dumper;
use Games::Lacuna::Task::Utils qw(normalize_name parse_date);

sub my_planets {
    my $self = shift;
    
    my @planets;
    foreach my $body_id ($self->my_bodies) {
        my $body_status = $self->my_body_status($body_id);
        
        next
            unless defined $body_status;
        next
            unless $body_status->{type} eq 'habitable planet'
            || $body_status->{type} eq 'gas giant';
        push(@planets,$body_status);
    }
    return @planets;
}

sub my_stations {
    my $self = shift;
    
    my @stations;
    foreach my $body_id ($self->my_bodies) {
        my $body_status = $self->my_body_status($body_id);
        next
            unless $body_status->{type} eq 'space station';
        push(@stations,$body_status);
    }
    return @stations;
}

sub my_body_status {
    my ($self,$body) = @_;
    
    return 
        unless defined $body;
    
    return $body
        if ref($body) eq 'HASH';
    
    my $body_id = $self->my_body_id($body);
    
    return 
        unless defined $body_id;

    my $body_status = $self->get_cache('body/'.$body_id);
    
    return $body_status
        if defined $body_status;
    
    $body_status = $self->request(
        object  => $self->build_object('Body', id => $body_id),
        method  => 'get_status',
    );
    
    return
        unless defined $body_status;
    
    return $body_status->{body};
}

sub get_building_object {
    my ($self,$body,$type) = @_;
    
    my $body_id = $self->my_body_id($body);
    return 
        unless $body_id;
    
    # Get space port
    my $building_data = $self->find_building($body_id,$type);
    
    return 
        unless $building_data;
    
    return $self->build_object($building_data);
}

sub find_building {
    my ($self,$body,$type) = @_;
    
    my $body_id = $self->my_body_id($body);
    return 
        unless $body_id;

    my $type_url = '/'.lc($type);
    
    # Get buildings
    my @results;
    foreach my $building_data ($self->buildings_body($body_id)) {
        next
            unless $building_data->{name} eq $type
            || $building_data->{url} eq $type_url;
          
        if (defined $building_data->{pending_build}
            && $building_data->{level} == 0) {
            my $timestamp = time();
            my $build_end = parse_date($building_data->{pending_build}{end});
            next 
                if ($build_end > $timestamp);
        }
        push (@results,$building_data);
    }
    
    @results = (sort { $b->{level} <=> $a->{level} } @results);
    return wantarray ? @results : $results[0];
}

sub buildings_body {
    my ($self,$body) = @_;
    
    my $body_id = $self->my_body_id($body);
    return
        unless $body_id;

    my $key = 'body/'.$body_id.'/buildings';
    my $buildings = $self->get_cache($key) || $self->request(
        object  => $self->build_object('Body', id => $body_id),
        method  => 'get_buildings',
    )->{buildings};
    
    my @results;
    foreach my $building_id (keys %{$buildings}) {
        $buildings->{$building_id}{id} = $building_id;
        push(@results,$buildings->{$building_id});
    }
    return @results;
}

sub max_resource_building_level {
    my ($self,$body_id) = @_;
    
    $body_id = $self->my_body_id($body_id);
    return
        unless $body_id;
    
    my $max_resource_level = 15;
    my $stockpile = $self->find_building($body_id,'Stockpile');
    if (defined $stockpile) {
       $max_resource_level += int(sprintf("%i",$stockpile->{level}/3));
    }
    my $university_level = $self->university_level + 1;
    
    return min($max_resource_level,$university_level);
}

sub university_level {
    my ($self) = @_;
    
    my @university_levels;
    foreach my $planet_stats ($self->my_planets) {
        my $university = $self->find_building($planet_stats,'University');
        next 
            unless $university;
        push(@university_levels,$university->{level});
    }
    return max(@university_levels);
}

sub my_bodies {
    my $self = shift;
    
    my $planets = $self->get_stash('planets');
    return keys %{$planets};
}

sub home_planet_id {
    my $self = shift;
    
    return $self->get_stash('home_planet_id')
}

sub my_body_id {
    my ($self,$body) = @_;

    return
        unless defined $body;

    return $body
        if $body =~ m/^\d+$/ && $body ~~ [$self->my_bodies];

    return $body->{id}
        if ref($body) eq 'HASH' && exists $body->{id};

    # Get my planets
    my $planets = $self->get_stash('planets');

    # Exact match
    foreach my $id (keys %$planets) {
        return $id
            if $planets->{$id} eq $body;
    }

    my $name_simple = normalize_name($body); 
    
    # Similar match
    foreach my $id (keys %$planets) {
        return $id
            if $name_simple eq normalize_name($planets->{$id});
    }

    return;
}

sub can_afford {
    my ($self,$planet_data,$cost) = @_;
    
    $planet_data = $self->my_body_status($planet_data);
    
    foreach my $resource (qw(food ore water energy)) {
        return 0
            if (( $planet_data->{$resource.'_stored'} - 1000 ) < $cost->{$resource});
    }
    
    return 0
        if (defined $cost->{waste} 
        && ($planet_data->{'waste_capacity'} - $planet_data->{'waste_stored'}) < $cost->{waste});
    
    return 1;
}

sub my_affinity {
    my ($self) = @_;
    
    my $affinity = $self->client->get_cache('affinity');
    
    return $affinity
        if defined $affinity;
    
    my $response = $self->request(
        object  => $self->build_object('Empire'),
        method  => 'view_species_stats',
    );
    
    $affinity = $response->{species};
    
    $self->client->set_cache(
        key     => 'affinity',
        value   => $affinity,
        max_age => (60 * 60 * 24)
    );
    
    return $affinity;
}

sub send_message {
    my ($self, $subject, $message) = @_;
            
    $message =~ s/>=/≥/g;
    $message =~ tr/></)(/;
    
    $self->request(
        object  => $self->build_object('Inbox'),
        method  => 'send_message',
        params  => [
            $self->empire_name,
            $subject,
            $message,
        ],
    );
}

no Moose::Role;
1;


=encoding utf8

=head1 NAME

Games::Lacuna::Task::Role::Helper - Various helper methods

=head1 METHODS

=head2 my_bodies

Returns an array of your body IDs

=head2 my_planets

Returns an array of your planet IDs

=head2 my_stations

Returns an array of alliance stations IDs

=head2 my_body_status

 my $body_status = $self->my_body_status($body_id OR $body_name);

Returns the status hash of a given body/planet.

=head2 my_body_id

 my $body_id = $self->my_body_id($body_name);

Returns the id for a given body name. Ignores case and accents
so that eg. 'Hà Nôi' equals 'HA NOI'.

=head2 buildings_body

 my $body_buildings = $self->buildings_body($body_id OR $boSdy_name);

Returns all buildings for a given planet.

=head2 can_afford

 $self->can_afford($planet_id or $planet_stats_hash,$cost_hash);

Calculates if the upgrade/repair can be afforded

=head2 find_building

 my @spaceports = $self->find_building($body_id or $body_name,'Space Port');

Finds all buildings on a given body of a given type ordered by level.

=head2 home_planet_id

Returns the id of the empire' home planet id

=head2 planet_ids

Returns the empire' planet ids

=head2 university_level

Returns your empire' university level

=head2 send_message

 $self->send_message($subject, $message);

Send yourself a notification via the in-game messaging system.

=head2 max_resource_building_level

 my $level = $self->max_resource_building_level($body_id);

Returns the max possible ressource building level for the given planet.

=head2 can_afford
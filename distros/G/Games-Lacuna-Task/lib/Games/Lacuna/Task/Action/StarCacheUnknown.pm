package Games::Lacuna::Task::Action::StarCacheUnknown;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use List::Util qw(min);

sub description {
    return q[Builds the star cache for all solar systems which have not been checked yet];
}

has 'coordinate' => (
    is          => 'ro',
    isa         => 'Lacuna::Task::Type::Coordinate',
    documentation=> q[Coordinates for query center],
    coerce      => 1,
    lazy_build  => 1,
);

has 'count' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 1000,
    documentation=> 'Number of queries to be used for caching [Default: 1000]',
);

sub _build_coordinate {
    my ($self) = @_;
    
    my $home_planet = $self->home_planet_id();
    my $home_planet_data = $self->my_body_status($home_planet);
    
    return [$home_planet_data->{x},$home_planet_data->{y}];
}

sub run {
    my ($self) = @_;
    
    my $rpc_max = min($self->client->get_stash('rpc_count') + $self->count, int($self->client->get_stash('rpc_limit') * 0.9));
    
    $self->search_stars_callback(
        sub {
            my ($star_data) = @_;
            
            return 0
                if $self->client->get_stash('rpc_count') > $rpc_max;
            
            return 1;
        },
        is_probed   => undef,
        x           => $self->coordinate->[0],
        y           => $self->coordinate->[0],
        distance    => 1,
    );
}



__PACKAGE__->meta->make_immutable;
no Moose;
1;

package Games::Lacuna::Task::Action::StarCacheBuild;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use List::Util qw(max min);

sub description {
    return q[Build a star cache, reducing subsequent api calls made by various tasks];
}

has 'coordinate' => (
    is          => 'ro',
    isa         => 'Lacuna::Task::Type::Coordinate',
    documentation=> q[Coordinates for query center],
    coerce      => 1,
    lazy_build  => 1,
);

has 'skip' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 1,
    documentation=> q[Skip firt N-queries],
);

has 'count' => (
    is          => 'ro',
    isa         => 'Int',
    default     => 20,
    documentation=> q[Number of queries to be cached],
);

sub _build_coordinate {
    my ($self) = @_;
    
    my $home_planet = $self->home_planet_id();
    my $home_planet_data = $self->my_body_status($home_planet);
    
    return [$home_planet_data->{x},$home_planet_data->{y}];
}

sub run {
    my ($self) = @_;
    
    my @pos = (0,0);
    my @vector = (-1,0);
    my $segment_length = 1;
    my $segment_passed = 0;
    
    if ($self->skip <= 1) {
        $self->get_star_step(0,0);
    }
    for my $round (2..$self->count) {
        $pos[$_] += $vector[$_] for (0..1);
        $segment_passed++;
        
        if ($round > $self->skip) {
            $self->get_star_area(@pos);
        }
        
        if ($segment_passed == $segment_length) {
            $segment_passed = 0;
            my $buffer = $vector[0];
            $vector[0] = $vector[1] * -1;
            $vector[1] = $buffer;
            $segment_length++
                if $vector[1] == 0;
        }
    }
}

sub get_star_step {
    my ($self,$x,$y) = @_;
    
    my ($cx,$cy) = ($x + $self->coordinate->[0],$y + $self->coordinate->[1]);
    my ($min_x,$min_y) = ( $x * $Games::Lacuna::Task::Constants::MAX_MAP_QUERY + $cx , $y * $Games::Lacuna::Task::Constants::MAX_MAP_QUERY + $cy);
    my ($max_x,$max_y) = ( ($x+1) * $Games::Lacuna::Task::Constants::MAX_MAP_QUERY + $cx , ($y+1) * $Games::Lacuna::Task::Constants::MAX_MAP_QUERY + $cy);
    
    $self->_get_star_api_area_by_xy($min_x,$min_y,$max_x,$max_y);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

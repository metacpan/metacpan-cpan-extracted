package Games::Cellulo::Game::Particle;
$Games::Cellulo::Game::Particle::VERSION = '0.22';
use strict;
use warnings FATAL => 'all';

use Moo;
use Term::ANSIColor;
use List::Util qw[ min ];

use constant {
    R => 1,
    B => 2, 
    G => 3,
    Y => 4,
};
has x => ( is => 'rw', required => 1 );
has y => ( is => 'rw', required => 1 );
has type => ( is => 'rw', required => 1 );

has xdir => ( is => 'rw', lazy => 1, builder => 1, clearer => 1 );
has ydir => ( is => 'rw', lazy => 1, builder => 1, clearer => 1 );
has char => ( is => 'lazy', clearer => 1 );
has clump => ( is => 'ro', );
has grayscale => ( is => 'ro', );
has rainbow => ( is => 'ro', );

sub _build_xdir {
    for( $_[0]->type ) {
        return -1 if $_ eq R;
        return 1 if $_ eq B;
        return 0;
    }
}

sub _build_ydir {
    for ( $_[0]->type ) {
        return -1 if $_ eq G;
        return 1  if $_ eq Y;
        return 0;
    }
}

has dir => (
    is => 'lazy',
);

sub _build_dir {
    return [ $_[0]->xdir,$_->[0]->ydir ];
}
sub _cc {
    my($color,$str) = @_;
    colored($str,$color);
}

sub _build_char {
    my $self = shift;
    my $st = 32;
    $st = 232 if( $self->grayscale );
    if ( $self->grayscale || $self->rainbow ) {
        my $r   = int( rand( 256 - $st ) );
        my $col = $st + $r;
        return sprintf "\x1b[48;5;${col}m \x1b[0m", 'o';
    }
    return _cc( 'blue',   'o' ) if $self->type eq B;
    return _cc( 'red',    'o' ) if $self->type eq R;
    return _cc( 'green',  'o' ) if $self->type eq G;
    return _cc( 'yellow', 'o' ) if $self->type eq Y;
}




sub move {
    my $self = shift;
    my $wantx = $self->xpos( $self->x + $self->xdir );
    my $wanty = $self->ypos( $self->y + $self->ydir );
    $self->x( $wantx );
    $self->y( $wanty );
}

my @possible_directions = (
    "-1,-1", "-1,0", "-1,1",
    "0,-1", "0,1", #skip 0,0, its a noop
    "1,-1", "1,0", "1,1",
);

my @possible_direction_refs = map { [ split ',', $_ ] } @possible_directions;
has tries_in_direction => (
    is => 'ro',
    default => sub { +{
            map { $_ => 0 } @possible_directions
        };
    }
);

has successes_in_direction => (
    is => 'ro',
    default => sub { +{
            map { $_ => 0 } @possible_directions
        };
    }
);

has num_avoid_tries => (
    is => 'rw',
    default => sub { 0 },
);

has num_successes => (
    is => 'rw',
    default => sub { 0 },
);

sub p_found_free_path {
    my $self = shift;
    my $num_tries = $self->num_avoid_tries;
    my $num_successes = $self->num_successes;
    return rand(1) unless $num_successes;
    return rand(1) unless $num_tries;
    return $num_tries / $num_successes;
}

sub p_went_in_direction {
    my( $self, $direction ) = @_;
    my $num_tries_in_direction = $self->tries_in_direction->{$direction};
    my $num_tries = $self->num_avoid_tries;
    return rand(1) unless $num_tries;
    return rand(1) unless $num_tries_in_direction;
    return $num_tries_in_direction / $num_tries;
}

sub p_found_free_path_went_in_direction_x {
    my( $self, $direction ) = @_;
    my $num_avoid_successes = $self->num_successes;
    my $num_avoid_successes_in_direction = $self->successes_in_direction->{$direction};
    return rand(1) unless $num_avoid_successes;
    return rand(1) unless $num_avoid_successes_in_direction;
    return $num_avoid_successes_in_direction / $num_avoid_successes;
}
sub p_went_in_direction_x_found_free_path {
    my( $self, $direction ) = @_;
    my $p_found_free_path = $self->p_found_free_path;
    my $p_went_in_direction = $self->p_went_in_direction( $direction );
#    warn $p_went_in_direction;
    my $p_found_free_path_went_in_direction_x = $self->p_found_free_path_went_in_direction_x( $direction );
    my $rand = rand(1);
    return $rand unless $p_found_free_path;
    return $rand unless $p_found_free_path_went_in_direction_x;
    return $rand unless $p_went_in_direction;
    my $ret = ( $p_found_free_path_went_in_direction_x * $p_went_in_direction ) / $p_found_free_path;
    return 1 - $ret if $self->clump;
    return $ret;

}
sub avoidx {
    my $self = shift;
#    return 0 if $self->xdir;
    int( rand(3) ) - 1;
}

sub avoidy {
    my $self = shift;
#    return 0 if $self->ydir;
    int( rand(3) ) - 1;
}

has initial_avoidx => ( is => 'lazy' );
has initial_avoidy => ( is => 'lazy' );

sub _build_initial_avoidx { shift->avoidy }
sub _build_initial_avoidy { shift->avoidx }

sub avoid_dir {
    my $self = shift;
#    return [ $_->avoidx, $_->avoidy ];
    my @p = map { $self->p_went_in_direction_x_found_free_path( $_ ) }  @possible_directions;
    my $min = min @p;
    my @possibles;
    for( my $i = 0; $i < @p; $i++) {
        push @possibles, $possible_direction_refs[$i] if $p[$i] == $min;
    }
    return $possibles[ int( rand( @possibles ) ) ] if @possibles;
    return;
}

1;
__END__

P(B|A) = P(A|B) * P(A)
        ---------------
            P(B)

Probability of
B: found a free path
given
A: Went in Direction $x

is equal to
( Went in Direction $x given Probability of found a free path )
*
Probability of went in direction $x
-------------------------
found a free path

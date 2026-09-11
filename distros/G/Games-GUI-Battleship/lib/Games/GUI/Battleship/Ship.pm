package Games::GUI::Battleship::Ship;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);

# Standard Battleship fleet specifications: name => length
our %SHIP_SIZES = (
    Carrier    => 5,
    Battleship => 4,
    Cruiser    => 3,
    Submarine  => 3,
    Destroyer  => 2,
);

# Standard fleet deployment order
our @FLEET_ORDER =
  ( 'Carrier', 'Battleship', 'Cruiser', 'Submarine', 'Destroyer', );

sub new ( $class, %args ) {
    my $type = $args{type} // croak 'type is required';
    my $x    = $args{x}    // croak 'x coordinate is required';
    my $y    = $args{y}    // croak 'y coordinate is required';
    my $dir  = $args{dir}  // 'H';

    my $len = $SHIP_SIZES{$type} // croak "Unknown ship type: $type";

    $dir = uc($dir);
    if ( $dir ne 'H' && $dir ne 'V' ) {
        croak "Invalid direction: $dir (must be 'H' or 'V')";
    }

    my $self = {
        type => $type,
        x    => int($x),
        y    => int($y),
        dir  => $dir,
        len  => $len,
        hits => {},
    };

    return bless $self, $class;
}

sub type ($self) {
    return $self->{type};
}

sub length ($self) {
    return $self->{len};
}

sub x ($self) {
    return $self->{x};
}

sub y ($self) {
    return $self->{y};
}

sub dir ($self) {
    return $self->{dir};
}

sub set_position ( $self, $x, $y, $dir = undef ) {
    $self->{x}   = int($x);
    $self->{y}   = int($y);
    $self->{dir} = uc($dir) if defined $dir;
    return $self;
}

sub set_dir ( $self, $dir ) {
    $dir = uc($dir);
    if ( $dir ne 'H' && $dir ne 'V' ) {
        croak "Invalid direction: $dir";
    }
    $self->{dir} = $dir;
    return $self;
}

sub rotate ($self) {
    $self->{dir} = ( $self->{dir} eq 'H' ) ? 'V' : 'H';
    return $self->{dir};
}

sub coordinates ($self) {
    my @coords;
    my $len = $self->{len};
    my $x   = $self->{x};
    my $y   = $self->{y};
    my $dir = $self->{dir};

    for my $i ( 0 .. $len - 1 ) {
        my $cx = ( $dir eq 'H' ) ? $x + $i : $x;
        my $cy = ( $dir eq 'V' ) ? $y + $i : $y;
        push @coords, [ $cx, $cy ];
    }
    return @coords;
}

sub occupies ( $self, $x, $y ) {
    my $key = "$x,$y";
    for my $coord ( $self->coordinates ) {
        return 1 if "$coord->[0],$coord->[1]" eq $key;
    }
    return 0;
}

sub record_hit ( $self, $x, $y ) {
    if ( $self->occupies( $x, $y ) ) {
        $self->{hits}{"$x,$y"} = 1;
        return 1;
    }
    return 0;
}

sub hit_count ($self) {
    return scalar keys %{ $self->{hits} };
}

sub is_sunk ($self) {
    return $self->hit_count >= $self->{len} ? 1 : 0;
}

sub is_hit_at ( $self, $x, $y ) {
    return $self->{hits}{"$x,$y"} ? 1 : 0;
}

sub clear_hits ($self) {
    $self->{hits} = {};
    return $self;
}

1;


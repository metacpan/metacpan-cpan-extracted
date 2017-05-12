package Games::Tetris::Complete::Shape;
use strict;
use warnings;
use Data::Dumper;
use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.03';

# Upper left corner of grid
for ( qw( ulx uly ) ) {
    has $_ => (
        is      => 'rw',
        isa     => 'Int',
        default => sub { -1 },
        traits  => [ 'Counter' ],
        handles => {
            "inc_$_" => 'inc',
            "dec_$_" => 'dec',
        },
    );
}

subtype 'Char' => as 'Str' => where { $_ ne ' ' && length $_ == 1 } =>
    message { "Not a string of length 1 ($_)" };
subtype 'Blank' => as 'Str' => where { $_ eq ' ' } =>
    message { "Not a blank char ($_)" };
subtype 'GameGrid' => as 'ArrayRef[ArrayRef[Char|Blank]]' =>
    message { "bad grid: " . Dumper( $_ ) };
coerce 'GameGrid' => from 'ArrayRef[Str]' => via { [ map [ split // ], @$_ ] };

has 'char' => (
    is         => 'ro',
    isa        => 'Char',
    lazy_build => 1,
);

sub _build_char {
    my $self = shift;
    my $grid = $self->grid;
    my %chars;
    for my $y ( 0 .. $self->ny - 1 ) {
        $chars{ $_ }++
            for grep $_ ne ' ', map $grid->[ $y ][ $_ ], 0 .. $self->nx - 1;
    }
    my @c = keys %chars;
    confess "No non-blank chars in grid!" unless @c;
    confess "More than one char in grid (" . join( ',', @c ) . ")"
        if @c > 1;
    $c[ 0 ];
}

has [ qw( nx ny ) ] => (
    is         => 'rw',
    isa        => 'Int',
    lazy_build => 1,
);
has 'grid' => (
    is       => 'rw',
    isa      => 'GameGrid',
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------#

no Moose;
use Carp;

sub _build_nx {
    my $self = shift;
    scalar @{ $self->grid->[ 0 ] };
}

sub _build_ny {
    my $self = shift;
    scalar @{ $self->grid };
}

# Test if given board point is covered by this shape
sub covers {
    my ( $self, $y, $x ) = @_;

    # Check if the grid covers the point (undef)
    my ( $ulx, $uly ) = ( $self->ulx, $self->uly );
    return if $ulx > $x || $uly > $y;
    my ( $grid_x, $grid_y ) = ( $x - $ulx, $y - $uly );
    return if $grid_x >= $self->nx || $grid_y >= $self->ny;

    # Check if the value at the given point is a Blank (0) or Char (1)
    my $char = $self->grid->[ $grid_y ][ $grid_x ];
    confess "No char at ($grid_x,$grid_y)!" unless $char;
    match_on_type $char => (
        Blank => sub { 0 },
        Char  => sub { 1 },
        => sub { confess "the fuck is this: '$char'" }
    );
}

sub covered_points {
    my $self = shift;
    my ( $ulx, $uly ) = ( $self->ulx, $self->uly );
    my $grid = $self->grid;
    my @points;
    for my $yi ( 0 .. $self->ny - 1 ) {
        for my $xi ( 0 .. $self->nx - 1 ) {
            # match_on_type $grid->[ $yi ][ $xi ] => (
            # Char => sub { push @points, [ $uly + $yi, $ulx + $xi ] },
            # Blank => sub { }
            # );
            # print "($yi,$xi) ";
            # print "char: '", $grid->[ $yi ][ $xi ], "'\n";
            if ( $grid->[ $yi ][ $xi ] ne ' ' ) {
                push @points, [ $uly + $yi, $ulx + $xi ];
            }
        }
    }
    @points;
}

1;

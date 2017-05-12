package Games::Tetris::Complete;
use warnings;
use strict;
use Games::Tetris::Complete::Shape;
use Term::ReadKey;
use Time::HiRes qw(usleep);
use Term::Screen::Uni;
use threads;
use threads::shared;
use Thread::Semaphore;
our ( @ISA, @EXPORT );

BEGIN {
    require Exporter;
    @ISA    = qw(Exporter);
    @EXPORT = qw(play);       # symbols to export on request
}
$| = 1;

our $VERSION = '0.03';

# Globals
my $semaphore           = Thread::Semaphore->new();
my $print_cond : shared = 0;
my $GAME_OVER : shared  = 0;
my %line_points         = (
    1 => 40,
    2 => 100,
    3 => 300,
    4 => 1200
);

sub play {
    my @args = @_ ? @_ : @ARGV ? @ARGV : ();
    @args = ( width => $args[ 0 ], height => $args[ 1 ] )
        if @args == 2 and int $args[ 0 ];
    my $self : shared = shared_clone( __PACKAGE__->new( @args ) );
    $semaphore->down;    # Block console until we get first input
    my $console_thread = threads->create( \&console_thread, $self );
    print "Enter any key to begin...";
    get_input( 0 );
    $self->active_shape( random_shape() );
    $semaphore->up;
    my $player_thread = threads->create( \&player_thread, $self );
    my $game_thread   = threads->create( \&game_thread,   $self );
    $player_thread->detach();
    $game_thread->join();
    # print "Joined game_thread.\n";
    {
        lock( $print_cond );
        $print_cond = -1;
        cond_signal( $print_cond );
    }
    $console_thread->join();
    print "Final Score: " . commify( $self->score ) . "\n";
}

# perlfaq5 (brian d foy)
sub commify {
    local $_ = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $_;
}

#------------------------------------------------------------------------------#
use Moose;

$SIG{ __DIE__ } = sub { confess $_[ 0 ] };

for ( qw/ width height / ) {
    has $_ => (
        is       => 'ro',
        isa      => 'Int',
        required => 1,
        default  => $_ eq 'width' ? 12 : 20
    );
}

has 'score' => (
    traits  => [ 'Number' ],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_score => 'add',
        dec_score => 'sub',
        set_score => 'set',
    },
);
has 'level' => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
);

has 'board' => (
    is         => 'ro',
    isa        => 'GameGrid',
    lazy_build => 1,
);

sub BUILD {
    my $self = shift;
    $self->board;    # Create board before sharing
}

has [ qw/ active_shape queued_shape / ] => (
    is  => 'rw',
    isa => 'Games::Tetris::Complete::Shape',
);

around 'active_shape' => sub {
    my ( $orig, $self, $shape ) = @_;
    return $self->$orig() unless $shape;
    lock( $GAME_OVER );

    # Update the board
    my $board      = $self->board;
    my $shape_grid = $shape->grid;
    my $shape_nx   = $shape->nx;
    my $x_offset   = int( $self->width / 2 ) - int( $shape_nx / 2 );
    for my $y ( 0 .. $shape->ny - 1 ) {
        my $shape_row = $shape_grid->[ $y ];

        # Note: can't splice shared arrays
        for ( 0 .. $shape_nx - 1 ) {
            my $shape_char = $shape_row->[ $_ ];
            # Game over if removed chars overlap shape chars
            $GAME_OVER = 1
                if $board->[ $y ][ $x_offset + $_ ] ne ' '
                    and $shape_char ne ' ';
            $board->[ $y ][ $x_offset + $_ ] = $shape_char;
        }
    }
    # Set the shape location
    $shape->ulx( $x_offset );
    $shape->uly( 0 );

    # Enqueue a new shape
    $self->queued_shape( shared_clone( random_shape() ) );

    # Set the shape as the active shape
    $self->$orig( shared_clone( $shape ) );
};

#------------------------------------------------------------------------------#

no Moose;
use Carp;
__PACKAGE__->meta->make_immutable;

sub _build_board {
    my $self = shift;
    my @board =
        map { [ map ' ', 0 .. $self->width - 1 ]; } 0 .. $self->height - 1;
    \@board;
}

sub _game_over {
    lock( $GAME_OVER );
    $GAME_OVER;
}

sub player_thread {
    my $self = shift;
    while ( 1 ) {
        last if _game_over();
        if ( my $action = get_input( 0.5 ) ) {
            $semaphore->down;
            block_to_print() if $action->( $self );
            $semaphore->up;
        }
    }
    # print "Exiting player_thread.\n";
}

sub game_thread {
    my $self               = shift;
    my $sleep_microseconds = 1_000_000;    # 0.2 second(s)
    my $speedup            = 1.1;
    # $self->level( 0.9 );   Testing only
    while ( 1 ) {
        usleep( $sleep_microseconds / ( $speedup * ( int $self->level + 1 ) ) );
        last if _game_over();
        $semaphore->down;
        if ( $self->down( 1 ) ) {
            block_to_print();
        }
        else {
            $self->next_shape;
        }
        $semaphore->up;
    }
    # print "Exiting game_thread.\n";
}

sub next_shape {
    my $self = shift;
    # Clear full lines
    if ( my $cleared = $self->clear_full_lines ) {
        my $level = $self->level;
        $self->inc_score( $line_points{ $cleared } * ( int( $level ) + 1 ) );
        $self->level( $level += 0.1 * $cleared );
    }
    # Start new shape
    $self->active_shape( $self->queued_shape );
    block_to_print();
}

sub block_to_print {
    lock( $print_cond );
    $print_cond++;
    cond_signal( $print_cond );
}

sub clear_full_lines {
    my $self  = shift;
    my $board = $self->board;
    my $width = $self->width;
    my @cleared;
    for ( 0 .. $self->height - 1 ) {
        next if grep $_ eq ' ', @{ $board->[ $_ ] };
        push @cleared, $_;
    }
    return 0 unless @cleared;

    # Animate!
    my $sleep_microseconds = 50_000;
    my $mid                = int( $width / 2 ) + $width % 2 - 1;
    $board->[ $_ ][ $mid ] = ' ' for @cleared;
    unless ( $width % 2 ) {
        $board->[ $_ ][ $mid + 1 ] = ' ' for @cleared;
    }
    block_to_print();
    usleep( $sleep_microseconds );
    for ( my $i = 1; $i < $mid; $i++ ) {
        $board->[ $_ ][ $mid - $i ] = ' ' for @cleared;
        $board->[ $_ ][ $mid + $i ] = ' ' for @cleared;
        block_to_print();
        usleep( $sleep_microseconds );
    }
    if ( @cleared == 4 ) {
        # Hell yea tetris, do some random pattern
        my @chars = ( '+', ' ' );
        for my $i ( 1, 2 ) {
            for my $y ( @cleared ) {
                # if ( $y == $cleared[ 0 ] or $y == $cleared[ 3 ] ) {
                if ( $y + $i % 2 ) {
                    $board->[ $y ][ $_ ] = $_ % 2 ? '+' : ' '
                        for 0 .. $width - 1;
                }
                else {
                    $board->[ $y ][ $_ ] = $_ % 2 ? ' ' : '+'
                        for 0 .. $width - 1;
                }
                block_to_print();
                usleep( $sleep_microseconds );
            }
        }
    }

    # Update The Board
    $self->clear_line( $_ ) for @cleared;

    scalar @cleared;
} ## end sub clear_full_lines

sub clear_line {
    my ( $self, $y ) = @_;
    my $board = $self->board;
    my $width = $self->width;
    for my $y ( reverse 0 .. $y - 1 ) {
        $board->[ $y + 1 ][ $_ ] = $board->[ $y ][ $_ ] for 0 .. $width - 1;
    }
    # Clear first line
    $board->[ 0 ][ $_ ] = ' ' for 0 .. $width - 1;
}

{
    my %input_response = (
        'j' => \&left,
        'k' => \&down,
        'l' => \&right,
        'i' => \&rotate_left,
        'a' => \&left,
        's' => \&down,
        'd' => \&right,
        'w' => \&rotate_left,
        'q' => \&quit,
        ' ' => \&drop,
    );

    sub get_input {
        my $timeout = @_ ? shift : 0;
        ReadMode 'cbreak';
        my $action;
        my $got = ReadKey $timeout;
        # print "Saw key: '$got'\n";
        $action = $input_response{ $got } if defined $got;
        ReadMode 'normal';
        $action;
    }
}

sub drop {
    my $self  = shift;
    my $lines = 0;
    while ( $self->down ) {
        $lines++;
    }
    $self->inc_score( $lines * 2 );
    $self->next_shape;
    $lines;
}

sub rotate_left {
    my $self       = shift;
    my $board      = $self->board;
    my $shape      = $self->active_shape;
    my $shape_grid = $shape->grid;
    my ( $nx,     $ny )    = ( $shape->nx,    $shape->ny );
    my ( $ulx,    $uly )   = ( $shape->ulx,   $shape->uly );
    my ( $height, $width ) = ( $self->height, $self->width );

    # Return if we'd run into a border
    return if $ny > $nx and $ulx == 0 || $ulx + $nx == $width;
    return if $nx > $ny and $uly + $ny == $height;

    # Build new rotated shape
    my @new_grid;
    for my $x ( reverse 0 .. $nx - 1 ) {
        push @new_grid, [ map $shape_grid->[ $_ ][ $x ], 0 .. $ny - 1 ];
    }
    my $new_shape = Games::Tetris::Complete::Shape->new(
        grid => \@new_grid,
        char => $shape->char,
        ulx  => $ulx - ( $ny - $nx ),
        uly  => $uly + ( $ny - $nx ),
    );

    # Return if new covered points overlap border or another shape
    my @covered     = $shape->covered_points;
    my @covered_new = $new_shape->covered_points;
    return if grep {
        my ( $y, $x ) = @$_;
        $y < 0 || $x < 0 || $y >= $height || $x >= $width
    } @covered_new;
    return if grep {
        my ( $y, $x ) = @$_;
        $board->[ $y ][ $x ] ne ' '
            # Don't count points covered by original shape
            and !grep { $y == $_->[ 0 ] and $x == $_->[ 1 ] } @covered
    } @covered_new;

    # Update board and store
    my $char = $shape->char;
    $board->[ $_->[ 0 ] ][ $_->[ 1 ] ] = ' '   for @covered;
    $board->[ $_->[ 0 ] ][ $_->[ 1 ] ] = $char for @covered_new;

    $shape->grid( shared_clone \@new_grid );
    $shape->ulx( $ulx - ( $ny - $nx ) );
    $shape->uly( $uly + ( $ny - $nx ) );
    $shape->nx( $ny );
    $shape->ny( $nx );

    1;
} ## end sub rotate_left

sub left  { shift->horizontal( 0 ) }
sub right { shift->horizontal( 1 ) }

sub horizontal {
    my ( $self, $right ) = @_;
    my $shape = $self->active_shape;
    my $board = $self->board;
    my ( $ulx,      $uly )      = ( $shape->ulx, $shape->uly );
    my ( $shape_nx, $shape_ny ) = ( $shape->nx,  $shape->ny );
    my $shape_grid = $shape->grid;

    # Check if right/left column overlaps next column or end of board
    return if !$right && !$ulx or $right && $ulx + $shape_nx == $self->width;
    return
        if grep {
        $shape_grid->[ $_ ][ $right ? ( $shape_nx - 1 ) : 0 ] ne ' '
            and $board->[ $uly + $_ ][
            $right
            ? ( $ulx + $shape_nx )
            : ( $ulx - 1 )
            ] ne ' '
        } 0 .. $shape_ny - 1;

    for my $i ( 0 .. $shape_nx ) {
        if ( $i ) {
            for my $y ( 0 .. $shape_ny - 1 ) {
                my $char = $shape_grid->[ $y ][ $i - 1 ];
                # Update board
                $board->[ $uly + $y ][
                    $right
                    ? ( $ulx + $i )
                    : ( $ulx + $i - 2 )
                    ]
                    = $char
                    # Keep right/left pixels the same when not blank
                    unless $char eq ' '
                        and ( $right && $i == $shape_nx or !$right && $i == 1 );
            }
        }
        else {
            # Blank left/right col
            $board->[ $uly + $_ ][ $right ? $ulx : ( $ulx + $shape_nx - 1 ) ] =
                ' '
                for 0 .. $shape_ny - 1;
        }
    }
    $right ? $shape->inc_ulx : $shape->dec_ulx;

    1;
} ## end sub horizontal

sub down {
    my ( $self, $dont_inc_score ) = @_;
    my $shape = $self->active_shape;
    my $board = $self->board;
    my ( $ulx,      $uly )      = ( $shape->ulx, $shape->uly );
    my ( $shape_nx, $shape_ny ) = ( $shape->nx,  $shape->ny );
    my $shape_grid = $shape->grid;

    # Check if last shape row overlaps beneath current location or end of board
    return if $uly + $shape->ny == $self->height;
    return if grep {
        my ( $y1, $x1 ) = ( $_->[ 0 ] + 1, $_->[ 1 ] );
        !$shape->covers( $y1, $x1 ) and $board->[ $y1 ][ $x1 ] ne ' '
    } $shape->covered_points;

    for my $i ( 0 .. $shape_ny ) {
        if ( $i ) {
            my $shape_row = $shape_grid->[ $i - 1 ];
            for ( 0 .. $shape_nx - 1 ) {
                my $char = $shape_row->[ $_ ];
                # Keep beneath pixels the same when not blank
                my ( $y, $x ) = ( $uly + $i, $ulx + $_ );
                $board->[ $y ][ $x ] = $char
                    unless $board->[ $y ][ $x ] ne ' '
                        and !$shape->covers( $y, $x );
            }
        }
        else {
            # Blank first row
            $board->[ $uly ][ $_ ] = ' ' for $ulx .. $ulx + $shape_nx - 1;
        }
    }
    $shape->inc_uly;
    $self->inc_score( 1 ) unless $dont_inc_score;
    1;
} ## end sub down

sub clear_screen {
    my $console = shift;
    $console->clrscr();
}

{
    # Output Stuff

    my $console;

    sub console_thread {
        my $self = shift;
        $console = Term::Screen::Uni->new() or die "couldn't make console";

        # Intro Screen
        clear_screen( $console );
        $self->print_intro;

        $semaphore->down;
        clear_screen( $console );
        $self->print_board;
        $semaphore->up;
        while ( 1 ) {
            lock( $print_cond );
            cond_wait( $print_cond ) until $print_cond;
            last if $print_cond == -1;
            $print_cond--;
            $console->at( 0, 0 );
            $self->print_board;
        }
        # print "Exiting console_thread.\n";
    }

    my $INSTRUCTIONS = <<EOI;

KEYBOARD CONFIGURATION:

    LEFT    - a / j
    DOWN    - s / k    
    RIGHT   - d / l
    ROTATE  - w / i
    DROP    - space

    QUIT    - q

EOI

    sub print_board {
        my ( $self ) = @_;
        my $board    = $self->board;
        my $level    = $self->level;
        my $width    = $self->width;
        printf "NEXT LEVEL: %2d\n", 10 - $level * 10 % 10;
        print '+' . '-' x $width . "+\n";
        for my $y ( 0 .. $self->height - 1 ) {
            print '|' . join( '', @{ $board->[ $y ] } ) . "|\n";
        }
        print '+' . '-' x $width . "+\n";
        # print $INSTRUCTIONS;
        my $col = $width + 4;
        $console->at( 2, $col );
        printf "Level: %02d", $level;
        $console->at( 4, $col );
        printf "Score: %06d", $self->score;
        $console->at( 8, $col );
        print " Next:";
        my $queued_shape = $self->queued_shape;
        my $grid_next    = $queued_shape->grid;
        my $row          = 7;
        $col = $width + 12;

        if ( $queued_shape->ny <= 2 ) {
            $console->at( $row, $col );
            print ' ' x 4;
            $row++;
        }
        for ( 0 .. 3 ) {
            my $grid_row = $grid_next->[ $_ ] || [];
            $console->at( $row, $col );
            print join '',
                map defined $grid_row->[ $_ ] ? $grid_row->[ $_ ] : ' ',
                0 .. 3;
            $row++;
        }
        $console->at( $self->height + 4, 0 );
    } ## end sub print_board

    sub print_intro {
        my $self = shift;
        my $msg  = 'TETRIS';
        my ( $width, $height ) = ( $self->width, $self->height );
        print '+' . '-' x $width . "+\n";
        for my $y ( 0 .. $height - 1 ) {
            if ( $y == int( $height / 2 ) ) {
                my $l1 = ( $width - length $msg ) / 2;
                print '|'
                    . ' ' x $l1
                    . $msg
                    . ' ' x ( $width - $l1 - length( $msg ) + $width % 2 )
                    . "|\n";
            }
            else {
                print "|" . ' ' x $width . "|\n";
            }
        }
        print '+' . '-' x $width . "+\n";
        print $INSTRUCTIONS;
    }
}

sub quit {
    lock( $GAME_OVER );
    $GAME_OVER = 1;
    return;
}

{
    my @shapes = (
        [ ' +', '++', '+ ' ],
        [ '+ ', '++', ' +' ],
        [ '++', '++' ],
        [ '+' x 4 ],
        [ ' + ', '+++' ],
        [ '++', '+ ', '+ ' ],
        [ '++', ' +', ' +' ],
    );
    # @shapes = ( [ '+' x 4 ] );    This is cheating

    sub random_shape {
        Games::Tetris::Complete::Shape->new(
            grid => $shapes[ int rand @shapes ] );
    }
}

1;

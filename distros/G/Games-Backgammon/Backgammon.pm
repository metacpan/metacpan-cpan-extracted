package Games::Backgammon;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.13';

use List::Util qw/min max sum first/;
use Data::Dumper;

use Inline C       => 'DATA',
           INC     => '-I../../../../',
           NAME    => 'Games::Backgammon',
           VERSION => '0.13';

use Carp;


local $Data::Dumper::Indent = undef;
our %POINT = map {($_ => 1)} (1 .. 24, 'bar', 'off');

sub new {
    my ($class, %arg) = @_;
    $class = ref($class) || $class;
    croak "Sorry, but I need a starting position" unless defined $arg{position};
    my $self = {
        whitepoints => undef,
        blackpoints => undef,
        atroll      => 'black',
    };
    bless $self => $class;
    $self->_init(%arg);
    return $self;
}

sub _init {
    my ($self, %arg) = @_;
    $self->__init;
    $self->set_position(%{$arg{position}});
}

sub set_position {
    my ($self, %pos) = @_;
    my %white  = %{$pos{whitepoints} || {}};
    my %black  = %{$pos{blackpoints} || {}};
    
    my $atroll = exists $pos{atroll} ? lc($pos{atroll}) : 'black';
    croak "The player at roll can be black or white -- nothing else"
        unless($atroll =~ /^(black|white)$/);
    
    my @white = map {$white{$_} || 0} (1 .. 24, 'bar');
    my @black = map {$black{$_} || 0} (1 .. 24, 'bar');
    my $board = $atroll eq 'black' ? [@white, @black] : [@black,@white];
    
    $self->__set_position($board);
    croak "Illegal Position specified (" . Dumper(\%pos) . ")"
        unless $self->__check_position;
        
    my @unknown_points = grep !$POINT{$_}, (keys %white, keys %black);
    croak "Unknown or unnecessary white or black points specified (@unknown_points)"
        if @unknown_points;
    
    $_->{off} = 15 - _checkers_in_play(%$_) for (\%white, \%black);
    
    $self->{whitepoints} = \%white;
    $self->{blackpoints} = \%black;
    $self->{atroll}      = $atroll;
    
    $self->{last_checker} = max grep {$self->{$atroll . "points"}->{$_}} (1 .. 24);
}

sub _checkers_in_play {
    my %point = @_;
    sum map {$point{$_}} grep m/^([1-9]|1\d|2[0-4]|bar)$/i, keys %point
    or 0;
}

sub whitepoints {
    my ($self, $point) = @_;
    $point 
        ? ($self->{whitepoints}->{$point} || 0) 
        : _only_real_points( %{$self->{whitepoints}} );
}

sub blackpoints {
    my ($self, $point) = @_;
    $point 
        ? ($self->{blackpoints}->{$point} || 0) 
        : _only_real_points( %{$self->{blackpoints}} );
}

sub _only_real_points { my %p = @_; map {($_ => $p{$_})} grep {$p{$_}} keys %p }

sub atroll {
    my ($self) = @_;
    return $self->{atroll};
}

sub legal_moves { 
    my ($self, $n1, $n2) = @_;
    defined($n1) && defined($n2) or 
        croak '$game->legal_moves(n1,n2) needs a defined roll';
    @_ == 3 or croak '$game->legal_moves(n1,n2) needs exactly two arguments';
    for ($n1, $n2) {
        m/^(1|2|3|4|5|6)$/ or croak "($n1, $n2) is not a legal roll";
    }
    $self->__generate_moves($n1,$n2) 
}

1;

=head1 NAME

Games::Backgammon - Perl extension for modelling backgammon games

=head1 SYNOPSIS

  use Games::Backgammon;
  
  my $game = Games::Backgammon->new(
    position => {
      whitepoints => {3 => 1, 4 => 1, 5 => 3, 6 => 3}, # ideal 40 pip position
      blackpoints => {4 => 3, 5 => 5, 6 => 7},         # ideal 79 pip position
      atroll      => 'black',
    }
  );

  print "Position ID: ", $game->position_id;  
  print "Checkers off from white", $game->whitepoints('off');
  print "Now you can do these moves: ", join " ", $game->legal_moves(2,1);
  
  
  [NOT IMPLEMENTED YET]
  
  $game->move('6-off 5-off');
  
  print join "\n", 
    "Now black has a pip count of " . $game->blackpips,
    "With " . $game->blackpoints('off') . " checkers off the game";
    
  
=head1 DESCRIPTION

This module helps modelling backgammon games.
It is not basically intented to play backgammon for itself.
I just wrote it to analyze (long) racings in a convenient way.

Most of the routines are just wrappers to the gnubg program of Gary Wong.

=head2 FUNCTIONS

=over

=item my $game = Games::Backgammon->new(position => \%pos)

This creates a new backgammon game.
At the moment, it's necessary to define the starting position.
The reason is that I just have not yet programmed how to do the beginning roll.

Please look to the documentation of set_position for the definition of the
position hash. 

=item $game->set_position(%pos)

Resets the backgammon game to a specific position.
You can specify the position of the checkers and who is at the roll.
(Of course, in future versions, I'll also add the doubling cube to the position,
and the possibility of doubling before a rol).

Thus the position hash has the following outlook:

  position => {
     whitepoints => {$point1 => $nr_of_white_checkers_on_point1,
                     $point2 => $nr_of_white_checkers_on_point2,
                     ...
                     'bar'   => $nr_of_white_checkers_on_the_bar},

     blackpoints => {$point1 => $nr_of_black_checkers_on_point1,
                     $point2 => $nr_of_black_checkers_on_point2,
                     ...
                     'bar'   => $nr_of_black_checkers_on_the_bar},
     
     atroll      => 'white'     # or 'black'
  }
  
With the C<whitepoints> and <blackpoints> arguments, you can define where the
checkers of each side are. The point numbers are always regarded from the
player's view. So point x for white is point (25-x) for black. Please take care
that black's and white's checkers are not at the same point (what would result
in an error). It's also forbidden that both players have a closed board and
both players have checkers on the bar. Specifying more than 15 checkers is not 
allowed.

Please also look also to the following example:

  GNU Backgammon  Position ID: sOfgEwDg8+AIBg
  +13-14-15-16-17-18------19-20-21-22-23-24-+     O: gnubg
  | X        X  O    |   | O  O  X          |     0 Points
  | X           O    |   | O  O  X          |     
  | X           O    |   | O                |     
  |                  |   | O                |     
  |                  |   |                  |    
 v|                  |BAR|                  |     (Doppler: 1)
  | O                |   | X                |    
  | O           X    |   | X                |     
  | O           X    |   | X                |     
  | O           X    |   | X                |     At Roll
  | O     O     X    |   | X                |     0 Points
  +12-11-10--9--8--7-------6--5--4--3--2--1-+     X: janek
 Pip counts: O 138, X 159

 This interesting position can be defined with (O is white, X is black)
 
 position => {
     whitepoints => {5 => 2, 6 => 4,  8 => 3, 13 => 5, 15 => 1},
     blackpoints => {6 => 5, 8 => 4, 13 => 3, 16 => 1, 21 => 2},
     atroll      => 'black'
 }
 
The number of checkers at the bar is defined with 
C<'bar' => $nr_of_checkers_at_bar>,

Note, that you neither needn't nor mustn't define the checkers off the game.
(They are simply calculated by the calculation of 15 - checkers still left in
the game).
The atroll parameter has to be either 'white' or 'black' (whether upper/lower
case is unimportant) [the default is 'black'].

This method is unfortunately not explicitly tested (only via the 
initialization with new).

=item my %point = $game->whitepoints; my $off = $game->whitepoints('off');

This method returns either the hash with all white points
(including the checkers off the game, if there are someones)
or the number of checkers at a specific point.
The hash is returned when there is no argument specified,
while the number of checkers is returned if the point is passed as argument.
Note that points without a checker are not represented in the hash.

For further details, please read the documentation of C<set_position>.

=item my %point = $game->blackpoints; my $off = $game->blackpoints('off');

Similar to C<whitepoints>.

=item my $atroll = $game->atroll;

Returns the player who is at roll

=item my $id = $game->position_id

Returns the position id of the current position from the view of the player 
at roll. This id is the same like generated from gnubg. Please look to the
documentation of gnubg to get a detailed explanation.

=item $game->legal_moves($n0, $n1)

Returning a list of all legal moves in the current position
with the roll ($n0, $n1).
(just a wrapper to gnubg's GenerateMoves)
A legal move is only represented by its string representation.
It's already a shorted string version.

=back

=head2 EXPORT

None by default.

=head1 BUGS

Please inform me about every one you can find.

There could be problems to compile/install this module.
I used gcc version 3.2 and I would recommend to have at least 2.95.

=head1 TODO

A lot. I'm working currently on it.

Please feel free to suggest me anything you'll need.
(I will do it on the top of my priority list).

My next planned steps are:

=over

=item Game::Backgammon::ideal_bearoff_position($pips)

Returning the ideal bearoff position for a given pip count for one man

=item Game::Backgammon::one_checker_race($whitepip,$blackpip)

Returning the chances in a one checker race for each position.

=back

Alltough, I have not yet implemented many functions of gnubg,
I have bundled whole the project with this module.
I plan to implement soon many more functions,
and currently I want to see whether the bundling also works with CPAN.

=head1 SEE ALSO

Have also a look to the great open source project gnubg of Gary Wong.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Janek Schleicher

This library is free software under the GPL.
Please read the COPYING file of this distributation for details.

=cut

__DATA__
__C__

#include "positionid.xc"
#include "format_move.xc"
#include "generate_moves.xc" 

typedef struct {
    int anBoard[ 2 ][ 25 ];
} gnubg_t;

SV* _CreateInternalPosition(AV* a) {
    int i, j;
    int anBoard[ 2 ][ 25 ];
    for (i = 0; i < 2; i++) {
        for (j = 0; j < 25; j++) {
            SV** sv = av_fetch(a,25*i + j,0);
            anBoard[ i ][ j ] = SvIV(*sv);
        }
    }
    return newSVpv((char*) anBoard, sizeof(anBoard));
}

void __init(HV* self) {
    gnubg_t* bg = (gnubg_t *) malloc(sizeof(bg));
    SV* sv = newSVpv((char*) bg,sizeof(gnubg_t));
    hv_store(self,"__gnubg",7,sv,0);
}

void __set_position(HV* self, AV* a) {
    SV** __sv = hv_fetch(self,"__gnubg",7,0); 
    STRLEN len;                               
    gnubg_t *bg = (gnubg_t*) SvPV(*__sv,len);

    int i,j;    
    for (i = 0; i < 2; i++) {
        for (j = 0; j < 25; j++) {
            SV** sv = av_fetch(a,25*i + j,0);
            bg->anBoard[ i ][ j ] = SvIV(*sv);
        }
    }
}


int __check_position(HV* self) {
    SV** __sv = hv_fetch(self,"__gnubg",7,0); 
    STRLEN len;                               
    gnubg_t *bg = (gnubg_t*) SvPV(*__sv,len);

    return CheckPosition(bg->anBoard) == 0;
}

char* position_id(HV* self) {
    SV** __sv = hv_fetch(self,"__gnubg",7,0); 
    STRLEN len;                               
    gnubg_t *bg = (gnubg_t*) SvPV(*__sv,len);

    return PositionID(bg->anBoard);
}

void __generate_moves(HV* self, SV* sv_n1, SV* sv_n2) {
    STRLEN len;
    SV** __sv;
    gnubg_t *bg;
    int i,j;
    char sz[40];
    int n1, n2;
    move* m;
    movelist pml;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    __sv = hv_fetch(self,"__gnubg",7,0);
    bg = (gnubg_t*) SvPV(*__sv,len);
    
    n1 = SvIV(sv_n1);
    n2 = SvIV(sv_n2);
    
    GenerateMoves(&pml, bg->anBoard, n1, n2, FALSE);
    
    for (i = 0; i < pml.cMoves; i++) {
        m = (pml.amMoves + i);
        FormatMove(sz,bg->anBoard,m->anMove);
        Inline_Stack_Push(sv_2mortal(newSVpv(sz,0)));
    }
    Inline_Stack_Done;
}

#!/usr/bin/perl -w

use strict;
use Curses;
use FindBin;
use lib "$FindBin::Bin/Window/";
use lib "$FindBin::Bin/../lib/";
use Window;

use Shogi;
use Chu;
use Dai;
use DaiDai;
use Heian;
use HeianDai;
use MakaDaiDai;
use Tai;
use Taikyoku;
use Tenjiku;
use Tori;
use Wa;

my $bell = 1;
sub BEEP() { print "\a" if $bell }

my $help;
my $hand;
my @in_hand = ([],[]);

my $grid = { t => 2, l => 2, dx => 4, dy => 2 };

# {{{ Choose the board game
my $name = 'shogi';
if($ARGV[0] eq '-g') { $name = $ARGV[1] }
my $Board = {
  chu => sub { Games::Shogi::Chu->new },
  dai => sub { Games::Shogi::Dai->new },
  daidai => sub { Games::Shogi::DaiDai->new },
  heian => sub { Games::Shogi::Heian->new },
  heiandai => sub { Games::Shogi::HeianDai->new },
  makadaidai => sub { Games::Shogi::MakaDaiDai->new },
  shogi => sub { Games::Shogi->new },
  tai => sub { Games::Shogi::Tai->new },
  taikyoku => sub { $grid->{dx} = 5; Games::Shogi::Taikyoku->new },
  tenjiku => sub { Games::Shogi::tenjiku->new },
  tori => sub { Games::Shogi::Tori->new },
  wa => sub { Games::Shogi::Wa->new },
}->{lc $name}->();
# }}}

my $board_size = min($Board->size,9);
$grid->{b} = $grid->{t} + $grid->{dy} * $board_size - 1;
$grid->{r} = $grid->{l} + $grid->{dx} * $board_size - 1;

# {{{ Usage statement
sub Usage {
  print STDERR <<_EOF_;
$0: $0 [options]
	-h	Print this help screen and quit
_EOF_
  exit 1;
}
# }}}

# {{{ side
sub side {
  my $piece = shift;
  return lc $piece eq $piece ? 0 : 1 }
# }}}

# {{{ same_side
sub same_side {
  my ($a,$b) = @_;
  return side($a) == side($b) }
# }}}

# {{{ Grid helper functions
sub min { $_[0] < $_[1] ? $_[0] : $_[1] }

sub grid_x { $grid->{l} + $grid->{dx}*shift() }
sub grid_y { $grid->{t} + $grid->{dy}*shift() }
sub grid_yx { my ($y,$x) = @_; (grid_y($y),grid_x($x)) }
# }}}

# {{{ display_grid
sub display_grid {
  my ($win,$board_size) = @_;

  for my $y (0..$board_size-2) {
    for my $x (0..$board_size-2) {
      $win->addstr(grid_y($y),     grid_x($x),            (' ' x ($grid->{dx}-1)) . '|');
      $win->addstr(grid_y($y) + 1, grid_x($x),            ('-' x ($grid->{dx}-1)) . '+');
      $win->addstr(grid_y($y) + 1, grid_x($board_size-1), ('-' x ($grid->{dx}-1))) } }
  for my $x(0..$board_size-2) {
    $win->addstr(grid_yx($board_size-1,$x), (' ' x ($grid->{dx}-1)) . '|') }
  $win->addstr(20,0,"<hjkl> diamond to move cursor");
  $win->addstr(21,0,"' ' to pick up or drop piece");
  $win->addstr(22,0,"'+' to promote piece");
  $win->addstr(23,0,"'?' to turn on help mode") }
# }}}

# {{{ display_board
sub display_board {
  my ($Window,$win,$board_size) = @_;
  my $piece_fmt = '%'.($grid->{dx}-1).'s';
  my $max_length = 40;
  my $max_fmt = "%${max_length}s";

  for my $y (0..$board_size-1) {
    for my $x (0..$board_size-1) {
      $win->addstr(grid_yx($y,$x),
                   sprintf($piece_fmt, $Window->square($x,$y) || ' ')) } }

  if($help and !$Window->empty_square) {
    my $piece = $Window->cur_square;
    $win->addstr(23,79-$max_length,
                 sprintf($max_fmt, $Board->english_name($piece)));
    if($Board->japanese_name($piece)) {
      $win->addstr(22,79-$max_length,
                   sprintf($max_fmt, $Board->japanese_name($piece))) } }
  else {
    $win->addstr(23,79-$max_length,' ' x $max_length);
    $win->addstr(22,79-$max_length,' ' x $max_length) } }
# }}}

# {{{ Can a piece land on this square?
sub land_square {
  my ($Window,$win,$board_size,$piece,$x,$y) = @_;
  return if $x < 0 or $y < 0 or $x >= $board_size or $y >= $board_size;

  my $side = int($grid->{dx} / 2) - 1;
  my $square = $Window->square($x,$y);
  my $dot_str = (' ' x $side) . '.' . (' ' x $side);
  my $x_str = (' ' x $side) . 'X' . (' ' x $side);

  unless(defined $square) {
    $win->addstr(grid_yx($y,$x),$dot_str);
    return }

  return if same_side($piece,$square); # XXX Jump here
  $win->addstr(grid_yx($y,$x),$x_str) }
# }}}

# {{{ help_direction
sub help_direction {
  my ($Window,$win,$board_size,$piece,$dir) = @_;

  my ($x,$y) = $Window->cursor;
  if($dir=~/[udlr]/i) {
    while($x >= 0 and $y >= 0 and $x < $Board->size and $y < $Board->size) {
      $y-- while $dir =~ /u/gi; # Sneaky way to accommodate 'uur' &c.
      $y++ while $dir =~ /d/gi;
      $x-- while $dir =~ /l/gi;
      $x++ while $dir =~ /r/gi;
      land_square($Window,$win,$board_size,$piece,$x,$y);
      last if lc $dir eq $dir; # XXX Accommodate '*' for jumps as well
      return if $Window->square($x,$y) } }
  else { ($x,$y) = @_[1,2] }

  land_square($Window,$win,$board_size,$piece,$x,$y) }
# }}}

# {{{ display_help
sub display_help {
  my ($Window,$win,$board_size) = @_;
  return if $Window->empty_square;

  my $piece = $Window->cur_square;
  unless($Board->neighbor($piece)) {
    endwin();
    die "Unknown piece '$piece'" }

  help_direction($Window,$win,$board_size,$piece,$_)
    for @{$Board->neighbor($piece)} }
# }}}

# {{{ display_borders
sub display_borders {
  my ($Window,$win,$board_size) = @_;

  $win->addstr($grid->{t}-1,
               $grid->{l}-1,
               ($Window->at_top and $Window->at_left) ? '+' : ' ');
  $win->addstr($grid->{t}-1,
               $grid->{r},
               ($Window->at_top and $Window->at_right) ? '+' : ' ');
  $win->addstr($grid->{b},
               $grid->{l}-1,
               ($Window->at_bottom and $Window->at_left) ? '+' : ' ');
  $win->addstr($grid->{b},
               $grid->{r},
               ($Window->at_bottom and $Window->at_right) ? '+' : ' ');

  my $top_ch = $Window->at_top ? '-' : ' ';
  my $bot_ch = $Window->at_bottom ? '-' : ' ';
  my $left_ch = $Window->at_left ? '|' : ' ';
  my $right_ch = $Window->at_right ? '|' : ' ';
  $win->addstr($grid->{t}-1, $grid->{l}, $top_ch x ($grid->{r} - $grid->{l}));
  $win->addstr($grid->{b}, $grid->{l}, $bot_ch x ($grid->{r} - $grid->{l}));
  for my $y($grid->{t}..$grid->{b}-1) {
    $win->addstr($y, $grid->{l}-1, $left_ch);
    $win->addstr($y, $grid->{r}, $right_ch) } }
# }}}

# {{{ display_cursor
sub display_cursor {
  my ($Window,$win,$board_size) = @_;

  my ($cx,$cy) = $Window->cursor;
  for my $x (0..$board_size-1) {
    $win->addstr($grid->{t} - 2, grid_x($x),
                 sprintf("%3s",
                         $x == $cx ? 'V' :
                                     $Board->size-$x-($Window->corner)[0])) }
  for my $y (0..$board_size-1) {
    $win->addstr(grid_y($y), $grid->{r} + 1,
                 sprintf("%2s",
                         $y == $cy ? '<' :
                                     chr(ord('a')+($Window->corner)[1]+$y))) } }
# }}}

# {{{ do_stuff
sub do_stuff {
  my ($Window,$ch) = @_;
  my $action = {
    'h' => sub { $Window->curs_left or BEEP },
    'j' => sub { $Window->curs_down or BEEP },
    'k' => sub { $Window->curs_up or BEEP },
    'l' => sub { $Window->curs_right or BEEP },
    ' ' => sub {
      if($hand) { # Dropping piece
        if($Window->empty_square) { # Move to empty square
          $Window->set_cur_square($hand);
          $hand = undef }
        elsif(same_side($hand,$Window->cur_square)) { BEEP } # Capture own piece
        else { # Capture other piece
          push @{$in_hand[side($Window->cur_square)]}, $Window->cur_square;
          $Window->set_cur_square($hand);
          $hand = undef } }
      elsif($Window->cur_square) { $hand = $Window->take_cur_square } },
    '+' => sub {
      do { BEEP; return } if $Window->empty_square;

      my $y = ($Window->cursor)[1] + ($Window->corner)[1];
      my $square = $Window->cur_square;
      my $prom = $Board->promote($square);
      $prom or do { BEEP; return };
      if(side($square) and $y > $Board->size - $Board->promotion_zone - 1) {
        $Window->set_cur_square(uc $prom) }
      elsif(!side($square) and $y < $Board->promotion_zone) {
        $Window->set_cur_square($prom) }
      else { BEEP } },
    '?' => sub { $help = !$help } };
  $action->{$ch}->() if $action->{$ch} }
# }}}

# {{{ Main Body
my $Window = Window->new(
  viewport => [ $board_size, $board_size ],
  cursor   => [ 0, 0 ],
  grid     => $Board->board() );
my $win = Curses->new();

grep { $_ eq '-h' } @ARGV and do { Usage() };

noecho();
cbreak();
$win->timeout(1);

display_grid($win,$board_size);

# {{{ Main loop
while(1) {
  display_board($Window,$win,$board_size);
  display_help($Window,$win,$board_size) if $help;
  display_borders($Window,$win,$board_size);
  display_cursor($Window,$win,$board_size);

  my $ch = $win->getch();
  last if lc $ch eq 'q';
  do_stuff($Window,$ch) }
# }}}

endwin();
# }}}

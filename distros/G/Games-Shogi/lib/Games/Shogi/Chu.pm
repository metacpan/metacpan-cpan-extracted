package Games::Shogi::Chu;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 12 }
sub promotion_zone() { 4 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP' ] }

# {{{ Board static data
my @board = (
  #    12 11 10  9  8  7  6  5  4  3  2  1
  [qw(  L FL  C  S  G DE  K  G  S  C FL  L )],  # a
  [qw( RC  _  B  _ BT PH KI BT  _  B  _ RC )],  # b
  [qw( SM VM  R DH DK FK LN DK DH  R VM SM )],  # c
  [qw(  P  P  P  P  P  P  P  P  P  P  P  P )],  # d
  [qw(  _  _  _ GB  _  _  _  _ GB  _  _  _ )],  # e
  [qw(  _  _  _  _  _  _  _  _  _  _  _  _ )],  # f
  [qw(  _  _  _  _  _  _  _  _  _  _  _  _ )],  # g
  [qw(  _  _  _ gb  _  _  _  _ gb  _  _  _ )],  # h
  [qw(  p  p  p  p  p  p  p  p  p  p  p  p )],  # i
  [qw( sm vm  r dh dk ln fk dk dh  r vm sm )],  # j
  [qw( rc  _  b  _ bt ki ph bt  _  b  _ rc )],  # k
  [qw(  l fl  c  s  g  k de  g  s  c fl  l )] );# l
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Bishop
  b => {
    name => 'Bishop',
    romaji => 'kakugyo',
    promote => 'dh',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Blind Tiger
  bt => {
    name => 'Blind Tiger',
    romaji => 'moko',
    promote => 'fs',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Copper General
  c => {
    name => 'Copper General',
    romaji => 'dosho',
    promote => 'sm',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Dragon Horse
  dh => {
    name => 'Dragon Horse',
    romaji => 'ryume',
    promote => 'hf',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( o^o ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Dragon King
  dk => {
    name => 'Dragon King',
    romaji => 'ryuo',
    promote => 'se',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Drunk Elephant
  de => {
    name => 'Drunk Elephant',
    romaji => 'suizo',
    promote => 'cp',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Ferocious Leopard
  fl => {
    name => 'Ferocious Leopard',
    romaji => 'mohyo',
    promote => 'b',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Free King
  fk => {
    name => 'Free King',
    romaji => "hon'o",
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Go-Between
  gb => {
    name => 'Go-Between',
    romaji => 'chunin',
    promote => 'de',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Gold General
  g => {
    name => 'Gold General',
    romaji => 'kinsho',
    promote => 'r',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ King
  k => {
    name => 'King',
    romaji => 'osho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Kirin
  ki => {
    name => 'Kirin',
    romaji => 'kylin',
    promote => 'ln',
    neighborhood => [
      q(  x  ),
      q( o o ),
      q(x ^ x),
      q( o o ),
      q(  x  ) ] },
  # }}}
  # {{{ Lance
  l => {
    name => 'Lance',
    romaji => 'kyosha',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Lion
  ln => {
    name => 'Lion',
    romaji => 'shishi',
    igui => 1,
    neighborhood2 => [
      q(22222), # The 'x' is a jump area, not the inside
      q(21112),
      q(21^12),
      q(21112),
      q(22222) ],
    neighborhood => { area => 2 }, # Really an area of 1 and a spare move...
    jump => { area => 2 } }, # Not quite correct, more of area 2 radius 1...
  # }}}
  # {{{ Pawn
  p => {
    name => 'Pawn',
    romaji => 'fuhyo',
    promote => '+p',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Phoenix
  ph => {
    name => 'Phoenix',
    romaji => 'hoo',
    promote => 'fk',
    neighborhood => [
      q(x   x),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(x   x) ] },
  # }}}
  # {{{ Reverse Chariot
  rc => {
    name => 'Reverse Chariot',
    romaji => 'hansha', # orig. 'hensha'
    promote => 'w',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Rook
  r => {
    name => 'Rook',
    romaji => 'hisha',
    promote => 'dk',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Side Mover
  sm => {
    name => 'Side Mover',
    romaji => 'ogyo',
    promote => 'fb',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Silver General
  s => {
    name => 'Silver General',
    romaji => 'ginsho',
    promote => 'vm',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Mover
  vm => {
    name => 'Vertical Mover',
    romaji => 'kengyo',
    promote => 'fo',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}

  # {{{ Crown Prince
  cp => {
    name => 'Crown Prince',
    romaji => 'taishi',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Flying Stag
  fs => {
    name => 'Flying Stag',
    romaji => 'hiroku',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( o^o ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Flying Ox
  fo => {
    name => 'Flying Ox',
    romaji => 'higyu',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Boar
  fb => {
    name => 'Free Boar',
    romaji => 'honcho',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Horned Falcon
  hf => {
    name => 'Horned Falcon',
    romaji => 'kakuo',
    promote => 'bgn',
    neighborhood2 => [
      q(\ 2 /),
      q( \1/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    igui => 1, # May burn the piece on 1, also capture 1 and neighborhood to 2
    neighborhood => {
      diagonal => 'range',
      horizontal => 'range',
      n => 1,
      s => 'range' },
    jump => { n => 2 } },
  # }}}
  # {{{ Promoted Pawn
  '+p' => {
    name => 'Promoted Pawn',
    romaji => 'tokin',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Soaring Eagle
  se => {
    name => 'Soaring Eagle',
    romaji => 'hiju',
    promote => 'rgn',
    neighborhood => [
      q(2   2),
      q( 1|1 ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    igui => 1 }, # May burn piece on 1 without moving
                 # May burn piece on 1 and neighborhood to 2, capture as well
  # }}}
  # {{{ Whale
  wh => {
    name => 'Whale',
    romaji => 'keigei',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ White Horse
  who => {
    name => 'White Horse',
    romaji => 'hakku',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
};
# }}}

# {{{ new
sub new {
  my $proto = shift;
  my $self = { pieces => $pieces };
  bless $self, ref($proto) || $proto;
  $self->{board} = $self->initial_board(\@board);
  return $self }
# }}}

1;
__END__

=head1 NAME

Games::Shogi - Piece descriptions and initial configuration for Chu Shogi

=head1 SYNOPSIS

  use Games::Shogi::Chu;
  $Game = Games::Shogi::Chu->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Chu Shogi is a middle variant with the Lion as its most outlandish piece, being able to move as a queen, and take 2 pieces at a time.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

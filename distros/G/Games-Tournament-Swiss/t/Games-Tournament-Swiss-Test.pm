package Games::Tournament::Swiss::Test;

use lib qw/t lib/;



use strict;
use warnings;
use Test::Base -Base;

our @EXPORT = qw/@p @g $gs $s $meets $play/;

use Games::Tournament::Contestant::Swiss -base;
use Games::Tournament::Swiss -base;
use Games::Tournament::Card -base;

our @p;
$p[0] = Games::Tournament::Contestant::Swiss->new( id => 9430101, name => 'Roy', title => 'Expert', rating => 100,  );
$p[1] = Games::Tournament::Contestant::Swiss->new( id => 9430102, name => 'Ron', title => 'Expert', rating => 80,  );
$p[2] = Games::Tournament::Contestant::Swiss->new( id => 9430103, name => 'Rex', score => 3, title => 'Expert', rating => '50', );
$p[3] = Games::Tournament::Contestant::Swiss->new( id => 9430104, name => 'Ray', title => 'Novice', rating => 25, );
$p[4] = Games::Tournament::Contestant::Swiss->new( id => 9430105, name => 'Rob', score => 3, title => 'Novice', rating => 1, );
$p[5] = Games::Tournament::Contestant::Swiss->new( id => 9430106, name => 'Ros', score => 3, title => 'Novice', rating => 0, );
$p[6] = Games::Tournament::Contestant::Swiss->new( id => 9430107, name => 'Reg', score => 3, title => 'Novice', );
$p[7] = Games::Tournament::Contestant::Swiss->new( id => 9430108, name => 'Red', score => 3, title => 'Novice', );

our $s = Games::Tournament::Swiss->new(entrants => \@p);

our @g;
$g[0] = Games::Tournament::Card->new( round => 1, contestants => {Black => $p[7], White => $p[0]}, result => {Black => 'Loss'} );
$g[1] = Games::Tournament::Card->new( round => 2, contestants => {Black => $p[2], White => $p[0]}, result => {Black => 'Loss'} );
$g[2] = Games::Tournament::Card->new( round => 3, contestants => {Black => $p[4], White => $p[0]}, result => {Black => 'Loss'} );

$g[3] = Games::Tournament::Card->new( round => 1, contestants => {Black => $p[6], White => $p[1]}, result => {Black => 'Loss'} );
$g[4] = Games::Tournament::Card->new( round => 2, contestants => {Black => $p[7], White => $p[1]}, result => {Black => 'Loss'} );
$g[5] = Games::Tournament::Card->new( round => 3, contestants => {Black => $p[3], White => $p[1]}, result => {Black => 'Loss'} );

$g[6] = Games::Tournament::Card->new( round => 1, contestants => {Black => $p[5], White => $p[2]}, result => {Black => 'Loss'} );
$g[7] = Games::Tournament::Card->new( round => 3, contestants => {Black => $p[7], White => $p[2]}, result => {Black => 'Loss'} );

$g[8] = Games::Tournament::Card->new( round => 1, contestants => {Black => $p[4], White => $p[3]}, result => {Black => 'Loss'} );
$g[9] = Games::Tournament::Card->new( round => 2, contestants => {Black => $p[6], White => $p[3]}, result => {Black => 'Loss'} );

$g[10] = Games::Tournament::Card->new( round => 2, contestants => {Black => $p[5], White => $p[4]}, result => {Black => 'Loss'} );

$g[11] = Games::Tournament::Card->new( round => 3, contestants => {Black => $p[6], White => $p[5]}, result => {Black => 'Loss'} );

$s->assignPairingNumbers;
map { $_->writeCard(@g) } @p;

$s->collectCards(@g);
our $play = $s->play;

$s->calculateScores(3);
our $gs = $s->formBrackets(3);

our $meets = $s->met($p[7],$p[0],$p[1],$p[2],$p[3],$p[4],$p[5],$p[6]);

# plan tests => $#tests+1;

# map { is_deeply( $_->[0], $_->[1,], $_->[2] ) } @tests;

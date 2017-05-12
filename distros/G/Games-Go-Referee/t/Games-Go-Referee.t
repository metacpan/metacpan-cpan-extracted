#########################

use Test::More tests => 7;
BEGIN { 
  use_ok('Games::Go::Referee');
  use_ok('Games::Go::SGF');
};

#########################

my $expected = ( 
'Illegal self-capture at move 1
Play over at move 11
Alternation error at move 12
Alternation error at move 16
Illegal self-capture at move 18
Board repetition at move 29
Illegal self-capture at move 30
Board repetition at move 30
Board repetition at move 55
');
my $referee = Games::Go::Referee->new;         # create an object
ok( defined $referee );                        # check that we got something
ok( $referee->isa('Games::Go::Referee') );     # and it's the right class
ok( $referee->pointformat('sgf') eq 'sgf' );   # check pointformat
$referee->sgffile('./sgf/test.sgf');
my $answer = join( '', $referee->errors ) ;
ok( $answer eq $expected );
my $sgf = new Games::Go::SGF('./sgf/test.sgf');
$referee->sgffile($sgf);
$answer = join( '', $referee->errors ) ;
ok( $answer eq $expected );


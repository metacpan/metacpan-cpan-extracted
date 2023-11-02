use 5.038;

use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Tiny;
# use Data::Dumper;
# use Data::Printer;
use Game::Lottery;
use Path::Tiny;

my $DG = Game::Lottery->new( game => 'draw');

ok( $DG->_NoCollision( [59,68,107,'[22]']),
  'The first pick collision checked is ok');
ok( $DG->_NoCollision( [49,38,07],['[22]']),
  'The second pick collision checked is ok');
ok( $DG->_NoCollision( [29,38,07,'[29]']),
  'The third pick collision checked is ok');
ok( !$DG->_NoCollision( [29,38,07,'[29]']),
  'Trying third pick again is rejected');
ok( !$DG->_NoCollision( [29,38,07],['[29]']),
  'Trying third pick again with the redball in a second array ref also fails');

done_testing();

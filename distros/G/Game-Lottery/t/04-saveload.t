use 5.038;

use Test2::V0;
use Test2::Bundle::More;
use Test2::Tools::Tiny;
# use Data::Dumper;
# use Data::Printer;
use Game::Lottery;
use Path::Tiny;

# letting adjust correct these.
my $PB = Game::Lottery->new( game => 'power');
my $MM = Game::Lottery->new( game => 'megamill');

my $wf1 = {
  balls => [ 33, 24, 40, 52, 68, '[10]' ],
  memo => "2023-10-11"
};
my @winners = $PB->ReadPicks( 't/data/winners.ticket' );
is( scalar(@winners),3, 'sample winners file had 3 tickets');
is_deeply( $winners[1], $wf1, 'verify line of winners file' );
is( $winners[0]->{memo}, '2023-10-10', 'first draw in winners memo');
is( $winners[2]->{memo}, undef, 'last draw in winners file had no memo');

my @spacescheck = $MM->ReadPicks( 't/data/sample.mm.ticket' );
is (scalar(@spacescheck), 6,
  'file with empty lines returned the number of lines with data');
is_deeply( $spacescheck[5]->{balls}, [ qw/ 03 26 31 44 68 [05]/],
  'confirm the last line in the file with empty lines is the correct line');

my @numbers = $PB->ReadPicks( 't/data/sample.pb.ticket' );
is( @numbers, 6, 'expected number of tickets in a sample file');
is_deeply( $numbers[3]->{balls}, [qw( 01 21 39 53 63 [07])], 'verify one of the lines');

my @checkoutput = $PB->CheckPicks( 't/data/winners.ticket', 't/data/sample.pb.ticket' );
# p @checkoutput;
is ( $checkoutput[7], "* 2023-10-11 * 33 24 40 52 68 [10]",
  'check a header line from CheckPicks' );
is ( $checkoutput[20], " 6 -- 16 34 46 55 67 [14] matched (6): 16 34 46 55 67 [14]",
  'last line is ticket that won the jackpot' );
is ( $checkoutput[1], " 1 -- 05 40 50 57 60 [15] ",
  'check a header line with no matches' );

done_testing();

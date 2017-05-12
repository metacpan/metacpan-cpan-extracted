use Test::More tests=>1;
use Games::QuizTaker;
use Sub::Override;

my $expected='Who is the creator of Perl?';
my $override=Sub::Override->new('Games::QuizTaker::test'=>sub{ $Games::QuizTaker::TESTONLY });

my $GQ=Games::QuizTaker->new(filename=>'t/testqa');
$GQ->load;
$GQ->generate;
my $OUT=$GQ->test;


like($OUT,qr/$expected/);


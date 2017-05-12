use Test::More tests => 1; 
use Games::QuizTaker;

my $file1="t/sampleqa";

my $GQ1=Games::QuizTaker->new(FileName=>$file1);

$GQ1->load;
$GQ1->generate;

my $maxquestions=$GQ1->get_MaxQuestions;
ok($maxquestions == 9);


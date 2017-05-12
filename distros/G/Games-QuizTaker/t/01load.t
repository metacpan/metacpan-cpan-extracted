use Test::More tests => 9;

BEGIN{ use_ok('Games::QuizTaker'); }

can_ok ('Games::QuizTaker','new');

my $GQ1=Games::QuizTaker->new(FileName=>"t/sampleqa",Score=>1);

ok(defined $GQ1,'Object created');

ok($GQ1->isa('Games::QuizTaker'));

my $file=$GQ1->get_FileName;
ok($file eq "t/sampleqa");

my $score=$GQ1->get_Score;
ok($score == 1);

my $delim=$GQ1->get_Delimiter;
ok($delim eq "|");

my $ans_delim=$GQ1->get_AnswerDelimiter;
ok($ans_delim eq " ");

$GQ1->load;
my $count=$GQ1->get_FileLength;
ok($count == 9);



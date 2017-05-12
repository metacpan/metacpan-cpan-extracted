use Test::More tests=>3;
use Games::QuizTaker;

my $gq=Games::QuizTaker->new(filename=>"t/sampleqa");
my $fn=$gq->get_FileName;
ok($fn eq "t/sampleqa");

eval{ my $Q=Games::QuizTaker->new(FileName=>"t/sample.csv",Delimiter=>',',AnswerDelimiter=>','); };
ok(defined $@);

eval{ my $q=Games::QuizTaker->new(); };
ok(defined $@);


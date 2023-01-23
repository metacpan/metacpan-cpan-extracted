use 5.012;
use warnings;
use Test::More;
use FASTX::Seq;
my $offset = 33;

# Min quality score in Illumina 1.8 
my $min_quality_encoded = '!';
my $min_quality_score   = 0;


my $char2qual = FASTX::Seq->char2qual($min_quality_encoded, $offset);
my $qual2char = FASTX::Seq->qual2char($min_quality_score, $offset);

ok($char2qual == $min_quality_score, "char2qual($min_quality_encoded, $offset) == $min_quality_score");
ok($qual2char eq $min_quality_encoded, "qual2char($min_quality_score, $offset) == $min_quality_encoded");

# High quality score in Illumina 1.8
my $high_quality_encoded = 'I';
my $high_quality_score   = 40;


my $high_char2qual = FASTX::Seq->char2qual($high_quality_encoded, $offset);
my $high_qual2char = FASTX::Seq->qual2char($high_quality_score, $offset);

ok($high_char2qual == $high_quality_score, "char2qual($high_quality_encoded, $offset) == $high_quality_score");
ok($high_qual2char eq $high_quality_encoded, "qual2char($high_quality_score, $offset) == $high_quality_encoded");

done_testing();

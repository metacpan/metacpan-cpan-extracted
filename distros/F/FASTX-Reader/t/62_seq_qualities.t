use 5.012;
use warnings;
use Test::More;
use FASTX::Seq;
my $record = FASTX::Seq->new(
    -seq => 'CAGATANN', 
    -name => 'Seq', 
    -qual => 'BAI8,,!!');
my $after = $record->copy();
my $until = $record->copy();
isa_ok($record, 'FASTX::Seq');

my $qual = $record->qual();
ok($qual eq 'BAI8,,!!', "Qualities are correct: $qual");

# Update offset
$record->offset(33);

my @quals = $record->qualities();
ok(scalar @quals == 8, "Qualities are correct: 8, got " . join(", ", @quals));
ok($quals[0] == 33,    "Quality at #1 is correct: 40, got $quals[0]");
ok($quals[1] == 32,    "Quality at #2 is correct: 32 got $quals[1]");
ok($quals[-1] == 0,    "Quality at last base is correct: 0 got $quals[-1]");

my $min_qual = $record->min_qual();
ok($min_qual == 0, "Min quality is correct: 0 got $min_qual");
my $max_qual = $record->max_qual();
ok($max_qual == 40, "Max quality is correct: 40 got $max_qual");


$after->trim_after($min_qual);
ok($after->seq eq 'CAGATA', "Trimming after $min_qual removes Ns: " . $after->seq);


$until->trim_until(40);
ok($until->seq eq 'GATANN', "Trimming until qual $min_qual only Ns: " . $until->seq);
done_testing();

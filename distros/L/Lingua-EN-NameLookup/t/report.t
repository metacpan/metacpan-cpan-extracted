print "1..4\n";

use Lingua::EN::NameLookup;

my $dict = Lingua::EN::NameLookup->new();

my $res = $dict->load("t/surnames.dat");

print "not " if (!$res);
print "ok 1\n";

my @report = $dict->report();
print "not " if ($report[0] != 1988);
print "ok 2\n";
print "not " if ($report[1] != 9773);
print "ok 3\n";
print "not " if ($report[2] != 81);
print "ok 4\n";


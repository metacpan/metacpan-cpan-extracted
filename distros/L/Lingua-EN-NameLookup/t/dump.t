print "1..3\n";

use Lingua::EN::NameLookup;

BEGIN { $SIG{'__WARN__'} = sub { warn $_[0] unless ($_[0] =~ /No such file/)} }
my $dict = Lingua::EN::NameLookup->new();

my $res = $dict->load("t/surnames.dat");

print "not " if (!$res);
print "ok 1\n";

$res = $dict->dump("t/surnames.dat2");

print "not " if (!$res);
print "ok 2\n";

$res = $dict->dump("silly/surnames.dat");

print "not " if ($res);
print "ok 3\n";

print "1..4\n";

use Lingua::EN::NameLookup;

BEGIN { $SIG{'__WARN__'} = sub { warn $_[0] unless ($_[0] =~ /No such file/)} }
my $dict = Lingua::EN::NameLookup->new();

my $res = $dict->init("t/surnames.src");

print "not " if (!$res);
print "ok 1\n";

$res = $dict->init("imaginary.src");

print "not " if ($res);
print "ok 2\n";

$res = $dict->load("t/surnames.dat");

print "not " if (!$res);
print "ok 3\n";

$res = $dict->load("imaginary.dat");

print "not " if ($res);
print "ok 4\n";

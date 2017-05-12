print "1..6\n";

use Lingua::EN::NameLookup;

my $dict = Lingua::EN::NameLookup->new();

my $res = $dict->load("t/surnames.dat");

print "not " if (!$res);
print "ok 1\n";

# lookup in a single element array
$res = $dict->ilookup("ABNER");

print "not " if (!$res);
print "ok 2\n";

# lookup in a multiple element array
$res = $dict->ilookup("BARLOW");

print "not " if (!$res);
print "ok 3\n";

# lookup should work this time 
$res = $dict->ilookup("Barlow");

print "not " if (!$res);
print "ok 4\n";

# lookup fails no soundex
$res = $dict->ilookup("WALL");

print "not " if ($res);
print "ok 5\n";

# lookup fails invalid soundex
$res = $dict->ilookup("12345");

print "not " if ($res);
print "ok 6\n";

print "1..6\n";

use Lingua::EN::NameLookup;

my $dict = Lingua::EN::NameLookup->new();

my $res = $dict->load("t/surnames.dat");

print "not " if (!$res);
print "ok 1\n";

# lookup fails no soundex
$res = $dict->lookup("WALL");

print "not " if ($res);
print "ok 2\n";

$dict->add("WALL");

# lookup should work now
$res = $dict->lookup("WALL");

print "not " if (!$res);
print "ok 3\n";

# case insensitive lookup should work now
$res = $dict->ilookup("Wall");

print "not " if (!$res);
print "ok 4\n";

# lookup fails no entry
$res = $dict->lookup("WALLS");

print "not " if ($res);
print "ok 5\n";

$dict->add("WALLS");

# lookup should work now
$res = $dict->lookup("WALLS");

print "not " if (!$res);
print "ok 6\n";


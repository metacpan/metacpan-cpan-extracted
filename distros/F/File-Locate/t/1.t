use Test::More;
use File::Spec;

BEGIN { plan tests => 349 };
use File::Locate;

ok(1); 

my $locatedb = File::Spec->catfile("t", "locatedb.test");

# ordinary fnmatch
my @files = locate "*", $locatedb;
ok (@files == 173, "num entries");
locate "*", $locatedb, sub { ok(shift(@files) eq $_, "single entry") };

# regex match
@files = locate "^/", -rex => 1, $locatedb;
ok (@files == 173, "num entries for rex");
locate "^/", $locatedb, -rex => 1, sub { ok(shift(@files) eq $_, "single entry") };

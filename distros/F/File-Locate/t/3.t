use Test::More;
use File::Spec;
use File::Locate;

# ordinary fnmatch
my $locatedb = File::Spec->catfile("t", "slocatedb.test");
my @files = locate "*", $locatedb;

plan tests => @files * 2 + 1;

if ($< == 0) {
    ok (@files == 716, "num entries");
} else {    
    # we really cannot know how many files slocate() returns
    # when not being root
    ok(1, "not root: anything could happen");
}

locate "*", $locatedb, sub { ok(shift(@files) eq $_, "single entry") };

# regex
@files = locate "^/", -rex => 1, $locatedb;
locate "^/", -rex => 1, $locatedb, sub { ok(shift(@files) eq $_, "single entry rex") };

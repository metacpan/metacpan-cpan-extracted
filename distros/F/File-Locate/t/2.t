use Test::More;
use File::Spec;

BEGIN { plan tests => 5 };
use File::Locate;
ok(1); 

my $locatedb = File::Spec->catfile("t", "locatedb.test");
my @files = locate "*", $locatedb;
ok(!locate("mp3", $locatedb), "no mp3 in database"); 
ok(locate("html", $locatedb), "html in database");
ok($files[0] eq '/usr/local/apache/', "first entry");
ok($files[-1] eq '/usr/local/apache/htdocs/manual/mod/mod_a', "last entry");


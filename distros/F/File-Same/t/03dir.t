use Test;
BEGIN { plan tests => 3 }
use File::Same;
use File::Spec;

chdir("testfiles");

my @same = File::Same::scan_dir('a', 'dir1');

ok(@same);

ok(@same, 1);

ok($same[0], File::Spec->catfile(dir1 => 'a'));


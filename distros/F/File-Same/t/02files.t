use Test;
BEGIN { plan tests => 3 }
use File::Same;
use File::Spec;

chdir "testfiles";

my @same = File::Same::scan_files('a', ['a', 'b', File::Spec->catfile(dir1 => 'a')]);
ok(@same);

ok(@same, 1);

ok($same[0], File::Spec->catfile(dir1 => 'a'));


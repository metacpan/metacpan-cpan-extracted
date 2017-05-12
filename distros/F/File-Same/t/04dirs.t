use Test;
BEGIN { plan tests => 3 }
use File::Same;
use File::Spec;

chdir("testfiles");

my @same = File::Same::scan_dirs(File::Spec->catfile(dir3 => 'g'), ['.', 'dir1', 'dir2', 'dir3']);

ok(@same);

ok(@same, 1);

ok($same[0], File::Spec->catfile(dir2 => 'g'));


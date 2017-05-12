use strict;
my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');

use Test::More tests => 2;

use File::Share ':all';
use Cwd qw[abs_path cwd];

my $share_dir = abs_path "$xt/Foo-Bar/share";
my $share_file = abs_path "$xt/Foo-Bar/share/o/hai.txt";

use lib "$xt/Foo-Bar/lib";
use Foo::Bar;

is dist_dir('Foo-Bar'), $share_dir, 'Dir is correct';
is dist_file('Foo-Bar', 'o/hai.txt'), $share_file, 'File is correct';

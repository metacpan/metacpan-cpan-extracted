use strict;
my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');

use Test::More tests => 2;

use File::Share ':all';
use Cwd qw[abs_path cwd];

my $share_dir = abs_path "$xt/Bar-Baz/share";
my $share_file = abs_path "$xt/Bar-Baz/share/o/hai.txt";

use lib "$xt/Bar-Baz/lib";
use Bar::Baz;

is dist_dir('Bar-Baz'), $share_dir, 'Dir is correct';
is dist_file('Bar-Baz', 'o/hai.txt'), $share_file, 'File is correct';

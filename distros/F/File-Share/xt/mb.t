use strict;
my $xt; use lib ($xt = -e 'xt' ? 'xt' : 'test/devel');

use Test::More tests => 2;

use File::Share ':all';
use Cwd qw[abs_path cwd];

my $share_dir  = abs_path "$xt/MB/share";
my $share_file = abs_path "$xt/MB/share/o/hai.txt";

use lib "$xt/MB/lib";
use MB;

is dist_dir('MB'), $share_dir, 'Dir is correct';
is dist_file( 'MB', 'o/hai.txt' ), $share_file, 'File is correct';

package TestFileShare1;
use strict;
use warnings;

use Readonly;
use File::Share qw(dist_dir);

Readonly $_;

my $d = dist_dir 'File-Share';

1;

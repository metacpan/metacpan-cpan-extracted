use strict;
use warnings;

use Test::More tests => 5;

use lib 'lib';
use File::DirObject::Dir;

# dir constructor without any arguments 
# should default to current working directory
my $dir = File::DirObject::Dir->new();

# or we specify which directory we want to be in
# here we get the current working directory from a shell
my $dir2 = File::DirObject::Dir->new(`pwd`);

# ... now all relevant methods should be the same
is $dir->is_cwd, 1;
is $dir2->is_cwd, 1;

is $dir->name, $dir2->name;
is $dir->full_path, $dir2->full_path;
is $dir->path, $dir2->path;


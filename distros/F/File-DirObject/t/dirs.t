use strict;
use warnings;

use Scalar::Util;
use Test::More;

use lib 'lib';
use File::DirObject::Dir;

my $count = 0;
my $dir = File::DirObject::Dir->new;

ok $dir->parent_dir->contains_dir($dir->name);
$count++;

foreach my $child ($dir->dirs) {
    is Scalar::Util::blessed $child, "File::DirObject::Dir";
    is $child->parent_dir->path, $dir->path;
    $count += 2;
}

done_testing($count);

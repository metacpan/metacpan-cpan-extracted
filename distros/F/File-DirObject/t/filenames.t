use strict;
use warnings;

use Scalar::Util;
use Test::More;

use lib 'lib';
use File::DirObject::Dir;
use File::DirObject::File;

my $dir = File::DirObject::Dir->new;
my $count = 0;

foreach my $file ($dir->files) {
    $count += 3;
    ok($file->name !~ /\/\//g, $file->name);
    ok($file->path !~ /\/\//g, $file->path);
    ok($file->full_path !~ /\/\//g, $file->full_path);
}

done_testing($count);

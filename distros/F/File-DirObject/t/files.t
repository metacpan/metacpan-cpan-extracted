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
    $count += 2;
    is Scalar::Util::blessed $file, "File::DirObject::File";
    is $file->dir, $dir;
}

done_testing($count);

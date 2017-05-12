use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 4;
use Test::Exception;

#make a new directory, and put some files in it
mkdir("./temp") or die $!;
my $fh;
open($fh, '>', './temp/foo');
open($fh, '>', './temp/foo.pl');

my $sp;
my $fff;
my @files;

$sp = {
    modified => '<='.time,
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 1, 'files has 2 elems');
is($files[0], './temp/foo', 'files has 0th elem foo');
is($files[1], './temp/foo.pl', 'files has 1st elem foo.pl');

$sp = {
    modified => '>'.time,
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, -1, 'files has 0 elems');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');;
rmdir('./temp');

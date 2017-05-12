use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 8;
use Test::Exception;

#make a new directory, and put some files in it
mkdir("./temp") or die $!;
mkdir("./temp/temp2") or die $!;
my $fh;
open($fh, '>', './temp/foo');
open($fh, '>', './temp/foo.pl');
open($fh, '>', './temp/foo.txt');
open($fh, '>', './temp/temp2/bar.pl');
open($fh, '>', './temp/temp2/bar.txt');
open($fh, '>', './temp/temp2/baz.txt');

my $sp;
my $fff;
my @files;

$sp = {
    recurse => 1,
    dirs => './temp'
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 6, 'files has 7 elems');
is($files[0], './temp/foo', 'files has 0th elem foo');
is($files[1], './temp/foo.pl', 'files has 1st elem foo.pl');
is($files[2], './temp/foo.txt', 'files has 2nd elem foo.txt');
is($files[3], './temp/temp2', 'files has 3rd elem temp2');
is($files[4], './temp/temp2/bar.pl', 'files has 4th elem bar.pl');
is($files[5], './temp/temp2/bar.txt', 'files has 5th elem bar.txt');
is($files[6], './temp/temp2/baz.txt', 'files has 6th elem baz.txt');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');
unlink('./temp/foo.txt');
unlink('./temp/temp2/bar.pl');
unlink('./temp/temp2/bar.txt');
unlink('./temp/temp2/baz.txt');
rmdir('./temp/temp2');
rmdir('./temp');

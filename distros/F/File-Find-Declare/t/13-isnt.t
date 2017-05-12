use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 22;
use Test::Exception;

#make a new directory, and put some files in it
mkdir("./temp") or die $!;
mkdir("./temp/temp2") or die $!;
my $fh;
open($fh, '>', './temp/foo');
chmod 0000, './temp/foo'; #none
open($fh, '>', './temp/foo.pl');
chmod 0555, './temp/foo.pl'; #read and execute
open($fh, '>', './temp/foo.txt');
chmod 0777, './temp/foo.txt'; #all
open($fh, '>', './temp/bar.pl');
chmod 0222, './temp/bar.pl'; #write only
open($fh, '>', './temp/bar.txt');
chmod 0111, './temp/bar.txt'; #execute only
open($fh, '>', './temp/baz.txt');

my $sp;
my $fff;
my @files;

$sp = {
    isnt => 'directory',
    dirs => './temp'
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 5, 'files has 6 elems');
is($files[0], './temp/bar.pl', 'files has 0th elem bar.pl');
is($files[1], './temp/bar.txt', 'files has 1st elem bar.txt');
is($files[2], './temp/baz.txt', 'files has 2nd elem baz.txt');
is($files[3], './temp/foo', 'files has 3rd elem foo');
is($files[4], './temp/foo.pl', 'files has 4th elem foo.pl');
is($files[5], './temp/foo.txt', 'files has 5th elem foo.txt');

$sp = {
    isnt => 'readable',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 2, 'files has 3 elems');
is($files[0], './temp/bar.pl', 'files has 0th elem bar.pl');
is($files[1], './temp/bar.txt', 'files has 1st elem bar.txt');
is($files[2], './temp/foo', 'files has 2nd elem foo');

$sp = {
    isnt => 'writable',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 2, 'files has 3 elems');
is($files[0], './temp/bar.txt', 'files has 0th elem bar.txt');
is($files[1], './temp/foo', 'files has 1st elem foo');
is($files[2], './temp/foo.pl', 'files has 2nd elem foo.pl');

$sp = {
    isnt => 'executable',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 2, 'files has 3 elems');
is($files[0], './temp/bar.pl', 'files has 10th elem bar.pl');
is($files[1], './temp/baz.txt', 'files has 1st elem bar.txt');
is($files[2], './temp/foo', 'files has 1st elem foo');

$sp = {
    isnt => ['readable', 'writable', 'executable'],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 0, 'files has 1 elems');
is($files[0], './temp/foo', 'files has 0th elem foo');

$sp = {
    isnt => ['readable', 'writable', 'executable', 'file'],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, -1, 'files has 0 elems');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');
unlink('./temp/foo.txt');
unlink('./temp/bar.pl');
unlink('./temp/bar.txt');
unlink('./temp/baz.txt');
rmdir('./temp/temp2');
rmdir('./temp');

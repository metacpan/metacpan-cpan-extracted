use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 9;
use Test::Exception;

#make a new directory, and put some files in it
mkdir("./temp") or die $!;
my $fh;
open($fh, '>', './temp/foo');
open($fh, '>', './temp/foo.pl');
open($fh, '>', './temp/foo.txt');
open($fh, '>', './temp/bar.pl');
open($fh, '>', './temp/bar.txt');
open($fh, '>', './temp/baz.txt');

my $sp;
my $fff;
my @files;

$sp = {
    ext => '.pl',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 1, 'files contains 2 elems');
is($files[0], './temp/bar.pl', 'files has 0th elem bar.pl');
is($files[1], './temp/foo.pl', 'files has 1st elem foo.pl');

$sp = {
    ext => ['.pl', '.txt'],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 4, 'files contains 5 elems');
is($files[0], , './temp/bar.pl', 'files has 0th elem bar.pl');
is($files[1], , './temp/bar.txt', 'files has 1st elem bar.txt');
is($files[2], , './temp/baz.txt', 'files has 2nd elem baz.txt');
is($files[3], , './temp/foo.pl', 'files has 3rd elem foo.pl');
is($files[4], , './temp/foo.txt', 'files has 4th elem foo.txt');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');
unlink('./temp/foo.txt');
unlink('./temp/bar.pl');
unlink('./temp/bar.txt');
unlink('./temp/baz.txt');
rmdir('./temp');

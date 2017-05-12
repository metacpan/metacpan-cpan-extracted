use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 11;
use Test::Exception;

#make a new directory, and put some files in it
mkdir("./temp") or die $!;
my $fh;
open($fh, '>', './temp/foo');
open($fh, '>', './temp/foo.pl');
print $fh "a"x512;
open($fh, '>', './temp/foo.txt');
print $fh "a"x1024;
open($fh, '>', './temp/bar.pl');
print $fh "a"x2048;
open($fh, '>', './temp/bar.txt');
print $fh "a"x4196;
open($fh, '>', './temp/baz.txt');
print $fh "a"x8392;

my $sp;
my $fff;
my @files;

$sp = {
    size => '0',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 0, 'files has 1 elem');
is($files[0], './temp/foo', 'files has 0th elem foo');

$sp = {
    size => '1024',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 0, 'files has 1 elem');
is($files[0], './temp/foo.txt', 'files has 0th elem foo.txt');

$sp = {
    size => '>2048',
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 1, 'files has 2 elems');
is($files[0], './temp/bar.txt', 'files has 0th elem bar.txt');
is($files[1], './temp/baz.txt', 'files has 1st elem baz.txt');

$sp = {
    size => ['1024', '2048'],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, -1, 'files has 0 elems');

$sp = {
    size => ['>=1024', '<=2048'],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 1, 'files has 2 elems');
is($files[0], './temp/bar.pl', 'files has 0th elem bar.pl');
is($files[1], './temp/foo.txt', 'files has 1st elem foo.txt');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');
unlink('./temp/foo.txt');
unlink('./temp/bar.pl');
unlink('./temp/bar.txt');
unlink('./temp/baz.txt');
rmdir('./temp');

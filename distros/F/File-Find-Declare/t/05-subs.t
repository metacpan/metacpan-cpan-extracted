use strict;
use warnings;
use File::Find::Declare;
use Test::More tests => 6;
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
    subs => sub { $_[0] =~ m/foo/ },
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 2, 'files has 3 elems');
is($files[0], './temp/foo', 'files has 0th elem foo');
is($files[1], './temp/foo.pl', 'files has 1st elem foo.pl');
is($files[2], './temp/foo.txt', 'files has 2nd elem foo.txt');

$sp = {
    subs => [sub { $_[0] =~ m/foo/ }, sub { $_[0] =~ m/txt/ }],
    dirs => './temp',
};
$fff = File::Find::Declare->new($sp);
@files = sort $fff->find();
is($#files, 0, 'files has 1 elem');
is($files[0], './temp/foo.txt', 'files has 0th elem baz.txt');

#delete temp directory
unlink('./temp/foo');
unlink('./temp/foo.pl');
unlink('./temp/foo.txt');
unlink('./temp/bar.pl');
unlink('./temp/bar.txt');
unlink('./temp/baz.txt');
rmdir('./temp');

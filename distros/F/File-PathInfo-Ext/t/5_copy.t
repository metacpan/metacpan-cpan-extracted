use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::PathInfo::Ext;
use Carp;
use Cwd;
use Smart::Comments '###';


use File::Path;
File::Path::rmtree('./t/tmp');



my $abs = Cwd::cwd().'/t/tmp/file.txt';
my $abs_to = Cwd::cwd().'/t/tmp/file2.txt';
mkdir './t/tmp';
open(FI,'>',$abs) or die($!);
print FI 'this is content';
close FI or die($!);
mkdir './t/tmp/dir';






my $f = File::PathInfo::Ext->new($abs) or die;



my $r;
ok( $r = $f->copy('file2.txt'),'copy()');
ok( $r eq $abs_to,"copy() returns what we expect") 
   or die("expected:'$abs_to'\ngot:'$r'\n");

ok( $r eq $abs_to);

ok( -f $abs,'after copy, original is still there');

ok( -f $abs_to,'as is copy');


ok( $f->abs_path eq $abs_to,"abs_path() is what we expect, and is refreshed");



warn " # NOW try to dirs\n\n\n";
my $dir1 = cwd().'/t/tmp/dir';
-d $dir1 or die;

# this one not on disk
my $dir2 = cwd().'/t/tmp/dirfake';


my $newpath = "$dir1/".$f->filename;

ok( $r = $f->copy( $dir1 ),'copied to dir existing') or die($f->errstr);

ok( $r eq $newpath,"newpath is expected") or die("expected: $newpath, got $r");


ok( -f $newpath, "newpath is there on disk and is dir");

ok $r = $f->copy('./t/tmp/dir/filealso.txt');

### $r

my $loc = $f->abs_loc;
my $r1 = "$loc/hahaha";
my $re;
ok( $re = $f->rename('hahaha'), 'rename()');
ok( $re eq $r1 );



sub ok_part { print STDERR "\n\n--------------@_\n----\n\n"; 1 }




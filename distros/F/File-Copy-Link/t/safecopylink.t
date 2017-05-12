#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl safecopylink.t'

use strict;
use warnings;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN{
    if( !eval{ (symlink q{}, q{}), 1 } ) {
        plan skip_all => q{'symlink' not implemented};
    }
    plan tests => 6;
    use_ok('File::Copy::Link', qw(safecopylink) );
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Compare;
use File::Temp qw(tempdir);
use File::Spec; 

my $dir = tempdir();

my $file = File::Spec->catfile($dir,'file.txt');
my $link = File::Spec->catfile($dir,'link.lnk');

open my $fh, ">", $file or die;
print $fh "text\n" or die;
close $fh or die;

    die unless
	symlink('file.txt',$link) && -l $link && !compare($file,$link);

    open $fh, ">>", $file or die;
    print $fh "more\n" or die;
    close $fh or die;
    not compare($file,$link) or die;

    ok( safecopylink($link), "safecopylink");
    ok( !(-l $link), "not a link");
    ok( !compare($file,$link), "compare file and copy");

    open $fh, ">>", $file or die;
    print $fh "more\n" or die;
    close $fh or die;

    compare($file,$link) or die;
    unlink $file or die;

    ok( -e $link, "copy not deleted"); 
    unlink $link or die;
    ok( !(-e $link), "copy deleted");

# $Id: safecopylink.t 187 2007-12-31 00:29:35Z rmb1 $

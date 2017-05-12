# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 25;
use File::Signature;

#########################

sub touch_testfile { 
    my $file = shift || './testfile';
    open F, '>>', $file or die "Couldn't open $file: $!"; #return undef; 
    print F "\n";
    close F;
    return 1;
}

sub remove_testfile { unlink './testfile' if -e './testfile' }
 
SKIP: {
    touch_testfile() or skip "couldn't create test file";
    my $obj = File::Signature->new('./testfile'); 
    ok( !$obj->changed , "hasn't changed" );
       ($o,$n) = $obj->old_and_new('pathname'); is( $o, $n, 'check pathnames' );
       ($o,$n) = $obj->old_and_new('digest');   is( $o, $n, 'check digests' );
       ($o,$n) = $obj->old_and_new('ino');      is( $o, $n, 'check inodes' );
       ($o,$n) = $obj->old_and_new('mode');     is( $o, $n, 'check modes' );
       ($o,$n) = $obj->old_and_new('uid');      is( $o, $n, 'check uids' );
       ($o,$n) = $obj->old_and_new('gid');      is( $o, $n, 'check gids' );
       ($o,$n) = $obj->old_and_new('size');     is( $o, $n, 'check sizes' );
       ($o,$n) = $obj->old_and_new('mtime');    is( $o, $n, 'check mtimes' );
    remove_testfile();
}

SKIP: {
    touch_testfile() or skip "couldn't create test file";
    my $obj = File::Signature->new('./testfile'); 
    sleep 1; 
    touch_testfile() or skip "couldn't touch test file";
    ok( $obj->changed , "has changed" );
    my ($o,$n) = $obj->old_and_new('pathname');  is( $o, $n, 'same pathnames' );
       ($o,$n) = $obj->old_and_new('digest');  isnt( $o, $n, 'digests differ' );
       ($o,$n) = $obj->old_and_new('ino');       is( $o, $n, 'same inodes' );
       ($o,$n) = $obj->old_and_new('mode');      is( $o, $n, 'same modes' );
       ($o,$n) = $obj->old_and_new('uid');       is( $o, $n, 'same uids' );
       ($o,$n) = $obj->old_and_new('gid');       is( $o, $n, 'same gids' );
       ($o,$n) = $obj->old_and_new('size');    isnt( $o, $n, 'sizes differ' );
       ($o,$n) = $obj->old_and_new('mtime');   isnt( $o, $n, 'mtimes differ' );
    chmod 0700, './testfile' or skip "can't chmod";
    ok( $obj->changed , "has changed again" );
       ($o,$n) = $obj->old_and_new('pathname');  is( $o, $n, 'same pathnames' );
       ($o,$n) = $obj->old_and_new('mode');    isnt( $o, $n, 'modes differ' );
    touch_testfile("./testfile2") or skip "couldn't create new test file";
    unlink './testfile';
    rename './testfile2', './testfile';
    ok( $obj->changed , "has changed yet again" );
       ($o,$n) = $obj->old_and_new('pathname');  is( $o, $n, 'same pathnames' );
       ($o,$n) = $obj->old_and_new('ino');     isnt( $o, $n, 'inodes differ' );
    remove_testfile();
}

my $err = File::Signature->new('nonexistent'); 
eval { $err->old_and_new('pathname') };
like( $@, qr/bad method call/, 'threw exception');



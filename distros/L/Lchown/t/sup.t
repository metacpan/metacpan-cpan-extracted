use strict;
use warnings;
use Test::More (tests => 17);

use Lchown qw(lchown LCHOWN_AVAILABLE);


SKIP: {
    skip "this system lacks lchown", 17 unless LCHOWN_AVAILABLE;

    is( lchown(0,0), 0, "null lchown gave 0" );
    my $result = lchown 0, 0;
    is( $result, 0, "null lchown without parens" );

    is( lchown(0,0,'nosuchfile','nosuchfile.bak'), 0,
        "lchown returns 0 with 2 missing files");

    skip "not running as root", 14 if $>;

    symlink 'bar', 'foo' or die "symlink: $!";

    is( lchown(123,456,'foo'), 1, "lchown foo success" );
    my ($uid,$gid) = (lstat 'foo')[4,5];
    is( $uid, 123, "lchown foo set uid 123" );
    is( $gid, 456, "lchown foo set gid 456" );

    unlink 'foo' or die "unlink: $!"; 

    symlink 'bar', 'foo' or die "symlink: $!";
    symlink 'bar', 'baz' or die "symlink: $!";
    is( lchown(123,456,'foo','baz'), 2, "foo,baz success" );
    ($uid,$gid) = (lstat 'foo')[4,5];
    is( $uid, 123, "foo,baz set foo uid 123" );
    is( $gid, 456, "foo,baz set foo gid 456" );
    ($uid,$gid) = (lstat 'baz')[4,5];
    is( $uid, 123, "foo,baz set baz uid 123" );
    is( $gid, 456, "foo,baz set baz gid 456" );

    unlink 'foo' or die "unlink: $!"; 
    unlink 'baz' or die "unlink: $!"; 

    symlink 'bar', 'foo' or die "symlink: $!";

    is( lchown(123,456,'foo','nosuch'), 1, "foo,nosuch success for foo" );
    ($uid,$gid) = (lstat 'foo')[4,5];
    is( $uid, 123, "foo,nosuch set foo uid 123" );
    is( $gid, 456, "foo,nosuch set foo gid 456" );

    unlink 'foo' or die "unlink: $!"; 

    symlink 'bar', 'foo' or die "symlink: $!";

    is( lchown(123,456,'nosuch','foo'), 1, "nosuch,foo success for foo" );
    ($uid,$gid) = (lstat 'foo')[4,5];
    is( $uid, 123, "nosuch,foo set foo uid 123" );
    is( $gid, 456, "nosuch,foo set foo gid 456" );

    unlink 'foo' or die "unlink: $!";
}


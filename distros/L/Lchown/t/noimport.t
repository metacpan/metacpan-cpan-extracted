use strict;
use warnings;

use Test::More (tests => 3);

use Lchown ();

SKIP: {
    skip "this system lacks lchown", 3 unless Lchown::LCHOWN_AVAILABLE;
    skip "not running as root",      3 if $>;

    symlink 'bar', 'foo' or die "symlink: $!";
    my $result = Lchown::lchown 123, 456, 'foo';
    is( $result, 1, "Lchown::Lchown prototype works" );
    my ($uid,$gid) = (lstat 'foo')[4,5];
    is( $uid, 123, "Lchown::lchown foo set uid 123" );
    is( $gid, 456, "Lchown::lchown foo set gid 456" );

    unlink 'foo' or die "unlink: $!"; 
}


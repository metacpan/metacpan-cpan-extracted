use strict;
use warnings;

use Test::More (tests => 6);

use Lchown qw(lchown LCHOWN_AVAILABLE);

SKIP: {
    skip "this system has lchown", 6 if LCHOWN_AVAILABLE;

    my $uid = $>;
    my $gid = $) =~ /^(\d+)/;

    ok( ! defined lchown($uid, $gid), "null lchown call failed" );
    like( $!, '/function not implemented/i', "null lchown gave ENOSYS" );
    
    my $symlink_exists = eval { symlink("",""); 1 };
    skip "Symlink not supported", 4 if !defined($symlink_exists);

    symlink 'bar', 'foo' or skip "can't make a symlink", 2;
    ok( ! defined lchown($uid, $gid, 'foo'), "valid lchown call failed" );
    like( $!, '/function not implemented/i', "valid lchown gave ENOSYS" );
    unlink 'foo';

    ok( ! defined lchown($uid, $gid, 'nosuchfile'), "missing file lchown call failed" );
    like( $!, '/function not implemented/i', "file valid lchown gave ENOSYS" );
}


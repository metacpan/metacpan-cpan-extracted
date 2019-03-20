#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

require Git::Mailmap;

BEGIN {
    use_ok('Git::Mailmap') || print "Bail out!\n";
    can_ok( 'Git::Mailmap', 'new' );
    can_ok( 'Git::Mailmap', 'add' );
    can_ok( 'Git::Mailmap', 'remove' );
    can_ok( 'Git::Mailmap', 'map' );
    can_ok( 'Git::Mailmap', 'verify' );
    can_ok( 'Git::Mailmap', 'to_string' );
    can_ok( 'Git::Mailmap', 'from_string' );
}

done_testing();


#!perl -T

use Test::More tests => 7;

BEGIN {
	use_ok( 'LJ::Schedule' );
}

LJ::Schedule::get_config('./t/test1.ini');

ok($LJ::Schedule::CONFIG->{'alias.j'} eq "joanne");
ok($LJ::Schedule::CONFIG->{'alias.jo'} eq "joisspecial");

ok($LJ::Schedule::CONFIG->{'entry.protect'} eq "private");
ok($LJ::Schedule::CONFIG->{'entry.subject'} eq "Schedule Post");

ok($LJ::Schedule::CONFIG->{'private.user'} eq "kitty");
ok($LJ::Schedule::CONFIG->{'private.pass'} eq "XXXXX");

1;

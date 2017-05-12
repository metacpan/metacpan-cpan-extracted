#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;
use Email::IsEmail qw/IsEmail/;


ok( 1 == IsEmail('prettyandsimple@example.com'), 'prettyandsimple@example.com is valid E-mail' );
ok( 1 == IsEmail('very.common@example.com'), 'very.common@example.com is valid E-mail' );
ok( 1 == IsEmail('disposable.style.email.with+symbol@example.com'), 'disposable.style.email.with+symbol@example.com is valid E-mail' );
ok( 1 == IsEmail('other.email-with-dash@example.com'), 'other.email-with-dash@example.com is valid E-mail' );
ok( 1 == IsEmail('x@example.com'), 'x@example.com@example.com is valid E-mail' );
ok( 1 == IsEmail('"much.more unusual"@example.com'), '"much.more unusual"@example.com is valid E-mail' );
ok( 1 == IsEmail('"very.unusual.@.unusual.com"@example.com'), '"very.unusual.@.unusual.com"@example.com is valid E-mail' );
ok( 1 == IsEmail('"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com'), '"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com is valid E-mail' );
ok( 1 == IsEmail('example-indeed@strange-example.com'), 'example-indeed@strange-example.com is valid E-mail' );
ok( 1 == IsEmail('admin@mailserver1'), 'admin@mailserver1 is valid E-mail' );
ok( 1 == IsEmail('#!$%&\'*+-/=?^_`{}|~@example.org'), '#!$%&\'*+-/=?^_`{}|~@example.org is valid E-mail' );
ok( 1 == IsEmail('"()<>[]:,;@\\\\\\"!#$%&\'-/=?^_`{}| ~.a"@example.org'), '"()<>[]:,;@\\\\\\"!#$%&\'-/=?^_`{}| ~.a"@example.org is valid E-mail' );
ok( 1 == IsEmail('" "@example.org'), '" "@example.org is valid E-mail' );
ok( 1 == IsEmail('example@localhost'), 'example@localhost is valid E-mail' );
ok( 1 == IsEmail('example@s.solutions'), 'example@s.solutions is valid E-mail' );
ok( 1 == IsEmail('user@localserver'), 'user@localserver is valid E-mail' );
ok( 1 == IsEmail('user@tt'), 'user@tt is valid E-mail' );
ok( 1 == IsEmail('user@[IPv6:2001:DB8::1]'), 'user@[IPv6:2001:DB8::1] is valid E-mail' );
ok( 1 == IsEmail('test@a123456789012345678901234567890123456789012345678901234567890ab.a123456789012345678901234567890123456789012345678901234567890ab.su'),
   'test@a123456789012345678901234567890123456789012345678901234567890ab.a123456789012345678901234567890123456789012345678901234567890ab.su is valid E-mail' );
ok( 1 == IsEmail('user@[127.0.0.1]'), 'user@[127.0.0.1] is valid E-mail' );
ok( 1 == IsEmail('user@[IPv6:::1]'), 'user@[IPv6:::1] is valid E-mail' );

ok( 1 == IsEmail('jsmith@[192.168.2.1]'), 'jsmith@[192.168.2.1] is valid E-mail' );
ok( 1 == IsEmail('"Abc\@def"@example.com'), '"Abc\@def"@example.com is valid E-mail' );
ok( 1 == IsEmail('"Fred Bloggs"@example.com'), '"Fred Bloggs"@example.com is valid E-mail' );
ok( 1 == IsEmail('"Joe\\Blow"@example.com'), '"Joe\\Blow"@example.com is valid E-mail' );
ok( 1 == IsEmail('"Abc@def"@example.com'), '"Abc@def"@example.com is valid E-mail' );
ok( 1 == IsEmail('customer/department=shipping@example.com'), 'customer/department=shipping@example.com is valid E-mail' );
ok( 1 == IsEmail('$A12345@example.com'), '$A12345@example.com is valid E-mail' );
ok( 1 == IsEmail('!def!xyz%abc@example.com'), '!def!xyz%abc@example.com is valid E-mail' );
ok( 1 == IsEmail('_somename@example.com'), '_somename@example.com is valid E-mail' );

done_testing();

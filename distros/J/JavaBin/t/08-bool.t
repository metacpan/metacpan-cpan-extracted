use strict;
use warnings;

use JavaBin;
use Scalar::Util 'refaddr';
use Test::More;

my $t = from_javabin to_javabin \1;

isa_ok $t, 'JavaBin::Bool', 'true is a JavaBin::Bool';

is refaddr $t, refaddr $JavaBin::true, 'the same true as $JavaBin::true';

ok $t, 'true is okay';
ok !!$t, 'not not true is okay';

ok $t == $t, 'true == true';
ok $t eq $t, 'true eq true';

my $f = from_javabin to_javabin \0;

isa_ok $f, 'JavaBin::Bool', 'false is a JavaBin::Bool';

is refaddr $f, refaddr $JavaBin::false, 'the same false as $JavaBin::false';

ok !$f, 'not false is okay';
ok !!!$f, 'not not not false is okay';

ok $f == $f, 'false == false';
ok $f eq $f, 'false eq false';

ok $t != $f, 'true != false';
ok $t ne $f, 'true ne false';

is from_javabin( to_javabin $t ), $t, 'true can round-trip';
is from_javabin( to_javabin $f ), $f, 'false can round-trip';

done_testing;

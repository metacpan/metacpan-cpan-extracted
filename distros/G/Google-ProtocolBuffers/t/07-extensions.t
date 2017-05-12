use Test::More tests => 24;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

Google::ProtocolBuffers->parse(
"
    package my.test;
    message R { optional int32 a = 1; extensions 10 to max; }
    extend  R { optional int32 b = 10; }
    message RFoo {
        extend  R { optional int32 c = 11; }
    }

", 
    { create_accessors => 1, simple_extensions => 1 }
);

my $r = My::Test::R->new();

$r->a(10);
is($r->a, 10);
is($r->{a}, 10);

$r->b(100);
is($r->b, 100);
is($r->{b}, 100);

$r->c(1000);
is($r->c, 1000);
is($r->{c}, 1000);

is($r->encode, "\x{08}\x{0a}PdX\x{e8}\x{07}");

my $rv = eval {
    Google::ProtocolBuffers->parse(
    "
        package my.test;
        message S { optional int32 a = 1; extensions 10 to max; }
        extend  S { optional int32 a = 10; }

    ", 
        { simple_extensions => 1 }
    );
};
ok(!$rv);


Google::ProtocolBuffers->parse(
"
    package my.test;
    message U { optional int32 a = 1; extensions 10 to max; }
    extend  U { optional int32 a = 10; }
    message UFoo {
        extend  U { optional int32 a = 11; }
    }
", 
    { create_accessors => 1 }
);

my $u = My::Test::U->decode("\x{08}\x{0a}PdX\x{e8}\x{07}");
is($u->{a}, 10);
is($u->{'[a]'}, 100);
is($u->{'[UFoo.a]'}, 1000);
is($u->a, 10);
is($u->getExtension('a'), 100);
is($u->getExtension('UFoo.a'), 1000);
is($u->getExtension('UFoo::a'), 1000);

$u->setExtension('a', 20);
is($u->getExtension('a'), 20);


$u->setExtension('UFoo.a', 200);
is($u->getExtension('UFoo::a'), 200);

$u->setExtension('UFoo::a', 400);
is($u->getExtension('UFoo.a'), 400);

ok(!eval{ $u->setExtension('asdf', 400) });
ok(!eval{ $u->getExtension('123') });


Google::ProtocolBuffers->parse(
"
    message TopLevel { optional int32 a = 1; extensions 10 to max; }

    // b is created as a top-level name
    extend  TopLevel { optional int32 b = 10; }

", 
    { create_accessors => 1, simple_extensions => 1}
);
my $t = TopLevel->decode("\x{08}\x{0a}PdX\x{e8}\x{07}");
is($t->{a}, 10);
is($t->{'b'}, 100);
is($t->a, 10);
is($t->b, 100);

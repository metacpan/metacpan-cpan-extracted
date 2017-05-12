use Test::More tests => 37;
use strict;
use warnings;
use Google::ProtocolBuffers;

BEGIN{ $SIG{__DIE__} = \&Carp::confess; }

ok(-f 't/MyTestR.pm');
ok(-f 't/MyTestU.pm');
ok(-f 't/UnitTest.pm');
require_ok('t/MyTestR.pm');
require_ok('t/MyTestU.pm');
require_ok('t/UnitTest.pm');
require_ok('t/UnitTest.pm');    ## what about second-time loading?


##
## A couple of test from everywhere:
##


##
## Encoder:
##
##
my $str;
$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 0});
is($str, "\x{08}\x{00}", "optional_int32=0");

$str = ProtobufUnittest::TestAllTypes->encode({optional_int32 => 1});
is($str, "\x{08}\x{01}", "optional_int32=1");


##
## Decoder
##
my $data;
$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{02}\x{08}\x{00}");
is_deeply($data->{optional_foreign_message}, {c => 0}, "optional_foreign_message={c => 0}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{0b}\x{08}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{ff}\x{01}");
is_deeply($data->{optional_foreign_message}, {c => -1}, "optional_foreign_message={c => -1}");

$data = ProtobufUnittest::TestAllTypes->decode("\x{9a}\x{01}\x{02}\x{08}\x{01}");
is_deeply($data->{optional_foreign_message}, {c => 1}, "optional_foreign_message={c => 1}");


##
## Enums
##
ProtobufUnittest::TestSparseEnum->import(':constants');
is(SPARSE_A(), 123);
is(SPARSE_B(), 62374);
is(SPARSE_C(), 12589234);
is(SPARSE_D(), -15);
is(SPARSE_E(), -53452);
is(SPARSE_F(), 0);
is(SPARSE_G(), 2);


##
## Accessors
## 
$data = ProtobufUnittest::TestAllTypes->new({optional_int32 => 10});
is($data->optional_int32, 10);

$data->optional_int32(100);
is($data->optional_int32, 100);


$data->optional_int32(20);
is($data->optional_int32, 20);

$data->optional_int32(0);
is($data->optional_int32, 0);


##
## Extensions
##
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

# t/01_test.t - check module loading, etc

use Test::More tests => 7;

BEGIN { use_ok( 'Digest::MD5::M4p' ); }

use strict;
use warnings;
use Digest::MD5::M4p qw(md5_hex);

my $a = new Digest::MD5::M4p;
isa_ok($a, 'Digest::MD5::M4p');

$a->add("a");
my $b = $a->clone;

ok($b->clone->hexdigest eq md5_hex("a"), 'Clone');
$a->add("a");
ok($a->hexdigest eq md5_hex("aa"), 'add');
ok($a->hexdigest eq md5_hex(""), 'nop');
$b->add("b");
ok($b->clone->hexdigest eq md5_hex("ab"), 'add again');
$b->add("c");
ok($b->clone->hexdigest eq md5_hex("abc"), 'and again');

use strict;
use Math::BigInt;
use Test::More tests => 11;

use_ok('Language::MzScheme');

my $env = Language::MzScheme->new;

my $obj = $env->define('bigint', Math::BigInt->new(0x12345));
is($obj->('as_hex'), "0x12345", 'auto context');
is($env->eval("(bigint 'as_hex)"), '0x12345', '...eval()');
is($obj->('as_hex@'), "(0x12345)", 'array context');
is($obj->('as_hex?'), "#t", 'bool context');

my $class = $env->define('Math::BigInt');
is($class->('VERSION'), Math::BigInt->VERSION, 'class method');
is($env->eval("(Math::BigInt 'VERSION)"), Math::BigInt->VERSION, '...eval()');
is($env->eval("((bigint 'can 'as_hex) bigint)"), '0x12345', 'nested invocation');

my $as_hex = $env->lambda(Math::BigInt->can('as_hex'));
is($class->as_perl_data, 'Math::BigInt', '$class->as_perl_data');
isa_ok($obj->as_perl_data, 'Math::BigInt', '$obj->as_perl_data');
is($as_hex->as_perl_data, Math::BigInt->can('as_hex'), '$code->as_perl_data');

1;

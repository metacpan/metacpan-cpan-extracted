use Test2::V0;

use Function::Interface;
eval "fun foo() :Return();";
ok(not $@);

no Function::Interface;

eval "fun bar() :Return();";

note $@;
like $@, qr/syntax error/;

done_testing;

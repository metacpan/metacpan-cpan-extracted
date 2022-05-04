
use strict;
use warnings;
use Test::More;
use Method::Signatures::Simple::ParseKeyword;

eval { Method::Signatures::Simple::ParseKeyword->import(invocant => { foo => "bar" }) };
like $@, qr/valid scalar identifier/;

eval { Method::Signatures::Simple::ParseKeyword->import(function_keyword => "this is fine") };
like $@, qr/function_keyword .* valid identifier/;

eval { Method::Signatures::Simple::ParseKeyword->import(name => "this is fine") };
like $@, qr/method_keyword .* valid identifier/;

done_testing;



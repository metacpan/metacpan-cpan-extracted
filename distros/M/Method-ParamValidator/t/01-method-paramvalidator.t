#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Test::Exception;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new({ config => "t/config.json" });

throws_ok { $validator->validate('get_xyz')  } qr/Invalid method name received/;
throws_ok { $validator->validate('add_user') } qr/Missing parameters/;
throws_ok { $validator->validate('add_user', []) } qr/Invalid parameters data structure/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }) } qr/Parameter failed check constraint/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 10, sex => 's' }) } qr/Parameter failed check constraint/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }) } qr/Missing required parameter/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }) } qr/Undefined required parameter/;
throws_ok { $validator->validate('add_user', { firstname => 'F' }) } qr/Missing required parameter/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'X' })  } qr/Parameter failed check constraint/;
lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'UK' }) };
lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'uk' }) };

done_testing();

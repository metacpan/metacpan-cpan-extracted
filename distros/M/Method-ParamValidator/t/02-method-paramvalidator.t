#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Test::Exception;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new;
$validator->add_field({ name => 'firstname', format => 's' });
$validator->add_field({ name => 'lastname',  format => 's' });
$validator->add_field({ name => 'age',       format => 'd' });
$validator->add_field({ name => 'sex',       format => 's' });
$validator->add_method({ name => 'add_user', fields => { firstname => 1, lastname => 1, age => 1, sex => 0 }});

throws_ok { $validator->validate('get_xyz')  }     qr/Invalid method name received/;
throws_ok { $validator->validate('add_user') }     qr/Missing parameters/;
throws_ok { $validator->validate('add_user', []) } qr/Invalid parameters data structure/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }) } qr/Parameter failed check constraint/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }) } qr/Missing required parameter/;
throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }) } qr/Undefined required parameter/;
throws_ok { $validator->validate('add_user', { firstname => 'F' }) } qr/Missing required parameter/;

done_testing();

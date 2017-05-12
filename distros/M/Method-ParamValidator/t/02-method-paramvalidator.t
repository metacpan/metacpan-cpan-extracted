#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new;
$validator->add_field({ name => 'firstname', format => 's' });
$validator->add_field({ name => 'lastname',  format => 's' });
$validator->add_field({ name => 'age',       format => 'd' });
$validator->add_field({ name => 'sex',       format => 's' });
$validator->add_method({ name => 'add_user', fields => { firstname => 1, lastname => 1, age => 1, sex => 0 }});

eval { $validator->validate('get_xyz'); };
like($@, qr/Invalid method name received/);

eval { $validator->validate('add_user'); };
like($@, qr/Missing parameters/);

eval { $validator->validate('add_user', []); };
like($@, qr/Invalid parameters data structure/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }); };
like($@, qr/Parameter failed check constraint/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }); };
like($@, qr/Missing required parameter/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }); };
like($@, qr/Undefined required parameter/);

eval { $validator->validate('add_user', { firstname => 'F' }); };
like($@, qr/Missing required parameter/);

done_testing();

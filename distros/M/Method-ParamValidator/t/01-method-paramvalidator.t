#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new({ config => "t/config.json" });

eval { $validator->validate('get_xyz'); };
like($@, qr/Invalid method name received/);

eval { $validator->validate('add_user'); };
like($@, qr/Missing parameters/);

eval { $validator->validate('add_user', []); };
like($@, qr/Invalid parameters data structure/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }); };
like($@, qr/Parameter failed check constraint/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 10, sex => 's' }); };
like($@, qr/Parameter failed check constraint/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }); };
like($@, qr/Missing required parameter/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }); };
like($@, qr/Undefined required parameter/);

eval { $validator->validate('add_user', { firstname => 'F' }); };
like($@, qr/Missing required parameter/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'X' }); };
like($@, qr/Parameter failed check constraint/);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'UK' }); };
like($@, qr//);

eval { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'uk' }); };
like($@, qr//);

done_testing();

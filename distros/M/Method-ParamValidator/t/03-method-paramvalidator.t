#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new;
my $LOCATION = { 'USA' => 1, 'UK' => 1 };
sub lookup { exists $LOCATION->{uc($_[0])} };

$validator->add_field({ name => 'location', format => 's', check => \&lookup });
$validator->add_method({ name => 'check_location', fields => { location => 1 }});

eval { $validator->validate('check_location', { }); };
like($@, qr/Missing required parameter/);

eval { $validator->validate('check_location', { location => undef }); };
like($@, qr/Undefined required parameter/);

eval { $validator->validate('check_location', { location => 'X' }); };
like($@, qr/Parameter failed check constraint/);

done_testing();

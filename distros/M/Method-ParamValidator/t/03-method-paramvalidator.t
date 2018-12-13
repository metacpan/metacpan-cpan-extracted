#!perl

use 5.006;
use strict; use warnings;

use Test::More;
use Test::Exception;
use Method::ParamValidator;

my $validator = Method::ParamValidator->new;
my $LOCATION = { 'USA' => 1, 'UK' => 1 };
sub lookup { exists $LOCATION->{uc($_[0])} };

$validator->add_field({ name => 'location', format => 's', check => \&lookup });
$validator->add_method({ name => 'check_location', fields => { location => 1 }});

throws_ok { $validator->validate('check_location', { })                   } qr/Missing required parameter/;
throws_ok { $validator->validate('check_location', { location => undef }) } qr/Undefined required parameter/;
throws_ok { $validator->validate('check_location', { location => 'X' })   } qr/Parameter failed check constraint/;

done_testing();

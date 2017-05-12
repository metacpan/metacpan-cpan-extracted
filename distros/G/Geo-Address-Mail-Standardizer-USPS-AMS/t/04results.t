use Test::More;

use_ok 'Geo::Address::Mail::Standardizer::USPS::AMS';
use_ok 'Geo::Address::Mail::US';

my $ms = new Geo::Address::Mail::Standardizer::USPS::AMS;

#$ms->datadir('/usr/share/uspsams');
#$ms->confdir('/etc/uspsams');

my $addr = new Geo::Address::Mail::US
{
	street		=> '4580 Rachel\'s Ln',
	city		=> 'Nashville',
	postal_code	=> 37076,
	state		=> 'TN'
};

my $results = $ms->standardize($addr);

isa_ok $results, 'Geo::Address::Mail::Standardizer::USPS::AMS::Results';

ok !$results->has_error,				'no has error';
ok $results->has_found,					'has found';
ok $results->has_candidates,			'has candidates';
ok $results->has_standardized_address,	'has standardized_address';

cmp_ok $results->found, '==', 2, 'Results->found';
isa_ok $results->standardized_address, 'Geo::Address::Mail::US';

my $addrstd = $results->standardized_address;

cmp_ok $addrstd->street,		'eq', '4580 RACHELS LN',	'standardized street';
cmp_ok $addrstd->city,			'eq', 'HERMITAGE',			'standardized city';
cmp_ok $addrstd->state,			'eq', 'TN',					'standardized state';
cmp_ok $addrstd->postal_code,	'eq', '37076-1331',			'standardized postal';

cmp_ok $results->changed_count, '==', 3, 'changed fields';
ok $results->is_changed('street'), 'street changed';
ok !$results->is_changed('street2'), 'street2 not changed';
ok $results->is_changed('city'), 'city changed';
ok !$results->is_changed('state'), 'state not changed';
ok $results->is_changed('postal_code'), 'postal changed';

done_testing;


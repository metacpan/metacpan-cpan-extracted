#!perl

use DomainOperations::ResellerClubHTTP;

use Data::Dumper;
my $do = DomainOperations::ResellerClubHTTP->new(
	username => '',
	password => '',
	account  => 'Production'
);

print Dumper $do->checkDomainAWithoutSuggestion(
	{ 'domains' => ['abcdefgh'], 'tlds' => [ 'com', 'net' ] } );

print Dumper $do->createCustomer(
	{
		_add_default_contact => '1',
		cemail               => '',
		cpassword            => '',
		cname                => ' ',
		caddress1            => 'test add 1',
		caddress2            => 'add 2',
		ccity                => 'delhi',
		cstate               => 'delhi',
		ccountry             => 'IN',
		czip                 => '',
		ccountrycode         => '91',
		cphone               => '',
	}
);

print Dumper $do->registerDomain(
	{
		domain      => 'xyz.com',
		years       => 4,
		nameservers => [ '', '' ],
		customer    => '',
		contact     => ''
	}
);

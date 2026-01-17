use Test2::V0;

{
	package Local::Person;
	use Types::Common -types;
	use Marlin
		name => NonEmptyStr,
		age  => PositiveOrZeroNum;
}

ok lives { Local::Person->new( age => 1 ) };

ok lives { Local::Person->new( name => 'Bob', age => 1 ) };


{
	package Local::Employee;
	use Types::Common -types;
	use Marlin -base    => 'Local::Person',
		'+name!',
		'+age!'  => NumRange[ 18, undef ];
}

like(
	dies { Local::Employee->new( age => 1 ) },
	qr/is required/,
);

like(
	dies { Local::Employee->new( name => 'Bob', age => 1 ) },
	qr/failed type constraint/,
);

like(
	dies { Local::Employee->new( age => 99 ) },
	qr/is required/,
);

ok lives { Local::Person->new( name => 'Bob', age => 99 ) };

done_testing;
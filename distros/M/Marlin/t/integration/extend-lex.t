use Test2::V0;
use Data::Dumper;

{
	package Local::Person;
	use Types::Common -types;
	use Marlin name => { reader => 'my name' };
	
	my $guy = __PACKAGE__->new( name => "Bob" );
	::is( &name( $guy ), "Bob" );
}

{
	my $e = do {
		local $@;
		eval q{
			package Local::Person2;
			use Types::Common -types;
			use Marlin -base => 'Local::Person';
			
			my $guy = __PACKAGE__->new( name => "Bob" );
			::is( &name( $guy ), "Bob" );
			1;
		} ? undef : $@;
	};
	like( $e, qr/Undefined sub/ );
}

{
	my $e = do {
		local $@;
		eval q{
			package Local::Person3;
			use Types::Common -types;
			use Marlin -base => 'Local::Person', '+name';
			
			my $guy = __PACKAGE__->new( name => "Bob" );
			::is( &name( $guy ), "Bob" );
			1;
		} ? undef : $@;
	};
	like( $e, qr/Undefined sub/ );
}

ok !defined &Local::Person::name;
ok !defined &Local::Person2::name;
ok !defined &Local::Person3::name;

done_testing;
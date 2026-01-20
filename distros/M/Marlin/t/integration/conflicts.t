use Test2::V0;

BEGIN {
	package Local::Foo;
	use Marlin 'foo';
};

do {
	my $e = do {
		local $@;
		eval q{
			package Local::Bar1;
			use Marlin
				-base => 'Local::Foo',
				bar   => { reader => "foo" };
		};
		$@;
	};
	like( $e, qr/Method 'foo' conflict/i );
};

do {
	my $e = do {
		local $@;
		eval q{
			package Local::Bar2;
			use Marlin
				-base => 'Local::Foo',
				bar   => { alias => "foo" };
		};
		$@;
	};
	like( $e, qr/Initialization argument 'foo' conflict/i );
};

done_testing;

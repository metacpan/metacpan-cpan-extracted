use Test2::V0;
use Data::Dumper;

BEGIN {
	package Local::MyRole;
	use Marlin::Role::Antlers;
	signature_for add_nums => ( pos => [ Int, Int ] );
};

BEGIN {
	package Local::MyClass;
	use Marlin::Antlers;
	with 'Local::MyRole';
	sub add_nums ( $self, $x, $y ) {
		return $x + $y;
	}
};

#$Data::Dumper::Deparse = 1;
#diag Dumper( \%Role::Tiny::INFO );

my $o = Local::MyClass->new;

is( $o->add_nums( 40, 2 ), 42 );

like( dies { $o->add_nums( 40, 0.2 ) }, qr/did not pass type constraint/ );

done_testing;

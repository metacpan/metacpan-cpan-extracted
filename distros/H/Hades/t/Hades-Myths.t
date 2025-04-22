use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Hades::Myths');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 3;
	ok( my $obj = Hades::Myths->new( {} ),
		q{my $obj = Hades::Myths->new({})}
	);
	ok( $obj = Hades::Myths->new(), q{$obj = Hades::Myths->new()} );
	isa_ok( $obj, 'Hades::Myths' );
};
subtest 'import' => sub {
	plan tests => 4;
	ok( my $obj = Hades::Myths->new( {} ),
		q{my $obj = Hades::Myths->new({})}
	);
	can_ok( $obj, 'import' );
	eval { $obj->import( [], 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->import([], 'phobos')}
	);
	eval { $obj->import( 'curae', 'phobos' ) };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/i,
		q{$obj->import('curae', 'phobos')}
	);
};
subtest 'new_object' => sub {
	plan tests => 2;
	ok( my $obj = Hades::Myths->new( {} ),
		q{my $obj = Hades::Myths->new({})}
	);
	can_ok( $obj, 'new_object' );
};
done_testing();

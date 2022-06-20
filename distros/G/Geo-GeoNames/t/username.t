use Test::More 0.98;

my $class = 'Geo::GeoNames';
my $method = 'new';

use_ok( $class );
can_ok( $class, $method );

subtest bad_name => sub {
	my $string;
	no warnings qw(redefine once);
	local *Geo::GeoNames::carp = sub { $string = join '', @_ };

	my $geo = eval { $class->$method(
		username => 'fakename',
		) } or fail($@);
	my $result = $geo->search( 'q' => 'Dijon' );
	isa_ok( $result, ref [] );
	is( scalar @$result, 0, 'There are no elements when the username is bad' );

	if( $string =~ /Invalid mime type \[]/ ) {
		note(
			"It looks like we did not get a response\n" .
			"Maybe you aren't connected."
			);
		}
	else {
		like( $string, qr/(GeoNames error: invalid username|does not exist)/, 'Fake username gives warning' );
		}
	};

subtest empty_name => sub {
	my $geo = eval { $class->$method(
		username => '',
		) };
	my $at = $@;

	is( $geo, undef, '$geo is undefined with empty username' );
	like( $at, qr/You must specify/i, 'Error message says to specify username' );
	};

subtest undef_name => sub {
	my $geo = eval { $class->$method(
		username => undef,
		) };
	my $at = $@;

	is( $geo, undef, '$geo is undefined with undef username' );
	like( $at, qr/You must specify/i, 'Error message says to specify username' );
	};

done_testing();

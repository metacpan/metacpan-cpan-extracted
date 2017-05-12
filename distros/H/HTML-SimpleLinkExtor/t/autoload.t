use Test::More 0.96;
use Test::Output;

my $class  = 'HTML::SimpleLinkExtor';
my $method = 'AUTOLOAD';

use_ok( $class );

$SIG{__WARN__} = sub { print STDERR @_ }; # 5.6.2 workaround problem in Test::Output

{
no strict 'refs';
ok( defined &{"${class}::$method"}, "$method is defined" );
}

my $extor = $class->new;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try some allowed methods
{
my @allowed = qw(a src href);

foreach my $method ( @allowed ) {
	can_ok( $extor, $method );
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try some un-allowed methods
{
my @not_allowed = qw(foo bar baz);

foreach my $method ( @not_allowed ) {
	ok( ! $extor->can( $method ),
		"can returns false for unallowed method $method" );

	stderr_like
		{ $extor->$method() }
		qr/method $method unknown/,
		"unallowed method $method gives a warning";
		}
}

done_testing();

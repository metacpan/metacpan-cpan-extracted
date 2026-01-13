use v5.40;
use Test2::V1 -ipP;
use Gears::X;
use Gears::X::HTTP;

################################################################################
# This tests whether exceptions work as expected
################################################################################

subtest 'should raise an exception from object' => sub {
	my $ex = Gears::X->new(message => 'test');
	my $ex2 = dies { $ex->raise };

	ok $ex == $ex2, 'raised ok';
};

subtest 'should raise an exception from class' => sub {
	my $ex = dies { Gears::X->raise('from_class') };
	is $ex->message, 'from_class', 'raised ok';
};

subtest 'should stringify correctly (base class)' => sub {
	my $ex = Gears::X->new(message => 'abcd');
	like "$ex", qr{An error occured: abcd \(raised at .+x\.t, line \d+\)}, 'stringified ok';
};

subtest 'should stringify correctly (HTTP)' => sub {
	my $ex = Gears::X::HTTP->new(code => 404, message => 'abcd');
	like "$ex", qr{An error occured: \[HTTP\] 404 - abcd \(raised at .+x\.t, line \d+\)}, 'stringified ok';
};

subtest 'should build and raise correctly (HTTP)' => sub {
	my $ex = dies { Gears::X::HTTP->raise(403 => 'not allowed here') };
	isa_ok $ex, 'Gears::X::HTTP';
	is $ex->code, 403, 'code ok';
	is $ex->message, 'not allowed here', 'message ok';
};

subtest 'should show a trace' => sub {
	my $ex = raise();
	my $trace = $ex->as_string(true);

	like $trace, qr{Stack trace:\v}, 'trace exists ok';
	like $trace, qr{t/x\.t, line 69}, 'trace 1 ok';
	like $trace, qr{t/x\.t, line 64}, 'trace 2 ok';
	like $trace, qr{t/x\.t, line 40}, 'trace 3 ok';

	note $trace;

	{
		local $Gears::X::PRINT_TRACE = true;
		$trace = $ex->as_string;
		like $trace, qr{Stack trace:\v}, 'trace with global var ok';
	}

	$trace = $ex->as_string;
	unlike $trace, qr{Stack trace:\v}, 'no trace ok';
};

done_testing;

sub raise
{
	raise2();
}

sub raise2
{
	Gears::X->new(message => 'test');
}


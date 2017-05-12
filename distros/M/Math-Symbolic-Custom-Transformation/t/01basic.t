#!perl
use strict;
use warnings;

use Test::More tests => 855;
#use Test::More 'no_plan';
use_ok('Math::Symbolic');
use_ok('Math::Symbolic::Custom::Pattern');
use_ok('Math::Symbolic::Custom::Transformation');

use Math::Symbolic qw/:all/;
use Math::Symbolic::Custom::Transformation qw/new_trafo/;

my $test;
my $in_test = 0;
my $line_no = 0;
while (<DATA>) {
	chomp;
	$line_no++;
	next if /^\s*#/;
	next if not $in_test and /^\s*$/;
	if ($in_test and /^\s*$/) {
		run_test($test);
		$in_test = 0;
		next;
	}

	if (not $in_test) {
		$in_test = 1;
		my $trafo_line = $_;
		$trafo_line =~ s/^\s*trafo\s*:\s*//i;
		my ($pattern, $repl) = split /\s*=>\s*/, $trafo_line;
		die "Invalid transformation specification"
		  if not defined $pattern or not defined $repl;
		my $status_line = <DATA>;
		$line_no++;
		my ($status) = $status_line =~ /^\s*status\s*:\s*(.*)$/;
		
	    $test = {
			pattern => $pattern,
			status => $status,
			repl => $repl,
			subtests => [],
			start_line => $line_no,
		};
		next;
	}

	my $tree_line = $_;
	my ($tree, $result) = split /\s*=\s*/, $tree_line;
	push @{$test->{subtests}}, [$tree, $result];
}

sub run_test {
	my $test = shift;

	my $trafo;
	eval {
		$trafo = Math::Symbolic::Custom::Transformation->new(
			$test->{pattern}, $test->{repl}
		);
	};
	
	my $other_trafo;
	eval {
		$other_trafo = new_trafo($test->{pattern}, $test->{repl});
	};
	
	ok(1, "Test starting at line $test->{start_line} reached test execution.");
	
	if ($test->{status}) {
		ok(
			(
				not $@ and ref($trafo)
				and $trafo->isa('Math::Symbolic::Custom::Transformation')
			),
			"Transformation from '$test->{pattern} => $test->{repl}' expectedly succeeded."
		);
		ok(
			(
				not $@ and ref($other_trafo)
				and $other_trafo->isa('Math::Symbolic::Custom::Transformation')
			),
			"Same transformation from new_trafo expectedly succeeded."
		);
		warn "Error: $@\n" if $@;
		warn "Error: not ref(\$trafo)\n" if not ref($trafo);
		warn "Error: not correct object.\n" if ref($trafo) and not $trafo->isa('Math::Symbolic::Custom::Transformation');
        ok( defined($trafo->to_string()), 'to_string() returns a string' );
	}
	else {
		ok(
			(
				$@ or not ref($trafo)
				or not $trafo->isa('Math::Symbolic::Custom::Transformation')
			),
			"Pattern creation from '$test->{pattern} => $test->{repl}' expectedly did not succeed."
		);
		ok(
			(
				$@ or not ref($other_trafo)
				or not $other_trafo->isa('Math::Symbolic::Custom::Transformation')
			),
			"Pattern creation from same source using new_trafo expectedly did not succeed."
		);
        ok(1, 'Cannot test to_string for a failing pattern');
	}

	foreach my $subt ( @{$test->{subtests}} ) {
		my ($tree_str, $result_str) = @$subt;
		my $result;
		if ($result_str =~ /^\s*undef\s*/i) {
			$result = undef;
		}
		else {
			$result = parse_from_string($result_str);
			die "Could not parse reference result '$result_str'." if not defined $result;
		}
		
		my $tree;
		eval {
			$tree = parse_from_string($tree_str);
		};

		ok(
			!$@,
			"Parsing tree '$tree_str' did not throw a fatal error."
		);
		ok(
			(ref($tree) and $tree->isa('Math::Symbolic::Base')),
			'Parse succeeded.'
		);

		if (!$@ and not ref($tree) or not $tree->isa('Math::Symbolic::Base')) {
			require Data::Dumper;
			Data::Dumper->import();
			warn Dumper($tree);
		}
		
		my $actual_result;
		eval {
			$actual_result = $trafo->apply($tree);
		};

		ok(!$@, 'Transformation did not throw a fatal error' . ($@?" Error: $@." : ''));
#		use Data::Dumper; warn $result;
#		warn $actual_result;
		if (not defined $result) {
			ok(!defined($actual_result), 'Transformation expectedly did not apply');
		}
		else {
			ok(ref($actual_result), 'Transformation was applied.');
			my $bool = $result->is_identical($actual_result);
			ok($bool, 'Transformation result is as expected.');
			warn "Expected: '$result'; Got: '$actual_result'." if not $bool;
			
		}
	}
}

__DATA__
# line 162 (check that yourself, though)
trafo: TREE_x + TREE_x => 2 * TREE_x
status: 1
a + a = 2 * a
(5*a) + (5*a) = 2 * (5*a)
1 + 1 = 2 * 1
1 + 2 = undef
2 + 1 = undef
a + 1 = undef

trafo: ( cos(TREE_x) )^2 + ( sin(TREE_x) )^2 => 1
status: 1
cos(sin(x)*cos(y))^2 + sin(sin(x)*cos(y))^2 = 1
cos(sin(y)*cos(y))^2 + sin(sin(x)*cos(y))^2 = undef
1 = undef

trafo: ( sin(TREE_x) )^2 + ( cos(TREE_x) )^ => 1
status: 0

trafo: ( sin(TREE_x) )^2 + ( cos(TREE_x) )^2 => 1
status: 1
sin(sin(x)*cos(y))^2 + cos(sin(x)*cos(y))^2 = 1
sin(sin(y)*cos(y))^2 + cos(sin(x)*cos(y))^2 = undef
1 = undef
sin(x)^2+cos(x)^2 = 1
cos(1)^1+sin(1)^2 = undef

trafo: asin( sin(TREE_x) ) => TREE_x
status: 1
asin(sin(foo^2)) = foo^2
asin(sin(1)) = 1
acos(sin(foo)) = undef
1 = undef
asin(cos(foo)) = undef

trafo: acos( cos(TREE_x) ) => TREE_x
status: 1
acos(cos(foo^2)) = foo^2
asin(sin(1)) = undef
acos(sin(foo)) = undef
1 = undef
asin(cos(foo)) = undef

trafo: atan( tan(TREE_x) ) => TREE_x
status: 1
atan(tan(foo^2)) = foo^2
tan(atan(1)) = undef
1 = undef


trafo: acot( cot(TREE_x) ) => TREE_x
status: 1
acot(cot(foo^2)) = foo^2
cot(acot(1)) = undef
1 = undef


trafo: asinh( sinh(TREE_x) ) => TREE_x
status: 1
asinh(sinh(foo^2)) = foo^2
sinh(asinh(1)) = undef
1 = undef

trafo: acosh( cosh(TREE_x) ) => TREE_x
status: 1
acosh(cosh(foo^2)) = foo^2
cosh(acosh(1)) = undef
1 = undef

trafo: sin( asin(TREE_x) ) => TREE_x
status: 1
asin(sin(foo^2)) = undef
sin(asin(1)) = 1
1 = undef

trafo: cos( acos(TREE_x) ) => TREE_x
status: 1
acos(cos(foo^2)) = undef
cos(acos(1)) = 1
1 = undef

trafo: tan( atan(TREE_x) ) => TREE_x
status: 1
atan(tan(foo^2)) = undef
tan(atan(1)) = 1
1 = undef

trafo: cot( acot(TREE_x) ) => TREE_x
status: 1
acot(cot(foo^2)) = undef
cot(acot(1)) = 1
1 = undef

trafo: sinh( asinh(TREE_x) ) => TREE_x
status: 1
sinh(asinh(foo^2)) = foo^2
asinh(sinh(1)) = undef
1 = undef

trafo: cosh( acosh(TREE_x) ) => TREE_x
status: 1
acosh(cosh(foo^2)) = undef
cosh(acosh(1)) = 1
1 = undef

trafo: TREE_x + CONST_y => CONST_y + TREE_x
status: 1
1 + 1   = 1 + 1
2 + 1   = 1 + 2
a + 2   = 2 + a
a + a   = undef
2 + a   = undef
5*2 + a = undef

trafo: 0 + TREE_x => TREE_x
status: 1
0 + 1 = 1
0 + 0 = 0
a + 0 = undef
1 + 0 = undef
0 + (1*a-0) = 1*a-0

trafo: TREE_x - 0 => TREE_x
status: 1
0 + 1 = undef
1 - 0 = 1
a - 0 = a
a*b - 0 = a*b 

trafo: 0 - TREE_x => -TREE_x
status: 1
0 - a = -a
a - 0 = undef
0 - 1 = -(1)

trafo: TREE_x - (-TREE_y) => TREE_x + TREE_y
status: 1
a - (-a) = a + a
a - (-b) = a + b
(a+b) - (-(c+d)) = (a+b) + (c+d)
1 - 1 = undef

trafo: (-TREE_x) - TREE_y => -(TREE_x + TREE_y)
status: 1
-a - b = -(a+b)
-(3) - (3*a-1+log(2,3)) = -(3 + (3*a-1+log(2,3)))
a - b = undef

trafo: (-TREE_x) - (-TREE_y) => TREE_y - TREE_x
status: 1
-a - (-b) = b - a
-b + (-a) = undef

trafo: TREE_x + (-TREE_y) => TREE_x - TREE_y
status: 1
(2*a) + (-(c*d)) = 2*a - c*d
1 = undef

trafo: (-TREE_x) + TREE_y => TREE_y - TREE_x
status: 1

trafo: (-TREE_x) + (-TREE_y) => -(TREE_x + TREE_y)
status: 1

trafo: TREE_x - TREE_x => 0
status: 1
((2*a) + (-(c*d))) - ((2*a) + (-(c*d))) = 0
0 - 0 = 0
1 - 0 = undef
0 + 0 = undef

trafo: TREE_x + TREE_x => 2 * TREE_x
status: 1
a + a = 2 * a
(a*3) + (a*3) = 2 * (a*3)
1 = undef
1 + a = undef

# Those parens around the 2's are to disambiguate between
# unary - (2) and the number -2
trafo: -(TREE_x + TREE_x) => -(2) * TREE_x
status: 1
-(a + a) = (-(2)) * a
-(a + b) = undef
1 = undef

trafo: TREE_a*TREE_x + TREE_x => simplify{TREE_a+1} * TREE_x
status: 1
3*x + x = 4*x
1*x + x = 2*x
x*3 + x = undef
1 = undef

trafo: TREE_x*TREE_a + TREE_x => simplify{TREE_a+1} * TREE_x
status: 1
x*3 + x = 4*x
x*1 + x = 2*x
3*x + x = undef
1 = undef

trafo: TREE_x + TREE_a*TREE_x => simplify{TREE_a+1} * TREE_x
status: 1
x + 1*x = 2*x
x + 3*x = 4*x
1 + 3 = undef

trafo: TREE_x + TREE_x*TREE_a => simplify{TREE_a+1} * TREE_x
status: 1
x + x*3 = 4*x
1 = undef

trafo: TREE_a*TREE_x + TREE_b*TREE_x => simplify{TREE_a+TREE_b} * TREE_x
status: 1
5*x + 2*x = 7*x
9*log(t,u) + 1*log(t,u) = 10*log(t,u)
1*2 + 3 * 4 = undef
1 = undef

trafo: TREE_x*TREE_a + TREE_b*TREE_x => simplify{TREE_a+TREE_b} * TREE_x
status: 1
q*2 + 2 * q = 4*q
1 = undef
1*2 + 3*4 = undef

trafo: TREE_a*TREE_x + TREE_x*TREE_b => simplify{TREE_a+TREE_b} * TREE_x
status: 1
3*x + x*4 = 7*x
1 = undef

trafo: TREE_x*TREE_a + TREE_x*TREE_b => simplify{TREE_a+TREE_b} * TREE_x
status: 1
x * 1 + x * 3 = 4*x

trafo: TREE_x / 1 => TREE_x
status: 1
2 / 1 = 2
a / 1 = a
(1+2) / 1 = 1+2
1 / 1 = 1
1 / a = undef
1 / 0 = undef

trafo: TREE_x / CONST_y => value{1/CONST_y} * TREE_x
status: 1
# floating point comparison!
# 2 / 2 = 0.5*2
# a / 4 = 0.25*a
# (1+2) / 2 = 0.5*(1+2)
1 / 1 = 1*1
# Would throw a fatal run-time error. Test mechanism cannot catch this.
# 1 / 0 = 1

trafo: TREE_x * CONST_y => CONST_y * TREE_x
status: 1

trafo: 1 * TREE_x => TREE_x
status: 1

trafo: 0 * TREE_x => 0
status: 1

trafo: 0 / TREE_x => 0
status: 1

trafo: TREE_a / (TREE_x / TREE_y) => TREE_a * (TREE_y / TREE_x)
status: 1

trafo: TREE_x / TREE_x => 1
status: 1
(a+b)/(a+b) = 1

trafo: TREE_x * TREE_x => TREE_x^2
status: 1
a*a = a^2
a^2*a^2=(a^2)^2

trafo: TREE_x^TREE_y * TREE_x^TREE_z => TREE_x^simplify{TREE_y*TREE_z}
status: 1
a^2*a^3 = a^6

trafo: TREE_x^TREE_y / TREE_x^TREE_z => TREE_x^simplify{TREE_y-TREE_z}
status: 1
# commented out since -1 will be parsed as -(1) and we would need the number -1.
# x^2 / x^3 = x^(-1)

trafo: TREE_x ^ 1 => TREE_x
status: 1
foo ^ 1 = foo
1 ^ foo = undef

trafo: TREE_x ^ 0 => 1
status: 1
5 ^ 0 = 1

trafo: 1^TREE_x => 1
status: 1
1^x = 1

trafo: 0^TREE_x => 0
status: 1
0^x = 0

trafo: TREE_x ^ log(TREE_x, TREE_y) => TREE_y
status: 1
x ^ log(x, y) = y

trafo: log(TREE_x, TREE_x^TREE_y) => TREE_y
status: 1
log(x, x^y) = y

trafo: log(TREE_x, TREE_x) => 1
status: 1
log(x, x) = 1

trafo: log(TREE_x, 1) => 0
status: 1
log(x, 1) = 0

trafo: foo => foo^2
status: 1
foo = foo^2

trafo: VAR_foo => VAR_foo^2
status: 1
bar => bar^2

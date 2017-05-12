#!perl -w

use strict;
$^W=1;
BEGIN { chdir "t" if -d "t"; }
use lib '../blib/arch', '../blib/lib';

use Test;
BEGIN { plan tests => 226, todo => [] }

use Math::Business::BlackScholes (
  qw/call_price put_price call_put_prices/,
  qw/implied_volatility_call implied_volatility_put/
);

my $tol=2e-5; # Tolerance for floating point comparisons
$Math::Business::BlackScholes::max_iter=20;

sub ae {
	my $lhs=shift;
	my $rhs=shift;
	my $ref=shift || 0.0;
# print("$lhs =? $rhs\n");
	return abs($lhs-$rhs) <= (abs($rhs) + abs($ref))*$tol;
}

sub check {
	ok(check1(@_));
}

sub check1 {
	die unless @_>=7 && @_<=9;
	my $call0=shift;
	my $put0=shift;
	my $mkt=$_[0];

	my $call1=call_price(@_);
	my $put1=put_price(@_);
	my ($call2, $put2)=call_put_prices(@_);

	ok($call1>=0);
	ok($put1>=0);

	ok(ae($call1, $call0));
	ok(ae($put1, $put0, $mkt));
	ok(ae($call2, $call1));
	ok(ae($put2, $put1));

	my @c10_args = (10*$_[0], $_[1], 10*$_[2], @_[3..$#_]);
	if(@_ > 5 && ref($_[5])) {
		$c10_args[5] = {
		  map { $_ => 10*$_[5]->{$_} } keys %{$_[5]}
		};
	}
	my $call10=call_price(@c10_args);
	ok(ae($call10, 10*$call1));

	my @p10_args = ($_[0], $_[1]/sqrt(10), $_[2], $_[3]*10, $_[4]/10);
	if(@_ > 5) {
		if(ref $_[5]) {
			push @p10_args, {
			  map { $_*10 => $_[5]->{$_} } keys %{$_[5]}
			};
		}
		else {
			push @p10_args, defined($_[5]) ? $_[5]/10 : undef;
		}
	}
	my $put10=put_price(@p10_args);
	ok(ae($put10,$put1));

	if($_[0]*$_[2]>0 && $_[3]>0) {
		my ($s, $e)=implied_volatility_call($_[0], $call1, @_[2..$#_]);
		ok(ae($s, $_[1], 2.0*$e/$tol));
		$s=implied_volatility_put($_[0], $put1, @_[2..$#_]);
		ok(ae($s, $_[1], 2.0*$e/$tol));
	}
	else {
		ok(1); ok(1);
	}

	return 1;
}

sub checkwarn {
	my $w;
	local($SIG{__WARN__})=sub { $w=1; };
	check(@_);
	ok($w);
}

# Each call to check() is 11 ok()'s.
check(1.65382, 1.45777, 10, 0.4, 10, 1, 0.03, 0.01); #1-11
check(3.14596, 2.94991, 10, 0.8, 10, 1, 0.03, 0.01); #12-22
check(2.13108, 0.96459, 10, 0.4, 9, 1, 0.03, 0.01); #23-33
check(1.16364, 1.06464, 10, 0.4, 10, 0.5, 0.03, 0.01); #34-44
check(1.78436, 1.30150, 10, 0.4, 10, 1, 0.06, 0.01); #45-55
check(1.59531, 1.49778, 10, 0.4, 10, 1, 0.03, 0.02); #56-66
check(0.96459, 2.13108, -10, 0.4, -9, 1, 0.03, 0.01); #67-77
check(4.30010, 0.046282, 34.25, 0.668419, 30, 0.01369, 0.015, 0.005); #78-88
check(1.97414, 0.05, 24.41, 0.228478, 22.5, 0.0657, 0.015, 0.005); #89-99

check(1.71387, 1.41833, 10, 0.4, 10, 1, 0.03, 0); #100-110
check(1.71387, 1.41833, 10, 0.4, 10, 1, 0.03, undef); #111-121
check(1.71387, 1.41833, 11.95556, 0.4, 10, 1, 0.03, {0.5=>1, 1.0=>1}); #122-132
check(1.71387, 1.41833, 10, 0.4, 10, 1, 0.03); #133-143
check(1.15278, 51.8, 28.30, 0.72524, 80, 1.00274, 0.015, 0.005); # 144-154

# Each call to checkwarn() is 12 ok()'s.
checkwarn( 0, 0, 10, -0.4, 10, 0, 0.03, 0.01); #155-166
checkwarn(20, 0, 10, 0.4, -10, 0, 0.03, 0.01); #167-178
checkwarn( 0, 0, 10, 0.4, 10, 0, -0.03, 0.01); #179-190
checkwarn( 0, 0, 10, 0.4, 10, 0, 0.03, -0.01); #191-202
checkwarn(1.65382, 1.45777, 10, 0.4, 10, 1, 0.03, 0.01, 999); #203-214
checkwarn(1.71387, 1.41833, 11.01511, 0.4, 10, 1, 0.03, {-0.5=>1}); #215-226


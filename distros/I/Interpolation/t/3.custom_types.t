#!perl -T
no warnings 'uninitialized';
use Test::More tests => 39;

BEGIN {
	use_ok( 'Interpolation' );
}

diag( "Testing Interpolation $Interpolation::VERSION, Perl $], $^X" );


{	my $count = 0;
	use Interpolation 'count:->$' => sub {if (@_) {$count = $_[0]} else {$count++}};
}

is("$count", 0, "Testing Interpolation::Scalar ('name:->\$' => ...)");
is("$count", 1);
is("$count", 2);
$count = 50;
is("$count", 50);
is("$count", 51);
untie $count;

{	my %count;
	ok( (import Interpolation 'count:$->$' => sub {
		if (@_ == 2) {
			$count{$_[0]} = $_[1]
		} else {
			$count{$_[0]}++
		}
	}), "Testing Interpolation ('name:\$->\$' => ...)");
}
is("$count{a}", 0);
is("$count{a}", 1);
is("$count{a}", 2);
is("$count{b}", 0);
is("$count{b}", 1);
$count{a} = 50;
is("$count{a}", 50);
is("$count{a}", 51);
is("$count{b}", 2);
untie %count;

ok( (import Interpolation 'list:$->@' => sub { (1..$_[0]) }), "Testing Interpolation ('name:\$->\@' => ...)");
is("$list{3}", "1 2 3");
is("$list{5}", "1 2 3 4 5");
untie %list;

{	my %List;
	ok( (import Interpolation 'list:$->@' => sub {
		if (@_ == 2) {
			$List{$_[0]} = $_[1];
			0 .. $List{$_[0]};
		} else {
			0 .. $List{$_[0]}++;
		}
	}), "Testing Interpolation ('name:\$->\@' => ...) assignment");
}
is("$list{a}", "0");
is("$list{a}", "0 1");
is("$list{a}", "0 1 2");
$list{a} = 5;
is("$list{a}", "0 1 2 3 4 5");
untie %list;

ok( (import Interpolation 'sum:@->$' => sub {
	my $sum = 0;
	$sum += $_ for @_;
	return $sum;
}), "Testing Interpolation ('name:\@->\$' => ...)");
is("$sum{1}", 1);
is("$sum{2,3}", 5);
is("$sum{5,1,2,8}", 16);
untie %sum;

ok( (import Interpolation 'reverse:@->@' => sub {
	return reverse(@_);
}), "Testing Interpolation ('name:\@->\@' => ...)");
is("$reverse{2,3}", "3 2");
is("$reverse{5,1,2,8}", "8 2 1 5");
untie %reverse;

ok( (import Interpolation 'sum:$*->$' => sub {
	my $sum = 0;
	$sum += $_ for @_;
	return $sum;
}), "Testing Interpolation ('name:\$*->\$' => ...)");
is("$sum{1}", 1);
is("$sum{2}{3}", 5);
is("$sum{5}{1}{2}{8}", 16);
is("$sum{5}{1}{2}{8}{$;}", 16);
untie %sum;

ok( (import Interpolation 'reverse:\@*->$' => sub {
	my $result = '';
	for (@_) {
		$result .= '(' . join(',', reverse @$_) . ')';
	}
	return $result;
}), "Testing Interpolation ('name:\\\@*->\$' => ...)");
is("$reverse{2,3}", "(3,2)");
is("$reverse{5,1}{2,8}", "(1,5)(8,2)");
is("$reverse{5,1}{9}{2,8}", "(1,5)(9)(8,2)");
untie %reverse;

#!perl -T
use strict;
use Test::More tests => 39;
no warnings 'uninitialized';

BEGIN {
	use_ok( 'Interpolation' );
}

diag( "Testing Interpolation $Interpolation::VERSION, Perl $], $^X" );


{
	my %count;
	{	my %cnt;
		ok( (tie %count, 'Interpolation', '$->$' => sub {
			if (@_ == 2) {
				$cnt{$_[0]} = $_[1]
			} else {
				$cnt{$_[0]}++
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
}
{
	our %count;
	is("$count{a}", "");
}

{
	my %list;
	ok( (tie %list, 'Interpolation', '$->@' => sub { (1..$_[0]) }), "Testing Interpolation ('name:\$->\@' => ...)");
	is("$list{3}", "1 2 3");
	is("$list{5}", "1 2 3 4 5");
}
{
	our %list;
	is("$list{a}", "");
}

{
	my %list;
	{	my %List;
		ok( (tie %list, 'Interpolation', '$->@' => sub {
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
}
{
	our %list;
	is("$list{a}", "");
}

{
	my %sum;
	ok( (tie %sum, 'Interpolation', '@->$' => sub {
		my $sum = 0;
		$sum += $_ for @_;
		return $sum;
	}), "Testing Interpolation ('name:\@->\$' => ...)");
	is("$sum{1}", 1);
	is("$sum{2,3}", 5);
	is("$sum{5,1,2,8}", 16);
}
{
	our %sum;
	is("$sum{2}", "");
	is("$sum{2}{6}", "");
}


{
	my %reverse;
	ok( (tie %reverse, 'Interpolation', '@->@' => sub {
		return reverse(@_);
	}), "Testing Interpolation ('name:\@->\@' => ...)");
	is("$reverse{2,3}", "3 2");
	is("$reverse{5,1,2,8}", "8 2 1 5");
}


{
	my %sum;
	ok( (tie %sum, 'Interpolation', '$*->$' => sub {
		my $sum = 0;
		$sum += $_ for @_;
		return $sum;
	}), "Testing Interpolation ('name:\$*->\$' => ...)");
	is("$sum{1}", 1);
	is("$sum{2}{3}", 5);
	is("$sum{5}{1}{2}{8}", 16);
	is("$sum{5}{1}{2}{8}{$;}", 16);
}


{
	my %reverse;
	ok( (tie %reverse, 'Interpolation', '\@*->$' => sub {
		my $result = '';
		for (@_) {
			$result .= '(' . join(',', reverse @$_) . ')';
		}
		return $result;
	}), "Testing Interpolation ('name:\\\@*->\$' => ...)");
	is("$reverse{2,3}", "(3,2)");
	is("$reverse{5,1}{2,8}", "(1,5)(8,2)");
	is("$reverse{5,1}{9}{2,8}", "(1,5)(9)(8,2)");
}
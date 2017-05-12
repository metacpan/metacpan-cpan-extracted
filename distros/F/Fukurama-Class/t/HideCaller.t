#!perl -T
use Test::More tests => 37;
use strict;
use warnings;

BEGIN {
	eval("use Fukurama::Class::HideCaller();Fukurama::Class::HideCaller->register_class('main')");
	main::like($@, qr/Wrong usage/);
}
use Fukurama::Class::HideCaller;


{
	package MyWrapper;
	sub test {
		main::test(@_);
	}
}
sub test {
	
	is($_[0], 1, 'first param');
	is(scalar(@_), 4, 'param length');
	my @c = caller();
	is($c[0], $_[1], 'caller is ok');
	
	no warnings;
	my $i = 0;
	my @last = ();
	while(my @s = caller($i++)) {
		@last = @s;
	}
	is($last[3], $_[3], 'first caller');
	is($i - 1, $_[2], 'caller stack length');
	2;
}

is(test(1, 'main', 1, 'main::test'), 2, 'normal call result');
is(MyWrapper::test(1, 'MyWrapper', 2, 'MyWrapper::test'), 2, 'normal wrapped call result');

Fukurama::Class::HideCaller->register_class('MyWrapper');

is(test(1, 'main', 1, 'main::test'), 2, 'hide normal call result');
is(MyWrapper::test(1, 'main', 1, 'main::test'), 2, 'hide wrapped call result');

$Fukurama::Class::HideCaller::DISABLE = 1;

is(test(1, 'main', 1, 'main::test'), 2, 'normal call result');
is(MyWrapper::test(1, 'MyWrapper', 2, 'MyWrapper::test'), 2, 'normal wrapped call result');

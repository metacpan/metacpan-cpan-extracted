use warnings;
use strict;

use Test::More;
BEGIN {
	plan skip_all => "bare subs impossible on this perl"
		if "$]" < 5.011002;
}
plan tests => 6;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

is eval q{
	use Lexical::Sub foo => sub () { my $x=123 };
	foo();
}, 123;

# test that non-constant foo() is not a const op
eval q{
	use Lexical::Sub foo => sub () { my $x=123 };
	foo() = 456;
	die;
};
like $@, qr/\ACan't modify non-lvalue subroutine call /;

# test that non-constant foo() does not participate in constant folding
eval q{
	die;
	use Lexical::Sub foo => sub () { my $x=123 };
	!foo() = 456;
};
like $@, qr/\ACan't modify not /;

is eval q{
	use Lexical::Sub foo => sub () { 123 };
	foo();
}, 123;

# test that constant foo() is a const op
eval q{
	die;
	use Lexical::Sub foo => sub () { 123 };
	foo() = 456;
};
like $@, qr/\ACan't modify constant item /;

# test that constant foo() participates in constant folding
eval q{
	die;
	use Lexical::Sub foo => sub () { 123 };
	!foo() = 456;
};
like $@, qr/\ACan't modify constant item /;

1;

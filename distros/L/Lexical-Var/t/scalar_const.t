use warnings;
use strict;

use Test::More tests => 12;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

is eval q{
	use Lexical::Var '$foo' => \(my $x=123);
	$foo;
}, 123;

# test that non-constant defined $foo is not a const op
eval q{
	die;
	use Lexical::Var '$foo' => \(my $x=123);
	$foo = 456;
};
like $@, qr/\ADied /;

# test that non-constant defined $foo does not participate in constant folding
eval q{
	die;
	use Lexical::Var '$foo' => \(my $x=123);
	!$foo = 456;
};
like $@, qr/\ACan't modify not /;

is eval q{
	use Lexical::Var '$foo' => \123;
	$foo;
}, 123;

# test that constant defined $foo is a const op
eval q{
	die;
	use Lexical::Var '$foo' => \123;
	$foo = 456;
};
like $@, qr/\ACan't modify constant item /;

# test that constant defined $foo participates in constant folding
eval q{
	die;
	use Lexical::Var '$foo' => \123;
	!$foo = 456;
};
like $@, qr/\ACan't modify constant item /;

is_deeply eval q{
	use Lexical::Var '$foo' => \(my $x=undef);
	[$foo];
}, [undef];

# test that non-constant undef $foo is not a const op
eval q{
	die;
	use Lexical::Var '$foo' => \(my $x=undef);
	$foo = 456;
};
like $@, qr/\ADied /;

# test that non-constant undef $foo does not participate in constant folding
eval q{
	die;
	use Lexical::Var '$foo' => \(my $x=undef);
	!$foo = 456;
};
like $@, qr/\ACan't modify not /;

is eval q{
	use Lexical::Var '$foo' => \undef;
	$foo;
}, undef;

# test that constant undef $foo is a const op
eval q{
	die;
	use Lexical::Var '$foo' => \undef;
	$foo = 456;
};
like $@, qr/\ACan't modify constant item /;

# test that constant undef $foo participates in constant folding
eval q{
	die;
	use Lexical::Var '$foo' => \undef;
	!$foo = 456;
};
like $@, qr/\ACan't modify constant item /;

1;

use warnings;
use strict;

use Test::More tests => 11;

eval q{
	use Lexical::Import qw(t::Exp1-1.00 foo);
	die unless foo() eq "FOO";
};
is $@, "";

eval q{
	use Lexical::Import qw(t::Exp1-1.20 foo);
	die unless foo() eq "FOO";
};
like $@, qr/\At::Exp1 version 1\.20? required--this is only version 1\.10/;

eval q{
	use Lexical::Import qw(t::Exp1-v1.0.0 foo);
	die unless foo() eq "FOO";
};
is $@, "";

eval q{
	use Lexical::Import qw(t::Exp1-v1.900.0 foo);
	die unless foo() eq "FOO";
};
like $@, qr/\At::Exp1 version v1\.900\.0 required--this is only version /;

eval q{
	use Lexical::Import qw(t::Exp0-1.00 successor);
	die unless successor(5) == 6;
};
like $@, qr/\At::Exp0 does not define \$t::Exp0::VERSION--/;

eval q{
	use Lexical::Import qw(t::Exp0-0 successor);
	die unless successor(5) == 6;
};
like $@, qr/\At::Exp0 does not define \$t::Exp0::VERSION--/;

eval q{
	use Lexical::Import qw(t::Exp2);
	die if defined(&successor);
	die if defined(&predecessor);
};
is $@, "";

eval q{
	use Lexical::Import qw(t::Exp2-0);
};
like $@, qr/\Aunrecognised version for importation/;

eval q{
	use Lexical::Import qw(t::Exp2-1);
	die unless successor(5) == 6;
	die if defined(&predecessor);
};
is $@, "";

eval q{
	use Lexical::Import qw(t::Exp2-2);
	die if defined(&successor);
	die unless predecessor(6) == 5;
};
is $@, "";

eval q{
	use Lexical::Import qw(t::Exp2-3);
};
like $@, qr/\Aunrecognised version for importation/;

1;

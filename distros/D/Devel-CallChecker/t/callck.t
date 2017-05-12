use warnings;
use strict;

use Test::More tests => 79;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callchecker0", "t", "callck");
ok 1;
require_ok "Devel::CallChecker";
t::LoadXS::load_xs("callck", "t", [Devel::CallChecker::callchecker_linkable()]);
ok 1;

t::callck::test_cv_getset_call_checker();
ok 1;

my @z = ();
my @a = qw(a);
my @b = qw(a b);
my @c = qw(a b c);

my($foo_got, $foo_ret);
sub foo($@) { $foo_got = [ @_ ]; return "z"; }

sub bar (\@$) { }
sub baz { }

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ 2, qw(a b c) ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = &foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_lists(\&foo);

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = &foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_scalars(\&foo);

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ 2, 3 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c, @a, @c);};
is $@, "";
is_deeply $foo_got, [ 2, 3, 1, 3 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = foo(@b);};
is $@, "";
is_deeply $foo_got, [ 2 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = foo();};
is $@, "";
is_deeply $foo_got, [];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = &foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, "\\\@\$");
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ \@b, 3 ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, undef);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
like $@, qr/ with no proto[ ,]/;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, \&bar);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ \@b, 3 ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, \&baz);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
like $@, qr/ with no proto[ ,]/;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, "\$");
$foo_got = undef;
eval q{$foo_ret = foo();};
like $@, qr/\ANot enough arguments for main::foo /;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto(\&foo, "\$");
$foo_got = undef;
eval q{$foo_ret = foo(1,2);};
like $@, qr/\AToo many arguments for main::foo /;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, "\\\@\$");
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ \@b, 3 ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, undef);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, \&bar);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ \@b, 3 ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, \&baz);
$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, [ qw(a b), qw(a b c) ];
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, "\$");
$foo_got = undef;
eval q{$foo_ret = foo();};
like $@, qr/\ANot enough arguments for main::foo /;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_proto_or_list(\&foo, "\$");
$foo_got = undef;
eval q{$foo_ret = foo(1,2);};
like $@, qr/\AToo many arguments for main::foo /;
is_deeply $foo_got, undef;
is $foo_ret, "z";

t::callck::cv_set_call_checker_multi_sum(\&foo);

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c);};
is $@, "";
is_deeply $foo_got, undef;
is $foo_ret, 5;

$foo_got = undef;
eval q{$foo_ret = foo(@b);};
is $@, "";
is_deeply $foo_got, undef;
is $foo_ret, 2;

$foo_got = undef;
eval q{$foo_ret = foo();};
is $@, "";
is_deeply $foo_got, undef;
is $foo_ret, 0;

$foo_got = undef;
eval q{$foo_ret = foo(@b, @c, @a, @c);};
is $@, "";
is_deeply $foo_got, undef;
is $foo_ret, 9;

1;

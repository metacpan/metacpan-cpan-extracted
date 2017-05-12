use warnings;
use strict;

our $cb;

BEGIN {
	eval {
		require ExtUtils::CBuilder;
		ExtUtils::CBuilder->VERSION(0.280209);
	};
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all =>
			"working ExtUtils::CBuilder unavailable");
	}
	$cb = ExtUtils::CBuilder->new(quiet => 1);
	unless($cb->have_compiler) {
		require Test::More;
		Test::More::plan(skip_all => "compiler unavailable");
	}
	eval { require File::Spec };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "File::Spec unavailable");
	}
}

use Test::More tests => 6;

BEGIN {
	use_ok "DynaLoader::Functions", qw(dyna_load dyna_resolve dyna_unload);
}

our @todelete;
END { unlink @todelete; }

my $c_file = File::Spec->catdir("t", "dyna_low.c");
my $o_file = $cb->compile(source => $c_file);
push @todelete, $o_file;
my($so_file, @so_tmps) =
	$cb->link(objects => [$o_file], module_name => "t::dyna_low",
		dl_func_list => [qw(dynalow_foo dynalow_bar)],
		dl_funcs => { "t::dyna_low" => [] });
push @todelete, $so_file, @so_tmps;

my $libh = dyna_load($so_file, { require_symbols => ["dynalow_foo"] });
ok 1;

ok(defined(dyna_resolve($libh, "dynalow_foo", {unresolved_action=>"IGNORE"})));
ok(defined(dyna_resolve($libh, "dynalow_bar", {unresolved_action=>"IGNORE"})));
ok(!defined(dyna_resolve($libh, "dynalow_baz", {unresolved_action=>"IGNORE"})));

dyna_unload($libh, {fail_action=>"IGNORE"});
ok 1;

1;

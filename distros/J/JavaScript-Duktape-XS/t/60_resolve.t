use strict;
use warnings;

use Test::More;
use Test::Exception;

my $CLASS = 'JavaScript::Duktape::XS';

use constant SUCCESSFUL_REQUIRE => <<'EOF';
var p = require('find_it');
'require successful';
EOF

use constant FAILED_REQUIRE => <<'EOF';
var retval;
try {
	require('not_there');
} catch(e) {
	retval = 'Perl exception: ' + e.message;
}
retval;
EOF

sub module_resolve {
	my ($requested_id, $parent_id) = @_;

	my $module_name = sprintf("%s.js", $requested_id);
	
	return $module_name;
}

sub module_load {
	my ($module_name, $exports, $module) = @_;

	if ('find_it.js' eq $module_name) {
		return 'module.exports = "found it";';
	} else {
		die "module not found\n";
	}
}

sub create_duktape {
	my (%options) = @_;

	my $vm = $CLASS->new({%options});
	$vm->set(perl_module_resolve => \&module_resolve);
	$vm->set(perl_module_load => \&module_load);

	return $vm;
}

sub test_successful_require {
	my $vm = create_duktape;

	is $vm->eval(SUCCESSFUL_REQUIRE), 'require successful', 'success';
}

sub test_failed_require {
	my $vm = create_duktape;

	eval { $vm->eval(FAILED_REQUIRE) };
	is $@, "Perl sub died with error: module not found\n", 'failed require';
}

sub test_failed_require_caught {
	my $vm = create_duktape(catch_perl_exceptions => 1);

	my $retval = eval { $vm->eval(FAILED_REQUIRE) };
	ok !$@, "nothing thrown";
	is $retval, "Perl exception: module not found\n",
		'failed require caught';
}

sub main {
	use_ok($CLASS);

	test_successful_require;
	test_failed_require;
	test_failed_require_caught;

	done_testing;

	return 0;
}

exit main();

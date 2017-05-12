# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Die qw(err);
use Error::Pure::Utils qw(clean err_get);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
@Error::Pure::Utils::ERRORS = qw(FOO BAR);
my @ret = err_get();
is_deeply(
	\@ret,
	[
		'FOO',
		'BAR',
	],
	'Simple test.',
);
is_deeply(
	\@Error::Pure::Utils::ERRORS,
	[
		'FOO',
		'BAR',
	],
	'@ERRORS variable control.',
);

# Test.
@ret = err_get(1);
is_deeply(
	\@ret,
	[
		'FOO',
		'BAR',
	],
	'Simple test. With cleaning.',
);
is_deeply(
	\@Error::Pure::Utils::ERRORS,
	[],
	'Cleaning control.',
);

# Test.
clean();
my $eval_string = <<'END';
	my $x = 'abc abc abc abc abc abc abc abc abc abc abc abc';
	$x = 'dba dba dba dba dba dba dba dba dba dba dba dba';
	err 'Error.';
END
eval $eval_string;
my @err = err_get();
my $print_eval_string = $eval_string;
$print_eval_string =~ s/([\'])/\\$1/gsm;
substr $print_eval_string, 100, -1, '...';
is($err[0]->{'stack'}->[1]->{'sub'}, "eval '$print_eval_string'",
	'Eval message trim after 100 chars.');

# Test.
clean();
$Error::Pure::Utils::MAX_EVAL = '10';
eval $eval_string;
@err = err_get();
$print_eval_string = $eval_string;
$print_eval_string =~ s/([\'])/\\$1/gsm;
substr $print_eval_string, 10, -1, '...';
is($err[0]->{'stack'}->[1]->{'sub'}, "eval '$print_eval_string'", 
	'Eval message trim after 10 chars.');

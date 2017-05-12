# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
@Error::Pure::Utils::ERRORS = qw(XXX);
clean();
is_deeply(
	\@Error::Pure::Utils::ERRORS,
	[],
	'Simple test.',
);

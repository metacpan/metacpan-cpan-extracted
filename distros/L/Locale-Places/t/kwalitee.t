use strict;
use warnings;

use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval { require Test::Kwalitee; Test::Kwalitee->import(); };

	plan(skip_all => 'Test::Kwalitee not installed; skipping') if $@;

	unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
} else {
	plan(skip_all => 'Author tests not required for installation');
}

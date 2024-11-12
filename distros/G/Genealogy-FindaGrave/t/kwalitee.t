use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

eval "use Test::Kwalitee tests => [ qw( -has_meta_yml ) ]";

if($@) {
	plan(skip_all => 'Test::Kwalitee not installed; skipping') if $@;
} else {
	unlink('Debian_CPANTS.txt') if -e 'Debian_CPANTS.txt';
}

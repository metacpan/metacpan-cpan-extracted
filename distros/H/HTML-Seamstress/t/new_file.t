use strict;
use warnings;
use Test::More qw(no_plan);

use HTML::Seamstress;

my $t = HTML::Seamstress->new_file(
	't/html/new_file/new_file.html',
	store_comments => 1
	);

warn $t->as_HTML('  ');

my $t = HTML::Seamstress->new_file(
	't/html/new_file/guts.html',
	guts => 1
	);

warn $t->as_HTML('  ');

my $t = HTML::Seamstress->new_file(
	't/html/new_file/guts.html',
	);

warn $t->as_HTML('  ');

ok 1;


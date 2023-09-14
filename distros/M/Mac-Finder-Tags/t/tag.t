#!perl
use strict;
use warnings;
use lib qw(lib);

use Test::More 0.88;
use Test::Warnings 0.010 qw(warning :no_end_test);
my $no_warnings;
use if $no_warnings = $ENV{AUTHOR_TESTING} ? 1 : 0, 'Test::Warnings';

plan tests => 12 + 3 + $no_warnings;


use Mac::Finder::Tags;


my ($ft, $t, $w);

$ft = Mac::Finder::Tags->new( caching => 0 );


# common cases
$t = $ft->tag('Important', 'red');
is $t->name, 'Important', 'tag name';
is $t->color, 'red', 'tag color';
is $t->flags, 6, 'tag flags';
is $t->emoji, "\x{1F534}", 'tag emoji';

$t = $ft->tag('Special');
is $t->name, 'Special', 'tag name color undef';
is $t->color, undef, 'tag color undef';
is $t->flags, undef, 'tag flags undef';
is $t->emoji, '', 'tag emoji empty';

$t = $ft->tag('New', 2);
is $t->color, 'green', 'tag flags color green';
is $t->emoji, "\x{1F7E2}", 'tag emoji';

$t = $ft->tag('Client data', 0);
is $t->color, '', 'tag flags no color';
is $t->emoji, "\x{26AA}\x{FE0F}", 'tag emoji no color';


# illegal input
$w = warning { $t = $ft->tag('Info', 8) };
like $w, qr/\bUnkown color\b/i, 'unkown color 8'
	or diag 'got warning(s): ', explain $w;
is $t->color, '8', 'tag flags no color';
is $t->flags, 0, 'tag flags no color';


done_testing;

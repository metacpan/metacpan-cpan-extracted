use strict;
use Test::More tests => 3;

use Lingua::EN::Keywords::Yahoo qw(keywords);

my @terms;
my $content  = "Italian sculptors and painters of the renaissance favored the Virgin Mary for inspiration.";
my @expected = sort { $a cmp $b } ('italian sculptors','virgin mary', 'painters', 'renaissance', 'inspiration');
ok(@terms = sort({ $a cmp $b } keywords($content)), "Got terms");

is(scalar(@terms), scalar(@expected), "Same number of terms");
is(join(' ',@terms),join(' ',@expected), "Terms are the same");



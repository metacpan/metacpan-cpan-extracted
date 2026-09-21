use warnings;
use strict;
use lib '.';

use Test::More tests => 7;

# Loading this module must not change how "my" scopes. With the keyword
# plugin installed, every keyword it declines (if, while, print, my
# itself) has allocated and freed a pad slot; a block opened right after
# one must still close the lexicals declared inside it. Before 0.005 the
# first "my" of such a block stayed visible after the block on ithreads
# perls, masking an outer lexical of the same name.

use Devel::CallParser ();

# the shadowing warning is a compile-time one: catch it from here on
our @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, $_[0] } }

my $if = "outer";
if (1) { my $if = "inner"; }
is $if, "outer", "a my inside an if block ends with the block";

my $bare = "outer";
{ my $bare = "inner"; }
is $bare, "outer", "and inside a bare block";

my @seen;
my @l = ("a", "b");
while (my $x = shift @l) {
	if (1) { my $x = "inner"; }
	push @seen, $x;
}
is_deeply \@seen, ["a", "b"], "the loop variable survives an inner block";

my $ok = 0;
sub tsub {
	my $v = "outer";
	if (1) { my $v = "inner"; }
	$ok = $v eq "outer";
}
tsub();
ok $ok, "the same inside a sub";

my $nested = "outer";
if (1) { if (1) { my $nested = "inner"; } }
is $nested, "outer", "and two blocks deep";

# a second declaration of the same name after the block is in a new
# scope relative to the block's, not the same one
my $again = 1;
if (1) { my $again = 2; }
{ my $again = 3; is $again, 3, "a later block declares its own"; }

is scalar(@warnings), 0, "no shadowing warning was emitted"
	or diag @warnings;

1;

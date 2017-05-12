use strict;
use warnings;
use Test::More 'no_plan';

sub foo { $_[0] = $_[1]; (); }

sub bar { is($_[0], 'yay', 'Var set ok by sub'); (); }

sub baz { () }

sub quux { is($_[0], 'w00t', 'Var set ok by ='); (); }

use Devel::BeginLift qw(foo bar baz quux);

foo(my $meep, 'yay');

bar($meep);

baz(my $lolz = 'w00t');

quux($lolz);

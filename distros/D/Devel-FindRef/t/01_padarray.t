BEGIN { $| = 1; print "1..1\n"; }

use Devel::FindRef;

sub xx {
   \my $x
}

my $y = xx;

Devel::FindRef::track $y;

print "ok 1\n";

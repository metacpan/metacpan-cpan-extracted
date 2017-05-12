#!perl -T

use Test::More tests => 7;

# --------------------------------------------------------------------------------------
# The other thing Semantic::Code can do is to define events.  Events only run when they
# trigger - that is, "start" won't run anything that's an event.
# --------------------------------------------------------------------------------------
use Decl qw(-nofilter Decl::Semantics);

$tree = Decl->new();

$tree->load (<<'EOF');

value variable ""

on event1 "" {
   $^variable += 1;
}
 
do "This is some random code" {
   my $something = 2;
   $^variable = $something + 1;
}

on event2 {
   $^variable = 0;
}

on event3 {
   $^variable += 2;
   ^!event1;
   ^!event1;
}

on set [stuff] {
   $^variable = $stuff;
}

EOF

# All right, that should be easy!

$tree->start();


is ($tree->value('variable'), 3);   # So far, so good.

$tree->do('event2');
is ($tree->value('variable'), 0);

$tree->do('event1');
is ($tree->value('variable'), 1);

$tree->do('event3');
is ($tree->value('variable'), 5);

$tree->do('event1');
is ($tree->value('variable'), 6);

$tree->do('set bing!');
is ($tree->value('variable'), 'bing!');

$tree->do('set "hi there"');
is ($tree->value('variable'), 'hi there');
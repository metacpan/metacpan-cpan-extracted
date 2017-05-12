#! /usr/bin/perl -w

# The internal &hand_print sub can be optionally exported to handle
# special output requirements...

use IO::Prompt 'hand_print';

hand_print "Now is the winter of\n";
hand_print { -speed => 0.25 }, "our discontent made ", { -speed => 0.5 },
  "glorious\n", { -speed => 0.15 }, "summmer by this son of York\n"

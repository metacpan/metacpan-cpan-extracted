#! /usr/bin/perl -w

# Variations on the yes/no theme...
#

use IO::Prompt;

1 until prompt(-YN1,    "Continue char (Y/N): ");
1 until prompt(-yn1,    "Continue char (y/n): ");
1 until prompt(-yesno1, "Continue char (y/n): ");
1 until prompt(-yes1,   "Continue char (y/*): ");
1 until prompt(-YES1,   "Continue char (Y/*): ");
1 until prompt(-Y1,     "Continue char (Y/*): ");
1 until prompt(-yn,     "Continue line (y/n): ");
1 until prompt(-yes,    "Continue line (y/*): ");
1 until prompt(-YN,     "Continue line (Y/N): ");
1 until prompt(-Y,      "Continue line (Y/*): ");

print "Done\n";

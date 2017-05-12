#! /usr/bin/perl -w

use IO::Prompt;
use Data::Dumper 'Dumper';

if (prompt -clearfirst, -escape, "first> ", -line) {
    warn Dumper [ $_ ];
}

# Should not wipe screen, since previous call already did...

while (prompt -clearfirst, " next> ", -line) {
    warn Dumper [ $_ ];
}

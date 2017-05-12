#! /usr/bin/perl -w

# Basic example...

use IO::Prompt;

while (prompt "next: ") {
    print "You said '$_'\n";
}

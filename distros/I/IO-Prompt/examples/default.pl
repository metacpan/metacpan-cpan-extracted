#! /usr/bin/perl -w

# Yes/no input only, with defaults set...

use IO::Prompt;

until (prompt "yes? ", -default => "N", -YN1) {
    print "That's a 'no'\n";
}

while (0 + prompt "next: ", -d => "-1") {
    print "That's non-zero\n";
}

while (prompt "****: ", -d => "secret", -e => '*') {
    print "That's '$_'\n";
}
print "\n";

while (prompt "**** [or default]: ", -d => "secret", -e => '*') {
    print "That's '$_'\n";
}

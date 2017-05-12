#! /usr/bin/perl -w

# The -while and -until flags control whether &prompt returns true on a given
# input...

use IO::Prompt;

while (prompt "first while digit: ", -while => qr/\d/) {
    print "You said '$_'\n";
}

while (prompt "second until digit: ", -until => qr/\d/) {
    print "You said '$_'\n";
}

while (
    prompt "third while digit (not zero): ",
    -while => qr/\d/,
    -until => qr/0/
  )
{
    print "You said '$_'\n";
}

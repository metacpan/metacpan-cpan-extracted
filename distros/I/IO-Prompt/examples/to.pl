#! /usr/bin/perl -w

# A filehandle in the argument list causes the prompt to be sent to
# that filehandle, rather than to the terminal...
#

use IO::Prompt;

open my $fh, '>/dev/null' or die $!;

print "No prompt should appear here... (type anything)\n";
if (prompt $fh, "> ", -line) {
    print;
}

if (prompt \*STDERR, "type some more> ", -line) {
    print;
}

use IO::File;
$fh = new IO::File, "<$0" or die $!;

print "This should fail at line ", __LINE__ + 1,
  " (read-only filehandle)...\n";
if (prompt $fh, "> ", -line) {
    print;
}

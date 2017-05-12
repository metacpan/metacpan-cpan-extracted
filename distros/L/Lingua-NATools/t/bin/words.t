#!/usr/bin/perl

use warnings;
use strict;

our $CTESTS = 5;
our $PERLTESTS = 1;
our $NTESTS = $CTESTS + $PERLTESTS;

print "1..$NTESTS\n";

if (system("./t/bin/words")) {
    nok();
} else {
    ok();
}

unlink "t/bin/words.output.bin" if -f "t/bin/words.output.bin";

sub nok { print "n",ok() }
sub ok  { print "ok ",++$CTESTS,"\n" }

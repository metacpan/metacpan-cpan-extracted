#!/usr/local/bin/perl

use strict;
use warnings;
use Test;
BEGIN { plan tests => 6 };

use Locale::MakePhrase::Utils qw(
  is_number
  left
  right
  alltrim
  die_from_caller
);
ok(1);

$Locale::MakePhrase::Utils::DEBUG = 0;



ok(is_number(-1.3)) or print "Bail out! -1.3 was not detected as a number.\n";
ok(not is_number("hi there")) or print "Bail out! 'hi there' was detected as a number.\n";

ok(left("hi there",2) eq "hi") or print "Bail out! Function 'left()' is broken.\n";
ok(right("hi there",5) eq "there") or print "Bail out! Function 'right()' is broken.\n";
ok(alltrim(" hi there   ") eq "hi there") or print "Bail out! Function 'alltrim()' is broken.\n";

## Note that its a little hard to test die_from_caller here...


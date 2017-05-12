
require 5;
# Time-stamp: "2005-01-05 16:46:57 AST"
use strict;
use Test;

BEGIN { plan tests => 18 }

use Lingua::EN::Numbers;
ok 1;

print "# Using Lingua::EN::Numbers v$Lingua::EN::Numbers::VERSION\n";

sub N { Lingua::EN::Numbers::num2en($_[0]) }

ok N(0), "zero";
ok N('0'), "zero";
ok N('-0'), "negative zero";
ok N('0.0'), "zero point zero";
ok N('.0'), "point zero";
ok N(1), "one";
ok N(2), "two";
ok N(3), "three";
ok N(4), "four";
ok N(40), "forty";
ok N(42), "forty-two";


ok N(400), "four hundred";
ok N('0.1'), "zero point one";
ok N('.1'), "point one";
ok N('.01'), "point zero one";


ok N('4003'), "four thousand and three";

print "# OK, that's it.\n";
ok 1;


use strict;
use Test;
BEGIN { plan tests => 60 }

use Lingua::EN::Numbers qw(num2en num2en_ordinal);
print "# Using Lingua::EN::Numbers v$Lingua::EN::Numbers::VERSION\n";
ok 1;

sub N ($) { num2en(        $_[0]) }
sub O ($) { num2en_ordinal($_[0]) }

ok N   0, 'zero';
ok N   1, 'one';
ok N   2, 'two';
ok N   3, 'three';
ok N   4, 'four';
ok N   5, 'five';
ok N   6, 'six';
ok N   7, 'seven';
ok N   8, 'eight';
ok N   9, 'nine';
ok N  10, 'ten';
ok N  11, 'eleven';
ok N  12, 'twelve';
ok N  13, 'thirteen';
ok N  14, 'fourteen';
ok N  15, 'fifteen';
ok N  16, 'sixteen';
ok N  17, 'seventeen';
ok N  18, 'eighteen';
ok N  19, 'nineteen';
ok N  20, 'twenty';
ok N  21, 'twenty-one';
ok N  22, 'twenty-two';
ok N  23, 'twenty-three';
ok N  24, 'twenty-four';
ok N  25, 'twenty-five';
ok N  26, 'twenty-six';
ok N  27, 'twenty-seven';
ok N  28, 'twenty-eight';
ok N  29, 'twenty-nine';
ok N  30, 'thirty';
ok N  99, 'ninety-nine';

ok N  103, 'one hundred and three';
ok N  139, 'one hundred and thirty-nine';

ok num2en_ordinal(133), 'one hundred and thirty-third';

ok N '3.14159', 'three point one four one five nine';
ok N '-123', 'negative one hundred and twenty-three';
ok N '+123', 'positive one hundred and twenty-three';
ok N '+123', 'positive one hundred and twenty-three';

ok N '0.0001', 'zero point zero zero zero one';
ok N '-14.000', 'negative fourteen point zero zero zero';

# and maybe even:
ok N '-1.53e34',  'negative one point five three times ten to the thirty-fourth';
ok N  -1.53e34,   'negative one point five three times ten to the thirty-fourth';
ok N '-1.53e+34', 'negative one point five three times ten to the thirty-fourth';
ok N '-1.53e-34', 'negative one point five three times ten to the negative thirty-fourth';
ok N '+19e009', 'positive nineteen times ten to the ninth';

ok N "263415", "two hundred and sixty-three thousand four hundred and fifteen";

ok N  "5001", "five thousand and one";
ok N "-5001", "negative five thousand and one";
ok N "+5001", "positive five thousand and one";

ok !defined N "abc";
ok !defined N "00.0.00.00.0.00.0.0";
ok N "1,000,000", "one million";
ok N "1,0,00,000", "one million";
ok !defined N "5 bananas";
ok !defined N "x5x";
ok !defined N "";
ok !defined N undef;

print "# Okay, seeya.\n";
ok 1;


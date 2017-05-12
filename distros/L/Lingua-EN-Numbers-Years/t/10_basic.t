
use strict;  # Time-stamp: "2005-01-05 18:03:07 AST"
use warnings;
use Test;

BEGIN { plan tests => 129 }

use Lingua::EN::Numbers 1.0 qw(num2en);
use Lingua::EN::Numbers::Years qw(year2en);

ok 1;
print "# Using Lingua::EN::Numbers v$Lingua::EN::Numbers::VERSION\n";
print "# Using Lingua::EN::Numbers::Years v$Lingua::EN::Numbers::Years::VERSION\n";

ok prototype('year2en'), '$';

ok year2en     0, "zero";
ok year2en     1, "one";
ok year2en     2, "two";
ok year2en     3, "three";
ok year2en     4, "four";
ok year2en     5, "five";
ok year2en     6, "six";
ok year2en     7, "seven";
ok year2en     8, "eight";
ok year2en     9, "nine";
ok year2en    10, "ten";
ok year2en    11, "eleven";
ok year2en    12, "twelve";
ok year2en    13, "thirteen";
ok year2en    20, "twenty";
ok year2en    21, "twenty-one";
ok year2en    22, "twenty-two";
ok year2en    23, "twenty-three";
ok year2en    80, "eighty";
ok year2en    81, "eighty-one";
ok year2en    82, "eighty-two";
ok year2en    83, "eighty-three";
ok year2en   101, "one oh one";
ok year2en   113, "one thirteen";
ok year2en   180, "one eighty";
ok year2en   173, "one seventy-three";

ok year2en   115, "one fifteen";
ok year2en   134, "one thirty-four";
ok year2en   360, "three sixty";
ok year2en   567, "five sixty-seven";
ok year2en   619, "six nineteen";
ok year2en   640, "six forty";
ok year2en  1586, "fifteen eighty-six";

ok year2en   100, "one hundred";
ok year2en   300, "three hundred";
ok year2en   900, "nine hundred";
ok year2en  1000, "one thousand";
ok year2en  1100, "eleven hundred";
ok year2en  1900, "nineteen hundred";
ok year2en  2000, "two thousand";

ok year2en  20010, "twenty thousand ten"; # I guess.  Or twenty thousand oh ten?
ok year2en  22003, "twenty-two oh oh three";
ok year2en  22010, "twenty-two oh ten";

ok year2en   101, "one oh one";
ok year2en   301, "three oh one";
ok year2en   901, "nine oh one";
ok year2en  1001, "one thousand one";
ok year2en  1101, "eleven oh one";
ok year2en  1901, "nineteen oh one";
ok year2en  2001, "two thousand one";
ok year2en  9001, "nine thousand one";
ok year2en  9301, "ninety-three oh one";
ok year2en  9901, "ninety-nine oh one";

ok year2en  3515, "thirty-five fifteen";
ok year2en  4183, "forty-one eighty-three";
ok year2en  4321, "forty-three twenty-one";
ok year2en  4373, "forty-three seventy-three";
ok year2en  4547, "forty-five forty-seven";
ok year2en  4617, "forty-six seventeen";
ok year2en  5087, "fifty eighty-seven";
ok year2en  6274, "sixty-two seventy-four";
ok year2en  6457, "sixty-four fifty-seven";
ok year2en  6622, "sixty-six twenty-two";
ok year2en  8166, "eighty-one sixty-six";
ok year2en  8383, "eighty-three eighty-three";
ok year2en  8648, "eighty-six forty-eight";
ok year2en  8944, "eighty-nine forty-four";
ok year2en  9222, "ninety-two twenty-two";
ok year2en  9304, "ninety-three oh four";
ok year2en 12145, "twelve one forty-five";
ok year2en 12231, "twelve two thirty-one";
ok year2en 12808, "twelve eight oh eight";
ok year2en 12969, "twelve nine sixty-nine";
ok year2en 13223, "thirteen two twenty-three";
ok year2en 13958, "thirteen nine fifty-eight";
ok year2en 13967, "thirteen nine sixty-seven";
ok year2en 14230, "fourteen two thirty";
ok year2en 14340, "fourteen three forty";
ok year2en 14407, "fourteen four oh seven";
ok year2en 14480, "fourteen four eighty";
ok year2en 15875, "fifteen eight seventy-five";
ok year2en 17031, "seventeen oh thirty-one";
ok year2en 17089, "seventeen oh eighty-nine";
ok year2en 17105, "seventeen one oh five";
ok year2en 17364, "seventeen three sixty-four";
ok year2en 17376, "seventeen three seventy-six";
ok year2en 17633, "seventeen six thirty-three";
ok year2en 18038, "eighteen oh thirty-eight";
ok year2en 43603, "forty-three six oh three";
ok year2en 44024, "forty-four oh twenty-four";
ok year2en 44433, "forty-four four thirty-three";
ok year2en 44610, "forty-four six ten";
ok year2en 45361, "forty-five three sixty-one";
ok year2en 46444, "forty-six four forty-four";
ok year2en 47131, "forty-seven one thirty-one";
ok year2en 47607, "forty-seven six oh seven";
ok year2en 51425, "fifty-one four twenty-five";
ok year2en 51754, "fifty-one seven fifty-four";
ok year2en 53280, "fifty-three two eighty";
ok year2en 54843, "fifty-four eight forty-three";
ok year2en 55258, "fifty-five two fifty-eight";
ok year2en 56082, "fifty-six oh eighty-two";

#
# And some troublesome cases:
#

ok year2en 10000, "ten thousand";
ok year2en -10001, "negative ten thousand one";
ok year2en 10001, "ten thousand one";
ok year2en 10015, "ten thousand fifteen";
ok year2en 10010, "ten thousand ten";
ok year2en 10100, "ten thousand one hundred";
ok year2en 10120, "ten thousand one twenty";
ok year2en 10123, "ten thousand one twenty-three";
ok year2en 10103, "ten thousand one oh three";
ok year2en 10705, "ten thousand seven oh five";
ok year2en 10710, "ten thousand seven ten";

ok year2en 60000, "sixty thousand";
ok year2en 60100, "sixty thousand one hundred";
ok year2en 60001, "sixty thousand one";
ok year2en 60015, "sixty thousand fifteen";
ok year2en 60705, "sixty thousand seven oh five";
ok year2en 61935, "sixty-one nine thirty-five";

ok year2en 99816, "ninety-nine eight sixteen";


# check comma:
ok year2en '99,816', "ninety-nine eight sixteen";


# And some very out of range cases:

ok !defined year2en undef;
ok !defined year2en '';
ok !defined year2en 'puppies';
ok year2en  '103,634', num2en('103,634');
ok year2en '-3.14159', num2en('-3.14159');



print "# OK, bye...\n";
ok 1;


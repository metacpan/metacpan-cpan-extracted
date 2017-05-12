# This file contains all the tests used to exercise the parser.

package Parse;
use strict;
use vars qw(%Tests);

# format:
# fields are separated by colons.
#   First: 3-digit test number
#   Second: cursor position
#   Third: test string
#   Result


# The tests to run
# Format: "index:cursorpos:inputstring" => result
%Tests = (
    "000::" => [[], undef, undef],
    "001::   " => [[], undef, undef],
    "002:0:" => [[''], 0, 0],
    "003:0:   " => [[''], 0, 0],
    "004:2:   " => [[''], 0, 0],
    "005::abcde" => [['abcde'], undef, undef],
    "006::abc def" => [['abc', 'def'], undef, undef],

# check whitespace trimming
    "010::big   space" => [['big', 'space'], undef, undef],
    "011::  trim beg" => [['trim', 'beg'], undef, undef],
    "012::trim end  " => [['trim', 'end'], undef, undef],
    "013::  trim both  " => [['trim', 'both'], undef, undef],
    "014::  trim    all extra   ws  " => [['trim', 'all', 'extra', 'ws'], undef, undef],

# whitespace trimming with cursor
    "021:1:  trim beg" => [['', 'trim', 'beg'], 0, 0],
    "022:4:t e  " => [['t', 'e', ''], 2, 0],
    "023:0:   " => [[''], 0, 0],
    "024:2:   " => [[''], 0, 0],
    "025:3:a    b" => [['a', '', 'b'], 1, 0],

# putting the cursor inside tokens
    "030:0:abc" => [['abc'], 0, 0],
    "031:1:abc" => [['abc'], 0, 1],
    "032:3:   abc" => [['abc'], 0, 0],
    "033:5:   abc" => [['abc'], 0, 2],

# putting the cursor after tokens
    "040:1:a" => [['a'], 0, 1],
    "041:3:a b" => [['a', 'b'], 1, 1],
    "042:3:a b  " => [['a', 'b'], 1, 1],
    "043:3:'' " => [['', ''], 1, 0],

# cursor when removing double quotes
    "050:0:\"b\"" => [['b'], 0, 0],
    "051:1:\"b\"" => [['b'], 0, 0],
    "052:2:\"b\"" => [['b'], 0, 1],
    "053:3:\"b\"" => [['b'], 0, 1],
    "054:2:\"ab\"" => [['ab'], 0, 1],
    "055:3:\"ab\"" => [['ab'], 0, 2],
    "056:4:\"ab\"" => [['ab'], 0, 2],
    "057:1: \"b\"" => [['b'], 0, 0],
    "058:1:\"\\\"\\\"\"" => [['""'], 0, 0],
    "059:3: \"\\\"\\\"\"" => [['""'], 0, 0],
    "060:3:\"\\\"\\\"\" " => [['""'], 0, 1],
    "061:6:  \"\\\"\\\"\"" => [['""'], 0, 1],
    "062:5:\"\\\"\\\"\"  " => [['""'], 0, 2],
    "063:7:\" \\\"\\\"\"" => [[' ""'], 0, 3],
    "064:2:\"\\'\\'\" " => [['\'\''], 0, 0],
    "065:2:\" \" \" " => [undef, undef, undef],
    "066:3: \"\"\"\" " => [['', ''], 0, 0],     # make sure it gravitates to the left-most token

# cursor when removing single quotes
    "070:0:'b'" => [['b'], 0, 0],
    "071:1:'b'" => [['b'], 0, 0],
    "072:2:'b'" => [['b'], 0, 1],
    "073:3:'b'" => [['b'], 0, 1],
    "074:2:'ab'" => [['ab'], 0, 1],
    "075:3:'ab'" => [['ab'], 0, 2],
    "076:4:'ab'" => [['ab'], 0, 2],
    "077:1: 'b'" => [['b'], 0, 0],
    "078:1:'\\'\\''" => [['\'\''], 0, 0],
    "079:2: '\\'\\''" => [['\'\''], 0, 0],
    "080:3:'\\'\\'' " => [['\'\''], 0, 1],
    "081:6:  '\\'\\''" => [['\'\''], 0, 1],
    "082:5:'\\'\\''  " => [['\'\''], 0, 2],
    "083:7:' \\'\\''" => [[' \'\''], 0, 3],
    "084:2:'\\\"\\\"' " => [['\"\"'], 0, 1],
    "085:2:' ' ' " => [undef, undef, undef],
    "086:3: '''' " => [['', ''], 0, 0],

# cursor when removing backslash escapes
    "090:0:\\b" => [['b'], 0, 0],
    "091:1:\\b" => [['b'], 0, 0],
    "092:2:\\b" => [['b'], 0, 1],
    "093:1: \\b" => [['b'], 0, 0],
    "094:2:\\a\\b\\c" => [['abc'], 0, 1],

# random
    "100::this   is \"a test\" of\\ quotewords \\\"for you" => [['this', 'is', 'a test', 'of quotewords', '"for', 'you'], undef, undef],
);

1;

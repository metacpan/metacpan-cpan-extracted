# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Test::More tests => 8;

use File::Globstar qw(quotestar);

is quotestar('back\slash\es'), 'back\\\\slash\\\\es', 'backslashes'; 
is quotestar('open [square [bracket'), 'open \\[square \\[bracket', 
    'open square bracket'; 
is quotestar('closing square] bracket]'), 'closing square\\] bracket\\]', 
    'closing square bracket'; 
is quotestar('aster**isk'), 'aster\\*\\*isk', 
    'asterisk'; 
is quotestar('question? mark?'), 'question\? mark\?', 
    'question mark'; 
is quotestar('!negated'), '!negated', 
    'exclamation mark'; 
is quotestar('!negated', 1), '\\!negated', 
    'escapable exclamation mark';
is quotestar('!\all*[put]*together?', 1), '\\!\\\\all\\*\\[put\\]\\*together\\?',
    'all';

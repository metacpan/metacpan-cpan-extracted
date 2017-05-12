use strict;

our $FILE_CONTENTS;

BEGIN {
    *CORE::GLOBAL::localtime = sub {
        return qw(42 08 10 1 3 101);
    }
}

use Log::StdLog { file => \$FILE_CONTENTS, level => 'warn' };
use Test::More 'no_plan';

local *$ = \12345;

print {*STDLOG} duh => "duh message\n";

ok !defined $FILE_CONTENTS          => 'Ran silent';

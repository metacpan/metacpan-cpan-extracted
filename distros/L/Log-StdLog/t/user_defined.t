use strict;

our $FILE_CONTENTS;

BEGIN {
    *CORE::GLOBAL::localtime = sub {
        return qw(42 08 10 1 3 101);
    }
}

use Log::StdLog { file => \$FILE_CONTENTS, level => 'user' };
use Test::More 'no_plan';

local *$ = \12345;

print {*STDLOG} duh => "duh message\n";

open my $logfile, '<', \$FILE_CONTENTS;

while (my $logged = <$logfile>) {
    my $expected = <DATA>;
    chomp $logged;
    chomp $expected;
    is $logged, $expected        => $expected;
}

ok !<DATA>                       => 'No extra outputs';

__DATA__
[20010401.100842] [12345] [duh] duh message

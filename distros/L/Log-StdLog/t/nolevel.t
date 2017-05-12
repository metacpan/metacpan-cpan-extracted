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

print {*STDLOG} trace => "trace message\n";
print {*STDLOG} debug => "debug message\n";
print {*STDLOG} "  user message\n";
print {*STDLOG} info  => "  info message\n";
print {*STDLOG} warn  => "  warn message\n";
print {*STDLOG} error => "error message\n";
print {*STDLOG} fatal => "fatal message\n";

open my $logfile, '<', \$FILE_CONTENTS;

while (my $logged = <$logfile>) {
    my $expected = <DATA>;
    chomp $logged;
    chomp $expected;
    is $logged, $expected        => $expected;
}

ok !<DATA>                       => 'No extra outputs';

__DATA__
[20010401.100842] [12345] [user]   user message
[20010401.100842] [12345] [info]   info message
[20010401.100842] [12345] [warn]   warn message
[20010401.100842] [12345] [error] error message
[20010401.100842] [12345] [fatal] fatal message

use strict;

our $FILE_CONTENTS;
my $FILE_HANDLE;

BEGIN {
    *CORE::GLOBAL::localtime = sub {
        return qw(42 08 10 1 3 101);
    }
}

use Test::More 'no_plan';

BEGIN {
    ok open($FILE_HANDLE, '>>', \$FILE_CONTENTS)  => 'Built filehandle';
}

use Log::StdLog { handle => $FILE_HANDLE, level => 'warn' };


local *$ = \12345;

print {*STDLOG} trace => "trace message\n";
print {*STDLOG} debug => "debug message\n";
print {*STDLOG} user  => "  user message\n";
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
[20010401.100842] [12345] [warn]   warn message
[20010401.100842] [12345] [error] error message
[20010401.100842] [12345] [fatal] fatal message

use strict;

our $FILE_CONTENTS;

BEGIN {
    *CORE::GLOBAL::localtime = sub {
        return qw(42 08 10 1 3 101);
    }
}

sub form {
    my ($time, $pid, $level, @msg) = @_;
    return "$level $time.$pid: @msg";
}

use Log::StdLog { file => \$FILE_CONTENTS, level => 'user', format=>\&form };
use Test::More 'no_plan';

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
user 20010401.100842.12345:   user message
info 20010401.100842.12345:   info message
warn 20010401.100842.12345:   warn message
error 20010401.100842.12345: error message
fatal 20010401.100842.12345: fatal message

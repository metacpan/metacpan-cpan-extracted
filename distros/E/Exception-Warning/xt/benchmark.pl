#!/usr/bin/perl -al

use lib 'lib', '../lib';

use Exception::Warning;

open NULL, '>', '/dev/null';
*STDERR = *NULL;

{
    package My::Warn;
    our $n = 0;
    sub init {
        undef $SIG{__WARN__};
    }
    sub test {
        init if $n++ == 0;
        warn 'Warning';
    }
}

{
    package My::WarnSubEmpty;
    our $n = 0;
    sub init {
        $SIG{__WARN__} = sub { };
    }
    sub test {
        init if $n++ == 0;
        warn 'Warning';
    }
}

{
    package My::ExceptionWarning;
    our $n = 0;
    sub init {
        $SIG{__WARN__} = \&Exception::Warning::__WARN__;
    }
    sub test {
        init if $n++ == 0;
        warn 'Warning';
    }
}

{
    package My::ExceptionWarning0;
    our $n = 0;
    sub init {
        $SIG{__WARN__} = \&Exception::Warning::__WARN__;
        Exception::Warning->import( verbosity => 0 );
    }
    sub test {
        init if $n++ == 0;
        warn 'Warning';
    }
}


package main;

use Benchmark ':all';

my %tests = (
    '01_Warn'                     => sub { My::Warn->test },
    '02_WarnSubEmpty'             => sub { My::WarnSubEmpty->test },
    '03_ExceptionWarning'         => sub { My::ExceptionWarning->test },
    '03_ExceptionWarning0'        => sub { My::ExceptionWarning0->test },
);

print "Benchmark for ", (My::Common::throw_something ? "FAIL" : "OK"), "\n";
#foreach (keys %tests) {
#    printf "%s = %d\n", $_, $tests{$_}->();
#}
my $result = timethese($ARGV[0] || -1, { %tests });
cmpthese($result);

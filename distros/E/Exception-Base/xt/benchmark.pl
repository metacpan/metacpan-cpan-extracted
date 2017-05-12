#!/usr/bin/perl

use 5.006;

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Cwd;

BEGIN {
    chdir dirname(__FILE__) or die "$!";
    chdir '..' or die "$!";

    unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

    my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
    unshift @INC, File::Spec->catdir($cwd, 'inc');
    unshift @INC, File::Spec->catdir($cwd, 'lib');
}

my %tests = (
    '01_EvalDieScalar'    => { desc => 'eval/die string' },
    '02_EvalDieObject'    => { desc => 'eval/die object' },
    '03_ExceptionEval'    => { desc => 'Exception::Base eval/if' },
    '04_Exception1Eval'   => { desc => 'Exception::Base eval/if verbosity=1' },
    '05_Error'            => { desc => 'Error' },
    '06_ClassThrowable'   => { desc => 'Class::Throwable' },
    '07_ExceptionClass'   => { desc => 'Exception::Class' },
    '08_ExceptionClassTC' => { desc => 'Exception::Class::TryCatch' },
    '09_TryCatch'         => { desc => 'TryCatch' },
    '10_TryTiny'          => { desc => 'Try::Tiny' },
);

foreach my $scenario (qw{ ok fail }) {
    open my $fh, '-|', "$^X xt/benchmark_$scenario.pl " . ($ARGV[0] || -1) or die;
    while ($_ = <$fh>) {
        print;
        /^(\d\d_\w+)\s+(\d+)\/s/ or next;
        my ($test, $result) = ($1, $2);
        $tests{$test}{$scenario} = $result;
    };
    close $fh or die;
};

print "  -----------------------------------------------------------------------\n";
print "  | Module                              | Success sub/s | Failure sub/s |\n";
print "  -----------------------------------------------------------------------\n";
foreach my $test (sort keys %tests) {
    next unless exists $tests{$test}{ok} and exists $tests{$test}{fail};
    printf "  | %-35.35s | %13.13s | %13.13s |\n",
           $tests{$test}{desc}, $tests{$test}{ok}, $tests{$test}{fail};
    print "  -----------------------------------------------------------------------\n";
};

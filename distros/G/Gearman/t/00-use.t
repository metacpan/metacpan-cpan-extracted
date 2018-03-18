use strict;
use warnings;
use version ();
use Test::More;

my @mn = qw/
    Gearman::Client
    Gearman::Job
    Gearman::JobStatus
    Gearman::Objects
    Gearman::ResponseParser
    Gearman::Task
    Gearman::Taskset
    Gearman::Util
    Gearman::Worker
    /;

my $v = version->declare("2.004.014");

foreach my $n (@mn) {
    use_ok($n);
    my $_v = eval '$' . $n . '::VERSION';

    # diag("Testing $n $v, Perl $], $^X");
    is($_v, $v, "$n version is $v");
} ## end foreach my $n (@mn)

done_testing;


use Test::More;
use Test::Pod::Coverage;
use Test::Pod;
use Test::Compile;

my @pods = all_pm_files(qw(lib));
push(@pods, all_pl_files(qw(bin scripts)));

subtest 'pod files ok' => sub {
    all_pod_files_ok(@pods);
};

subtest 'pod coverage ok' => sub {
    all_pod_coverage_ok(@pods);
};

done_testing;


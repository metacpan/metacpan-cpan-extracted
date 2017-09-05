use Test::Compile;
use Test::More;
use Test::Pod::Coverage;
use Test::Pod;

my @pods = all_pm_files(qw(lib));
push(@pods, all_pl_files(qw(bin scripts)));

subtest 'pod files ok' => sub {
    all_pod_files_ok(@pods);
};

subtest 'pod coverage ok' => sub {
    all_pod_coverage_ok(@pods, { trust_me => "DESTROY" });
};

done_testing;


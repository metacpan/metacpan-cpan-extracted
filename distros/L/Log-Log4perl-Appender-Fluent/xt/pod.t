use Test::More;
use Test::Pod::Coverage;
use Test::Pod;
use Test::Compile;

## Something something, why don't you mock me>
BEGIN {
    $INC{'Log/Log4perl/Appender.pm'} = 1;
};

local *Log::Log4perl::Appender::new = sub {
    return bless({}, "Log::Log4perl::Appender");
};
local *Log::Log4perl::Appender::layout = sub { return 1};
local *Log::Log4perl::Appender::reset  = sub { return 1};
## End the mocking will ya

my @pods = all_pm_files(qw(lib));
push(@pods, all_pl_files(qw(bin scripts)));

subtest 'pod files ok' => sub {
    all_pod_files_ok(@pods);
};

subtest 'pod coverage ok' => sub {
    all_pod_coverage_ok(@pods);
};

done_testing;


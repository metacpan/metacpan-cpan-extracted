use Devel::DTrace::Provider::Builder;
use strict;
use warnings;
use Test::More qw/ no_plan /;

BEGIN {
    $Devel::DTrace::Provider::DTRACE_AVAILABLE = 0;
    
    provider 'provider1' => as {
        probe 'probe1', 'string';
        probe 'probe2', 'string';
    };
}

ok($main::{'probe1'});
ok($main::{'probe1_enabled'});
ok($main::{'probe2'});
ok($main::{'probe2_enabled'});

probe1 { shift->fire('foo') };
probe2 { shift->fire('foo') };
probe1 { shift->fire('foo') } if probe1_enabled;
probe2 { shift->fire('foo') } if probe2_enabled;

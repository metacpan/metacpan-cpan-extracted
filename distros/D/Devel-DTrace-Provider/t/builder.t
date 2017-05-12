use Devel::DTrace::Provider::Builder;
use strict;
use warnings;
use Test::More qw/ no_plan /;

BEGIN {
    provider 'provider1' => as {
        probe 'probe1', 'string';
        probe 'probe2', 'string';
    };
}

ok($main::{'probe1'});
ok($main::{'probe1_enabled'});
ok($main::{'probe2'});
ok($main::{'probe2_enabled'});

ok($main::{'provider1_probe1'});
ok($main::{'provider1_probe1_enabled'});
ok($main::{'provider1_probe2'});
ok($main::{'provider1_probe2_enabled'});

probe1 { shift->fire('foo') };
probe2 { shift->fire('foo') };
probe1 { shift->fire('foo') } if probe1_enabled;
probe2 { shift->fire('foo') } if probe2_enabled;

provider1_probe1 { shift->fire('foo') };
provider1_probe2 { shift->fire('foo') };
provider1_probe1 { shift->fire('foo') } if provider1_probe1_enabled;
provider1_probe2 { shift->fire('foo') } if provider1_probe2_enabled;

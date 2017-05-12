#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Warn;

use FindBin;
use lib ("$FindBin::Bin/../lib" =~ m[^(/.*)])[0];


# 'use' with params sets up all configuration options
{
    use LocalOverride (
        base_namespace => 'base',
        core_only      => 1,
        local_prefix   => 'prefix'
    );
    is($LocalOverride::base_namespace, 'base',   'use sets base_namespace');
    is($LocalOverride::core_only,      1,        'use sets core_only');
    is($LocalOverride::local_prefix,   'prefix', 'use sets local_prefix');
}

# 'no' unimports module
{
    is_deeply([map { substr $_, 0, 4 } grep { ref $_ } @INC],
              ['CODE'], 'one coderef in @INC prior to unload');
    eval 'no LocalOverride';
    is_deeply([grep { ref $_ } @INC], [], 'unload removes coderef from @INC');
}

# 'use' with params that don't correspond to any options warns about them
{
    warning_like { eval 'use LocalOverride ( bad_param => 0 )' }
    qr/unrecognized option bad_param/i, 'use warns on unknown param';
}

done_testing;


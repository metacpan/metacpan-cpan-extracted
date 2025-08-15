#!/usr/bin/env perl

use 5.018;
use warnings;
use English;
use Test2::V0;

use Log::Any '$log',
    default_adapter => [
        'MacOS::OSLog',
        subsystem => 'com.example.perl',
        log_level => 'trace',
    ];
use Log::Any::Adapter { category => 'private' }, 'MacOS::OSLog',
    subsystem => 'com.example.perl',
    private   => 1,
    log_level => 'trace';

ok( lives {
        $log->info(
            q{Hello from Perl's Log::Any::Adapter::MacOS::Log},
            {   foo => 'hello',
                bar => 'world',
                baz => {
                    food   => 'pizza',
                    things => [ 'TV', 90210 ],
                },
            } );
    },
    'log',
) or note($EVAL_ERROR);

my $private_log = Log::Any->get_logger( category => 'private' );
ok( lives {
        $private_log->debug('Shhh!');
    },
    'private debug log',
) or note($EVAL_ERROR);

ok( lives {
        $log->infof( 'Hello from Perl version %s', $PERL_VERSION )
    },
    'log with format string',
) or note($EVAL_ERROR);

done_testing();

use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ MakeMaker => ],
                    [ VerifyPhases => ], # { skip => [ 'Makefile.PL' ] }
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        [
            grep {
                /\[VerifyPhases\]/
                && ( Dist::Zilla->VERSION < 5.022
                    ? ! /^\[VerifyPhases\] file has been added after file gathering phase: 'Makefile.PL'/
                    : 1 )
            }
            map { colorstrip($_) } @{ $tzil->log_messages }
        ],
        [],
        'no warnings from the plugin despite Makefile.PL being modified late',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

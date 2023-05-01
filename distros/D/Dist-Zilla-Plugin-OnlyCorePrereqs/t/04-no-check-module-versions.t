use strict;
use warnings;

use Test::More 0.88;

plan skip_all => 'the check_module_versions option has been removed';

use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ Prereqs => RuntimeRequires => { 'HTTP::Tiny' => '0.025' } ],
                    [ OnlyCorePrereqs => { starting_version => '5.014', check_module_versions => 0 } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    # normally we'd see this:
    # [OnlyCorePrereqs] detected a runtime requires dependency on HTTP::Tiny
    # 0.025: perl 5.014 only has 0.012
    is(
        exception { $tzil->build },
        undef,
        'build succeeded, despite HTTP::Tiny not at 0.025 in perl 5.014'
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

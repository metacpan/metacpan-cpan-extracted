use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

subtest "eumm_version = $_" => sub {
    my $eumm_version = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                  'GatherDir',
                    [ 'MakeMaker::Awesome' => { eumm_version => $eumm_version } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $content = $tzil->slurp_file('build/Makefile.PL');

    like(
        $content,
        qr/^use ExtUtils::MakeMaker '$eumm_version';$/m,
        'EUMM version uses quotes to prevent losing information from numification',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach ('7.00', '6.55_02');

done_testing;

use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
              'GatherDir',
              'MakeMaker',
              [ Prereqs => { perl => '5.8.1' } ],
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/Makefile.PL');

like($content, qr/^use 5\.008001;\s*$/m, "normalized the perl version needed");

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

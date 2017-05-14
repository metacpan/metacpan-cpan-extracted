use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

use lib 't/lib';
use Versions;
my $latest_stable_perl = Versions::latest_stable_perl();
my $latest_dev_perl = Versions::latest_dev_perl();

# fake the current perl version to be the latest known stable release.
local $] = '5.010000';

$ENV{DZIL_ANY_PERL} = 0;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'EnsureLatestPerl' ],
                [ FakeRelease => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
### BEGIN $tzil->release check
like(
    exception { $tzil->release },
    qr/^\[EnsureLatestPerl\] current perl \(5.010000\) is neither the current stable nor development perl \($latest_stable_perl, $latest_dev_perl\) -- \(disable check with DZIL_ANY_PERL=1\)/,
    'release halts if perl is too old',
);
### END $tzil->release check

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::EnsureLatestPerl',
                    config => {
                        'Dist::Zilla::Plugin::EnsureLatestPerl' => {
                            'Module::CoreList' => Module::CoreList->VERSION,
                        },
                    },
                    name => 'EnsureLatestPerl',
                    version => Dist::Zilla::Plugin::EnsureLatestPerl->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

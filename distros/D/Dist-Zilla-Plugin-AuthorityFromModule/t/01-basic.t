use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'AuthorityFromModule' => { module => 'Foo::Bar' } ],
            ),
            path(qw(source lib Foo.pm)) => "use strict;\npackage Foo;\n1;\n",
            path(qw(source lib Foo Bar.pm)) => "use strict;\npackage Foo::Bar;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof('[AuthorityFromModule] found \'Foo::Bar\' in lib/Foo/Bar.pm'),
    'filename containing the module is logged',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_authority_from_module => 'Foo::Bar',
        x_permissions_from_module => 'Foo::Bar',
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::AuthorityFromModule',
                    config => superhashof({
                        'Dist::Zilla::Plugin::AuthorityFromModule' => {
                            module => 'Foo::Bar',
                        },
                    }),
                    name => 'AuthorityFromModule',
                    version => Dist::Zilla::Plugin::AuthorityFromModule->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata, including dumped configs',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

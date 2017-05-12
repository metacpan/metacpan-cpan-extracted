use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MungeFile' => { finder => ':MainModule' } ],
            ),
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $string = "{{ uc('hello hello') }}";
1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $string = "HELLO HELLO";
1;
NEW_MODULE
    'module content is transformed',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::MungeFile',
                    config => {
                        'Dist::Zilla::Plugin::MungeFile' => {
                            finder => [ ':MainModule' ],
                            files => [ ],
                        },
                    },
                    name => 'MungeFile',
                    version => Dist::Zilla::Plugin::MungeFile->VERSION,
                },
            ),
        }),
    }),
    'distmeta is correct',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

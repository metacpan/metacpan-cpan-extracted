use strict;
use warnings;

use Test::More 0.96;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Manifest => ],
                [ MetaConfig => ],
                [ 'Test::Portability' ],
            ),
            path(qw(source lib Foo.pm)) => <<'MODULE',
package Foo;
use strict;
use warnings;
1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author portability.t));
ok( -e $file, $file . ' created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');
unlike($content, qr/\t/m, 'no tabs in generated test');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::More' => '0',
                    'Test::Portability::Files' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::Portability',
                    config => {
                        'Dist::Zilla::Plugin::Test::Portability' => {
                            options => '',
                        },
                    },
                    name => 'Test::Portability',
                    version => Dist::Zilla::Plugin::Test::Portability->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the develop phase',
) or diag 'got distmeta: ', explain $tzil->distmeta;

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;

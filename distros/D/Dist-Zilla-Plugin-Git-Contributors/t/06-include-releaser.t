use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

my $tempdir = no_git_tempdir();
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    author   => 'Anne O\'Thor <author@example.com>',
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Git::Contributors' => { include_releaser => 0 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        tempdir_root => $tempdir->stringify,
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root);

# upper case here
my $releaser = 'Test User <test@example.com>';

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => $tzil->authors->[0] });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => $releaser });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => lc $releaser }); # lowercase here

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'fourth commit', author => 'Anon Y. Moose <anon@null.com>' });

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

is(
    $tzil->plugin_named('Git::Contributors')->_releaser,
    $releaser,
    'properly determined the name+email of the current user',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_contributors => [
            'Anon Y. Moose <anon@null.com>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => superhashof({
                            include_releaser => 0,
                        }),
                    },
                    name => 'Git::Contributors',
                    version => Dist::Zilla::Plugin::Git::Contributors->VERSION,
                },
            ),
        }),
    }),
    'releaser not included in contributor list (nor author, by default)',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

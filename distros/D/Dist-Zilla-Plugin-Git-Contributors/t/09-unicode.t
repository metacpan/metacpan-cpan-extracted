use strict;
use warnings;

use utf8;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

binmode Test::More->builder->$_, ':encoding(UTF-8)' foreach qw(output failure_output todo_output);
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

local $TODO = 'tests of git commits with unicode do not seem to work yet; see genehack/Git-Wrapper/#52'
    if $^O eq 'MSWin32';

# diag uses todo_output if in_todo :/
no warnings 'redefine';
*::diag = sub {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tb = Test::Builder->new;
    $tb->_print_comment($tb->failure_output, @_);
};

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
                [ Prereqs => ConfigureRequires => { perl => '5.010' } ],
                [ 'Git::Contributors' => { include_authors => 1, include_releaser => 0 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        tempdir_root => $tempdir->stringify,
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root, { 'user.name' => 'Olivier Mengué', 'user.email' => 'dolmen@cpan.org' });

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add('Changes');
$git->commit({ message => 'first commit', author => 'Dagfinn Ilmari Mannsåker <ilmari@example.org>' });

$changes->append("- a changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'second commit', author => 'Anne O\'Thor <author@example.com>' });

$changes->append("- another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'third commit', author => 'Z. Tinman <ztinman@example.com>' });

$changes->append("- yet another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'fourth commit', author => '김도형 - Keedi Kim <keedi@example.org>', });

$changes->append("- still yet another changelog entry\n");
$git->add('Changes');
$git->commit({ message => 'fifth commit', author => 'Évelyne Brochu <evelyne@example.com>' });

$changes->append("- commit from the releaser\n");
$git->add('Changes');
$git->commit({ message => 'sixth commit', author => 'Olivier Mengué <dolmen@cpan.org>' });

$tzil->chrome->logger->set_debug(1);

is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            configure => { requires => { perl => '5.010' } },
            # here is where we stick runtime prereqs if there are any
        },
        x_contributors => [
            'Anne O\'Thor <author@example.com>',
            'Dagfinn Ilmari Mannsåker <ilmari@example.org>',
            'Évelyne Brochu <evelyne@example.com>',
            'Z. Tinman <ztinman@example.com>',
            '김도형 - Keedi Kim <keedi@example.org>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => superhashof({
                            include_authors => 1,
                            include_releaser => 0,
                        }),
                    },
                    name => 'Git::Contributors',
                    version => Dist::Zilla::Plugin::Git::Contributors->VERSION,
                },
            ),
        }),
    }),
    'contributor names are extracted properly, without mojibake, with names sorted using unicode collation',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'extracted contributors: ', explain $tzil->distmeta->{x_contributors}
    if $^O eq 'MSWin32';

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

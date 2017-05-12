use strict;
use warnings;

use Test::More 0.88;
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
                [ ExecDir => ],
                [ MetaConfig => ],
                [ 'Test::EOL' ],
            ),
            path(qw(source lib Foo.pm)) => <<'MODULE',
package Foo;
use strict;
use warnings;
1;
MODULE
            path(qw(source lib Bar.pod)) => <<'POD',
package Bar;
=pod

=cut
POD
            path(qw(source bin myscript)) => <<'SCRIPT',
use strict;
use warnings;
print "hello there!\n";
SCRIPT
            path(qw(source t foo.t)) => <<'TEST',
use strict;
use warnings;
use Test::More tests => 1;
pass('hi!');
TEST
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt author eol.t));
ok( -e $file, $file . ' created');

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');
unlike($content, qr/\t/m, 'no tabs in generated test');

my @files = (
    path(qw(lib Foo.pm)),
    path(qw(lib Bar.pod)),
    path(qw(bin myscript)),
    path(qw(t foo.t)),
);

like($content, qr/'\Q$_\E'/m, "test checks $_") foreach @files;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::More' => '0.88',
                    'Test::EOL' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::EOL',
                    config => {
                        'Dist::Zilla::Plugin::Test::EOL' => {
                            filename => 'xt/author/eol.t',
                            trailing_whitespace => 1,
                            finder => [ ':ExecFiles', ':InstallModules', ':TestFiles' ],
                        },
                    },
                    name => 'Test::EOL',
                    version => Dist::Zilla::Plugin::Test::EOL->VERSION,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the develop phase',
) or diag 'got distmeta: ', explain $tzil->distmeta;

# not needed, but Test::EOL (pre-1.5) loads it from the generated test, and $0
# is wrong for it
use FindBin;

my $files_tested;

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    $files_tested = Test::Builder->new->current_test;
};

is($files_tested, @files, 'correct number of files were tested');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;

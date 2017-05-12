use strict;
use warnings;
use Test::More;
use Test::Warnings ':no_end_test', ':all';
use Test::DZil;
use Test::Script;
use Path::Tiny;
use Test::Deep;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    {
        dist_root => 't/does-not-exist',
    },
    {
        add_files => {
            path(qw/source dist.ini/) => simple_ini(
                [ GatherDir => ],
                [ ExecDir => ],
                [ MetaConfig => ],
                [ 'Test::EOF' ],
            ),
            path(qw/source lib Shim.pm/) => q{
                package Shim.pm;

                use strict;

                1;
},
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw/xt author eof.t/);
ok(-e $file, "$file created");

my $content = $file->slurp_utf8;
like($content, qr{\v\Z}xms, 'Ends with vertical whitespace');

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::More' => '0',
                    'Test::EOF' => '0',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof({
                class => 'Dist::Zilla::Plugin::Test::EOF',
                config => {
                    'Dist::Zilla::Plugin::Test::EOF' => { filename => 'xt/author/eof.t' },
                },
                name => 'Test::EOF',
                version => ignore,
            }),
        }),
    }),
    'prereqs are properly injected for the develop phase',
) or diag 'got distmeta: ' . explain $tzil->distmeta;

my $files_tested;

subtest 'run the generated test' => sub {
    my $wd = pushd $build_dir;

    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    $files_tested = Test::Builder->new->current_test;
};

is($files_tested, 2, 'correct number of files were tested');

diag 'got log messages: ' . explain $tzil->log_messages if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{'AUTHOR_TESTING'};

done_testing;

__END__

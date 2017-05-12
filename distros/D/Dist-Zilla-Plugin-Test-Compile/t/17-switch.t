use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

my @tests = (
    {
        test_case => 'warnings enabled -- warning passes through',
        switches => [ '-w' ],
        expected_warnings => [ 'boo hoo' ],
    },
    {
        test_case => 'deprecation warnings disabled',
        switches => [ '-w', '-M-warnings=deprecated' ],
        expected_warnings => [],
    },
);

subtest $_->{test_case} => sub {

    my $test = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ ExecDir => ],
                    [ MetaConfig => ],
                    [ 'Test::Compile' => { fail_on_warning => 'none', switch => $test->{switches} } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\nwarnings::warnif('deprecated','boo hoo');\n1;\n",
                path(qw(source bin foobar)) => "#!/usr/bin/perl\nwarnings::warnif('deprecated','boo hoo');\nprint \"foo\n\";\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child(qw(t 00-compile.t));
    ok(-e $file, 'test created');

    my $content = $file->slurp_utf8;
    unlike($content, qr/[^\S\n]\n/, 'no trailing whitespace in generated test');

    my @files = (
        path(qw(Foo.pm)),
        path(qw(bin foobar)),
    );

    like($content, qr/'\Q$_\E'/m, "test checks $_") foreach @files;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Test::Compile',
                        config => {
                            'Dist::Zilla::Plugin::Test::Compile' => superhashof({
                                fail_on_warning => 'none',
                                switch => $test->{switches},
                            }),
                        },
                        name => 'Test::Compile',
                        version => Dist::Zilla::Plugin::Test::Compile->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs are good',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    my $num_tests;
    my @warnings = warnings {
        subtest 'run the generated test' => sub
        {
            my $wd = pushd $build_dir;
            $tzil->plugin_named('MakeMaker')->build;

            local $ENV{AUTHOR_TESTING} = 1;
            do $file;
            note 'ran tests successfully' if not $@;
            fail($@) if $@;

            $num_tests = Test::Builder->new->current_test;
        };
    };

    is($num_tests, @files, 'correct number of files were tested');

    cmp_deeply(
        \@warnings,
        [ map { re(qr/^$_/) } @{ $test->{expected_warnings} } ],
        'got expected warnings from compiling a module with a deprecation warning',
    )
        or diag 'got warning(s): ', explain(\@warnings);

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;

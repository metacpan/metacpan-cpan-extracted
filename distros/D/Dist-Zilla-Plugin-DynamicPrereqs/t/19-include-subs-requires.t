use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use PadWalker 'closed_over';
use Dist::Zilla::Plugin::DynamicPrereqs;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

use lib 't/lib';
use Helper;

my $included_subs = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::_build__sub_definitions)->{'%included_subs'};

foreach my $subs (
    [ 'requires' ],
    [ 'runtime_requires' ],
    [ 'test_requires', 'build_requires' ],
)
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ DynamicPrereqs => {
                            '-condition' => '1 == 1',
                            -raw => [
                                map $_.q|('strict', '0.23');|, @$subs
                            ],
                        } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
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
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            prereqs => {
                configure => {
                    requires => {
                        'ExtUtils::MakeMaker' => ignore,
                    }
                },
            },
        }),
        'no prereqs added for included subs',
    )
    or diag 'found metadata: ', explain $tzil->distmeta;

    my $build_dir = path($tzil->tempdir)->child('build');
    my $file = $build_dir->child('Makefile.PL');
    ok(-e $file, 'Makefile.PL created');

    my $makefile = $file->slurp_utf8;
    unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');
    unlike($makefile, qr/\t/m, 'no tabs in modified file');

    isnt(
        index(
            $makefile,
            "if (1 == 1) {\n" . join("\n", map $_.q|('strict', '0.23');|, @$subs) . "\n" . "}\n",
        ),
        -1,
        'Makefile.PL condition and raw clauses are correct',
    );

    isnt(
        index($makefile, "\nsub $_ {"),
        -1,
        "Makefile.PL contains definition for $_()",
    ) foreach @$subs;

    run_makemaker($tzil);

    {
        no strict 'refs';
        cmp_deeply(
            \%{'main::MyTestMakeMaker::'},
            superhashof({
                map +($_ => *{"MyTestMakeMaker::$_"}), @$subs
            }),
            'Makefile.PL defined all required subroutines',
        ) or diag 'Makefile.PL defined symbols: ', explain \%{'main::MyTestMakeMaker::'};
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;

    %$included_subs = ();
}

done_testing;

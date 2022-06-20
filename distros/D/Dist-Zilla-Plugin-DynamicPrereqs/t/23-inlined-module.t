use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use PadWalker 'closed_over';
use Test::Deep;
use Test::File::ShareDir ();

# since we change directories during the build process, this must be absolute
use lib path('t/lib')->absolute->stringify;

sub tzil {
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MakeMaker => ],
                    [ DynamicPrereqs => {
                        -include_sub => [ 'foo' ],
                        -raw => [ 'foo();' ],
                      },
                    ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source share include_subs foo)) => "sub foo {\n  1;\n}\n",
            },
        },
    );

    Test::File::ShareDir->import(
        -root => path($tzil->tempdir)->child('source')->stringify,
        -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share' } },
    );

    return $tzil;
}

{
    my $tzil = tzil();

    my $sub_inc_dependencies = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::gather_files)->{'%sub_inc_dependencies'};
    $sub_inc_dependencies->{foo} = { 'Does::Not::Exist' => '0' };

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/(?:Could not find module|Can't locate) Does::Not::Exist/,
        'build fails when module to be inlined is not installed',
    ) or diag 'got log messages: ', explain $tzil->log_messages;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = tzil();

    my ($strict_version, $stricter_version) = (strict->VERSION, strict->VERSION * 2);

    my $sub_inc_dependencies = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::gather_files)->{'%sub_inc_dependencies'};
    $sub_inc_dependencies->{foo} = { 'strict' => $stricter_version };

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        qr/\[DynamicPrereqs\] strict version $stricter_version required--only found version $strict_version/,
        'build fails when module to be inlined is not installed',
    ) or diag 'got log messages: ', explain $tzil->log_messages;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = tzil();

    my $sub_inc_dependencies = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::gather_files)->{'%sub_inc_dependencies'};
    $sub_inc_dependencies->{foo} = { 'Inlined::Module' => '1.23' };

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    ) or diag 'got log messages: ', explain $tzil->log_messages;

    my $build_dir = path($tzil->tempdir)->child('build');

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 1,
            prereqs => {
                configure => {
                    requires => {
                        'ExtUtils::MakeMaker' => ignore,
                    },
                },
                develop => {
                    requires => {
                        'Inlined::Module' => '1.23',
                    },
                },
            },
        }),
        'inlined module added to develop prereqs',
    )
    or diag 'found metadata: ', explain $tzil->distmeta;

    my $file = $build_dir->child('Makefile.PL');
    ok(-e $file, 'Makefile.PL created');

    my $makefile = $file->slurp_utf8;
    unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');
    unlike($makefile, qr/\t/m, 'no tabs in modified file');

    my $version = Dist::Zilla::Plugin::DynamicPrereqs->VERSION;
    isnt(
        index(
            $makefile,
            <<CONTENT),
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs $version
foo();

CONTENT
    -1,
    'raw code inserted into Makefile.PL',
) or diag "found Makefile.PL content:\n", $makefile;

my $expected_subs = <<CONTENT;

# inserted by Dist::Zilla::Plugin::DynamicPrereqs $version
sub foo {
  1;
}
CONTENT

    my $included_subs_index = index($makefile, $expected_subs);
    isnt(
        $included_subs_index,
        -1,
        'requested included_sub inserted from sharedir files into Makefile.PL',
    ) or diag "found Makefile.PL content:\n", $makefile;

    is(
        length($makefile),
        $included_subs_index + length($expected_subs),
        'included_subs appear at the very end of the file',
    ) or $included_subs_index != -1
        && diag 'found content after included subs: '
            . substr($makefile, $included_subs_index + length($expected_subs));

    ok(-e $build_dir->child(qw(inc Inlined Module.pm)), 'inlined module added to distribution');
TODO: {
    local $TODO = 'include_dependencies temporarily disabled, pending Module::CoreList fixes...';
    ok(-e $build_dir->child(qw(inc Inlined Dependency.pm)), '...and its dependency too');
}

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            re(qr/\[DynamicPrereqs\] inlining Inlined::Module into inc\//),
        ),
        'logged messages about inlining the required module',
    ) or diag 'got log messages: ', explain $tzil->log_messages;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

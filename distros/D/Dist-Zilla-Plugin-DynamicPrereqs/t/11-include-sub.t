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

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DynamicPrereqs => {
                    -include_sub => [ 'foo' ],
                    -raw => [ 'foo();', 'bar();' ],
                  },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source share include_subs foo)) => "sub foo {\n  bar();\n}\n",
            path(qw(source share include_subs bar)) => "sub bar {\n  baz();\n}\n",
            path(qw(source share include_subs baz)) => "sub baz {\n  require POSIX;\n}\n",
        },
    },
);

Test::File::ShareDir->import(
    -root => path($tzil->tempdir)->child('source')->stringify,
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share' } },
);

my $sub_dependencies = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::_all_required_subs_for)->{'%sub_dependencies'};
$sub_dependencies->{foo} = [ qw(bar) ];
$sub_dependencies->{bar} = [ qw(baz) ];

my $sub_prereqs = closed_over(\&Dist::Zilla::Plugin::DynamicPrereqs::register_prereqs)->{'%sub_prereqs'};
$sub_prereqs->{baz} = { 'POSIX' => '0' };


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
                    'POSIX' => 0,
                },
            },
        },
    }),
    'added prereqs used by included subs',
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
bar();

CONTENT
    -1,
    'raw code inserted into Makefile.PL',
) or diag "found Makefile.PL content:\n", $makefile;

my $expected_subs = <<CONTENT;

# inserted by Dist::Zilla::Plugin::DynamicPrereqs $version
sub bar {
  baz();
}

sub baz {
  require POSIX;
}

sub foo {
  bar();
}
CONTENT

my $included_subs_index = index($makefile, $expected_subs);
isnt(
    $included_subs_index,
    -1,
    'requested included_sub, and its dependencies, inserted from sharedir files into Makefile.PL',
) or diag "found Makefile.PL content:\n", $makefile;

is(
    length($makefile),
    $included_subs_index + length($expected_subs),
    'included_subs appear at the very end of the file',
) or $included_subs_index != -1
    && diag 'found content after included subs: '
        . substr($makefile, $included_subs_index + length($expected_subs));

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;

use strict;
use warnings;

use Test::More;
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

delete $ENV{RELEASE_STATUS};
delete $ENV{TRIAL};
delete $ENV{V};

# we are done with 0.004_* trial releases - time to go stable!
$ENV{V} = '0.005';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => dist_ini(
                { # configs as in simple_ini, but no version assignment
                    name             => 'DZT-Sample',
                    abstract         => 'Sample DZ Dist',
                    author           => 'E. Xavier Ample <example@example.org>',
                    license          => 'Perl_5',
                    copyright_holder => 'E. Xavier Ample',
                },
                [ GatherDir               => ],
                [ MetaConfig              => ],
                [ RewriteVersion          => ],
                [ FakeRelease             => ],
                [ BumpVersionAfterRelease => ],
            ),
            # test files with the eval and without
            path(qw(source lib Foo.pm)) => "package Foo;\n\nour \$VERSION = '0.004_003'; # TRIAL\n\n1;\n",
            path(qw(source lib Foo Eval.pm)) =>
              "package Foo::Eval;\n\nour \$VERSION = '0.004_003';\n\$VERSION = eval \$VERSION;\n\n1;\n",
            path(qw(source lib Foo Eval Trial.pm)) =>
              "package Foo::Eval::Trial;\n\nour \$VERSION = '0.004_003'; # TRIAL\n\$VERSION = eval \$VERSION;\n\n1;\n",
            path(qw(source lib Foo Transliterate.pm)) =>
              "package Foo::Transliterate;\n\nour \$VERSION = '0.004_003';\n\$VERSION =~ tr/_//d;\n\n1;\n",
            path(qw(source lib Foo Transliterate Trial.pm)) =>
              "package Foo::Transliterate::Trial;\n\nour \$VERSION = '0.004_003'; # TRIAL\n\$VERSION =~ tr/_//d;\n\n1;\n",
            path(qw(source lib Foo Substitute.pm)) =>
              "package Foo::Substitute;\n\nour \$VERSION = '0.004_003';\n\$VERSION =~ s/_//g;\n\n1;\n",
            path(qw(source lib Foo Substitute Trial.pm)) =>
              "package Foo::Substitute::Trial;\n\nour \$VERSION = '0.004_003'; # TRIAL\n\$VERSION =~ s/_//g;\n\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is( exception { $tzil->release }, undef, 'build and release proceeds normally', );

is( $tzil->version, '0.005', 'version was taken from the environment', );

is(
    path( $tzil->tempdir, qw(build lib Foo.pm) )->slurp_utf8,
    "package Foo;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'TRIAL comment is removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Eval.pm) )->slurp_utf8,
    "package Foo::Eval;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'eval line is removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Eval Trial.pm) )->slurp_utf8,
    "package Foo::Eval::Trial;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'TRIAL comment and eval line are removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Transliterate.pm) )->slurp_utf8,
    "package Foo::Transliterate;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'tr line is removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Transliterate Trial.pm) )->slurp_utf8,
    "package Foo::Transliterate::Trial;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'TRIAL comment and tr line are removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Substitute.pm) )->slurp_utf8,
    "package Foo::Substitute;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'substitution line is removed and version reset',
);

is(
    path( $tzil->tempdir, qw(build lib Foo Substitute Trial.pm) )->slurp_utf8,
    "package Foo::Substitute::Trial;\n\nour \$VERSION = '0.005';\n\n1;\n",
    'TRIAL comment and substiution line are removed and version reset',
);

is(
    path( $tzil->tempdir, qw(source lib Foo.pm) )->slurp_utf8,
    "package Foo;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and TRIAL removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Eval.pm) )->slurp_utf8,
    "package Foo::Eval;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and eval removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Eval Trial.pm) )->slurp_utf8,
    "package Foo::Eval::Trial;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and TRIAL and eval removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Transliterate.pm) )->slurp_utf8,
    "package Foo::Transliterate;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and tr removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Transliterate Trial.pm) )->slurp_utf8,
    "package Foo::Transliterate::Trial;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and TRIAL and tr removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Substitute.pm) )->slurp_utf8,
    "package Foo::Substitute;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and substitution removed',
);

is(
    path( $tzil->tempdir, qw(source lib Foo Substitute Trial.pm) )->slurp_utf8,
    "package Foo::Substitute::Trial;\n\nour \$VERSION = '0.006';\n\n1;\n",
    '.pm contents in source saw the version incremented and TRIAL and substitution removed',
);

diag 'got log messages: ', explain $tzil->log_messages
  if not Test::Builder->new->is_passing;

done_testing;

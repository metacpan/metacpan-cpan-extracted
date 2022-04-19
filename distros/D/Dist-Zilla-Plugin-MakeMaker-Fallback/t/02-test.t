use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Deep;

use lib 't/lib';
use RunTests;

# build a dist with MBT and Fallback
# include a simple test in the dist
# run 'dzil test'
#   - only Build test run; make test is not; environment variables not set
# run 'dzil test --release'
#   - Build test and make test are both run; variables are set properly

{
    package BuildMunger;
    use Moose;
    with 'Dist::Zilla::Role::InstallTool';

    sub setup_installer {
        my $self = shift;

        my @mfpl = grep +($_->name eq 'Makefile.PL' or $_->name eq 'Build.PL'), @{ $self->zilla->files };
        $self->log_fatal('No Makefile.PL or Build.PL was found!') unless @mfpl == 2;

        # munges build scripts to add a line that saves the *TESTING
        # variables' value to 'environment-<builder>'
        for my $mfpl ( @mfpl ) {
            my $filename = $mfpl->name;
            $mfpl->content($mfpl->content . <<"LOG_ENVIRONMENT");

use Path::Tiny;
my \$file = path('../../environment-${filename}');
\$file->append_utf8('\$ENV{' . \$_ . '} = ' . (\$ENV{\$_} || '0') . "\\n")
    foreach qw(RELEASE_TESTING AUTHOR_TESTING);
LOG_ENVIRONMENT
      }
      return;
    }
}

foreach my $extra_testing (undef, 1)
{
    note '------------ performing a test, with extra testing variables '
        . ($extra_testing ? '' : 'un') . 'set';

    local $ENV{RELEASE_TESTING}; $ENV{RELEASE_TESTING} = $extra_testing if defined $extra_testing;
    local $ENV{AUTHOR_TESTING}; $ENV{AUTHOR_TESTING} = $extra_testing if defined $extra_testing;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ 'MetaJSON' ],
                    [ 'GatherDir' ],
                    [ 'MakeMaker::Fallback' ],
                    [ 'ModuleBuildTiny' => { version => 0 } ],
                    [ '=BuildMunger' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    # $tzil->test, printing diagnostics on failure
    runtests($tzil) || next;

    # I'm not really sure why the build seems to be getting run inside the
    # 'source' dir, rather than 'build' -- seems rather odd...
    my $source_dir = path($tzil->tempdir)->child('source');

    if (not $extra_testing)
    {
        # confirm that just Build.PL ran, with no environment set
        my $env_build = $source_dir->child('environment-Build.PL');
        ok(-e $env_build, 'Build.PL ran and saved some data for us');
        is(
            $env_build->slurp_utf8,
            "\$ENV{RELEASE_TESTING} = 0\n\$ENV{AUTHOR_TESTING} = 0\n",
            'when test variables are unset, Build.PL ran with variables unset',
        );

        my $env_makefile = $source_dir->child('environment-Makefile.PL');
        ok(!-e $env_makefile, 'Makefile.PL did not run');

        cmp_deeply(
            $tzil->log_messages,
            superbagof(
                re(qr/\Q[MakeMaker::Fallback] doing nothing during test...\E/),
                re(qr/all's well/),
            ),
            'the test method does not die; correct diagnostics printed',
        );
    }
    else
    {
        # confirm that both Build.PL and Makefile.PL ran, with env set and not set.

        my $env_build = $source_dir->child('environment-Build.PL');
        ok(-e $env_build, 'Build.PL ran and saved some data for us');
        is(
            $env_build->slurp_utf8,
            "\$ENV{RELEASE_TESTING} = 1\n\$ENV{AUTHOR_TESTING} = 1\n",
            'when test variables are set, Build.PL ran with variables set',
        );

        my $env_makefile = $source_dir->child('environment-Makefile.PL');
        ok(-e $env_makefile, 'Makefile.PL ran and saved some data for us');
        is(
            $env_makefile->slurp_utf8,
            "\$ENV{RELEASE_TESTING} = 0\n\$ENV{AUTHOR_TESTING} = 0\n",
            'when test variables are set, Makefile.PL ran with variables unset',
        );

        cmp_deeply(
            $tzil->log_messages,
            superbagof(
                re(qr/\[MakeMaker::Fallback\] performing test with RELEASE_TESTING, AUTHOR_TESTING unset/),
                re(qr/all's well/),
            ),
            'the test method does not die; correct diagnostics printed',
        )
    }

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;

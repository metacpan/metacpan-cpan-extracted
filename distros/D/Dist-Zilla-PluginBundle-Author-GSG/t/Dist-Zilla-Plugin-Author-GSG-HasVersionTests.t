use strict;
use warnings;

use Test::More;

use Test::DZil;

use File::Spec qw();
use IPC::Cmd   qw( run );

use lib qw(lib);
use Dist::Zilla::Plugin::Author::GSG::HasVersionTests;

sub run_tests {
    my ($tzil, @tests) = @_;

    my $oldpwd = File::Spec->rel2abs('.');
    chdir $tzil->built_in || die "Unable to chdir: $!";
    my ( $success, $error_message, undef, $stdout_buf, $stderr_buf ) = run(
        command => [$^X, '-Ilib', @tests],
        timeout => 30
    );
    chdir $oldpwd; # allow tmpdir cleanup

    my $stdout = join '', @{ $stdout_buf || [] };
    my $stderr = join '', @{ $stderr_buf || [] };

    return ( $success, $error_message, $stdout, $stderr );
}

subtest 'Module without a version' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/MissingVersion' },
        { tmpdir_root => File::Spec->tmpdir,
          add_files => {
                'source/dist.ini' => dist_ini(
                    {   name    => 'Defaults',
                        version => '1.2.3',
                        author  => 'An Author <an.author@example.test>',
                        license => 'MIT',
                        copyright_holder => 'An Author',
                        copyright_year   => '1995',
                    },
                    'Author::GSG::HasVersionTests',
                    'GatherDir',
                    'MakeMaker',
                ),
                'source/lib/HasVersion.pm' =>
                    "package HasVersion;\n# ABSTRACT: ABSTRACT\nour \$VERSION = 0.01;\n1;",
                'source/lib/MissingVersion.pm' =>
                    "package MissingVersion;\n# ABSTRACT: ABSTRACT\n1;",
            }
        }
    );

    $tzil->build;

    my ( $success, $error_message, $stdout, $stderr )
        = run_tests( $tzil, 'xt/author/has-version.t' );

    ok !$success, "Version test did not succeed";
    is $error_message,
        qq['$^X -Ilib xt/author/has-version.t' exited with value 1],
        "Correct error message for failing test";

    like $stdout, qr/\Qok 1 - lib\/HasVersion.pm has version/,
        "HasVersion is ok";
    like $stdout, qr/\Qnot ok 2 - lib\/MissingVersion.pm has version/,
        "MissingVersion is not ok";

    like $stderr, qr/\QFailed test 'lib\/MissingVersion.pm has version'/xms,
        "The subroutine a_function is 'naked'";
    like $stderr, qr/To address these failed HasVersion tests/,
        "With our custom diagnostics included";
};

subtest 'Module without a version' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/MissingVersion' },
        { tmpdir_root => File::Spec->tmpdir,
          add_files => {
                'source/dist.ini' => dist_ini(
                    {   name    => 'Defaults',
                        version => '1.2.3',
                        author  => 'An Author <an.author@example.test>',
                        license => 'MIT',
                        copyright_holder => 'An Author',
                        copyright_year   => '1995',
                    },
                    'Author::GSG::HasVersionTests',
                    'GatherDir',
                    'MakeMaker',
                ),
                'source/lib/HasVersion.pm' =>
                    "package HasVersion;\n# ABSTRACT: ABSTRACT\nour \$VERSION = 0.01;\n1;",
            }
        }
    );

    $tzil->build;

    my ( $success, $error_message, $stdout, $stderr )
        = run_tests( $tzil, 'xt/author/has-version.t' );

    ok $success,        "Version test succeeded";
    ok !$error_message, "No error with a success";

    like $stdout, qr/\Qok 1 - lib\/HasVersion.pm has version/,
        "HasVersion is OK";

    ok !$stderr, "No messages printed to STDERR on success";
};
done_testing;


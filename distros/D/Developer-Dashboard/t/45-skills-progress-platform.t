use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Skills ();
use Developer::Dashboard::SkillManager;

{
    package Local::CaptureProgress;

    sub new {
        my ( $class, @args ) = @_;
        shift @args if @args % 2 == 1 && !ref( $args[0] );
        my %args = @args;
        return bless \%args, $class;
    }
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Progress::new = sub { return Local::CaptureProgress->new(@_) };
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;

    my $progress = Developer::Dashboard::CLI::Skills::_skills_install_progress();
    isa_ok( $progress, 'Local::CaptureProgress', 'skills install progress can be captured through the progress constructor override' );
    is( $progress->{max_detail_lines}, 10, 'skills install progress caps dependency detail output at ten lines' );
    my @task_ids = map { $_->{id} } @{ $progress->{tasks} || [] };
    is_deeply(
        \@task_ids,
        [ 'fetch_source', 'prepare_layout' ],
        'skills install progress starts with only fetch and layout tasks before manifest files are known',
    );

    my $source_progress = Developer::Dashboard::CLI::Skills::_skills_install_progress_for_sources(qw(one two));
    isa_ok( $source_progress, 'Local::CaptureProgress', 'multi-source skills install progress also uses the capture progress override' );
    is( $source_progress->{max_detail_lines}, 10, 'multi-source skills install progress also caps dependency detail output at ten lines' );
}

{
    my $skill_root = tempdir( CLEANUP => 1 );
    my $manager = Developer::Dashboard::SkillManager->new();
    make_path($skill_root);
    _write_file( File::Spec->catfile( $skill_root, 'aptfile' ), "jq\n" );
    _write_file( File::Spec->catfile( $skill_root, 'brewfile' ), "jq\n" );
    _write_file( File::Spec->catfile( $skill_root, 'package.json' ), qq|{"name":"skill","version":"1.0.0"}\n| );
    _write_file( File::Spec->catfile( $skill_root, 'requirements.txt' ), "requests==2.32.3\n" );
    _write_file( File::Spec->catfile( $skill_root, 'cpanfile' ), "requires 'JSON::XS';\n" );
    _write_file( File::Spec->catfile( $skill_root, 'Makefile' ), "all:\n\t\@:\n" );
    _write_file( File::Spec->catfile( $skill_root, 'ddfile' ), "dep-alpha\n" );

    {
        local $ENV{DD_TEST_OS} = 'linux';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 1;
        local $ENV{DD_TEST_ALPINE} = 0;
        local $ENV{DD_TEST_FEDORA} = 0;
        my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
        is_deeply(
            \@task_ids,
            [
                'install_aptfile',
                'install_package_json',
                'install_requirements_txt',
                'install_cpanfile',
                'install_makefile',
                'install_ddfile',
            ],
            'skills install progress on Debian-like hosts shows only applicable manifest-backed tasks in install order',
        );
    }

    {
        local $ENV{DD_TEST_OS} = 'darwin';
        local $ENV{DD_TEST_DEBIAN_LIKE} = 0;
        local $ENV{DD_TEST_ALPINE} = 0;
        local $ENV{DD_TEST_FEDORA} = 0;
        my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
        is_deeply(
            \@task_ids,
            [
                'install_brewfile',
                'install_package_json',
                'install_requirements_txt',
                'install_cpanfile',
                'install_makefile',
                'install_ddfile',
            ],
            'skills install progress on macOS shows brewfile plus present cross-platform manifests only',
        );
    }
}

{
    local $ENV{DD_TEST_OS} = 'MSWin32';
    local $ENV{DD_TEST_DEBIAN_LIKE} = 0;
    local $ENV{DD_TEST_ALPINE} = 0;
    local $ENV{DD_TEST_FEDORA} = 0;
    my $skill_root = tempdir( CLEANUP => 1 );
    my $manager = Developer::Dashboard::SkillManager->new();
    _write_file( File::Spec->catfile( $skill_root, 'wingetfile' ), "Git.Git\n" );
    _write_file( File::Spec->catfile( $skill_root, 'package.json' ), qq|{"name":"skill","version":"1.0.0"}\n| );

    my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
    is_deeply(
        \@task_ids,
        [ 'install_wingetfile', 'install_package_json' ],
        'skills install progress on Windows shows wingetfile plus present cross-platform manifests only',
    );
}

{
    local $ENV{DD_TEST_OS} = 'linux';
    local $ENV{DD_TEST_DEBIAN_LIKE} = 0;
    local $ENV{DD_TEST_ALPINE} = 1;
    local $ENV{DD_TEST_FEDORA} = 0;
    my $skill_root = tempdir( CLEANUP => 1 );
    my $manager = Developer::Dashboard::SkillManager->new();
    _write_file( File::Spec->catfile( $skill_root, 'apkfile' ), "git\n" );
    _write_file( File::Spec->catfile( $skill_root, 'brewfile' ), "jq\n" );
    my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
    is_deeply( \@task_ids, ['install_apkfile'], 'skills install progress on Alpine hosts hides unrelated system package manifests even when they exist' );
}

{
    local $ENV{DD_TEST_OS} = 'linux';
    local $ENV{DD_TEST_DEBIAN_LIKE} = 0;
    local $ENV{DD_TEST_ALPINE} = 0;
    local $ENV{DD_TEST_FEDORA} = 1;
    my $skill_root = tempdir( CLEANUP => 1 );
    my $manager = Developer::Dashboard::SkillManager->new();
    _write_file( File::Spec->catfile( $skill_root, 'dnfile' ), "git\n" );
    my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
    is_deeply( \@task_ids, ['install_dnfile'], 'skills install progress on Fedora-like hosts keeps only dnfile-backed package manager work' );
}

{
    local $ENV{DD_TEST_OS} = 'solaris';
    local $ENV{DD_TEST_DEBIAN_LIKE} = 0;
    local $ENV{DD_TEST_ALPINE} = 0;
    local $ENV{DD_TEST_FEDORA} = 0;
    my $skill_root = tempdir( CLEANUP => 1 );
    my $manager = Developer::Dashboard::SkillManager->new();
    _write_file( File::Spec->catfile( $skill_root, 'aptfile' ), "jq\n" );
    _write_file( File::Spec->catfile( $skill_root, 'brewfile' ), "jq\n" );
    _write_file( File::Spec->catfile( $skill_root, 'cpanfile' ), "requires 'JSON::XS';\n" );
    my @task_ids = map { $_->{id} } @{ $manager->dependency_progress_tasks_for_skill_path($skill_root) || [] };
    is_deeply(
        \@task_ids,
        ['install_cpanfile'],
        'skills install progress on unknown hosts still hides OS-specific manifests and keeps only present cross-platform tasks',
    );
}

done_testing();

sub _write_file {
    my ( $path, $content ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($path);
    make_path($dir) if defined $dir && $dir ne '' && !-d $dir;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    return 1;
}

__END__

=pod

=head1 NAME

t/45-skills-progress-platform.t - skill install progress host filtering regression

=head1 PURPOSE

This test keeps the skill-install progress board aligned with the current host.
It verifies that dependency detail output is capped to ten lines and that only
platform-relevant package-manager tasks stay visible in the progress board.

=head1 WHY IT EXISTS

The skills install progress board became noisy and misleading because it showed
every package-manager step regardless of the current operating system. This
test exists to stop regressions where Linux users see irrelevant Brew or
Winget progress rows, macOS users see Apt rows, or dependency output floods
the whole terminal instead of staying capped.

=head1 WHEN TO USE

Use this test when changing the skills install progress task list, the
platform-detection logic behind package-manager filtering, or the detail-line
limit used while streaming dependency installation progress.

=head1 HOW TO USE

Run this file directly with C<prove -lv t/45-skills-progress-platform.t> when
iterating on the progress board behaviour, or let it run through the full test
suite to confirm the regression stays covered across the release gates. The
test forces synthetic Linux and macOS host markers through environment
variables and inspects the captured progress object produced by the skills
helper.

=head1 WHAT USES IT

This file is used by the repository release metadata gate, the full Perl test
suite, and contributors changing C<Developer::Dashboard::CLI::Skills> or the
shared progress rendering behaviour.

=head1 EXAMPLES

  prove -lv t/45-skills-progress-platform.t
  prove -lr t

=cut

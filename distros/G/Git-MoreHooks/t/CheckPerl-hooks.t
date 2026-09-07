#!perl
use strict;
use warnings;
use Test2::V0;

use Test2::Require::Module 'Perl::Critic';
use Log::Any::Adapter ( 'Stderr', log_level => 'trace' );
use Git::Hooks::Test ':all';
use Path::Tiny;
use English qw( -no_match_vars );  # Avoids regex performance penalty in perl 5.16 and earlier

my ( $repo, $clone, $T );
# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

sub setup_repos {
    ( $repo, undef, $clone, $T ) = new_repos();

    install_hooks( $repo,  undef, qw/pre-commit/ );
    install_hooks( $clone, undef, qw/update pre-receive/ );
    return;
}

sub modify_file {
    my ( $testname, $filepath, $action, $data ) = @_;

    if( ! defined $data ) {
        fail($testname);
        diag("[TEST FRAMEWORK INTERNAL ERROR] No data\n");
    }
    my @path_parts = split qr{/}msx, $filepath;
    my $wcpath     = path( $repo->work_tree() );
    my $file       = $wcpath->child(@path_parts);

    unless ( -e $file ) {    ## no critic (ControlStructures::ProhibitUnlessBlocks)
        pop @path_parts;
        my $dirname = $wcpath->child(@path_parts);
        $dirname->mkpath;
    }

    if ( $action eq 'append' ) {
        if ( $file->append( $data ) ) {
            $repo->run( add => $file );
        }
        else {
            fail($testname);
            diag("[TEST FRAMEWORK INTERNAL ERROR] Cannot append to file: $file; $OS_ERROR\n");
        }
    }
    elsif ( $action eq 'truncate' ) {
        if ( $file->append( { truncate => 1 }, $data ) ) {
            $repo->run( add => $file );
        }
        else {
            fail($testname);
            diag("[TEST FRAMEWORK INTERNAL ERROR] Cannot write to file: $file; $OS_ERROR\n");
        }
    }
    elsif ( $action eq 'rm' ) {
        $repo->run( rm => $file );
    }
    else {
        fail($testname);
        diag("[TEST FRAMEWORK INTERNAL ERROR] Invalid action: $action; $OS_ERROR\n");
    }

    return $file;
}

sub check_can_commit {
    my ( $testname, $filepath, $action, $data, $env ) = @_;
    my $all_env = { %git_test_env, %{$env} };
    modify_file( $testname, $filepath, $action, $data );
    test_ok( $testname, $repo, 'commit', '-m', $testname, { env => $all_env } );
    return 1;
}

sub check_cannot_commit {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $testname, $regex, $filepath, $action, $data, $env ) = @_;
    my $all_env  = { %git_test_env, %{$env} };
    my $filename = modify_file( $testname, $filepath, $action, $data );
    my $exit =
      $regex
      ? test_nok_match( $testname, $regex, $repo, 'commit', '-m', $testname, { env => $all_env } )
      : test_nok( $testname, $repo, 'commit', '-m', $testname, { env => $all_env } );
    $repo->run(qw/reset --hard/);
    return $exit;
}

setup_repos();

# Put the hook into use.
$repo->run( qw/config githooks.plugin Git::MoreHooks::CheckPerl/, { env => {%git_test_env} } );
$repo->run( qw(commit --allow-empty -m), 'Initial (Empty) Commit', { env => {%git_test_env} } );

# Normal config
{
    # Overriding variables (because you never know...)
    my %env = (
        GIT_AUTHOR_NAME     => 'My Self',
        GIT_AUTHOR_EMAIL    => 'myself@example.com',
        GIT_COMMITTER_NAME  => 'My Self',
        GIT_COMMITTER_EMAIL => 'myself@example.com',
    );
    check_can_commit( 'empty perl script file', 'perl-script.pl', 'append', q{}, \%env );

    my $script = 'use warnings; say "Hello, World!";';

    check_cannot_commit( 'perl script file #2', undef, 'perl-script-test-2.pl', 'append', $script, \%env );
}

done_testing();

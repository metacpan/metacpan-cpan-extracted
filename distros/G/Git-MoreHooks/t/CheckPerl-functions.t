#!perl
## no critic (Subroutines::ProtectPrivateSubs)
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Spec ();
use File::Temp ();

use Test2::Require::Module 'Perl::Critic';
use Test::Requires::Git ();
use Test::Git qw(test_repository);
use Git::MoreHooks::CheckPerl ();

# We need Git which supports the --initial-branch parameter in init command.
Test::Requires::Git::test_requires_git '2.28.0';

# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

subtest 'Internals' => sub {

    # Prepare repo
    my $perlcriticrc = "verbose = 11\nseverity = brutal";

    my $r = test_repository(
        temp => [ CLEANUP => 1 ],               # File::Temp::tempdir options
        init => [ '--initial-branch', 'main' ], # git init options
        git  => {},                             # Git::Repository options
    );
    $r->run( qw/config user.name My Self/,             { env => {%git_test_env} } );
    $r->run( qw/config user.email myself@example.com/, { env => {%git_test_env} } );
    $r->run( qw( commit --allow-empty -m ), 'Initial (empty) commit', { env => \%git_test_env } );
    my $pc_rc_file = path( $r->work_tree )->child( '.perlcriticrc' );
    $pc_rc_file->append( $perlcriticrc );
    $r->run( qw( add .perlcriticrc ), { env => \%git_test_env } );
    $r->run( qw( commit -m ), 'Add .perlcriticrc', qw( .perlcriticrc ),
        { env => \%git_test_env } );

    my $pc_rc_location = 'refs/heads/main:.perlcriticrc';
    my $c = Git::MoreHooks::CheckPerl::_get_critic_profile( $r, $pc_rc_location );
    is( $c, $perlcriticrc, 'Critic content match' );

    $pc_rc_file->append( "\nforce     = 0" );
    $r->run( qw( add .perlcriticrc ), { env => \%git_test_env } );
    $r->run( qw( commit -m ), 'Add .perlcriticrc', qw( .perlcriticrc ),
        { env => \%git_test_env } );
    is( $c, $perlcriticrc, 'Critic content not match' );

    $r->run( qw/config githooks.checkperl.critic.profile/, $pc_rc_location,
        { env => {%git_test_env} } );
    my $cache = Git::MoreHooks::CheckPerl::_set_critic( $r );
    isa_ok( $cache->{'critic'}, ['Perl::Critic'], 'Critic object created' );

    my $perl_script = "use warnings;\nprint 'Hello, World!';";
    my $p_file = path( $r->work_tree )->child( 'perl-script.pl' );
    $pc_rc_file->append( $perl_script );
    my @faults = Git::MoreHooks::CheckPerl::_check_perl_critic_violations($r, ':0',
        $cache, $perl_script, 'perl-script.pl');

    cmp_ok( scalar @faults, q{>}, 1, 'One error found' );
    done_testing;
};

done_testing;

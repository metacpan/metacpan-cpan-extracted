#!perl
## no critic (Subroutines::ProtectPrivateSubs)
## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
## no critic (Modules::RequireExplicitInclusion)
use strict;
use warnings;
use Test2::V1 qw( -utf8 -x -strict -warnings ), -include => ['Data::Dumper'];
use Test2::Tools::Subtest qw( subtest_streamed );
use Path::Tiny qw( path );

use Test2::Require::Module 'Perl::Critic';
# We need Git which supports the --initial-branch parameter in init command.
use Test::Requires::Git '2.28.0';
use Test::Git qw( test_repository );
use Git::MoreHooks::CheckPerl ();
use Git::Repository 'GitHooks';

# Eliminate the effects of system wide and global configuration.
# https://metacpan.org/dist/Git-Repository/view/lib/Git/Repository/Tutorial.pod#Ignore-the-system-and-global-configuration-files
my %git_test_env = (
    LC_ALL              => 'C',
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,
);

subtest_streamed 'Internals' => sub {

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
    T2->is( $c, $perlcriticrc, 'Critic content match' );

    $pc_rc_file->append( "\nforce     = 0" );
    $r->run( qw( add .perlcriticrc ), { env => \%git_test_env } );
    $r->run( qw( commit -m ), 'Add .perlcriticrc', qw( .perlcriticrc ),
        { env => \%git_test_env } );
    T2->is( $c, $perlcriticrc, 'Critic content not match' );

    $r->run( qw/config githooks.checkperl.critic.profile/, $pc_rc_location,
        { env => {%git_test_env} } );
    my $cache = Git::MoreHooks::CheckPerl::_set_critic( $r );
    T2->isa_ok( $cache->{'critic'}, ['Perl::Critic'], 'Critic object created' );

    my $perl_script = "use warnings;\nprint 'Hello, World!';";
    my $p_file = path( $r->work_tree )->child( 'perl-script.pl' );
    $pc_rc_file->append( $perl_script );
    my @faults = Git::MoreHooks::CheckPerl::_check_perl_critic_violations($r, ':0',
        $cache, $perl_script, 'perl-script.pl');

    T2->cmp_ok( scalar @faults, q{>}, 1, 'One error found' );
    T2->done_testing;
};

my %CHECK_PERL_DEFAULT_CONFIG = (
    'perl-c' => {
                  'active' => [
                                0
                              ]
                },
    'critic' => {
                  'active' => [
                                'true'
                              ],
                  'profile' => []
                },
    'use-temp-files' => [
                          0
                        ],
    'name' => [
                '*.p[lm]',
                '*.psgi',
                '*.t',
              ],
    'dirpath' => [
                'bin',
                'script',
              ],
    'filepath' => [],
);

subtest_streamed 'Config and default values' => sub {

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

    my $r_githooks = Git::Repository->new( work_tree => $r->work_tree );

    Git::MoreHooks::CheckPerl::_setup_config( $r_githooks, );

    my $c = $r_githooks->get_config( 'githooks.checkperl' );

    T2->is( $c, \%CHECK_PERL_DEFAULT_CONFIG, 'very okey' );

    T2->done_testing;
};

my %CHECK_PERL_NEW_CONFIG = (
    'perl-c' => {
                  'active' => [
                                0
                              ]
                },
    'critic' => {
                  'active' => [
                                'true'
                              ],
                  'profile' => []
                },
    'use-temp-files' => [
                          'true',
                        ],
    'name' => [
                't/*.t',
                'binaries/*',
                'share/these-scripts/*',
              ],
    'dirpath' => [
                'bin',
                'script',
              ],
    'filepath' => [],
);

subtest_streamed 'Config with default values overriden' => sub {

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
    $r->run( qw( config --add githooks.checkperl.name ), 't/*.t', ,   { env => \%git_test_env } );
    $r->run( qw( config --add githooks.checkperl.name ), 'binaries/*', { env => \%git_test_env } );
    $r->run( qw( config --add githooks.checkperl.name ), 'share/these-scripts/*', { env => \%git_test_env } );
    $r->run( qw( config set --bool githooks.checkperl.use-temp-files 1),      { env => \%git_test_env } );

    my $r_githooks = Git::Repository->new( work_tree => $r->work_tree );

    Git::MoreHooks::CheckPerl::_setup_config( $r_githooks, );

    my $c = $r_githooks->get_config( 'githooks.checkperl' );

    T2->is( $c, \%CHECK_PERL_NEW_CONFIG, 'very okey' );

    T2->done_testing;
};

T2->done_testing;

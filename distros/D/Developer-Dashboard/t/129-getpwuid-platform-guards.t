#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Platform qw(passwd_home_directory passwd_user_name);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;

# The child-process scenario below re-runs the shipped modules under a perl
# whose getpwuid dies, so resolve the checkout library path before the hermetic
# chdir moves the cwd away from the repository root.
my $repo_lib = File::Spec->rel2abs('lib');

# Hermetic runtime: isolated HOME plus an isolated state root, with the cwd
# anchored inside the temp HOME so DD-OOP-LAYER discovery resolves from a
# controlled tree instead of the checkout's own runtime layer.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $windows = 'MSWin32';

# A uid that cannot own a passwd record on the test host, used to exercise the
# "no record" outcome with the real getpwuid instead of a stub.
my $absent_uid = 4294967294;

# ---------------------------------------------------------------------------
# Feature: the guarded passwd accessors never die.
# Scenario: on a Windows runtime the accessors short-circuit before any passwd
# call, because perl leaves getpwuid unimplemented there and it dies when
# called.
# ---------------------------------------------------------------------------
{
    local $Developer::Dashboard::Platform::OS_NAME = $windows;

    my $name = eval { passwd_user_name($<) };
    is( $@,    '',    'passwd_user_name does not die on a Windows runtime' );
    is( $name, undef, 'passwd_user_name reports no name on a Windows runtime' );

    my $dir = eval { passwd_home_directory($>) };
    is( $@,   '',    'passwd_home_directory does not die on a Windows runtime' );
    is( $dir, undef, 'passwd_home_directory reports no home on a Windows runtime' );
}

# ---------------------------------------------------------------------------
# Scenario: on a runtime with a real passwd database the accessors still return
# the account name and home directory.
# ---------------------------------------------------------------------------
{
    my @entry = getpwuid($<);
    is( passwd_user_name($<),      $entry[0], 'passwd_user_name returns the real account name' );
    is( passwd_home_directory($<), $entry[7], 'passwd_home_directory returns the real home directory' );

    is( passwd_user_name($absent_uid),      undef, 'passwd_user_name reports no name for an absent uid' );
    is( passwd_home_directory($absent_uid), undef, 'passwd_home_directory reports no home for an absent uid' );
}

# ---------------------------------------------------------------------------
# Feature: PathRegistry state-root namespacing on non-interactive Windows.
# Scenario: a Windows service or scheduled job has USER and LOGNAME unset and
# only USERNAME set, so the state-root user resolves from USERNAME instead of
# dying inside getpwuid.
# ---------------------------------------------------------------------------
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

    {
        local %ENV = %ENV;
        local $Developer::Dashboard::Platform::OS_NAME = $windows;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        $ENV{USERNAME} = 'DD Service$';

        my $resolved = eval { $paths->_state_root_user };
        is( $@,        '',              'the state-root user resolves without dying on Windows' );
        is( $resolved, 'DD_Service_',   'USERNAME namespaces the state root on Windows and is sanitized' );
    }

    # Scenario: nothing in the environment names the account, so the literal
    # fallback documented for this chain is actually reached.
    {
        local %ENV = %ENV;
        local $Developer::Dashboard::Platform::OS_NAME = $windows;
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        delete $ENV{USERNAME};

        my $resolved = eval { $paths->_state_root_user };
        is( $@,        '',     'the state-root user survives a fully anonymous Windows environment' );
        is( $resolved, 'user', 'the literal fallback is reached when no environment variable names the account' );
    }
}

# ---------------------------------------------------------------------------
# Feature: SkillManager home resolution on non-interactive Windows.
# Scenario: HOME is unset and USERPROFILE names the home, so the Windows
# fallback takes effect instead of dying in the passwd lookup ahead of it.
# ---------------------------------------------------------------------------
{
    my $profile_home = tempdir( CLEANUP => 1 );

    {
        local %ENV = %ENV;
        local $Developer::Dashboard::Platform::OS_NAME = $windows;
        delete $ENV{HOME};
        $ENV{USERPROFILE} = $profile_home;

        my $manager = eval { Developer::Dashboard::SkillManager->new };
        is( $@, '', 'SkillManager->new does not die on Windows without HOME' );
        isa_ok( $manager, 'Developer::Dashboard::SkillManager', 'SkillManager built from USERPROFILE' );
        is( $manager->{paths}->home, $profile_home,
            'SkillManager resolves USERPROFILE as the runtime home on Windows' );
    }

    # Scenario: no home variable at all reports the intended explicit error,
    # not an unimplemented-function crash from the passwd lookup.
    {
        local %ENV = %ENV;
        local $Developer::Dashboard::Platform::OS_NAME = $windows;
        delete $ENV{HOME};
        delete $ENV{USERPROFILE};

        my $manager = eval { Developer::Dashboard::SkillManager->new };
        is( $manager, undef, 'SkillManager->new fails when no home is resolvable' );
        like( $@, qr/Missing home directory/, 'the failure names the missing home directory' );
        unlike( $@, qr/unimplemented/i, 'the failure is not an unimplemented passwd function' );
    }
}

# ---------------------------------------------------------------------------
# Feature: the guards hold against a real dying getpwuid, not just a forced
# platform name.
# Scenario: a child perl whose getpwuid dies exactly as Windows perl does
# resolves both fallback chains, proving the eval guard and not only the
# is_windows() short-circuit protects them. This mirrors the technique the
# install-bootstrap gate uses for the make staging recipe.
# ---------------------------------------------------------------------------
{
    my $profile_home = tempdir( CLEANUP => 1 );
    my $prelude      = 'BEGIN { *CORE::GLOBAL::getpwuid = sub ($) { die "The getpwuid function is unimplemented" }; } ';
    my $child        = <<'PERL';
use strict;
use warnings;
use Developer::Dashboard::SkillManager;
my $manager = Developer::Dashboard::SkillManager->new;
print "HOME=", $manager->{paths}->home, "\n";
print "STATE_USER=", $manager->{paths}->_state_root_user, "\n";
PERL

    my ( $stdout, $stderr, $exit ) = capture {
        local %ENV = %ENV;
        delete $ENV{HOME};
        delete $ENV{DD_STATE_ROOT_USER};
        delete $ENV{USER};
        delete $ENV{LOGNAME};
        delete $ENV{USERNAME};
        $ENV{USERPROFILE} = $profile_home;
        system( $^X, '-I' . $repo_lib, '-e', $prelude . $child );
        $?;
    };

    is( $exit >> 8, 0, 'both fallback chains run to completion under a getpwuid that dies' )
      or diag $stderr;
    is( $stderr, '', 'the dying passwd lookup leaks no warnings or errors' );
    like( $stdout, qr/^HOME=\Q$profile_home\E$/m,
        'the skill manager home falls back to USERPROFILE when getpwuid dies' );
    like( $stdout, qr/^STATE_USER=user$/m,
        'the state-root user falls back to the literal when getpwuid dies' );
}

done_testing();

__END__

=pod

=head1 NAME

t/129-getpwuid-platform-guards.t - regression gate for the guarded passwd
lookups behind the runtime state-root and skill-manager home fallbacks

=head1 PURPOSE

This test is the cross-platform contract for every passwd database lookup the
runtime performs. It pins the fixed behavior from both directions: it drives the
guarded platform accessors and both fallback chains with the platform name
forced to Windows, and it re-runs the shipped modules inside a child perl whose
getpwuid dies exactly as Windows perl's does, so the guard is proven against a
real dying lookup and not only against a forced platform name.

=head1 WHY IT EXISTS

Windows perl leaves the passwd functions unimplemented, and calling one dies at
runtime. The DD-389 Windows guest verification observed two fallback chains
calling the passwd database unguarded and ahead of their own Windows fallbacks:
the runtime state-root user, which namespaces the shared temporary state area,
and the skill manager's home resolution. On a non-interactive Windows session -
a service, a scheduled job, or an agent runner - the interactive user variables
are unset, so those chains aborted before the fallback that was written for
Windows could ever run.

=head1 WHEN TO USE

Use this file when changing the runtime state-root naming, the skill manager
home resolution, or the platform passwd accessors they share. Any new caller of
the passwd database belongs here as well, because every such caller has to stay
safe on a runtime that has no passwd database at all.

=head1 HOW TO USE

Run C<prove -lv t/129-getpwuid-platform-guards.t> while iterating on the guards,
and keep it green in the full suite run. The child-process scenario needs the
checkout library path, so run it from the repository root.

=head1 WHAT USES IT

The repository test suite uses this file as the cross-platform regression gate
for the passwd fallbacks. The Windows end-to-end verification uses the same
expectations on a real guest: a session with no interactive user variables must
still resolve a usable state-root user and a usable home directory.

=head1 EXAMPLES

Example 1:

  prove -lv t/129-getpwuid-platform-guards.t

Run the guard regression gate by itself while changing the fallback chains.

Example 2:

  prove -lv t/84-platform-coverage.t t/97-pathregistry-coverage.t t/129-getpwuid-platform-guards.t

Run it beside the coverage files that own the modules it exercises.

=cut

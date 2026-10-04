#!/usr/bin/env perl

use strict;
use warnings;

# BEGIN-time CORE::GLOBAL overrides so ActionRunner and CommandRunner resolve
# open and pipe through them. They fail only for exact registered paths (or when
# the pipe flag is armed) and can redirect one path to another file, so the
# error branches run for any uid, root included.
our ( %FAIL, %REDIRECT, $FAIL_PIPE );

BEGIN {
    require Symbol;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            if ( $FAIL{ $_[2] } ) {
                $! = 13;
                return 0;
            }
            return CORE::open( $_[0], $_[1], $REDIRECT{ $_[2] } ) if $REDIRECT{ $_[2] };
        }
        # A bareword handle (STDIN/STDOUT/STDERR) arrives as a plain name.
        if ( defined $_[0] && !ref $_[0] && ref \$_[0] eq 'SCALAR' ) {
            my $fh = Symbol::qualify_to_ref( $_[0], scalar caller );
            return CORE::open( $fh, $_[1] ) if @_ == 2;
            return CORE::open( $fh, $_[1], @_[ 2 .. $#_ ] );
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::pipe = sub (**) {
        if ($FAIL_PIPE) {
            $! = 24;
            return 0;
        }
        return CORE::pipe( $_[0], $_[1] );
    };
}

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::CommandRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home, workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ] );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $runner = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

sub write_file {
    my ( $file, $text ) = @_;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# run_command_action falls back to the current directory when none is given.
{
    my $result = $runner->run_command_action( command => 'pwd' );
    like( $result->{stdout}, qr/\S/, 'an action without a cwd runs in the current directory' );
}

# A failing pipe stops a background action before it forks.
{
    local $FAIL_PIPE = 1;
    my $err = eval { $runner->run_command_action( command => 'true', cwd => $home, background => 1 ); 1 } ? '' : $@;
    like( $err, qr/Unable to create background action pipe/, 'a background action reports a pipe failure' );
}

# Devel::Cover stops recording in a process once a real exec has been attempted,
# so the "exec returned" failure path is driven through a stubbed _exec_command
# that returns false while the detached child is simulated in-process.
{
    my $fork_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::_fork_process = sub {
        $fork_calls++;
        return fork() if $fork_calls == 1;
        return 0;
    };
    local *Developer::Dashboard::ActionRunner::_exec_command = sub { return 0 };
    my $err = eval { $runner->run_command_action( command => 'never-execs', cwd => $home, background => 1, timeout_ms => 1000 ); 1 } ? '' : $@;
    like( $err, qr/Unable to exec background action command/, 'a background command whose exec returns reports the failure' );
}

# The procfs state reader tolerates an unreadable or unparsable stat file.
SKIP: {
    skip '/proc is not readable here', 3 if !-r "/proc/$$/stat";
    my $stat = "/proc/$$/stat";
    {
        local $FAIL{$stat} = 1;
        ok( !defined $runner->_read_process_state($$), 'an unopenable procfs stat file yields no state' );
    }
    my $garbage = write_file( File::Spec->catfile( $home, 'garbage-stat' ), "not a stat line\n" );
    {
        local $REDIRECT{$stat} = $garbage;
        my $state = $runner->_read_process_state($$);
        ok( !defined $state || $state =~ /\A[A-Za-z]\z/, 'an unparsable procfs stat file falls through to ps' );
    }
    like( $runner->_read_process_state($$), qr/\A[A-Za-z]\z/, 'the real procfs stat file parses' );
}

# CommandRunner ignores a pid file it cannot open.
{
    my $pidfile = write_file( File::Spec->catfile( $home, 'cmd.pid' ), "1234\n" );
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($pidfile), 1234, 'a readable pid file yields its pid' );
    local $FAIL{$pidfile} = 1;
    is( Developer::Dashboard::CommandRunner::command_pid_from_file($pidfile), undef, 'an unopenable pid file yields no pid' );
}

done_testing;

__END__

=pod

=head1 NAME

t/711-actionrunner-commandrunner-coverage.t - failure-injection coverage for ActionRunner and CommandRunner

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the background-action pipe failure, the procfs stat read failures, the default-cwd fallback and the unreadable pid file branch through BEGIN-time CORE::GLOBAL open and pipe overrides.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and these branches only run when a system call fails, which file permissions cannot force when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the background action spawn, the process-state reader or the command pid-file reader, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/711-actionrunner-commandrunner-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/711-actionrunner-commandrunner-coverage.t

Run this coverage-gap test by itself while editing ActionRunner or CommandRunner.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/711-actionrunner-commandrunner-coverage.t

Confirm the failure branches are reported as covered.

=cut

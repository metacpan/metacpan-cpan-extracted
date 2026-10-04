#!/usr/bin/env perl

use strict;
use warnings;

# Directories whose chdir should fail even for a privileged user, so the
# "Unable to change directory" branches can be driven hermetically.
our %FAIL_CHDIR;

BEGIN {
    no warnings 'once';
    *CORE::GLOBAL::chdir = sub (;$) {
        if ( @_ && defined $_[0] && exists $FAIL_CHDIR{ $_[0] } ) {
            $! = 13;
            return 0;
        }
        return @_ ? CORE::chdir( $_[0] ) : CORE::chdir();
    };
}

use Test::More;
use Cwd qw(abs_path cwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Ticket qw(run_workspace_command);

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# ok_tmux()
# Builds a tmux runner stand-in that succeeds silently for every argv.
# Input: none.
# Output: tmux runner coderef.
sub ok_tmux {
    return sub { return { exit_code => 0, stdout => '', stderr => '' } };
}

# error_from($code)
# Runs a code reference and returns the exception text, or empty when it lives.
# Input: code reference.
# Output: error string.
sub error_from {
    my ($code) = @_;
    return eval { $code->(); 1 } ? '' : $@;
}

my $dir     = File::Spec->catdir( $home, 'ws-dir' );
my $missing = File::Spec->catdir( $home, 'no-such-dir' );
make_path($dir);

subtest 'a path alias that is not a directory is refused without -c' => sub {
    my $err = error_from( sub { run_workspace_command( args => ['DD-1'], tmux => ok_tmux(), resolve_dir => sub { return $missing } ) } );
    like( $err, qr/Workspace path alias 'DD-1' resolves to '\Q$missing\E', which is not a directory/, 'the non-directory alias target is reported' );
};

subtest 'an empty or undefined alias target leaves the directory alone' => sub {
    for my $target ( undef, '' ) {
        my $plan = run_workspace_command( args => ['DD-2'], tmux => ok_tmux(), resolve_dir => sub { return $target } );
        is( $plan->{session}, 'DD-2', 'workspace proceeds without changing directory' );
    }
};

subtest 'chdir failures are reported for both the -c and alias forms' => sub {
    local $FAIL_CHDIR{$dir} = 1;
    my $err = error_from( sub { run_workspace_command( args => [ '-c', 'DD-3' ], tmux => ok_tmux(), resolve_dir => sub { return $dir } ) } );
    like( $err, qr/Unable to change directory to '\Q$dir\E' for workspace 'DD-3'/, '-c chdir failure is reported' );

    $err = error_from( sub { run_workspace_command( args => ['DD-4'], tmux => ok_tmux(), resolve_dir => sub { return $dir } ) } );
    like( $err, qr/Unable to change directory to '\Q$dir\E' for workspace path alias 'DD-4'/, 'alias chdir failure is reported' );
};

is_deeply( \@warnings, [], 'no warnings escaped' );

done_testing;

__END__

=pod

=head1 NAME

t/304-cli-ticket-full-coverage.t - workspace directory branch coverage for CLI::Ticket

=head1 DESCRIPTION

Covers the alias-not-a-directory refusal and both chdir failure branches of
C<run_workspace_command>, using a C<chdir> override so the failures also occur
for privileged users.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: workspace directory branch coverage for CLI::Ticket.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/304-cli-ticket-full-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/304-cli-ticket-full-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/304-cli-ticket-full-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Developer::Dashboard::PageRuntime;

my $class = 'Developer::Dashboard::PageRuntime';

{
    no warnings 'redefine';
    local $Developer::Dashboard::PageRuntime::SETPGID = sub { return 1 };

    my @seen;
    local *Developer::Dashboard::PageRuntime::_exec_command = sub { my ( $c, @command ) = @_; @seen = @command; return 0 };
    my $ok = eval { $class->_exec_saved_ajax_command( 'worker', 'arg' ); 1 };
    ok( !$ok, 'a failed exec is reported as an error' );
    like( $@, qr/Unable to exec saved ajax command worker/, 'the error names the command that could not be executed' );
    is_deeply( \@seen, [ 'worker', 'arg' ], 'the helper receives the whole command' );

    local *Developer::Dashboard::PageRuntime::_exec_command = sub { return 1 };
    my $survived = eval { $class->_exec_saved_ajax_command( 'worker' ); 1 };
    ok( $survived, 'a helper that reports success lets the caller return' );
}

{
    my @warnings;
    my $failed;
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $failed = $class->_exec_command('/no/such/saved-ajax-worker');
    }
    ok( !$failed, '_exec_command returns false when the exec fails' );
    like( join( '', @warnings ), qr{Can't exec "/no/such/saved-ajax-worker"}, 'the failed exec is reported as a warning naming the command' );
}

done_testing;

__END__

=pod

=head1 NAME

t/800-pageruntime-exec-helper-coverage.t - covers the exec helper behind the saved ajax launcher in Developer::Dashboard::PageRuntime

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It stubs the exec helper so both outcomes of C<_exec_saved_ajax_command> run, and calls the helper itself on a command that cannot be executed.

=head1 WHY IT EXISTS

It exists because Devel::Cover records nothing after a failed exec in the same sub, so the failure path could only be covered by moving the exec into its own helper and stubbing that helper (Problem 20).

=head1 WHEN TO USE

Use this file when you change the saved ajax launcher or its exec helper, or when a coverage run reports the exec failure line as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/800-pageruntime-exec-helper-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/800-pageruntime-exec-helper-coverage.t

Run this coverage-gap test by itself while editing the saved ajax launcher.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/800-pageruntime-exec-helper-coverage.t

Confirm both outcomes of the exec check are reported as covered.

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::OpenFile;
use Developer::Dashboard::CLI::Ticket;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0]; return };

my $dir = tempdir( CLEANUP => 1 );

# The exec handoffs are split into tiny helpers; the dying fall-through after a
# failed exec is reached by replacing the helper, and the helpers themselves are
# driven through a genuinely failing exec (nothing runnable on PATH).
{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::OpenFile::_exec_raw = sub { $! = 2; return 0 };
    eval { Developer::Dashboard::CLI::OpenFile::_command_exec( '/some/editor', 'file.txt' ) };
    like( $@, qr{\QUnable to run command '/some/editor'\E}, '_command_exec dies naming the command when the exec returns' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Ticket::_exec_tmux = sub { $! = 2; return 0 };
    eval { Developer::Dashboard::CLI::Ticket::exec_workspace_attach( args => ['attach-session'] ) };
    like( $@, qr/Unable to exec tmux to attach the workspace session/, 'exec_workspace_attach dies when the tmux exec returns' );
}

{
    my $got = Developer::Dashboard::CLI::OpenFile::_exec_raw( File::Spec->catfile( $dir, 'no-such-editor' ), 'x' );
    ok( !$got, '_exec_raw returns false when the editor cannot be executed' );
}

{
    local $ENV{PATH} = $dir;
    my $got = Developer::Dashboard::CLI::Ticket::_exec_tmux('attach-session');
    ok( !$got, '_exec_tmux returns false when tmux is not on PATH' );
}

ok( scalar( grep {/Can't exec/} @warnings ) >= 1, 'the failed execs warned as perl does' );
is( scalar( grep { !/Can't exec/ } @warnings ), 0, 'no other warnings were emitted' );

done_testing;

__END__

=pod

=head1 NAME

t/770-cli-exec-handoff-coverage.t - covers the failed-exec fall-through of OpenFile and Ticket

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives the editor and tmux exec handoffs through their failure paths without replacing the test process.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/770-cli-exec-handoff-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/770-cli-exec-handoff-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/770-cli-exec-handoff-coverage.t

Confirm the targeted lines are reported as covered.

=cut

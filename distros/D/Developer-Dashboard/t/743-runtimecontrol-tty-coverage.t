#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Spec;

use lib 'lib';

use Developer::Dashboard::CLI::RuntimeControl;

my $pkg = 'Developer::Dashboard::CLI::RuntimeControl';

{
    no warnings 'redefine';
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = '';
    {
        local *Developer::Dashboard::CLI::RuntimeControl::_stderr_is_tty = sub { 1 };
        my $progress = Developer::Dashboard::CLI::RuntimeControl::_lifecycle_progress( title => 't', tasks => [] );
        isa_ok( $progress, 'Developer::Dashboard::CLI::Progress', 'progress is built for an interactive terminal even when not enabled' );
    }
    {
        local *Developer::Dashboard::CLI::RuntimeControl::_stderr_is_tty = sub { 0 };
        ok( !defined Developer::Dashboard::CLI::RuntimeControl::_lifecycle_progress( title => 't', tasks => [] ), 'progress is skipped when disabled and not interactive' );
    }
    {
        local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
        local *Developer::Dashboard::CLI::RuntimeControl::_stderr_is_tty = sub { 0 };
        isa_ok( Developer::Dashboard::CLI::RuntimeControl::_lifecycle_progress( title => 't', tasks => [] ), 'Developer::Dashboard::CLI::Progress', 'progress is built when enabled without a terminal' );
    }
}

ok( defined &Developer::Dashboard::CLI::RuntimeControl::_stderr_is_tty, 'the terminal probe exists' );
{
    local *STDERR;
    open STDERR, '>', File::Spec->devnull or die;
    ok( !Developer::Dashboard::CLI::RuntimeControl::_stderr_is_tty(), 'the terminal probe is false for a redirected STDERR' );
}

done_testing;

__END__

=pod

=head1 NAME

t/743-runtimecontrol-tty-coverage.t - covers the terminal-probe branches of Developer::Dashboard::CLI::RuntimeControl

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It stubs the C<_stderr_is_tty> probe so C<_lifecycle_progress> runs its interactive and non-interactive paths deterministically.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and a real terminal is never available under prove.

=head1 WHEN TO USE

Use this file when you change C<_lifecycle_progress>, or when a coverage run reports its terminal branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/743-runtimecontrol-tty-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  prove -lv t/743-runtimecontrol-tty-coverage.t

Run this coverage-gap test by itself while editing the lifecycle progress code.

=cut

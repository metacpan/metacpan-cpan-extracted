use strict;
use warnings;

use Test::More;

my @modules = qw(
  Developer::Dashboard
  Developer::Dashboard::Auth
  Developer::Dashboard::PathRegistry
  Developer::Dashboard::FileRegistry
  Developer::Dashboard::Codec
  Developer::Dashboard::JSON
  Developer::Dashboard::DataHelper
  Developer::Dashboard::Folder
  Developer::Dashboard::Zipper
  Developer::Dashboard::Runtime::Result
  Developer::Dashboard::InternalCLI
  Developer::Dashboard::CLI::OpenFile
  Developer::Dashboard::CLI::Paths
  Developer::Dashboard::CLI::Query
  Developer::Dashboard::IndicatorStore
  Developer::Dashboard::Collector
  Developer::Dashboard::CollectorRunner
  Developer::Dashboard::Config
  Developer::Dashboard::ActionRunner
  Developer::Dashboard::PageResolver
  Developer::Dashboard::PageRuntime
  Developer::Dashboard::DockerCompose
  Developer::Dashboard::Prompt
  Developer::Dashboard::RuntimeManager
  Developer::Dashboard::PageDocument
  Developer::Dashboard::PageStore
  Developer::Dashboard::SkillManager
  Developer::Dashboard::SkillDispatcher
  Developer::Dashboard::UpdateManager
  Developer::Dashboard::SessionStore
  Developer::Dashboard::Web::App
  Developer::Dashboard::Web::DancerApp
  Developer::Dashboard::Web::Server::Daemon
  Developer::Dashboard::Web::Server
);

for my $module (@modules) {
    use_ok($module);
}

done_testing;

__END__

=head1 NAME

00-load.t - load tests for Developer Dashboard modules

=head1 DESCRIPTION

This test verifies that the core Developer Dashboard modules compile and load.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file checks that the core modules load cleanly under the test harness.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/00-load.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/00-load.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut

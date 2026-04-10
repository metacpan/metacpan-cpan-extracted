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

This test is the executable regression contract for module loading and compile-time safety. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because module loading and compile-time safety has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing module loading and compile-time safety, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/00-load.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/00-load.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/00-load.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut

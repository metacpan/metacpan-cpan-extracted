#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(cwd);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Developer::Dashboard::Config;
use Developer::Dashboard::CLI::SeededPages;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
my $paths = Developer::Dashboard::PathRegistry->new(
    workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $pages = Developer::Dashboard::PageStore->new( paths => $paths );
my $migrated = $pages->migrate_legacy_json_pages;
print "Migrated " . scalar(@{$migrated}) . " legacy JSON bookmark(s)\n" if @{$migrated};

my $config_file = $config->ensure_global_file;
print "Ensured global config $config_file\n";

my @pages = $pages->list_saved_pages;
for my $seed (
    [ 'api-dashboard', Developer::Dashboard::CLI::SeededPages::api_dashboard_page() ],
    [ 'sql-dashboard', Developer::Dashboard::CLI::SeededPages::sql_dashboard_page() ],
  )
{
    my ( $id, $page ) = @{$seed};
    my $status = Developer::Dashboard::CLI::SeededPages::ensure_seeded_page(
        page  => $page,
        pages => $pages,
        paths => $paths,
    );
    push @pages, $id if !grep { $_ eq $id } @pages;
    print ucfirst($status) . " $id page\n" if $status eq 'created' || $status eq 'updated';
}

print "Runtime bootstrap complete\n";

__END__

=head1 NAME

01-bootstrap-runtime.pl - bootstrap runtime files for Developer Dashboard

=head1 DESCRIPTION

This update script writes default global configuration and creates the starter
API and SQL dashboard pages when they do not already exist.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This staged update script owns one explicit phase of runtime update, bootstrap, and staged maintenance behavior. Read it when you need the real runtime side effects, logging, and failure behavior for that phase rather than inferring it from the higher-level command wrapper.

=head1 WHY IT EXISTS

It exists so the update pipeline stays explicit, inspectable, and testable one phase at a time. That keeps failures visible and avoids hiding important runtime changes inside one oversized installer step.

=head1 WHEN TO USE

Use this file when changing runtime update, bootstrap, and staged maintenance behavior, when debugging the staged update pipeline, or when the higher-level dashboard update flow fails and you need to isolate this phase.

=head1 HOW TO USE

Run it through C<dashboard update> for the supported path, or invoke the file directly from the source tree when you need to debug only this phase. Keep the phase explicit, idempotent where intended, and noisy on failure.

=head1 WHAT USES IT

The staged runtime update pipeline, update-manager verification, and contributors debugging install or bootstrap regressions use this file.

=head1 EXAMPLES

Example 1:

  prove -lv t/26-sql-dashboard.t t/27-sql-dashboard-playwright.t

Rerun the SQL dashboard seed tests after changing how this bootstrap phase refreshes managed starter pages.

Example 2:

  dashboard update

Run the supported end-user path that can reach this update phase.

Example 3:

  perl updates/01-bootstrap-runtime.pl

Invoke only this phase while debugging the update pipeline in a source checkout.

Example 4:

  prove -lv t/04-update-manager.t

Rerun the focused update-manager coverage after changing update behavior.

=for comment FULL-POD-DOC END

=cut

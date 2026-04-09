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
use Developer::Dashboard::SeedSync;

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
    if ( grep { $_ eq $id } @pages ) {
        my $current = eval { $pages->read_saved_entry($id) };
        next
          if defined $current
          && Developer::Dashboard::SeedSync::same_content_md5( $current, $page->canonical_instruction );
        next;
    }
    $pages->save_page($page);
    push @pages, $id;
    print "Created $id page\n";
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

Update script in the Developer Dashboard codebase. This file creates the baseline runtime directories and seed files used during update and install flows.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep update/bootstrap phases explicit, rerunnable, and separately testable.

=head1 WHEN TO USE

Use this file when you are working on the staged update/bootstrap pipeline or debugging update-time runtime preparation.

=head1 HOW TO USE

Run it through the dashboard update/bootstrap flow rather than inventing a parallel manual setup path. Keep the phase idempotent and explicit so reruns are safe.

=head1 WHAT USES IT

It is used by the runtime update/bootstrap pipeline, by the related update manager logic, and by tests that verify update behaviour.

=head1 EXAMPLES

  dashboard update

That higher-level command is the supported path that eventually reaches this staged update phase.

=for comment FULL-POD-DOC END

=cut

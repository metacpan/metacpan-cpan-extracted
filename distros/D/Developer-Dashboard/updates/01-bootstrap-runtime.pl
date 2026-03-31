#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(cwd);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageDocument;
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

my $global = $config->load_global;
if ( !exists $global->{collectors} || ref( $global->{collectors} ) ne 'ARRAY' ) {
    $global->{collectors} = [
        {
            name     => 'example.collector',
            command  => "printf 'example collector output\\n'",
            cwd      => 'home',
            interval => 60,
        },
    ];
    $config->save_global($global);
    print "Wrote default global config\n";
}

my @pages = $pages->list_saved_pages;
if ( !grep { $_ eq 'welcome' } @pages ) {
    my $page = Developer::Dashboard::PageDocument->new(
        id          => 'welcome',
        title       => 'Welcome to Developer Dashboard',
        description => 'A project-neutral local dashboard starter page.',
        layout      => {
            body => "Developer Dashboard is ready.\n\nUse dashboard page new/save to create more pages.\nUse dashboard serve to browse them.\nUse dashboard collector run to refresh prepared data.\nUse dashboard ps1 from your shell to render prompt status.",
        },
        state => {
            project => '',
        },
        actions => [
            { id => 'serve', label => 'Run dashboard serve' },
            { id => 'ps1',   label => 'Use dashboard ps1 in your shell' },
        ],
    );
    $pages->save_page($page);
    print "Created welcome page\n";
}

print "Runtime bootstrap complete\n";

__END__

=head1 NAME

01-bootstrap-runtime.pl - bootstrap runtime files for Developer Dashboard

=head1 DESCRIPTION

This update script writes default global configuration and creates the starter
welcome page when they do not already exist.

=cut

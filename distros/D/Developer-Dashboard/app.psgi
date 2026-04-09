#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;
use Developer::Dashboard::Web::Server;

my $paths = Developer::Dashboard::PathRegistry->new(
    workspace_roots => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
    project_roots   => [ grep { defined && -d } map { "$ENV{HOME}/$_" } qw(projects src work) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $pages = Developer::Dashboard::PageStore->new( paths => $paths );
my $runtime = Developer::Dashboard::PageRuntime->new(
    files   => $files,
    paths   => $paths,
    aliases => $config->path_aliases,
);
my $auth = Developer::Dashboard::Auth->new(
    files => $files,
    paths => $paths,
);
my $actions = Developer::Dashboard::ActionRunner->new(
    files => $files,
    paths => $paths,
);
my $resolver = Developer::Dashboard::PageResolver->new(
    actions => $actions,
    config  => $config,
    pages   => $pages,
    paths   => $paths,
);
my $prompt = Developer::Dashboard::Prompt->new( paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );
my $app = Developer::Dashboard::Web::App->new(
    actions  => $actions,
    auth     => $auth,
    pages    => $pages,
    prompt   => $prompt,
    resolver => $resolver,
    runtime  => $runtime,
    sessions => $sessions,
);

Developer::Dashboard::Web::Server->new(
    app  => $app,
    host => $ENV{DEVELOPER_DASHBOARD_WEB_HOST} || '0.0.0.0',
    port => $ENV{DEVELOPER_DASHBOARD_WEB_PORT} || 7890,
)->psgi_app;

__END__

=head1 NAME

app.psgi - PSGI entrypoint for Developer Dashboard

=head1 DESCRIPTION

This PSGI bootstrap builds the standard dashboard web stack and exposes it for
running under C<plackup -s Starman>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

PSGI entrypoint script in the Developer Dashboard codebase. This file assembles the default PSGI web stack for Developer Dashboard and returns the Plack application object.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists so the web stack can be launched through standard PSGI tooling without forcing callers to rebuild the wiring themselves.

=head1 WHEN TO USE

Use this file when you need the PSGI app directly, when debugging web bootstrap issues, or when verifying the web stack under Plack or Starman.

=head1 HOW TO USE

Run it through PSGI tooling such as C<plackup>. When editing it, keep it as wiring code that assembles the normal dashboard web objects and returns the PSGI app.

=head1 WHAT USES IT

It is used by PSGI servers such as C<plackup>, by web-server smoke tests, and by anyone who wants the assembled web application without going through the CLI server wrapper.

=head1 EXAMPLES

  plackup -s Starman app.psgi

That starts the assembled dashboard web application through the standard PSGI server stack.

=for comment FULL-POD-DOC END

=cut

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

This PSGI entrypoint assembles the default dashboard web stack from the file registry, config store, page store, auth service, action runner, session store, and web app wrapper, then returns one PSGI application coderef. It is the non-CLI way to boot the same browser experience that C<dashboard serve> runs through the server wrapper.

=head1 WHY IT EXISTS

It exists so the dashboard can be hosted under standard PSGI tools such as C<plackup> without reimplementing object wiring in an ad hoc shell script. That keeps the web bootstrap path debuggable and makes framework-level smoke tests possible outside the CLI lifecycle manager.

=head1 WHEN TO USE

Use this file when you are debugging web bootstrap order, checking how the browser stack is assembled, or running the dashboard behind a PSGI host instead of the built-in serve/restart commands.

=head1 HOW TO USE

Run it through a PSGI server. Keep edits limited to construction and wiring of the standard runtime services; route behavior belongs in C<Developer::Dashboard::Web::App> and transport behavior belongs in C<Developer::Dashboard::Web::Server>.

=head1 WHAT USES IT

It is used by C<plackup>, by PSGI-oriented smoke tests, and by contributors who need the assembled app object without going through the process-management code in C<dashboard serve>.

=head1 EXAMPLES

Example 1:

  plackup -s Starman app.psgi

Start the dashboard through PSGI with the default Starman host and port.

Example 2:

  DEVELOPER_DASHBOARD_WEB_PORT=7891 plackup -s Starman app.psgi

Boot the same PSGI app on an explicit alternate port while debugging browser behavior.

Example 3:

  prove -lv t/03-web-app.t

Rerun the focused web-app route regression after changing this bootstrap wiring.

Example 4:

  prove -lv t/17-web-server-ssl.t

Recheck the HTTPS-facing bootstrap path when SSL-related web wiring changes.


=for comment FULL-POD-DOC END

=cut

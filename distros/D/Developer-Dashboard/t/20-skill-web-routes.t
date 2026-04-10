#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Web::App;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $test_repos = tempdir( CLEANUP => 1 );
my $paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );

my $repo = _create_skill_repo('route-skill');
my $install = $manager->install( 'file://' . $repo );
ok( !$install->{error}, 'route skill installs cleanly' ) or diag $install->{error};

my $app = Developer::Dashboard::Web::App->new(
    auth     => bless( {}, 'Local::AuthStub' ),
    pages    => bless( {}, 'Local::PagesStub' ),
    sessions => bless( {}, 'Local::SessionsStub' ),
    config   => {},
);

my $missing = $app->dispatch_request(
    path    => '/skill/missing-skill/bookmarks',
    method  => 'GET',
    headers => {},
);
is( $missing->[0], 404, 'missing skill routes return 404' );

my $list = $app->dispatch_request(
    path    => '/skill/route-skill/bookmarks',
    method  => 'GET',
    headers => {},
);
is( $list->[0], 200, 'installed skill bookmark listing returns success' );
like( $list->[2], qr/welcome/, 'bookmark listing exposes the isolated skill bookmark id' );

my $render = $app->dispatch_request(
    path    => '/skill/route-skill/bookmarks/welcome',
    method  => 'GET',
    headers => {},
);
is( $render->[0], 200, 'installed skill bookmark render route returns success' );
like( $render->[2], qr/Skill Route Bookmark/, 'skill bookmark render returns the isolated bookmark html' );

my $missing_bookmark = $app->dispatch_request(
    path    => '/skill/route-skill/bookmarks/missing',
    method  => 'GET',
    headers => {},
);
is( $missing_bookmark->[0], 404, 'missing skill bookmark routes return 404' );

done_testing();

sub _create_skill_repo {
    my ($name) = @_;
    my $repo = File::Spec->catdir( $test_repos, $name );
    make_path($repo);
    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _run_or_die(qw(git init --quiet));
    _run_or_die(qw(git config user.email test@example.com));
    _run_or_die(qw(git config user.name Test));
    make_path('cli');
    make_path('config');
    make_path('dashboards');
    _write_file( File::Spec->catfile( 'cli', 'noop' ), "#!/usr/bin/env perl\nprint qq{noop\\n};\n", 0755 );
    _write_file( File::Spec->catfile( 'config', 'config.json' ), qq|{"skill_name":"$name"}\n|, 0644 );
    _write_file(
        File::Spec->catfile( 'dashboards', 'welcome' ),
        <<'BOOKMARK',
TITLE: Skill Route Bookmark
:--------------------------------------------------------------------------------:
BOOKMARK: welcome
:--------------------------------------------------------------------------------:
HTML:
Skill Route Bookmark
BOOKMARK
        0644,
    );
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Initial route skill' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

sub _write_file {
    my ( $path, $content, $mode ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh;
    chmod $mode, $path or die "Unable to chmod $path: $!";
    return 1;
}

sub _run_or_die {
    my (@command) = @_;
    system(@command) == 0 or die "Command failed: @command";
    return 1;
}

package Local::AuthStub;
sub trust_tier { return 'admin' }
sub helper_users_enabled { return 1 }

package Local::PagesStub;
sub editable_url { return '/' }
sub render_url   { return '/' }

package Local::SessionsStub;

__END__

=pod

=head1 NAME

t/20-skill-web-routes.t - test isolated skill bookmark routes

=head1 License

This test is part of Developer Dashboard.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the isolated skill installation and routing stack. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the isolated skill installation and routing stack has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the isolated skill installation and routing stack, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/20-skill-web-routes.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/20-skill-web-routes.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/20-skill-web-routes.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut

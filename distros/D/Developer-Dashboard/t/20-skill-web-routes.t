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

Test file in the Developer Dashboard codebase. This file tests skill-backed web route behaviour.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/20-skill-web-routes.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/20-skill-web-routes.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut

#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::SkillManager;
use Developer::Dashboard::Web::App;

my $original_cwd = getcwd();
local $ENV{HOME} = tempdir( CLEANUP => 1 );
my $test_cwd = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";
my $test_repos = tempdir( CLEANUP => 1 );
my $paths = Developer::Dashboard::PathRegistry->new( home => $ENV{HOME} );
my $manager = Developer::Dashboard::SkillManager->new( paths => $paths );

my $repo = _create_skill_repo('route-skill');
my $install = $manager->install( 'file://' . $repo );
ok( !$install->{error}, 'route skill installs cleanly' ) or diag $install->{error};
my $other_repo = _create_skill_repo( 'other-skill', nav_label => 'Other Skill Nav' );
my $other_install = $manager->install( 'file://' . $other_repo );
ok( !$other_install->{error}, 'second route skill installs cleanly' ) or diag $other_install->{error};

my $store = Developer::Dashboard::PageStore->new( paths => $paths );
$store->save_page(
    Developer::Dashboard::PageDocument->from_instruction(<<'BOOKMARK')
TITLE: Shared Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Shared Index
BOOKMARK
);

my $app = Developer::Dashboard::Web::App->new(
    auth     => bless( {}, 'Local::AuthStub' ),
    pages    => $store,
    sessions => bless( {}, 'Local::SessionsStub' ),
    config   => {},
);

my $missing = $app->handle(
    path        => '/app/missing-skill/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $missing->[0], 404, 'missing nested skill routes return 404' );

my $index = $app->handle(
    path        => '/app/route-skill',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $index->[0], 200, 'installed skill index route returns success' );
like( $index->[2], qr/Skill Route Index/, 'installed skill index route renders the skill index bookmark' );
like( $index->[2], qr/Skill Route Nav/, 'installed skill index route renders skill nav fragments' );
like( $index->[2], qr/Other Skill Nav/, 'installed skill index route also renders nav fragments from other installed skills' );

my $render = $app->handle(
    path        => '/app/route-skill/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $render->[0], 200, 'installed skill page route returns success' );
like( $render->[2], qr/Skill Route Foo/, 'skill page route renders the requested skill bookmark html' );
like( $render->[2], qr/Skill Route Nav/, 'installed skill page route renders skill nav fragments' );
like( $render->[2], qr/Other Skill Nav/, 'installed skill page route renders nav contributed by other installed skills too' );

my $shared_index = $app->handle(
    path        => '/app/index',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $shared_index->[0], 200, 'saved non-skill index route returns success' );
like( $shared_index->[2], qr/Shared Index/, 'saved non-skill index route renders the shared saved page body' );
like( $shared_index->[2], qr/Skill Route Nav/, 'saved non-skill index route renders nav from installed skills' );
like( $shared_index->[2], qr/Other Skill Nav/, 'saved non-skill index route renders nav from every installed skill' );

my $disable = $manager->disable('other-skill');
ok( !$disable->{error}, 'other-skill disables cleanly for route coverage' ) or diag $disable->{error};

my $disabled_shared_index = $app->handle(
    path        => '/app/index',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $disabled_shared_index->[0], 200, 'shared index still renders after disabling one skill' );
like( $disabled_shared_index->[2], qr/Skill Route Nav/, 'shared index keeps nav from enabled skills after a disable' );
unlike( $disabled_shared_index->[2], qr/Other Skill Nav/, 'shared index drops nav from disabled skills' );

my $disabled_skill = $app->handle(
    path        => '/app/other-skill',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $disabled_skill->[0], 404, 'disabled skill routes are no longer served' );

my $legacy_render = $app->handle(
    path        => '/skill/route-skill/bookmarks/foo',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $legacy_render->[0], 200, 'legacy /skill/<repo>/bookmarks/<id> route still returns success' );
like( $legacy_render->[2], qr/Skill Route Foo/, 'legacy skill bookmark route still renders the requested skill bookmark html' );

my $missing_bookmark = $app->handle(
    path        => '/app/route-skill/missing',
    method      => 'GET',
    headers     => { host => '127.0.0.1' },
    remote_addr => '127.0.0.1',
);
is( $missing_bookmark->[0], 404, 'missing skill bookmark routes return 404' );

done_testing();

END {
    chdir $original_cwd if defined $original_cwd && length $original_cwd;
}

sub _create_skill_repo {
    my ( $name, %args ) = @_;
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
        File::Spec->catfile( 'dashboards', 'index' ),
        <<'BOOKMARK',
TITLE: Skill Route Index
:--------------------------------------------------------------------------------:
BOOKMARK: index
:--------------------------------------------------------------------------------:
HTML:
Skill Route Index
BOOKMARK
        0644,
    );
    _write_file(
        File::Spec->catfile( 'dashboards', 'foo' ),
        <<'BOOKMARK',
TITLE: Skill Route Foo
:--------------------------------------------------------------------------------:
BOOKMARK: foo
:--------------------------------------------------------------------------------:
HTML:
Skill Route Foo
BOOKMARK
        0644,
    );
    make_path( File::Spec->catdir( 'dashboards', 'nav' ) );
    _write_file(
        File::Spec->catfile( 'dashboards', 'nav', 'skill.tt' ),
        '<div>' . ( $args{nav_label} || 'Skill Route Nav' ) . "</div>\n",
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

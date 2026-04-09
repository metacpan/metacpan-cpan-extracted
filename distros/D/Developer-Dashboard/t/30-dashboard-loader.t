#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $repo_root = getcwd();
my $dashboard = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );
my $source = _slurp($dashboard);

like( $source, qr/\A#!\/usr\/bin\/env perl\b/, 'dashboard entrypoint uses /usr/bin/env perl' );
unlike( $source, qr/TITLE:\s+API Dashboard/, 'dashboard entrypoint no longer embeds the api-dashboard bookmark source' );
unlike( $source, qr/BOOKMARK:\s+api-dashboard/, 'dashboard entrypoint no longer embeds the api-dashboard bookmark id source' );
unlike( $source, qr/TITLE:\s+SQL Dashboard/, 'dashboard entrypoint no longer embeds the sql-dashboard bookmark source' );
unlike( $source, qr/BOOKMARK:\s+sql-dashboard/, 'dashboard entrypoint no longer embeds the sql-dashboard bookmark id source' );
unlike( $source, qr/Developer::Dashboard::CLI::SeededPages/, 'dashboard entrypoint no longer loads the seeded bookmark loader directly' );
unlike( $source, qr/Developer::Dashboard::CLI::Query/, 'dashboard entrypoint no longer loads the query CLI module directly' );
unlike( $source, qr/Developer::Dashboard::CLI::OpenFile/, 'dashboard entrypoint no longer loads the open-file CLI module directly' );
unlike( $source, qr/Developer::Dashboard::CLI::Ticket/, 'dashboard entrypoint no longer loads the ticket CLI module directly' );
unlike( $source, qr/\bif\s*\(\s*\$cmd\s+eq\s+'(?:encode|decode|indicator|collector|config|auth|init|cpan|page|action|docker|serve|stop|restart|shell|doctor|skills|skill)'\s*\)/, 'dashboard entrypoint no longer embeds built-in command implementation branches' );
like( $source, qr/Developer::Dashboard::InternalCLI/, 'dashboard entrypoint delegates built-in commands through InternalCLI staging' );
like( $source, qr/_exec_switchboard_command/, 'dashboard entrypoint only resolves and execs staged commands' );
like( $source, qr/_custom_command_path/, 'dashboard entrypoint resolves layered custom commands' );
like( $source, qr/_builtin_helper_path/, 'dashboard entrypoint resolves staged private built-in helpers' );

my $share_seeded_root = File::Spec->catdir( $repo_root, 'share', 'seeded-pages' );
ok( -d $share_seeded_root, 'seeded bookmark assets are shipped outside the dashboard entrypoint' );
for my $page (qw(api-dashboard.page sql-dashboard.page)) {
    ok( -f File::Spec->catfile( $share_seeded_root, $page ), "share/seeded-pages/$page is shipped" );
}
ok( !-f File::Spec->catfile( $share_seeded_root, 'welcome.page' ), 'share/seeded-pages/welcome.page is no longer shipped' );

my $lib = File::Spec->catdir( $repo_root, 'lib' );
my $fake_lib = tempdir( CLEANUP => 1 );
my $fake_web_dir = File::Spec->catdir( $fake_lib, 'Developer', 'Dashboard', 'Web' );
make_path($fake_web_dir);
my $fake_web_app = File::Spec->catfile( $fake_web_dir, 'App.pm' );
open my $fake_web_fh, '>', $fake_web_app or die "Unable to write $fake_web_app: $!";
print {$fake_web_fh} <<'PERL';
package Developer::Dashboard::Web::App;
die "lazy-loader-regression: heavy web runtime was loaded for a lightweight command\n";
PERL
close $fake_web_fh;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
local $ENV{PERL5OPT} = '-I' . $fake_lib;
my $jq_json = File::Spec->catfile( $ENV{HOME}, 'sample.json' );
open my $jq_fh, '>', $jq_json or die "Unable to write $jq_json: $!";
print {$jq_fh} qq|{"alpha":1}\n|;
close $jq_fh;

my $jq_output = qx{$^X -I$lib $dashboard jq .alpha "$jq_json" 2>&1};
my $jq_exit = $? >> 8;
is( $jq_exit, 0, 'dashboard jq stays on the lazy lightweight path without loading heavy web modules' )
  or diag $jq_output;
like( $jq_output, qr/\b1\b/, 'dashboard jq still returns the requested value' );

my $version_output = qx{$^X -I$lib $dashboard version 2>&1};
my $version_exit = $? >> 8;
is( $version_exit, 0, 'dashboard version also stays on the lightweight path without loading heavy web modules' )
  or diag $version_output;
like( $version_output, qr/^\d+\.\d+\s*\z/, 'dashboard version still prints the package version' );

my @perl_scripts = (
    File::Spec->catfile( $repo_root, 'bin', 'dashboard' ),
    File::Spec->catfile( $repo_root, 'app.psgi' ),
    (
    map { File::Spec->catfile( $repo_root, 'updates', $_ ) } qw(
      01-bootstrap-runtime.pl
      02-install-deps.pl
      03-shell-bootstrap.pl
    ),
    ),
    (
    map { File::Spec->catfile( $repo_root, 'share', 'private-cli', $_ ) } qw(
      jq
      yq
      tomq
      propq
      iniq
      csvq
      xmlq
      of
      open-file
      ticket
      path
      paths
      ps1
      _dashboard-core
      encode
      decode
      indicator
      collector
      config
      auth
      init
      cpan
      page
      action
      docker
      serve
      stop
      restart
      shell
      doctor
      skills
      skill
    ),
    ),
    (
    map { File::Spec->catfile( $repo_root, 't', $_ ) } qw(
      19-skill-system.t
      20-skill-web-routes.t
    ),
    ),
    File::Spec->catfile( $repo_root, 'integration', 'blank-env', 'run-integration.pl' ),
);

for my $path (@perl_scripts) {
    my $content = _slurp($path);
    like( $content, qr/\A#!\/usr\/bin\/env perl\b/, "$path uses /usr/bin/env perl" );
}

done_testing();

sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Unable to read $path: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

__END__

=head1 NAME

30-dashboard-loader.t - verify dashboard stays thin, lazy, and env-perl based

=head1 DESCRIPTION

This test keeps the public dashboard entrypoint free from embedded bookmark
source, verifies lightweight commands avoid the heavy web runtime, and enforces
the C</usr/bin/env perl> shebang for shipped Perl scripts.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Test file in the Developer Dashboard codebase. This file tests the thin dashboard loader and installed helper lookup behaviour.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/30-dashboard-loader.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/30-dashboard-loader.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut

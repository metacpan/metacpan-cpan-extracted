#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Test::More;

our $ROOT;
BEGIN {
    $ROOT = Cwd::abs_path( Cwd::getcwd() );
    unshift @INC, File::Spec->catdir( $ROOT, 'lib' );
}

use Developer::Dashboard::PathRegistry;

my $skill_name       = join q{}, 'sql', '-dashboard';
my $ajax_route_name  = join q{}, $skill_name, '-profiles-bootstrap';
my $skill_ok_payload = qq|{"status":"skill-local"}\n|;
my $skill_mount_path = "/tmp/$skill_name";

my $version = do {
    open my $fh, '<', File::Spec->catfile( $ROOT, 'lib', 'Developer', 'Dashboard.pm' )
      or die "Unable to read lib/Developer/Dashboard.pm: $!";
    local $/;
    my $pm = <$fh>;
    close $fh or die "Unable to close lib/Developer/Dashboard.pm: $!";
    my ($found) = $pm =~ /our \$VERSION = '([^']+)'/;
    $found || die "Unable to determine distribution version\n";
};

my $tarball = File::Spec->catfile( $ROOT, "Developer-Dashboard-$version.tar.gz" );

plan skip_all => "smart-router two-stage guard runs after dzil build when $tarball exists"
  if !-f $tarball;
plan skip_all => 'docker is required for the post-build smart-router two-stage guard'
  if !_command_on_path('docker');
plan skip_all => 'docker daemon is not reachable for the post-build smart-router two-stage guard'
  if !_docker_available();

my $repos_root = tempdir( CLEANUP => 1 );
my $skill_repo = _create_dashboard_skill_repo( $repos_root, $skill_name, $ajax_route_name );
my $container = sprintf 'dd-smart-router-two-stage-%d-%d', $$, time;
my $host_port = _find_free_port();
my $container_tarball = "/tmp/Developer-Dashboard-$version.tar.gz";

END {
    return if !$container;
    system( 'docker', 'rm', '-f', $container );
}

_run_or_die(
    'docker', 'run', '-d',
    '--name', $container,
    '-p', "127.0.0.1:$host_port:7890",
    'perl:latest',
    'sleep', 'infinity',
);
_run_or_die( 'docker', 'cp', $tarball, "$container:$container_tarball" );
_run_or_die( 'docker', 'cp', $skill_repo, "$container:$skill_mount_path" );
_run_or_die( 'docker', 'exec', $container, 'sh', '-lc', "chown -R root:root $skill_mount_path" );
_run_or_die_with_retry(
    2,
    [ 'docker', 'exec', $container, 'sh', '-lc', "cpanm --notest $container_tarball" ],
);
_run_or_die( 'docker', 'exec', $container, 'sh', '-lc', 'dashboard init' );
_run_or_die( 'docker', 'exec', $container, 'sh', '-lc', 'cd /root && dashboard restart web' );

my ( $stage1_code, $stage1_body ) = _container_http_get(
    $container,
    "http://127.0.0.1:7890/ajax/$ajax_route_name?type=json",
);
is( $stage1_code, 404, 'stage 1 root extracted-dashboard ajax route is absent before skill installation' );
is( $stage1_body, "Ajax handler not found\n", 'stage 1 root extracted-dashboard ajax route reports the handler is absent before skill installation' );

_run_or_die( 'docker', 'exec', $container, 'sh', '-lc', "cd /root && dashboard skills install file://$skill_mount_path" );
ok(
    _docker_file_exists(
        $container,
        "/root/.developer-dashboard/skills/$skill_name/dashboards/ajax/$ajax_route_name",
    ),
    'stage 2 installs the extracted-dashboard ajax handler into the skill-local dashboards/ajax tree',
);

my ( $stage2_root_code, $stage2_root_body ) = _container_http_get(
    $container,
    "http://127.0.0.1:7890/ajax/$ajax_route_name?type=json",
);
is( $stage2_root_code, 404, 'stage 2 root extracted-dashboard ajax route stays absent after skill installation' );
is( $stage2_root_body, "Ajax handler not found\n", 'stage 2 root extracted-dashboard ajax route still reports the handler is absent after skill installation' );

my ( $stage2_skill_code, $stage2_skill_body ) = _container_http_get(
    $container,
    "http://127.0.0.1:7890/ajax/$skill_name/$ajax_route_name?type=json",
);
is( $stage2_skill_code, 200, 'stage 2 skill-local extracted-dashboard ajax route resolves through the installed web stack without a restart' );
is( $stage2_skill_body, $skill_ok_payload, 'stage 2 skill-local extracted-dashboard ajax route streams the installed skill ajax handler body' );

done_testing;

sub _command_on_path {
    my ($name) = @_;
    return system( 'sh', '-lc', "command -v $name >/dev/null 2>&1" ) == 0 ? 1 : 0;
}

sub _docker_available {
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'docker', 'info' );
        return $? >> 8;
    };
    return 0 if $exit != 0;
    return 1;
}

sub _find_free_port {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        Listen    => 1,
        ReuseAddr => 1,
    ) or die "Unable to allocate a free TCP port: $!";
    my $port = $socket->sockport;
    close $socket or die "Unable to close the free-port probe socket: $!";
    return $port;
}

sub _create_dashboard_skill_repo {
    my ( $root, $name, $ajax_name ) = @_;
    my $repo = File::Spec->catdir( $root, $name );
    make_path( File::Spec->catdir( $repo, 'dashboards', 'ajax' ) );

    my $cwd = getcwd();
    chdir $repo or die "Unable to chdir to $repo: $!";
    _run_or_die(qw(git init --quiet));
    _run_or_die(qw(git config user.email test@example.com));
    _run_or_die(qw(git config user.name Test));
    _write_file(
        File::Spec->catfile( 'dashboards', 'ajax', $ajax_name ),
        "print qq|{\"status\":\"skill-local\"}\\n|;\n",
        0700,
    );
    _run_or_die(qw(git add .));
    _run_or_die( 'git', 'commit', '-m', 'Initial extracted dashboard skill fixture' );
    chdir $cwd or die "Unable to chdir back to $cwd: $!";
    return $repo;
}

sub _write_file {
    my ( $path, $content, $mode ) = @_;
    open my $fh, '>:raw', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    chmod $mode, $path or die "Unable to chmod $path: $!";
    return 1;
}

sub _run_or_die {
    my (@command) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system(@command);
        return $? >> 8;
    };
    if ( $exit != 0 ) {
        die sprintf "Command failed (%s)\nSTDOUT:\n%sSTDERR:\n%s", join( ' ', @command ), $stdout, $stderr;
    }
    return $stdout;
}

sub _run_or_die_with_retry {
    my ( $attempts, $command_ref ) = @_;
    die "_run_or_die_with_retry requires an attempt count\n" if !defined $attempts;
    die "_run_or_die_with_retry requires at least one attempt\n" if $attempts < 1;
    die "_run_or_die_with_retry requires an arrayref command\n"
      if ref $command_ref ne 'ARRAY' || !@{$command_ref};

    my $last_error;
    for my $attempt ( 1 .. $attempts ) {
        my $ok = eval {
            _run_or_die( @{$command_ref} );
        };
        return $ok if defined $ok;

        $last_error = $@;
        die $last_error if !$last_error || !_looks_like_transient_cpanm_fetch_failure($last_error);
        die $last_error if $attempt >= $attempts;
    }

    die $last_error || "Command failed after retry attempts\n";
}

sub _looks_like_transient_cpanm_fetch_failure {
    my ($error) = @_;
    return 0 if !defined $error || $error eq q{};

    return 1 if $error =~ /Failed to unpack .* no directory/sm;
    return 1 if $error =~ /Failed to fetch distribution/sm;
    return 1 if $error =~ /unexpected end of file/sm;
    return 1 if $error =~ /Child returned status 1/sm;

    return 0;
}

sub _container_http_get {
    my ( $container_name, $url ) = @_;
    my $perl = <<'PERL';
my $url = shift @ARGV;
require LWP::UserAgent;
my $ua = LWP::UserAgent->new;
my $response = $ua->get($url);
print $response->code, "\n";
print $response->decoded_content;
PERL
    my $output = _run_or_die( 'docker', 'exec', $container_name, 'perl', '-e', $perl, $url );
    my ( $code, $body ) = split /\n/, $output, 2;
    $body = '' if !defined $body;
    return ( $code + 0, $body );
}

sub _docker_file_exists {
    my ( $container_name, $path ) = @_;
    return system( 'docker', 'exec', $container_name, 'test', '-f', $path ) == 0 ? 1 : 0;
}

__END__

=pod

=head1 NAME

44-smart-router-two-stage.t - post-build Docker guard for staged smart-router extraction

=head1 DESCRIPTION

This test is a post-build guardrail. It runs only after a fresh distribution
tarball exists, installs that tarball into a blank C<perl:latest> Docker
container, and then exercises the two-stage smart-router contract for one
extracted dashboard skill fixture.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This file proves the behavior that can only be observed after packaging. The
core tarball must ship without the root SQL Ajax handler, then a later skill
install must make only the namespaced skill-local Ajax route appear without
restarting the web service.

=head1 WHY IT EXISTS

It exists because the source-tree tests and even live PSGI unit coverage are
still earlier than the built-distribution stage. The original failure was
reported after install and runtime boot inside Docker, so this file keeps that
exact post-build contract under automated regression coverage.

=head1 WHEN TO USE

Use this file after C<dzil build> creates the fresh tarball, and before
claiming the packaging or smart-router work is finished.

=head1 HOW TO USE

Run it with C<prove -lv t/44-smart-router-two-stage.t> after the current
distribution tarball exists in the repository root. The test auto-skips when
the tarball has not been built yet or Docker is unavailable.

=head1 WHAT USES IT

Developers use it during the post-build verification phase, and the release
gate should run it after C<dzil build> and before the blank-container install
and release steps are considered complete.

=head1 EXAMPLES

Example 1:

  dzil build
  prove -lv t/44-smart-router-two-stage.t

Run the staged smart-router Docker guard after building the tarball.

Example 2:

  rm -f Developer-Dashboard-*.tar.gz
  prove -lv t/44-smart-router-two-stage.t

Observe the intentional skip that reminds you this guard belongs after the
build step.

Example 3:

  dzil build
  prove -lr t
  prove -lv t/44-smart-router-two-stage.t

Keep the source-tree suite and the post-build smart-router guard both green
before finishing the change.

=for comment FULL-POD-DOC END

=cut

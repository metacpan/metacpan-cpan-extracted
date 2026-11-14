use v5.44;
use FindBin;
use LibTmux::Server;
use LibTmux::Workspace;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $tmux   = shift @ARGV // 'tmux';
my $server = LibTmux::Server->new(
    socket_path => $socket,
    executable  => $tmux,
    config_file => '/dev/null',
);

# example: begin plan
open my $in, '<:raw', "$FindBin::Bin/workspace.json" or die $!;
my $json = do { local $/; <$in> };
close $in or die $!;
my $workspace = LibTmux::Workspace->from_json($json);
my $plan      = $workspace->plan;
say 'planned sessions: ', scalar $plan->{sessions}->@*;
die 'plan must not mutate' if $plan->{mutates};

# example: end plan
my ($session, $failure);
try {
    # example: begin load
    my $report   = $workspace->load(server => $server);
    my $snapshot = $server->snapshot;
    $session = $snapshot->sessions->one({name => 'perl-workspace'});
    my $windows = $session->window_links;
    say 'loaded windows: ', $windows->count;
    my $editor = $windows->one({window => {-is => {name => 'editor'}}})->window;
    say 'editor panes: ', $editor->panes->count;

    # example: end load
    die 'workspace structure differs'
        unless $windows->count == 2 && $editor->panes->count == 2;

    # example: begin repeat
    my $again = $workspace->load(server => $server, existing => 'skip');
    say 'skipped existing sessions: ', scalar $again->{skipped}->@*;

    # example: end repeat
    die 'repeat did not skip' unless $again->{skipped}->@* == 1;
    die 'environment was not inherited'
        unless $server->get_environment(session => $session, name => 'PROJECT')
        eq 'api';
}
catch ($error) { $failure = $error }
if ($session) {
    try { $server->kill_session(session => $session) }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}
die $failure if defined $failure;
say 'workspace plan, load, repeat: ok';

use v5.44;
use IO::Async::Loop::Ppoll;
use Future;
use LibTmux::Async::Server;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $tmux   = shift @ARGV // 'tmux';

# example: begin connect
my $loop   = IO::Async::Loop::Ppoll->new;
my $server = LibTmux::Async::Server->new(
    loop           => $loop,
    socket_path    => $socket,
    executable     => $tmux,
    config_file    => '/dev/null',
    max_concurrent => 2,
    max_queue      => 8,
);

# example: end connect
my ($session, $failure);
try {
    my $created = $server->new_session(
        name    => 'perl-async',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    $loop->await($created);
    $session = $created->get;

    # example: begin concurrent
    my $capture = $server->snapshot;
    my $version = $server->cmd('display-message', '-p', '#{version}');
    $loop->await(Future->needs_all($capture, $version));
    my $snapshot = $capture->get;
    my $panes    = $snapshot->sessions->one({name => 'perl-async'})
        ->window_links->one->window->panes->where({active => true});
    say 'async active panes: ', $panes->count;
    say 'tmux version: ',       $version->get->stdout;

    # example: end concurrent
    die 'async session missing pane' unless $panes->count == 1;

    # example: begin batch
    my $batch = $server->batch(
        [
            ['display-message', '-p', 'first'],
            ['display-message', '-p', 'second'],
        ]
    );
    $loop->await($batch);
    my $results = $batch->get;
    for my $entry ($results->@*) {
        die $entry->{error} if defined $entry->{error};
        print $entry->{result}->stdout;
    }

    # example: end batch
    die 'batch order changed'
        unless $results->[0]{result}->stdout eq "first\n"
        && $results->[1]{result}->stdout eq "second\n";
}
catch ($error) {
    $failure = $error;
    $session //= $error->created if $error isa LibTmux::X::Creation;
}
if ($session) {
    try {
        my $removed = $server->kill_session(session => $session);
        $loop->await($removed);
        $removed->get;
    }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}

# example: begin close
my $closed = $server->close;
$loop->await($closed);
try { $closed->get }
catch ($cleanup) {
    warn "executor cleanup failed: $cleanup\n";
    $failure //= $cleanup;
}
die $failure if defined $failure;
say 'async operations and cleanup: ok';

# example: end close

use v5.44;
use LibTmux::Server;
use LibTmux::Filter;

my $socket = shift @ARGV // die "Usage: $0 SOCKET_PATH [TMUX]\n";
my $tmux   = shift @ARGV // 'tmux';
my $server = LibTmux::Server->new(
    socket_path => $socket,
    executable  => $tmux,
    config_file => '/dev/null',
);
my ($session, $failure);
try {
    # example: begin create
    $session = $server->new_session(
        name    => 'perl-workflow',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    my $editor = $session->window_links->one->window;
    $server->rename_window(window => $editor, name => 'editor');
    my $right = $server->split_pane(
        pane       => $editor->panes->one,
        horizontal => true,
        command    => [$^X, '-e', 'while (<STDIN>) { print }'],
    );
    $server->select_layout(window => $editor, layout => 'even-horizontal');
    my $logs = $server->new_window(
        session => $session,
        name    => 'logs',
        command => [$^X, '-e', 'while (<STDIN>) { print }'],
    );

    # example: end create

    # example: begin filter
    my $snapshot = $server->snapshot;
    my $panes =
        $snapshot->windows->one({name => 'editor'})
        ->panes->where({width => {-gte => 1}})
        ->grep(sub ($pane) { $pane->height > 0 });
    my @ids    = map { $_->id } $panes->@*;
    my $active = $panes->one({active => true});
    say 'editor panes: ',          scalar @ids;
    say 'active pane belongs to ', $active->window->name;

    # example: end filter
    die 'expected two editor panes' unless @ids == 2;

    # example: begin input
    $server->send_text(
        pane  => $right,
        text  => 'hello from Perl',
        enter => true
    );
    my $screen = $server->capture_pane(pane => $right, start => -100);
    say 'captured bytes: ', length $screen;
    $server->set_environment(
        session => $session,
        name    => 'PROJECT',
        value   => 'api',
    );
    say 'PROJECT=',
        $server->get_environment(session => $session, name => 'PROJECT');

    # example: end input

    # example: begin wire
    my $filter = LibTmux::Filter->new(
        entity => 'pane',
        where  => {active => true, width => {-gte => 1}},
    );
    my $restored = LibTmux::Filter->from_json($filter->to_json);
    my $selected = $panes->where($restored);
    say 'restored filter matches: ', $selected->count;

    # example: end wire
    die 'wire filter changed membership'
        unless $selected->one->id eq $active->id;

    # example: begin relations
    my $windows    = $snapshot->windows->where({id => $editor->id});
    my $same_child = $windows->where(
        {
            panes => {-some => {-and => [{index => 0}, {index => 1}]}},
        }
    );
    my $different_children = $windows->where(
        {
            -and => [
                {panes => {-some => {index => 0}}},
                {panes => {-some => {index => 1}}},
            ],
        }
    );
    say 'same child: ',         $same_child->count;
    say 'different children: ', $different_children->count;

    # example: end relations
    die 'quantifiers conflated children'
        unless $same_child->count == 0 && $different_children->count == 1;

    # example: begin query
    my $where = {active => true, width => {-gte => 1}};
    my $local = $server->query_panes(where => $where, pushdown => 'never');
    my $verification;
    my $verified = $server->query_panes(
        where           => $where,
        pushdown        => 'require',
        on_verification => sub ($report) { $verification = $report },
    );
    say 'native verification: ', $verification->{status};

    # example: end query
    die 'native/local results differ'
        unless join(',', map { $_->id } $local->@*) eq
        join(',', map { $_->id } $verified->@*);

    # example: begin graph
    my $before = $snapshot->window_by_id($logs->id);
    $server->rename_window(window => $logs, name => 'build');
    die 'captured name changed' unless $before->name eq 'logs';
    die 'new name missing'
        unless $server->snapshot->window_by_id($logs->id)->name eq 'build';
    say 'captured name: ', $before->name;

    # example: end graph
}
catch ($error) {
    $failure = $error;
    $session //= $error->created if $error isa LibTmux::X::Creation;
}
if ($session) {
    try { $server->kill_session(session => $session) }
    catch ($cleanup) {
        warn "session cleanup failed: $cleanup\n";
        $failure //= $cleanup;
    }
}
die $failure if defined $failure;
say 'core workflow: ok';

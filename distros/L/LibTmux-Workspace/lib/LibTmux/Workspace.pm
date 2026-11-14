package LibTmux::Workspace;
use v5.44;
use JSON::PP     ();
use Scalar::Util qw(blessed refaddr);
use LibTmux 0.003;
use LibTmux::Server;
use LibTmux::Workspace::X;
our $VERSION = '0.003';

sub _bad ($path, $message) {
    LibTmux::Workspace::X::Config->throw(path => $path, message => $message);
}

sub _object ($value, $path, @allowed) {
    _bad($path, 'expected an object') unless ref($value) eq 'HASH';
    my %allowed = map { $_ => true } @allowed;
    _bad("$path.$_", 'unknown configuration key')
        for sort grep { !$allowed{$_} } keys %$value;
}

sub _text ($value, $path, $nonempty = false) {
    _bad($path, 'expected a NUL-free string')
        unless defined($value)
        && !ref($value)
        && $value !~ /\0/
        && (!$nonempty || length $value);
    return "$value";
}

sub _env ($value, $path) {
    _object($value, $path, keys %$value) if ref($value) eq 'HASH';
    _bad($path, 'expected an environment object') unless ref($value) eq 'HASH';
    my %out;
    for my $name (sort keys %$value) {
        _bad("$path.$name", 'invalid environment name')
            unless $name =~ /\A[A-Za-z_][A-Za-z_0-9]*\z/;
        $out{$name} = _text($value->{$name}, "$path.$name");
    }
    return \%out;
}

sub _list ($value, $path) {
    _bad($path, 'expected a nonempty array')
        unless ref($value) eq 'ARRAY' && @$value;
}

sub new ($class, %args) {
    _bad('options', 'only config is accepted')
        if grep { $_ ne 'config' } keys %args;
    my $raw = $args{config};
    _object($raw, 'workspace', qw(schema sessions environment));
    _bad('workspace.schema', 'expected libtmux.workspace/v1')
        unless defined($raw->{schema})
        && !ref($raw->{schema})
        && $raw->{schema} eq 'libtmux.workspace/v1';
    _bad('workspace.sessions', 'expected an array')
        unless ref($raw->{sessions}) eq 'ARRAY';
    my $global = _env($raw->{environment} // {}, 'workspace.environment');
    my (@sessions, %names);
    my $i = 0;

    for my $session ($raw->{sessions}->@*) {
        my $path = 'workspace.sessions[' . $i++ . ']';
        _object($session, $path, qw(name environment windows));
        my $name = _text($session->{name}, "$path.name", true);
        _bad("$path.name",
            'tmux session names cannot contain colon, period, or newline')
            if $name =~ /[:.\n\r]/;
        _bad("$path.name", 'duplicate session name') if $names{$name}++;
        my %environment = (
            %$global,
            %{_env($session->{environment} // {}, "$path.environment")}
        );
        _list($session->{windows}, "$path.windows");
        my (@windows, %window_names);
        my $j = 0;

        for my $window ($session->{windows}->@*) {
            my $wp = "$path.windows[" . $j++ . ']';
            _object($window, $wp, qw(name cwd layout panes environment));
            my $window_name =
                _text($window->{name} // 'window', "$wp.name", true);
            _bad("$wp.name", 'duplicate window name')
                if $window_names{$window_name}++;
            my %window_env = (
                %environment,
                %{_env($window->{environment} // {}, "$wp.environment")}
            );
            _list($window->{panes}, "$wp.panes");
            my @panes;
            my $k = 0;

            for my $pane ($window->{panes}->@*) {
                my $pp = "$wp.panes[" . $k++ . ']';
                _object($pane, $pp,
                    qw(command shell_command cwd environment horizontal));
                _bad($pp,
                    'exactly one of command and shell_command is required')
                    if exists($pane->{command}) ==
                    exists($pane->{shell_command});
                my %out = (
                    environment => {
                        %window_env,
                        %{
                            _env($pane->{environment} // {}, "$pp.environment")
                        }
                    }
                );
                if (exists $pane->{command}) {
                    _list($pane->{command}, "$pp.command");
                    $out{command} =
                        [map { _text($_, "$pp.command") } $pane->{command}->@*];
                }
                else {
                    $out{shell_command} =
                        _text($pane->{shell_command}, "$pp.shell_command");
                }
                $out{cwd} =
                    _text($pane->{cwd} // $window->{cwd}, "$pp.cwd", true)
                    if exists($pane->{cwd}) || exists($window->{cwd});
                if (exists $pane->{horizontal}) {
                    _bad("$pp.horizontal", 'expected Boolean or 0/1')
                        unless !ref($pane->{horizontal})
                        && defined($pane->{horizontal})
                        && (JSON::PP::is_bool($pane->{horizontal})
                        || "$pane->{horizontal}" eq '0'
                        || "$pane->{horizontal}" eq '1');
                    $out{horizontal} = $pane->{horizontal} ? true : false;
                }
                push @panes, \%out;
            }
            my %out = (name => $window_name, panes => \@panes);
            $out{layout} = _text($window->{layout}, "$wp.layout", true)
                if exists $window->{layout};
            push @windows, \%out;
        }
        push @sessions,
            {name => $name, environment => \%environment, windows => \@windows};
    }
    return
        bless {
        config => {schema => 'libtmux.workspace/v1', sessions => \@sessions}
        }, $class;
}

sub from_json ($class, $json) {
    my $data;
    try {
        $data =
            JSON::PP->new->utf8->core_bools->max_size(1024 * 1024)
            ->max_depth(32)
            ->decode($json)
    }
    catch ($error) { _bad('workspace', 'invalid or oversized JSON: ' . $error) }
    return $class->new(config => $data);
}

sub _copy ($value) {
    return {map { $_ => _copy($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { _copy($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub plan ($self, %args) {
    my $existing = $args{existing} // 'error';
    _bad('existing', 'expected error or skip')
        unless !ref($existing) && $existing =~ /\A(?:error|skip)\z/;
    return {
        schema     => 'libtmux.workspace.plan/v1',
        existing   => $existing,
        mutates    => false,
        sessions   => _copy($self->{config}{sessions}),
        completion =>
'command acceptance and captured handles; application readiness requires caller assertions'
    };
}

sub load ($self, %args) {
    my $server = $args{server};
    _bad('server', 'expected a synchronous public LibTmux::Server')
        unless blessed($server) && $server->isa('LibTmux::Server');
    my $plan = $self->plan(existing => $args{existing} // 'error');
    my %existing;
    try {
        %existing = map { $_->name => $_ } $server->snapshot->sessions->@*
    }
    catch ($error) {
        die $error unless blessed($error) && $error->isa('LibTmux::X::NoServer')
    }
    if ($plan->{existing} eq 'error') {
        for my $session ($plan->{sessions}->@*) {
            LibTmux::Workspace::X::Conflict->throw(
                message => 'session already exists: ' . $session->{name})
                if $existing{$session->{name}};
        }
    }
    my $report = {
        status         => 'loading',
        created        => [],
        skipped        => [],
        steps          => [],
        cleanup_errors => []
    };
    my @owned;
    my $step;
    try {
        for my $session ($plan->{sessions}->@*) {
            if ($existing{$session->{name}}) {
                push $report->{skipped}->@*, $session->{name};
                next;
            }
            $step = 'create session ' . $session->{name};
            my $first_window = $session->{windows}[0];
            my %first        = %{$first_window->{panes}[0]};
            delete $first{horizontal};
            my $created =
                $server->new_session(name => $session->{name}, %first);
            push @owned,                 $created;
            push $report->{created}->@*, $created->id;
            push $report->{steps}->@*,   $step;

            for my $name (sort keys $session->{environment}->%*) {
                $step = 'set environment ' . $session->{name} . '.' . $name;
                $server->set_environment(
                    session => $created,
                    name    => $name,
                    value   => $session->{environment}{$name}
                );
                push $report->{steps}->@*, $step;
            }
            my $index = 0;
            for my $window ($session->{windows}->@*) {
                $step =
                    'create window ' . $session->{name} . ':' . $window->{name};
                my $physical;
                if (!$index++) {
                    $physical = $created->window_links->first->window;
                    $server->rename_window(
                        window => $physical,
                        name   => $window->{name}
                    );
                }
                else {
                    my %pane = %{$window->{panes}[0]};
                    delete $pane{horizontal};
                    $physical = $server->new_window(
                        session => $created,
                        name    => $window->{name},
                        %pane
                    );
                }
                push $report->{steps}->@*, $step;
                my $target = $physical->panes->first;
                for my $i (1 .. $#{$window->{panes}}) {
                    $step =
                          'split pane '
                        . $session->{name} . ':'
                        . $window->{name} . ':'
                        . $i;
                    $target = $server->split_pane(
                        pane => $target,
                        %{$window->{panes}[$i]}
                    );
                    push $report->{steps}->@*, $step;
                }
                if (exists $window->{layout}) {
                    $step =
                        'layout ' . $session->{name} . ':' . $window->{name};
                    $server->select_layout(
                        window => $physical,
                        layout => $window->{layout}
                    );
                    push $report->{steps}->@*, $step;
                }
            }
        }
        $report->{status} = 'loaded';
    }
    catch ($error) {
        if (   blessed($error)
            && $error->isa('LibTmux::X::Creation')
            && $error->created
            && $error->created->kind eq 'session')
        {
            push @owned,                 $error->created;
            push $report->{created}->@*, $error->created->id;
        }
        $report->{status}      = 'failed';
        $report->{failed_step} = $step;
        $report->{dispatch_uncertain} =
            blessed($error) && $error->isa('LibTmux::X')
            ? $error->dispatched // true
            : true;
        for my $owned (reverse @owned) {
            try { $server->kill_session(session => $owned) }
            catch ($cleanup) {
                push $report->{cleanup_errors}->@*,
                    {
                    target => $owned->identity,
                    action => 'kill_session',
                    error  => $cleanup,
                    };
            }
        }
        LibTmux::Workspace::X::Load->throw(
            message => 'workspace load failed at ' . $step,
            cause   => $error,
            report  => $report
        );
    }
    return $report;
}

=head1 NAME

LibTmux::Workspace - Versioned JSON configuration and owned orchestration

=head1 SYNOPSIS

    use LibTmux::Workspace;
    my $workspace = LibTmux::Workspace->from_json($json_octets);
    my $plan = $workspace->plan(existing => 'error');
    my $report = $workspace->load(server => $server);

=head1 METHODS

=head2 new

C<new(config =E<gt> $hashref)> validates and copies a
C<libtmux.workspace/v1> configuration. No I/O occurs. Sessions contain named
windows with nonempty pane arrays. Each pane requires literal C<command>
arguments or an explicit C<shell_command>. Environment values inherit from
workspace, session, and window, with pane values taking precedence. All
configuration errors throw L<Config|LibTmux::Workspace::X/Config>.

=head2 from_json

Decode bounded UTF-8 JSON octets with core L<JSON::PP> and call L</new>.
Reject unsupported versions, unknown keys, invalid commands, and duplicate
names. YAML is not part of this distribution.

=head2 plan

C<plan(existing =E<gt> 'error'|'skip')> returns a fresh data plan in input
order. It performs no tmux I/O or mutations. A dry-run does not prove live
availability or command success. Exports share no mutable arrays with the
loader. No context-dependent return values are used.

=head2 load

C<load(server =E<gt> $server, existing =E<gt> 'error'|'skip')> uses public
L<LibTmux::Server> operations. It checks all session-name conflicts before
creation. C<error> rejects any existing target with
L<Conflict|LibTmux::Workspace::X/Conflict>; C<skip> leaves that entire session
alone, so repeated application creates only absent sessions. A missing server
permits explicit creation; other acquisition failures propagate.

Return one report containing created IDs, skipped names, and completed steps.
On failure, rollback only sessions returned by successful creation, then throw
L<Load|LibTmux::Workspace::X/Load> with original cause and partial-effect report.
An uncertain creation without a returned ID cannot be rolled back safely.
Existing resources are never rollback targets. Layouts apply after splitting;
working directories and environments reach every initial process. Completion
means command acceptance and captured state, not application readiness.

=head1 COMMAND LINE

The packaged C<libtmux-workspace> executable exposes C<validate>, C<plan>, and
C<load>. C<--dry-run> selects planning without tmux I/O. See the installed
executable's help for socket and repeat-application options.

=head1 DOCUMENTATION

Read the L<Perl documentation|https://libtmux.org/en/perl/> and
L<workspace guide|https://libtmux.org/en/perl/latest/workspace/source-guide/>
for complete configuration and CLI examples. The
L<API reference|https://libtmux.org/en/perl/latest/workspace/reference/libtmux-workspace/>
documents validation, planning, loading, and failure reports. The
L<CPAN distribution|https://metacpan.org/dist/LibTmux-Workspace> includes
runnable consumer examples. The C<0.x> API can change between releases.

=cut

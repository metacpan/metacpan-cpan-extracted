package LibTmux::Server;
use v5.44;
use Scalar::Util qw(blessed);
use File::Spec;
use Time::HiRes qw(time);
use JSON::PP    ();
use LibTmux;
use LibTmux::Operation;
use LibTmux::Transport;
use LibTmux::Codec;
use LibTmux::Schema;
use LibTmux::Snapshot;
use LibTmux::Filter;
use LibTmux::X;

sub new ($class, %args) {
    my %allowed = map { $_ => 1 }
        qw(executable socket_name socket_path config_file timeout max_output env);
    LibTmux::X::InvalidArgument->throw(message => "unknown server option $_")
        for grep { !$allowed{$_} } keys %args;
    LibTmux::X::InvalidArgument->throw(
        message => 'socket_name and socket_path are exclusive')
        if exists($args{socket_name}) && exists($args{socket_path});
    for my $key (qw(executable socket_name socket_path config_file)) {
        next unless exists $args{$key};
        LibTmux::X::InvalidArgument->throw(
            message => "$key must be a nonempty NUL-free scalar")
            if !defined($args{$key})
            || ref($args{$key})
            || !length($args{$key})
            || $args{$key} =~ /\0/;
    }
    LibTmux::X::InvalidArgument->throw(
        message => 'socket name cannot contain a slash')
        if exists($args{socket_name}) && $args{socket_name} =~ m!/!;
    $args{socket_path} = File::Spec->rel2abs($args{socket_path})
        if exists $args{socket_path};
    %args = LibTmux::Transport->_configuration(%args);
    $args{env} = {%{$args{env}}};
    $args{executable} //= 'tmux';
    $args{timeout}    //= 5;
    $args{max_output} //= 8 * 1024 * 1024;
    return bless \%args, $class;
}

sub _prefix ($self) {
    my @argv = ($self->{executable});
    push @argv, ('-S', $self->{socket_path}) if exists $self->{socket_path};
    push @argv, ('-L', $self->{socket_name}) if exists $self->{socket_name};
    push @argv, ('-f', $self->{config_file}) if exists $self->{config_file};
    return @argv;
}

sub _process_op ($self, $argv, %options) {
    LibTmux::Operation->request(
        argv       => $argv,
        timeout    => $self->{timeout},
        max_output => $self->{max_output},
        env        => {%{$self->{env}}},
        %options
    );
}

sub _raw_op ($self, $argv, %options) {
    LibTmux::X::InvalidArgument->throw(
        message => 'argv must be a nonempty array')
        unless ref($argv) eq 'ARRAY' && @$argv;
    for (@$argv) {
        LibTmux::X::InvalidArgument->throw(
            message => 'arguments must be defined NUL-free scalars')
            if !defined($_) || ref($_) || /\0/;
    }
    my @literal = map { my $value = "$_"; $value =~ s/;\z/\\;/; $value } @$argv;

    # Preserve framing bytes even when the caller's locale is not UTF-8.
    $self->_process_op([$self->_prefix, '-u', @literal], %options);
}

sub _checked ($self, $operation) {
    $operation->then(
        sub ($result) {
            unless ($result->success) {
                my $message = $result->stderr;
                $message =~ s/\n\z//;
                my $type =
                    $message =~
/no server running|server exited unexpectedly|(?:failed to connect|error connecting to).*(?:No such file or directory|Connection refused)/s
                    ? 'LibTmux::X::NoServer'
                    : 'LibTmux::X::Command';
                $type = 'LibTmux::X::NoSuchTarget'
                    if $message =~
/can't find (?:pane|window|session|client)|no such (?:pane|window|session|client)/;
                $type->throw(
                    message    => $message || 'tmux command failed',
                    result     => $result,
                    dispatched => true
                );
            }
            return $result;
        }
    );
}

sub _cmd_op ($self, $argv, %options) {
    $self->_checked($self->_raw_op($argv, %options));
}

sub at_least ($class, $version, $minimum) {
    LibTmux::Schema->_version_at_least($version, $minimum);
}

sub _binary_op ($self) {
    return LibTmux::Operation->value($self->{binary_version})
        if $self->{binary_version};
    return $self->_checked($self->_process_op([$self->{executable}, '-V']))
        ->then(
        sub ($result) {
            my $version = $result->stdout;
            $version =~ s/\s+\z//;
            LibTmux::X::Unsupported->throw(
                message => "tmux 3.3a or newer required; found $version")
                unless $self->at_least($version, '3.3a');
            $self->{binary_version} = $version;
            return $version;
        }
        );
}

sub _identity_op ($self) {
    my @fields = qw(socket_path pid start_time version);
    my $format = LibTmux::Codec->format(@fields);
    return $self->_cmd_op(['display-message', '-p', $format])->then(
        sub ($result) {
            my $rows = LibTmux::Codec->decode($result->stdout, scalar @fields);
            LibTmux::X::Codec->throw(
                message => 'expected one server identity row')
                unless @$rows == 1;
            my %identity;
            @identity{@fields} = $rows->[0]->@*;
            LibTmux::X::Codec->throw(message => 'invalid daemon identity')
                unless $identity{pid} =~ /\A[1-9][0-9]*\z/
                && $identity{start_time} =~ /\A[0-9]+\z/
                && length $identity{socket_path};
            LibTmux::X::Unsupported->throw(
                message => 'connected daemon is below tmux 3.3a')
                unless $self->at_least($identity{version}, '3.3a');
            $identity{server_id}  = $identity{socket_path};
            $identity{generation} = "$identity{pid}/$identity{start_time}";
            return \%identity;
        }
    );
}

sub _list_op ($self, $kind, $version) {
    my %commands = (
        session => ['list-sessions'],
        window  => ['list-windows', '-a'],
        pane    => ['list-panes',   '-a'],
        client  => ['list-clients']
    );
    LibTmux::X::InvalidArgument->throw(
        message => 'listing kind must be session/window/pane/client')
        unless $commands{$kind};
    my $schema = LibTmux::Schema->entity($kind)->{fields};
    my @keys   = sort grep {
               $schema->{$_}{source}
            && $self->at_least($version, $schema->{$_}{minimum})
    } keys %$schema;
    my @tokens = map { $schema->{$_}{source} } @keys;
    my %context =
        $kind eq 'window'
        ? (
        session_id    => 'session_id',
        window_index  => 'window_index',
        window_active => 'window_active'
        )
        : $kind eq 'pane' ? (
        session_id   => 'session_id',
        window_id    => 'window_id',
        window_index => 'window_index'
        )
        : $kind eq 'client' ? (session_id => 'session_id')
        :                     ();
    my @extra  = sort keys %context;
    my @all    = (@keys, @extra);
    my $format = LibTmux::Codec->format(@tokens, map { $context{$_} } @extra);
    return $self->_cmd_op([@{$commands{$kind}}, '-F', $format])->then(
        sub ($result) {
            my $rows = LibTmux::Codec->decode($result->stdout, scalar @all);
            my @out;
            for my $values (@$rows) {
                my %row;
                @row{@all} = @$values;
                for my $field (@keys) {
                    $row{$field} = undef
                        if $schema->{$field}{nullable} && $row{$field} eq '';
                    $row{$field} = LibTmux::Schema->normalize(
                        $schema->{$field}, $row{$field},
                        "$kind.$field",    'Codec'
                    );
                }
                for my $field (@extra) {
                    $row{$field} = undef
                        if $kind eq 'client' && $row{$field} eq '';
                }
                push @out, \%row;
            }
            return \@out;
        }
    );
}

sub _capture_op ($self) {
    my $start = time();
    return $self->_identity_op->then(
        sub ($before) {
            my @kinds = qw(session window pane client);
            LibTmux::Operation->sequence(
                [map { $self->_list_op($_, $before->{version}) } @kinds])
                ->then(
                sub ($lists) {
                    $self->_identity_op->then(
                        sub ($after) {
                            LibTmux::X::AcquisitionRace->throw(message =>
                                    'server generation changed during capture')
                                unless $before->{server_id} eq
                                $after->{server_id}
                                && $before->{generation} eq
                                $after->{generation};
                            my %lists;
                            @lists{@kinds} = @$lists;
                            my (@windows,     @panes,     @links);
                            my (%window_seen, %pane_seen, %link_seen);
                            my $json = JSON::PP->new->canonical;
                            for my $row ($lists{window}->@*) {
                                my %record      = %$row;
                                my $session_id  = delete $record{session_id};
                                my $index       = delete $record{window_index};
                                my $active      = delete $record{window_active};
                                my $fingerprint = $json->encode(\%record);
                                if (exists $window_seen{$record{id}}) {
                                    LibTmux::X::AcquisitionRace->throw(
                                        message =>
'window changed between contextual rows'
                                        )
                                        unless $window_seen{$record{id}} eq
                                        $fingerprint;
                                }
                                else {
                                    $window_seen{$record{id}} = $fingerprint;
                                    push @windows, \%record;
                                }
                                my $link_id = "$session_id:$index";
                                LibTmux::X::AcquisitionRace->throw(message =>
                                        'duplicate session/index association')
                                    if $link_seen{$link_id}++;
                                push @links,
                                    {
                                    id         => $link_id,
                                    session_id => $session_id,
                                    window_id  => $record{id},
                                    index      => 0 + $index,
                                    active     => $active eq '1' ? true : false
                                    };
                            }
                            for my $row ($lists{pane}->@*) {
                                my %record  = %$row;
                                my $context = $row->{session_id} . ':'
                                    . $row->{window_index};
                                LibTmux::X::AcquisitionRace->throw(message =>
'pane context was not captured as a window link'
                                ) unless $link_seen{$context};
                                delete @record{qw(session_id window_index)};
                                my $fingerprint = $json->encode(\%record);
                                if (exists $pane_seen{$record{id}}) {
                                    LibTmux::X::AcquisitionRace->throw(
                                        message =>
'pane changed between contextual rows'
                                        )
                                        unless $pane_seen{$record{id}} eq
                                        $fingerprint;
                                }
                                else {
                                    $pane_seen{$record{id}} = $fingerprint;
                                    push @panes, \%record;
                                }
                            }
                            for my $session ($lists{session}->@*) {
                                my @members =
                                    grep { $_->{session_id} eq $session->{id} }
                                    @links;
                                LibTmux::X::AcquisitionRace->throw(message =>
'captured session has incomplete window links'
                                    )
                                    unless @members
                                    && 1 == grep { $_->{active} } @members;
                            }
                            for my $window (@windows) {
                                my @members =
                                    grep { $_->{window_id} eq $window->{id} }
                                    @panes;
                                LibTmux::X::AcquisitionRace->throw(message =>
                                        'captured window has incomplete panes')
                                    unless @members
                                    && 1 == grep { $_->{active} } @members;
                            }
                            return LibTmux::Snapshot->from_records(
                                server_id    => $before->{server_id},
                                generation   => $before->{generation},
                                complete     => true,
                                sessions     => $lists{session},
                                windows      => \@windows,
                                window_links => \@links,
                                panes        => \@panes,
                                clients      => $lists{client},
                                metadata     => {
                                    capture_start => $start,
                                    capture_end   => time(),
                                    version       => $before->{version},
                                    pid           => $before->{pid}
                                }
                            );
                        }
                    );
                }
                );
        }
    );
}
sub _literal_format ($value) { $value =~ s/#/##/g; $value }

sub _target_op ($self, $kind, $target) {
    my $handle =
        blessed($target) && $target->isa('LibTmux::Entity') ? $target : undef;
    LibTmux::X::InvalidArgument->throw(message => "expected $kind handle")
        if $handle && $handle->kind ne $kind;
    my $id = $handle ? $handle->id : $target;
    LibTmux::X::InvalidArgument->throw(message => "invalid $kind target")
        unless defined($id) && !ref($id) && length($id) && $id !~ /\0/;
    my %pattern = (
        session     => qr/\A\$[0-9]+\z/,
        window      => qr/\A\@[0-9]+\z/,
        pane        => qr/\A%[0-9]+\z/,
        window_link => qr/\A\$[0-9]+:[0-9]+\z/
    );
    LibTmux::X::InvalidArgument->throw(message => "invalid $kind target")
        if $pattern{$kind} && $id !~ $pattern{$kind};
    return $self->_identity_op->then(
        sub ($identity) {
            if ($handle) {
                LibTmux::X::StaleReference->throw(
                    message => 'handle belongs to another server generation')
                    unless $handle->server_id eq $identity->{server_id}
                    && $handle->generation eq $identity->{generation};
                if ($kind eq 'window_link' || $kind eq 'client') {
                    my ($flag, $token, $expected) =
                        $kind eq 'window_link'
                        ? ('-t', 'window_id', $handle->window->id)
                        : ('-c', 'client_pid', $handle->pid);
                    return $self->_cmd_op(
                        ['display-message', '-p', $flag, $id, "#{$token}"])
                        ->then(
                        sub ($result) {
                            my $actual = $result->stdout;
                            $actual =~ s/\n\z//;
                            LibTmux::X::StaleReference->throw(
                                message => 'contextual target was replaced')
                                unless $actual eq $expected;
                            return [$id, $identity];
                        }
                        )->catch(
                        sub ($error) {
                            die $error
                                if blessed($error)
                                && $error->isa('LibTmux::X::StaleReference');
                            LibTmux::X::StaleReference->throw(
                                message => 'contextual target no longer exists',
                                cause   => $error
                            );
                        }
                        );
                }
            }
            return [$id, $identity];
        }
    );
}

sub _pane_command ($args) {
    LibTmux::X::InvalidArgument->throw(
        message => 'command and shell_command are exclusive')
        if exists($args->{command}) && exists($args->{shell_command});
    if (exists $args->{shell_command}) {
        LibTmux::X::InvalidArgument->throw(
            message => 'shell_command must be a NUL-free string')
            if !defined($args->{shell_command})
            || ref($args->{shell_command})
            || $args->{shell_command} =~ /\0/;
        return ($args->{shell_command});
    }
    return () unless exists $args->{command};
    my $argv = $args->{command};
    LibTmux::X::InvalidArgument->throw(
        message => 'command must be a nonempty literal argument array')
        unless ref($argv) eq 'ARRAY' && @$argv;
    for (@$argv) {
        LibTmux::X::InvalidArgument->throw(
            message => 'command arguments must be NUL-free scalars')
            if !defined($_) || ref($_) || /\0/;
    }
    return ($^X, '-e', 'exec {$ARGV[0]} @ARGV or exit 127', '--', $argv->[0])
        if @$argv == 1;
    return @$argv;
}

sub _creation_format ($kind) {
    LibTmux::Codec->format(qw(socket_path pid start_time version),
        $kind . '_id');
}

sub _created_op ($self, $argv, $kind) {
    return $self->_cmd_op($argv)->then(
        sub ($result) {
            my $receipt;
            my $capture;
            try {
                my $rows = LibTmux::Codec->decode($result->stdout, 5);
                LibTmux::X::Codec->throw(
                    message => 'expected one creation receipt')
                    unless @$rows == 1;
                my ($server_id, $pid, $started, $version, $id) = $rows->[0]->@*;
                LibTmux::X::Codec->throw(
                    message => 'invalid creation generation')
                    unless length($server_id)
                    && $pid     =~ /\A[1-9][0-9]*\z/
                    && $started =~ /\A[0-9]+\z/;
                my %plural = (
                    session => 'sessions',
                    window  => 'windows',
                    pane    => 'panes'
                );
                my $store = LibTmux::Snapshot->from_records(
                    server_id      => $server_id,
                    generation     => "$pid/$started",
                    complete       => false,
                    $plural{$kind} => [{id => $id}]
                );
                $receipt =
                      $kind eq 'session' ? $store->session_by_id($id)
                    : $kind eq 'window'  ? $store->window_by_id($id)
                    :                      $store->pane_by_id($id);
                $capture = $self->_capture_op;
            }
            catch ($error) {
                LibTmux::X::Creation->throw(
                    message =>
                        'creation accepted but receipt/acquisition failed',
                    created    => $receipt,
                    cause      => $error,
                    result     => $result,
                    dispatched => true
                );
            }
            return $capture->then(
                sub ($snapshot) {
                    LibTmux::X::AcquisitionRace->throw(
                        message => 'server changed after creation')
                        unless $snapshot->server_id eq $receipt->server_id
                        && $snapshot->generation eq $receipt->generation;
                    my $id = $receipt->id;
                    my $entity =
                          $kind eq 'session' ? $snapshot->session_by_id($id)
                        : $kind eq 'window'  ? $snapshot->window_by_id($id)
                        :                      $snapshot->pane_by_id($id);
                    LibTmux::X::AcquisitionRace->throw(message =>
                            'created entity disappeared before acquisition')
                        unless $entity;
                    return $entity;
                }
            )->catch(
                sub ($error) {
                    LibTmux::X::Creation->throw(
                        message => 'creation accepted but acquisition failed',
                        created => $receipt,
                        cause   => $error,
                        result  => $result,
                        dispatched => true
                    );
                }
            );
        }
    );
}

sub _prepare ($self, $name, %args) {
    if ($name eq 'select_layout') {
        my $layout  = $args{layout};
        my @matches = grep { index($_, $layout) == 0 }
            qw(even-horizontal even-vertical main-horizontal main-vertical tiled);
        LibTmux::X::InvalidArgument->throw(message =>
'layout must be an unambiguous predefined name or a checksum-prefixed tmux layout'
        ) unless @matches == 1 || $layout =~ /\A[0-9a-fA-F]{4},/;
    }
    if ($name eq 'snapshot') { return $self->_capture_op }
    if ($name eq 'execute') {
        return $self->_raw_op(delete($args{argv}), %args);
    }
    if ($name eq 'cmd') { return $self->_cmd_op($args{argv}) }
    if ($name eq 'clients') {
        return $self->_capture_op->then(sub ($s) { $s->clients });
    }
    if ($name eq 'listings') {
        return $self->_identity_op->then(
            sub ($identity) {
                $self->_list_op($args{kind}, $identity->{version});
            }
        );
    }
    if ($name eq 'new_session') {
        LibTmux::X::InvalidArgument->throw(
            message => 'session name is required')
            unless defined($args{name}) && !ref($args{name});
        my @argv = (
            'new-session', '-d', '-P', '-F', _creation_format('session'),
            '-s',          _literal_format($args{name})
        );
        push @argv, ('-x', $args{width})                if exists $args{width};
        push @argv, ('-y', $args{height})               if exists $args{height};
        push @argv, ('-c', _literal_format($args{cwd})) if exists $args{cwd};
        push @argv, map { ('-e', $_ . '=' . $args{environment}{$_}) }
            sort keys %{$args{environment} // {}};
        push @argv, '--', _pane_command(\%args);
        return $self->_identity_op->catch(
            sub ($error) {
                die $error
                    unless blessed($error)
                    && $error->isa('LibTmux::X::NoServer');
                undef;
            }
        )->then(sub { $self->_created_op(\@argv, 'session') });
    }
    if ($name eq 'new_window' || $name eq 'split_pane') {
        my $split   = $name eq 'split_pane';
        my @command = _pane_command(\%args);
        return $self->_target_op($split ? 'pane' : 'session',
            $args{$split ? 'pane' : 'session'})->then(
            sub ($target) {
                my @argv = (
                    $split ? 'split-window' : 'new-window',
                    '-d',
                    '-P',
                    '-F',
                    $split
                    ? _creation_format('pane')
                    : _creation_format('window'),
                    '-t',
                    $split ? $target->[0] : $target->[0] . ':'
                );
                push @argv, '-h' if $split && $args{horizontal};
                if (!$split && exists $args{name}) {
                    push @argv, ('-n', _literal_format($args{name}));
                }
                push @argv, ('-c', _literal_format($args{cwd}))
                    if exists $args{cwd};
                push @argv, map { ('-e', $_ . '=' . $args{environment}{$_}) }
                    sort keys %{$args{environment} // {}};
                push @argv, '--', @command;
                return $self->_created_op(\@argv, $split ? 'pane' : 'window');
            }
            );
    }
    if ($name eq 'link_window') {
        return $self->_target_op('window', $args{window})->then(
            sub ($window) {
                $self->_target_op('session', $args{session})->then(
                    sub ($session) {
                        $self->_cmd_op(
                            [
                                'link-window', '-s', $window->[0], '-t',
                                $session->[0] . ':' . ($args{index} // '')
                            ]
                        )->then(sub { undef });
                    }
                );
            }
        );
    }
    if ($name eq 'move_window') {
        return $self->_target_op('window_link', $args{link})->then(
            sub ($link) {
                $self->_target_op('session', $args{session})->then(
                    sub ($session) {
                        $self->_cmd_op(
                            [
                                'move-window', '-s', $link->[0], '-t',
                                $session->[0] . ':' . ($args{index} // '')
                            ]
                        )->then(sub { undef });
                    }
                );
            }
        );
    }
    my %simple = (
        rename_session =>
            ['session', 'session', 'rename-session', 'name', 'format'],
        rename_window =>
            ['window', 'window', 'rename-window', 'name', 'format'],
        unlink_window => ['window_link', 'link',    'unlink-window'],
        select_window => ['window_link', 'link',    'select-window'],
        select_pane   => ['pane',        'pane',    'select-pane'],
        select_layout => ['window',      'window',  'select-layout', 'layout'],
        kill_pane     => ['pane',        'pane',    'kill-pane'],
        kill_window   => ['window',      'window',  'kill-window'],
        kill_session  => ['session',     'session', 'kill-session'],
        detach_client => ['client',      'client',  'detach-client'],
    );
    if (my $spec = $simple{$name}) {
        return $self->_target_op($spec->[0], $args{$spec->[1]})->then(
            sub ($target) {
                my @argv = ($spec->[2], '-t', $target->[0]);
                if ($spec->[3]) {
                    LibTmux::X::InvalidArgument->throw(
                        message => "$spec->[3] is required")
                        unless defined $args{$spec->[3]};
                    push @argv, '--',
                        $spec->[4]
                        ? _literal_format($args{$spec->[3]})
                        : $args{$spec->[3]};
                }
                return $self->_cmd_op(\@argv)->then(sub { undef });
            }
        );
    }
    if ($name eq 'kill_server') {
        return $self->_cmd_op(['kill-server'])->then(sub { undef });
    }
    if (   $name eq 'resize_pane'
        || $name eq 'set_title'
        || $name eq 'send_keys'
        || $name eq 'send_text'
        || $name eq 'capture_pane')
    {
        return $self->_target_op('pane', $args{pane})->then(
            sub ($target) {
                my @argv;
                if ($name eq 'resize_pane') {
                    @argv = ('resize-pane', '-t', $target->[0]);
                    push @argv, ('-x', $args{width})  if exists $args{width};
                    push @argv, ('-y', $args{height}) if exists $args{height};
                }
                elsif ($name eq 'set_title') {
                    @argv = (
                        'select-pane', '-t', $target->[0], '-T',
                        _literal_format($args{title})
                    );
                }
                elsif ($name eq 'send_keys') {
                    LibTmux::X::InvalidArgument->throw(
                        message => 'keys must be an array reference')
                        unless ref($args{keys}) eq 'ARRAY';
                    @argv = (
                        'send-keys', '-t', $target->[0], '--',
                        $args{keys}->@*
                    );
                }
                elsif ($name eq 'send_text') {
                    @argv = (
                        'send-keys', '-t', $target->[0], '-l', '--', $args{text}
                    );
                }
                else {
                    @argv = ('capture-pane', '-p', '-t', $target->[0]);
                    push @argv, ('-S', $args{start}) if exists $args{start};
                    push @argv, ('-E', $args{end})   if exists $args{end};
                }
                return $self->_cmd_op(\@argv)->then(
                    sub ($result) {
                        return $result->stdout if $name eq 'capture_pane';
                        return $self->_cmd_op(
                            ['send-keys', '-t', $target->[0], 'Enter'])
                            ->then(sub { undef })
                            if $name eq 'send_text' && $args{enter};
                        return undef;
                    }
                );
            }
        );
    }
    if (   $name eq 'set_option'
        || $name eq 'get_option'
        || $name eq 'unset_option')
    {
        my %scope =
            (session => '', window => '-w', pane => '-p', server => '-s');
        my $scope = $args{scope} // 'session';
        LibTmux::X::InvalidArgument->throw(message => 'unknown option scope')
            unless exists $scope{$scope};
        my @argv = ($name eq 'get_option' ? 'show-options' : 'set-option');
        push @argv, $scope{$scope} if length $scope{$scope};
        push @argv, '-g'           if $args{global};
        push @argv, ('-t', $args{target}) if exists $args{target};
        push @argv, '-A' if $name eq 'get_option' && $args{inherited};
        push @argv, '-u' if $name eq 'unset_option';
        push @argv, '--', $args{name};
        push @argv, $args{value} if $name eq 'set_option';
        return $self->_cmd_op(\@argv)->then(
            sub ($result) {
                return undef unless $name eq 'get_option';
                return LibTmux::Codec->_option_value($result->stdout,
                    $args{name});
            }
        );
    }
    if ($name eq 'set_hook' || $name eq 'show_hooks') {
        my @argv = ($name eq 'set_hook' ? 'set-hook' : 'show-hooks');
        push @argv, '-g' if $args{global};
        push @argv, ('-t', $args{target}) if exists $args{target};
        push @argv, ('--', $args{name}, $args{command}) if $name eq 'set_hook';
        return $self->_cmd_op(\@argv)
            ->then(sub ($r) { $name eq 'show_hooks' ? $r->stdout : undef });
    }
    if ($name =~ /\A(?:set|get|unset)_environment\z/) {
        LibTmux::X::InvalidArgument->throw(
            message => 'invalid environment name')
            unless defined($args{name})
            && $args{name} =~ /\A[A-Za-z_][A-Za-z_0-9]*\z/;
        my $target =
            exists($args{session})
            ? $self->_target_op('session', $args{session})
            : LibTmux::Operation->value(undef);
        return $target->then(
            sub ($resolved) {
                my @argv = (
                    $name eq 'get_environment'
                    ? 'show-environment'
                    : 'set-environment'
                );
                push @argv, defined($resolved) ? ('-t', $resolved->[0]) : '-g';
                push @argv, '-s' if $name eq 'get_environment';
                push @argv, '-u' if $name eq 'unset_environment';
                push @argv, '--', $args{name};
                push @argv, $args{value} if $name eq 'set_environment';
                return $self->_cmd_op(\@argv)->then(
                    sub ($r) {
                        return undef unless $name eq 'get_environment';
                        my $text =
                            LibTmux::Codec->_environment_value($r->stdout,
                            $args{name});
                        LibTmux::X::Command->throw(
                            message => 'environment variable is unset',
                            result  => $r
                        ) unless defined $text;
                        return $text;
                    }
                );
            }
        );
    }
    if (   $name eq 'set_buffer'
        || $name eq 'show_buffer'
        || $name eq 'delete_buffer')
    {
        my @argv = (
              $name eq 'set_buffer'  ? 'load-buffer'
            : $name eq 'show_buffer' ? 'show-buffer'
            : 'delete-buffer',
            '-b', $args{name}
        );
        push @argv, '-' if $name eq 'set_buffer';
        return $self->_cmd_op(\@argv,
            $name eq 'set_buffer' ? (stdin => $args{data}) : ())->then(
            sub ($r) {
                $name eq 'show_buffer' ? $r->stdout : undef;
            }
            );
    }
    if ($name eq 'batch') {
        LibTmux::X::InvalidArgument->throw(
            message => 'batch needs an array of argv arrays')
            unless ref($args{requests}) eq 'ARRAY';
        my @ops = map {
            $self->_raw_op($_)
                ->then(sub ($r) { +{result => $r, error => undef} })
                ->catch(sub ($e) { +{result => undef, error => $e} })
        } $args{requests}->@*;
        return LibTmux::Operation->sequence(\@ops);
    }
    if ($name eq 'query_panes') {
        require LibTmux::QueryPlan;
        my $observer = delete $args{on_verification};
        my $plan     = LibTmux::QueryPlan->new(%args);
        my $finish   = sub ($selection, $report) {
            $observer->($report) if defined $observer;
            return $selection;
        };
        return $self->_capture_op->then(
            sub ($snapshot) {
                my $local = $snapshot->panes->where($plan->filter);
                return $finish->(
                    $local, $plan->_verification_report($snapshot, $local, {})
                ) if $plan->policy eq 'never';
                my $lowered = $plan->lowering($snapshot->metadata->{version});
                LibTmux::X::Unsupported->throw(message =>
                        'query has no complete exact native implementation')
                    if $plan->policy eq 'require' && !$lowered->{exact};
                return $finish->(
                    $local,
                    $plan->_verification_report($snapshot, $local, $lowered)
                ) unless defined $lowered->{filter};
                return $self->_cmd_op(
                    [
                        'list-panes', '-a',
                        '-f',         $lowered->{filter},
                        '-F',         '#{pane_id}'
                    ]
                )->then(
                    sub ($r) {
                        my (%native, @native);
                        for my $id (grep { length } split /\n/, $r->stdout) {
                            LibTmux::X::Codec->throw(
                                message => 'invalid native candidate ID')
                                unless $id =~ /\A%[0-9]+\z/;
                            push @native, $id unless $native{$id}++;
                        }
                        my $report =
                            $plan->_verification_report($snapshot, $local,
                            $lowered, \@native);
                        if (
                            $report->{status} eq 'disagreed'
                            && ($plan->_is_native || $plan->policy eq 'require')
                            )
                        {
                            LibTmux::X::QueryMismatch->throw(
                                message =>
'native candidates disagree with captured data; cause undetermined',
                                verification => $report
                            );
                        }
                        my $selection =
                            $plan->_is_native
                            ? $snapshot->panes->grep(
                            sub ($pane) { $native{$pane->id} })
                            : $local;
                        return $finish->($selection, $report);
                    }
                );
            }
        );
    }
    LibTmux::X::InvalidArgument->throw(message => "unknown operation $name");
}

sub operation ($self, $name, %args) {
    $self->_validate_options($name, \%args);
    for my $key (qw(argv keys command)) {
        $args{$key} = [$args{$key}->@*] if ref($args{$key}) eq 'ARRAY';
    }
    $args{environment} = {%{$args{environment}}} if exists $args{environment};
    $args{requests} =
        [map { ref($_) eq 'ARRAY' ? [@$_] : $_ } $args{requests}->@*]
        if exists $args{requests};
    if ($name eq 'explain_panes') {
        require LibTmux::QueryPlan;
        return LibTmux::Operation->value(LibTmux::QueryPlan->new(%args));
    }
    my $operation = $self->_prepare($name, %args);
    return $self->_binary_op->then(sub { $operation });
}

sub _validate_options ($self, $name, $args) {
    my $spec = LibTmux::Schema->catalog->{operations}{$name};
    LibTmux::X::InvalidArgument->throw(message => "unknown operation $name")
        unless $spec;
    my $params = $spec->{parameters};
    LibTmux::X::InvalidArgument->throw(message => "unknown $name option $_")
        for sort grep { !exists $params->{$_} } keys %$args;
    for my $key (sort keys %$params) {
        my $param = $params->{$key};
        LibTmux::X::InvalidArgument->throw(message => "$name requires $key")
            if $param->{required} && !exists $args->{$key};
        next unless exists $args->{$key};
        my $value = $args->{$key};
        my $type  = $param->{type};
        my $valid = true;
        if ($type eq 'text' || $type eq 'bytes') {
            $valid =
                   defined($value)
                && !ref($value)
                && ($type eq 'bytes' ? !utf8::is_utf8($value) : $value !~ /\0/);
        }
        elsif ($type eq 'integer'
            || $type eq 'positive'
            || $type eq 'nonnegative')
        {
            $valid =
                   defined($value)
                && !ref($value)
                && "$value" =~ /\A-?[0-9]+\z/
                && length("$value") < 16;
            $valid &&= $value > 0  if $type eq 'positive';
            $valid &&= $value >= 0 if $type eq 'nonnegative';
        }
        elsif ($type eq 'boolean') {
            $valid =
                   defined($value)
                && !ref($value)
                && (JSON::PP::is_bool($value)
                || "$value" eq '0'
                || "$value" eq '1');
        }
        elsif ($type eq 'target') {
            $valid = defined($value)
                && (!ref($value)
                || blessed($value) && $value->isa('LibTmux::Entity'));
        }
        elsif ($type eq 'argv' || $type eq 'keys' || $type eq 'requests') {
            $valid = ref($value) eq 'ARRAY';
            if ($valid && $type ne 'requests') {
                $valid = !grep { !defined($_) || ref($_) || /\0/ } @$value;
            }
            $valid &&= @$value > 0 if $type eq 'argv';
        }
        elsif ($type eq 'seconds') {
            $valid =
                   defined($value)
                && !ref($value)
                && "$value" =~ /\A(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/
                && $value > 0
                && $value <= 86400;
        }
        elsif ($type eq 'callback') { $valid = ref($value) eq 'CODE' }
        elsif ($type eq 'handle')   { $valid = defined(fileno($value)) }
        elsif ($type eq 'environment') {
            $valid = ref($value) eq 'HASH';
            if ($valid) {
                $valid = !grep {
                           $_ !~ /\A[A-Za-z_][A-Za-z_0-9]*\z/
                        || !defined($value->{$_})
                        || ref($value->{$_})
                        || $value->{$_} =~ /\0/
                } keys %$value;
            }
        }
        LibTmux::X::InvalidArgument->throw(
            message => "invalid $name.$key; expected $type")
            unless $valid;
    }
}

sub _run ($self, $operation) {
    my ($value, $error, $finished);
    $operation->run(
        sub ($request, $done, $fail) {
            try { $done->(LibTmux::Transport->run(%$request)) }
            catch ($caught) { $fail->($caught) }
            return sub { };
        },
        sub ($result) { $value = $result; $finished = true },
        sub ($caught) { $error = $caught; $finished = true }
    );
    die $error if defined $error;
    LibTmux::X::Transport->throw(
        message => 'synchronous executor did not finish')
        unless $finished;
    return $value;
}
sub cmd ($self, @argv) { $self->_run($self->operation('cmd', argv => \@argv)) }

sub listings ($self, $kind) {
    $self->_run($self->operation('listings', kind => $kind));
}

sub batch ($self, $requests) {
    $self->_run($self->operation('batch', requests => $requests));
}

sub attach_argv ($self, %args) {
    $self->_validate_options('attach_argv', \%args);
    my $id = $args{session};
    LibTmux::X::InvalidArgument->throw(
        message => 'attach_argv needs a session ID')
        unless defined($id) && $id =~ /\A\$[0-9]+\z/;
    return [$self->_prefix, 'attach-session', '-t', $id];
}

sub execute ($self, %args) { $self->_run($self->operation('execute', %args)) }

sub new_session ($self, %args) {
    $self->_run($self->operation('new_session', %args));
}

sub new_window ($self, %args) {
    $self->_run($self->operation('new_window', %args));
}

sub split_pane ($self, %args) {
    $self->_run($self->operation('split_pane', %args));
}
sub snapshot ($self, %args) { $self->_run($self->operation('snapshot', %args)) }

sub query_panes ($self, %args) {
    $self->_run($self->operation('query_panes', %args));
}

sub explain_panes ($self, %args) {
    $self->_run($self->operation('explain_panes', %args));
}

sub rename_session ($self, %args) {
    $self->_run($self->operation('rename_session', %args));
}

sub rename_window ($self, %args) {
    $self->_run($self->operation('rename_window', %args));
}

sub link_window ($self, %args) {
    $self->_run($self->operation('link_window', %args));
}

sub unlink_window ($self, %args) {
    $self->_run($self->operation('unlink_window', %args));
}

sub move_window ($self, %args) {
    $self->_run($self->operation('move_window', %args));
}

sub select_window ($self, %args) {
    $self->_run($self->operation('select_window', %args));
}

sub select_pane ($self, %args) {
    $self->_run($self->operation('select_pane', %args));
}

sub select_layout ($self, %args) {
    $self->_run($self->operation('select_layout', %args));
}

sub resize_pane ($self, %args) {
    $self->_run($self->operation('resize_pane', %args));
}

sub set_title ($self, %args) {
    $self->_run($self->operation('set_title', %args));
}

sub send_keys ($self, %args) {
    $self->_run($self->operation('send_keys', %args));
}

sub send_text ($self, %args) {
    $self->_run($self->operation('send_text', %args));
}

sub capture_pane ($self, %args) {
    $self->_run($self->operation('capture_pane', %args));
}

sub kill_pane ($self, %args) {
    $self->_run($self->operation('kill_pane', %args));
}

sub kill_window ($self, %args) {
    $self->_run($self->operation('kill_window', %args));
}

sub kill_session ($self, %args) {
    $self->_run($self->operation('kill_session', %args));
}

sub kill_server ($self, %args) {
    $self->_run($self->operation('kill_server', %args));
}
sub clients ($self, %args) { $self->_run($self->operation('clients', %args)) }

sub detach_client ($self, %args) {
    $self->_run($self->operation('detach_client', %args));
}

sub set_option ($self, %args) {
    $self->_run($self->operation('set_option', %args));
}

sub get_option ($self, %args) {
    $self->_run($self->operation('get_option', %args));
}

sub unset_option ($self, %args) {
    $self->_run($self->operation('unset_option', %args));
}
sub set_hook ($self, %args) { $self->_run($self->operation('set_hook', %args)) }

sub show_hooks ($self, %args) {
    $self->_run($self->operation('show_hooks', %args));
}

sub set_environment ($self, %args) {
    $self->_run($self->operation('set_environment', %args));
}

sub get_environment ($self, %args) {
    $self->_run($self->operation('get_environment', %args));
}

sub unset_environment ($self, %args) {
    $self->_run($self->operation('unset_environment', %args));
}

sub set_buffer ($self, %args) {
    $self->_run($self->operation('set_buffer', %args));
}

sub show_buffer ($self, %args) {
    $self->_run($self->operation('show_buffer', %args));
}

sub delete_buffer ($self, %args) {
    $self->_run($self->operation('delete_buffer', %args));
}

=head1 NAME

LibTmux::Server - Explicit tmux acquisition and commands

=head1 SYNOPSIS

    use v5.44;
    use LibTmux::Server;
    my $server = LibTmux::Server->new(socket_name => 'application');
    my $snapshot = $server->snapshot;
    my $pane = $snapshot->panes->first;
    say $server->capture_pane(pane => $pane) if defined $pane;

=head1 CONTRACT

Construction and planning perform no I/O. Acquisition and mutation are explicit,
bounded operations. Captured L<LibTmux::Snapshot> entities retain their observed
graph; mutations do not refresh them. Acquire another snapshot to observe changes.
Connection settings remain owned by the server wrapper; destroying it never
kills a tmux daemon. See the L<orchestration guide|https://github.com/libtmux/libtmux-perl/blob/master/docs/orchestration.md>.

Physical entity targets accept stable ID strings or generation-checked handles.
Session-relative window operations require L<LibTmux::WindowLink>. Checks across
subprocesses are optimistic rather than transactional. Single-quote session IDs
such as C<'$1'> to avoid interpolating a Perl capture variable.

=head1 ERRORS

Invalid arguments throw L<LibTmux::X/InvalidArgument> before dispatch. Acquisition
and checked commands propagate typed L<LibTmux::X> failures, including missing
executables, absent daemons, vanished targets, stale handles, codec errors,
timeouts, and output limits. Failures never become empty selections. Cancellation
or a timeout after dispatch does not prove nonexecution or roll back effects.

=head1 METHODS

=head2 new

C<new(executable =E<gt> tmux, socket_nameE<verbar>socket_path =E<gt> string, timeout =E<gt> seconds, max_output =E<gt> bytes, config_file =E<gt> path, env =E<gt> hashref)>.

Return a new server wrapper without I/O. Select socket_name or socket_path,
never both. Defaults are executable tmux, timeout 5 seconds, and an 8 MiB
combined retained-output limit. env is copied; child processes clear ambient
TMUX and TMUX_PANE. Invalid configuration throws
L<LibTmux::X/InvalidArgument>.

    my $server = LibTmux::Server->new(socket_name => 'application');

=head2 execute

C<execute(argv =E<gt> arrayref, stdin =E<gt> bytes?, timeout =E<gt> seconds?, cancel_fh =E<gt> handle?)>.

Perform one raw command and return L<LibTmux::CommandResult>, including
nonzero exits. stdout and stderr remain separate octet strings. stdin is
optional bytes; cancel_fh is borrowed and remains open. Transport failures
throw typed L<LibTmux::X> with bounded partial output when available.

    my $result = $server->execute(argv => ['list-sessions']);

=head2 cmd

C<cmd(@literal_arguments)>.

Perform one checked literal tmux command and return L<LibTmux::CommandResult>.
No shell wrapper or implicit tmux command list is used. Nonzero exits throw
L<LibTmux::X/Command> or a more specific target/server error; transport
failures propagate.

    my $result = $server->cmd('display-message', '-p', '#{version}');

=head2 new_session

C<new_session(name =E<gt> string, command =E<gt> arrayref?, shell_command =E<gt> string?, width =E<gt> integer?, height =E<gt> integer?, cwd =E<gt> bytes?, environment =E<gt> hashref?)>.

Create a detached session and return its captured L<LibTmux::Session>. command
is a literal argument vector; shell_command explicitly requests a shell and is
mutually exclusive. Omitting both uses tmux's default command. cwd is path
octets; environment supplies NAME/value pairs to the first process. Performs
I/O. If creation succeeds but acquisition fails, L<LibTmux::X/Creation>
retains the known generation-scoped creation receipt and cause.

    my $session = $server->new_session(name => 'application', command => ['/bin/cat']);

=head2 new_window

C<new_window(session =E<gt> SessionE<verbar>session_id, name =E<gt> string?, command =E<gt> arrayref?, shell_command =E<gt> string?, cwd =E<gt> bytes?, environment =E<gt> hashref?)>.

Create a detached physical window in the selected session and return its
captured L<LibTmux::Window>. command, shell_command, cwd, and environment
follow L</new_session>. The new link uses tmux's next available index.
Performs I/O; L<LibTmux::X/Creation> preserves known effects if subsequent
acquisition fails.

    my $window = $server->new_window(session => $session, name => 'logs', command => ['/bin/cat']);

=head2 split_pane

C<split_pane(pane =E<gt> PaneE<verbar>pane_id, horizontal =E<gt> boolean?, command =E<gt> arrayref?, cwd =E<gt> bytes?, environment =E<gt> hashref?)>.

Split the targeted pane and return the new captured L<LibTmux::Pane>.
horizontal selects side-by-side placement; false uses tmux's vertical split.
command, shell_command, cwd, and environment follow L</new_session>. Performs
I/O; creation/acquisition failures follow L<LibTmux::X/Creation>.

    my $other = $server->split_pane(pane => $pane, horizontal => true, command => ['/bin/cat']);

=head2 snapshot

C<snapshot()>.

Perform strict graph acquisition and return L<LibTmux::Snapshot>. Physical
windows/panes appear once; L<LibTmux::WindowLink> retains each contextual
association. Capture start/end describe an observation interval, not an atomic
transaction. Acquisition, unsupported capabilities, and incomplete topology
throw typed L<LibTmux::X>; no partial snapshot is returned.

    my $snapshot = $server->snapshot;

=head2 listings

C<listings(kind)>.

Perform acquisition and return a fresh unblessed array reference of contextual
hash records in tmux order, preserving duplicate physical identities. kind is
session, window, pane, or client. An attached-client listing can be empty.
Records are detached values; L</snapshot> normalizes the graph.
Acquisition/codec failures propagate through L<LibTmux::X>.

    my $rows = $server->listings('window');

=head2 query_panes

C<query_panes(where =E<gt> criteriaE<verbar>Filter?, pushdown =E<gt> autoE<verbar>neverE<verbar>require?, native_filter =E<gt> string?, on_verification =E<gt> coderef?)>.

Acquire and return a new L<LibTmux::PaneSelection> in captured physical-pane
order. where accepts a hash reference or L<LibTmux::Filter>. auto verifies
safe scalar candidates after complete local evaluation; never disables the
native comparison. The default auto costs one extra command and supervisor
when lowering is available; it does not reduce acquisition. Select never when
only the captured answer is needed. require throws L<LibTmux::X/Unsupported>
unless lowering is exact, or L<LibTmux::X/QueryMismatch> on disagreement.
native_filter is an exclusive expert escape hatch. Empty successful matches
remain a typed selection; acquisition/evaluation failures propagate.

C<on_verification> receives one detached report hashref in void context after a
successful decision, including auto fallback. It runs inline once; its return
is ignored and exceptions propagate unchanged unless the operation has already
been cancelled. Cancellation suppresses subsequent result/error delivery.
Failed queries do not invoke it. Report edits cannot change the returned selection. See
L</VERIFICATION REPORT> and L</explain_panes>.

    my $panes = $server->query_panes(where => {active => true}, pushdown => 'auto');

=head2 explain_panes

C<explain_panes(where =E<gt> criteriaE<verbar>Filter, pushdown =E<gt> policy?)>.

Validate criteria and return an inspectable L<LibTmux::QueryPlan> without I/O
or mutation. The plan records required fields/relations, source commands,
residuals, and conditional daemon capability needs. Invalid criteria throw
L<LibTmux::X/InvalidFilter>. Executing L</query_panes> discovers the connected
generation and capabilities.

    my $plan = $server->explain_panes(where => {width => {-gte => 120}});

=head2 rename_session

C<rename_session(session =E<gt> SessionE<verbar>session_id, name =E<gt> string)>.

Rename the selected L<LibTmux::Session> using a literal name. Existing
captured handles keep the old observed name; use L</snapshot> to observe the
change.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->rename_session(session => $session, name => 'application');

=head2 rename_window

C<rename_window(window =E<gt> WindowE<verbar>window_id, name =E<gt> string)>.

Rename the physical L<LibTmux::Window> across all its links. Names remain
literal rather than expanding tmux formats. Captured handles keep their
observed name.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->rename_window(window => $window, name => 'logs');

=head2 link_window

C<link_window(window =E<gt> WindowE<verbar>window_id, session =E<gt> SessionE<verbar>session_id, index =E<gt> integer?)>.

Add an association from a physical L<LibTmux::Window> to a
L<LibTmux::Session>. index is optional; conflicts remain command failures.
Existing associations are preserved. Inspect new L<LibTmux::WindowLink>
records through L</snapshot>.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->link_window(window => $window, session => $session, index => 4);

=head2 unlink_window

C<unlink_window(link =E<gt> WindowLinkE<verbar>session_id:index)>.

Remove exactly one L<LibTmux::WindowLink>, given a captured link or
session_id:index string. Removing the final link can destroy its physical
window; other linked associations retain their context.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->unlink_window(link => $link);

=head2 move_window

C<move_window(link =E<gt> WindowLinkE<verbar>session_id:index, session =E<gt> SessionE<verbar>session_id, index =E<gt> integer?)>.

Move one contextual L<LibTmux::WindowLink> into the destination session/index.
Other links of the physical window keep their own associations. Use
L</link_window> to add an association without moving one.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->move_window(link => $link, session => $session, index => 4);

=head2 select_window

C<select_window(link =E<gt> WindowLinkE<verbar>session_id:index)>.

Select a L<LibTmux::WindowLink> within its session. A physical window alone
cannot identify session-relative active state. Capture again through
L</snapshot> to observe the selected link.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->select_window(link => $link);

=head2 select_pane

C<select_pane(pane =E<gt> PaneE<verbar>pane_id)>.

Change the active L<LibTmux::Pane> of its physical window. This differs from
selecting a session's L<LibTmux::WindowLink>.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->select_pane(pane => $pane);

=head2 select_layout

C<select_layout(window =E<gt> WindowE<verbar>window_id, layout =E<gt> string)>.

Apply an unambiguous predefined layout name or a checksum-prefixed native
layout to a L<LibTmux::Window>. Unknown or ambiguous predefined names throw
L<LibTmux::X/InvalidArgument> before dispatch, including on tmux 3.3a. Native
custom-layout validation remains tmux's responsibility.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->select_layout(window => $window, layout => 'tiled');

=head2 resize_pane

C<resize_pane(pane =E<gt> PaneE<verbar>pane_id, width =E<gt> positive_integer?, height =E<gt> positive_integer?)>.

Resize a L<LibTmux::Pane> to the supplied positive width and/or height. tmux's
layout constraints may affect the resulting dimensions; inspect another
L<LibTmux::Snapshot> for observed values.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->resize_pane(pane => $pane, width => 100);

=head2 set_title

C<set_title(pane =E<gt> PaneE<verbar>pane_id, title =E<gt> string)>.

Set a L<LibTmux::Pane> title. Literal input is protected from format
expansion; tmux's own title sanitization remains observable in a new
L<LibTmux::Snapshot>.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->set_title(pane => $pane, title => 'build.v2');

=head2 send_keys

C<send_keys(pane =E<gt> PaneE<verbar>pane_id, keys =E<gt> arrayref)>.

Send the array's named keys in order to a L<LibTmux::Pane>. tmux interprets
key names; arguments beginning with a dash remain key operands. An empty array
sends no keys. Acceptance does not prove the pane application consumed input.
Use L</send_text> for literal text.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->send_keys(pane => $pane, keys => ['Enter']);

=head2 send_text

C<send_text(pane =E<gt> PaneE<verbar>pane_id, text =E<gt> stringE<verbar>bytes, enter =E<gt> boolean?)>.

Send literal text/bytes to a L<LibTmux::Pane>, then optionally send Enter.
Empty text is permitted. Acceptance does not prove application completion. Use
an application-specific observable handshake before relying on output;
L</capture_pane> reads observed terminal content.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->send_text(pane => $pane, text => 'hello', enter => true);

=head2 capture_pane

C<capture_pane(pane =E<gt> PaneE<verbar>pane_id, start =E<gt> integer?, end =E<gt> integer?)>.

Read a L<LibTmux::Pane> and return raw terminal octets, including tmux's final
newline. Optional start/end select native history rows; no UTF-8 replacement
is performed. This I/O reads current observed content without waiting for
application work. Command/transport failures propagate through L<LibTmux::X>.

    my $bytes = $server->capture_pane(pane => $pane, start => -20);

=head2 kill_pane

C<kill_pane(pane =E<gt> PaneE<verbar>pane_id)>.

Destroy the selected L<LibTmux::Pane>. Killing a window's final pane may
destroy the physical window and its L<LibTmux::WindowLink> associations.
Previously captured records remain readable observations.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->kill_pane(pane => $pane);

=head2 kill_window

C<kill_window(window =E<gt> WindowE<verbar>window_id)>.

Destroy the physical L<LibTmux::Window> and every L<LibTmux::WindowLink>
referring to it. Use L</unlink_window> when removing one association is the
intended effect.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->kill_window(window => $window);

=head2 kill_session

C<kill_session(session =E<gt> SessionE<verbar>session_id)>.

Destroy the selected L<LibTmux::Session> and its links. Windows linked
elsewhere can survive. Captured data remains local; later mutations through
stale generation handles are checked.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->kill_session(session => $session);

=head2 kill_server

C<kill_server()>.

Explicitly request destruction of the connected tmux daemon. This method can
affect a borrowed server and must be called intentionally; wrapper destruction
never calls it. Successful command acceptance alone does not prove every
daemon/client process exited.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->kill_server;

=head2 clients

C<clients()>.

Acquire a graph and return its L<LibTmux::ClientSelection>. A daemon without
attached clients produces an empty selection. Membership is copied away from
graph storage. Acquisition failures propagate through L<LibTmux::X>;
L</detach_client> changes client state explicitly.

    my $clients = $server->clients;

=head2 attach_argv

C<attach_argv(session =E<gt> session_id)>.

Return a fresh literal argument array for a caller-owned interactive terminal
without I/O. The session target is a stable ID string; obtain it through
L<LibTmux::Session/id>. The caller owns terminal/process setup and exit
observation; the bounded capture transport does not allocate a TTY. Invalid
inputs throw L<LibTmux::X/InvalidArgument>.

    my $argv = $server->attach_argv(session => '$1');

=head2 detach_client

C<detach_client(client =E<gt> ClientE<verbar>client_name)>.

Request detachment of a captured L<LibTmux::Client> or explicit native client
name. Command acceptance can precede client-process exit; callers owning an
attached process must observe its exit separately.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->detach_client(client => $client);

=head2 set_option

C<set_option(name =E<gt> string, value =E<gt> stringE<verbar>integer, scope =E<gt> sessionE<verbar>windowE<verbar>paneE<verbar>server, target =E<gt> id?, global =E<gt> boolean?)>.

Set an option at explicit session/window/pane/server scope. Supply an exact
target ID for local settings or global => true for the global level. Empty and
zero values are preserved. L</get_option> controls whether inherited values
participate.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->set_option(scope => 'window', target => $window->id, name => '@build', value => '0');

=head2 get_option

C<get_option(name =E<gt> string, scope =E<gt> scope, target =E<gt> id?, global =E<gt> boolean?, inherited =E<gt> boolean?)>.

Read an option and return its octets, decoding tmux's quoted string values.
Literal backslashes and non-UTF-8 bytes remain distinct on older daemons.
Key, numeric and command options retain native printed syntax. Array values are
joined with newlines in native index order; an empty array returns C<''>.
Empty text and '0' remain values. C<inherited =E<gt> true> requests tmux's
C<-A> behavior; otherwise only the selected local level is queried. Performs
I/O without mutation. Native missing-option errors throw L<LibTmux::X/Command>;
malformed output throws L<LibTmux::X/Codec>. A built-in option without a local
override may produce empty output. See L</set_option> and L</unset_option>.

    my $value = $server->get_option(scope => 'window', target => $window->id, name => '@build');

=head2 unset_option

C<unset_option(name =E<gt> string, scope =E<gt> scope, target =E<gt> id?, global =E<gt> boolean?)>.

Remove the selected local/global option so inheritance can take effect. Scope
and target follow L</set_option>; removing an override differs from assigning
empty text.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->unset_option(scope => 'window', target => $window->id, name => '@build');

=head2 set_hook

C<set_hook(name =E<gt> hook_or_hook[index], command =E<gt> explicit_tmux_command_string, target =E<gt> session_id?, global =E<gt> boolean?)>.

Set a native hook or sparse hook[index] entry for an explicit session target
or global scope. command is deliberately a tmux command string, unlike literal
process argv. L</show_hooks> preserves native indexes/quoting rather than
inventing a flattened hook list.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->set_hook(target => $session->id, name => 'after-select-window[3]', command => 'display-message hook');

=head2 show_hooks

C<show_hooks(target =E<gt> session_id?, global =E<gt> boolean?)>.

Read hooks and return raw octets preserving sparse indexes and tmux quoting.
No hooks produce empty text. Performs I/O; failures propagate through
L<LibTmux::X>. See L</set_hook> for explicit command-string semantics.

    my $hooks = $server->show_hooks(target => $session->id);

=head2 set_environment

C<set_environment(name =E<gt> env_name, value =E<gt> bytes, session =E<gt> session_target?)>.

Set a literal environment value for a L<LibTmux::Session> handle or explicit
session ID, or globally when
session is omitted. Empty text and '0' remain values. Existing pane processes
are unaffected; creation-time environment belongs to L</new_session>,
L</new_window>, and L</split_pane>.
Captured handles are checked against the connected daemon generation before
dispatch; stale handles throw L<LibTmux::X/StaleReference>. Raw IDs target the
current session. The probe and mutation remain separate operations.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->set_environment(session => $session, name => 'BUILD', value => '0');

=head2 get_environment

C<get_environment(name =E<gt> env_name, session =E<gt> session_target?)>.

Read a session/global variable and return its octets. The native quoted
representation is parsed as data; no shell evaluates it. Literal backslashes,
newlines and non-UTF-8 bytes remain distinct. Empty text and '0' remain values.
Performs I/O without mutation; missing or explicitly unset variables throw
L<LibTmux::X/Command>, and malformed output throws L<LibTmux::X/Codec>.
Captured targets follow L</set_environment>'s generation checks.

    my $value = $server->get_environment(session => $session, name => 'BUILD');

=head2 unset_environment

C<unset_environment(name =E<gt> env_name, session =E<gt> session_target?)>.

Unset the named session/global variable. This differs from setting an empty
value; L</get_environment> reports the unset state as a command error.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->unset_environment(session => $session, name => 'BUILD');

=head2 set_buffer

C<set_buffer(name =E<gt> string, data =E<gt> bytes)>.

Load a named tmux buffer through stdin bytes rather than interpolating data
into a command. Empty data is permitted. L</show_buffer> retrieves bytes;
buffer ownership remains in the daemon until L</delete_buffer> or an external
change.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->set_buffer(name => 'application', data => "a\0b");

=head2 show_buffer

C<show_buffer(name =E<gt> string)>.

Read a named tmux buffer and return raw octets, including embedded NUL bytes.
Empty data remains an empty string. Performs I/O; a missing buffer throws
L<LibTmux::X/Command>. See L</set_buffer>.

    my $bytes = $server->show_buffer(name => 'application');

=head2 delete_buffer

C<delete_buffer(name =E<gt> string)>.

Delete the named daemon buffer loaded through L</set_buffer>. Other daemon
buffers remain untouched; later L</show_buffer> calls report absence as a
command failure.

Returns C<undef> after command acceptance. Performs I/O; failures propagate
through L<LibTmux::X>. Captured objects are not modified.

    $server->delete_buffer(name => 'application');

=head2 batch

C<batch(arrayref_of_argv)>.

Perform ordered independent literal requests and return a fresh array
reference of {result, error} records in input order. Each result is
L<LibTmux::CommandResult> or undef; each dispatch error is the original typed
L<LibTmux::X> or undef. Nonzero command exits stay raw results. An empty input
returns an empty array without command I/O. Requests are attempted in order,
without rollback or tmux command-list attribution.

    my $results = $server->batch([['display-message', '-p', '#{version}']]);

=head2 operation

C<operation($name, %arguments)> validates and copies arguments, returning one
L<LibTmux::Operation> without I/O. The optional Future facade shares this
preparation and parsing boundary. Use the named methods above for synchronous
execution. Invalid arguments or criteria throw L<LibTmux::X/InvalidArgument>
or L<LibTmux::X/InvalidFilter> before submission.

    my $operation = $server->operation('snapshot');

=head1 VERIFICATION REPORT

L</query_panes> supplies a fresh, detached hashref to C<on_verification>.
It contains no entity handles. Every ID array retains stable order; editing
the report cannot mutate captured data or the query result.

=over 4

=item C<policy>, C<status>, C<comparison>

Policy is auto, never, require, or native for the expert escape hatch. Status
is disabled (never), local (no safe lowering), agreed, disagreed, or native.
Comparison is none, exact_ids, candidate_superset, or captured_membership.
Partial lowering checks inclusion of local matches; expert queries check only
membership in the captured graph. Neither establishes full filter equivalence.

=item C<native_checked>, C<translation_exact>, C<native_filter>, C<reasons>

native_checked is Boolean. translation_exact is Boolean, or undef for never
and expert queries. native_filter is the executed expression, or undef when no
native check ran. reasons is a fresh arrayref of lowering limitations. Exact
translation and agreement between two observations are separate facts.

=item C<server_id>, C<generation>, C<daemon_version>, C<capture_start>, C<capture_end>

Identity strings and the captured interval in wall-clock seconds since the
epoch, from L<LibTmux::Snapshot/metadata>. This is not an atomic observation.

=item C<captured_ids>, C<local_ids>, C<native_ids>

captured_ids and local_ids follow physical capture order; local_ids is undef
for expert queries. native_ids holds unique IDs in native first-occurrence
order, or undef when no check ran. An empty array is an observed empty set.

=item C<missing_ids>, C<unexpected_ids>, C<uncaptured_ids>

missing_ids lists local matches absent natively, in local order. For exact
lowering, unexpected_ids lists native matches absent locally. uncaptured_ids
lists native IDs absent from the graph. The latter two follow native order;
inapplicable lists are empty. Any applicable mismatch produces disagreed.
L<LibTmux::X/QueryMismatch> carries this report for require or expert failures;
the observer is not called for a failed query. A discrepancy has no inferred
cause: concurrent changes, compiler defects and backend differences all need
investigation.

=back

=cut

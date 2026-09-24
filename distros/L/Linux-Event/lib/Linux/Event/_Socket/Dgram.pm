package Linux::Event::_Socket::Dgram;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::_Socket';

use Carp qw(croak);
use Config ();
use Errno ();
use Fcntl qw(F_GETFD F_GETFL F_SETFD F_SETFL FD_CLOEXEC O_NONBLOCK);
use Scalar::Util qw(blessed);
use Socket qw(
    AF_INET AF_INET6 AF_UNIX AI_PASSIVE
    IPPROTO_IPV6 IPV6_V6ONLY
    SOCK_DGRAM SOCK_NONBLOCK SOCK_CLOEXEC
    SOL_SOCKET SO_BROADCAST SO_ERROR SO_REUSEADDR SO_REUSEPORT SO_TYPE
    getaddrinfo inet_pton pack_sockaddr_in pack_sockaddr_in6 pack_sockaddr_un
);
use utf8 ();

use Linux::Event::Address;
use Linux::Event::Error;
use Linux::Event::_SocketConfig ();
use Linux::Event::_Resolver ();
require Linux::Event::Kernel::Timer;
require XSLoader;
XSLoader::load(__PACKAGE__);

my %CLASS_DESCRIPTOR;
my @APPLICATION_CALLBACK = qw(
    on_datagram on_drain on_ready on_error on_close
);
my $MAX_INTEGER = $Config::Config{ivsize} >= 8
    ? '9223372036854775807' : '2147483647';

sub _integer ($target, $name, $value, $minimum, $maximum = undef) {
    croak "$target $name must be an integer"
        if !defined($value) || ref($value) || $value !~ /\A\d+\z/;
    $maximum //= $MAX_INTEGER;
    my $digits = "$value";
    $digits =~ s/\A0+(?=\d)//;
    croak "$target $name must be at most $maximum"
        if length($digits) > length("$maximum")
        || (length($digits) == length("$maximum")
            && $digits gt "$maximum");
    $value = 0 + $value;
    croak "$target $name must be at least $minimum" if $value < $minimum;
    return $value;
}

sub _boolean ($target, $name, $value) {
    croak "$target $name must be zero or one"
        if !defined($value) || ref($value) || $value !~ /\A[01]\z/;
    return $value ? 1 : 0;
}

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak 'Linux::Event::_Socket::Dgram is an abstract base class'
        if $class eq __PACKAGE__;
    croak "$class is not a Linux::Event::_Socket::Dgram subclass"
        if !$class->isa(__PACKAGE__);
    my %callback = map { $_ => scalar $class->can($_) } qw(
        on_datagram on_drain on_ready on_error on_close configure_socket
    );
    my %option = (
        max_datagram_size      => 65_535,
        max_datagrams_per_tick => 256,
        edge_triggered         => 0,
        high_watermark         => 1_048_576,
        low_watermark          => 262_144,
        max_pending_bytes      => 0,
        max_pending_datagrams  => 0,
        reuseaddr              => 0,
        reuseport              => 0,
        broadcast              => 0,
        v6only                 => undef,
        send_buffer            => undef,
        receive_buffer         => undef,
    );
    if (my $configure = $class->can('datagram_options')) {
        my @configured = $configure->($class);
        my %configured;
        if (@configured == 1 && ref($configured[0]) eq 'HASH') {
            %configured = %{ $configured[0] };
        } else {
            croak "$class datagram_options() returned an odd option list"
                if @configured % 2;
            %configured = @configured;
        }
        my @unknown = grep { !exists $option{$_} } keys %configured;
        croak "$class datagram_options() returned unknown options: "
            . join(', ', sort @unknown) if @unknown;
        @option{keys %configured} = values %configured;
    }
    $option{max_datagram_size} = _integer(
        $class, 'max_datagram_size', $option{max_datagram_size}, 1, 16_777_216,
    );
    $option{max_datagrams_per_tick} = _integer(
        $class, 'max_datagrams_per_tick',
        $option{max_datagrams_per_tick}, 0,
    );
    for my $name (qw(high_watermark low_watermark max_pending_bytes
        max_pending_datagrams)) {
        $option{$name} = _integer($class, $name, $option{$name}, 0);
    }
    croak "$class low_watermark must be <= high_watermark"
        if $option{low_watermark} > $option{high_watermark};
    for my $name (qw(edge_triggered reuseaddr reuseport broadcast)) {
        $option{$name} = _boolean($class, $name, $option{$name});
    }
    $option{v6only} = _boolean($class, 'v6only', $option{v6only})
        if defined $option{v6only};
    for my $name (qw(send_buffer receive_buffer)) {
        $option{$name} = Linux::Event::_SocketConfig::normalize(
            $class, $name, $option{$name},
        ) if defined $option{$name};
    }
    croak "$class edge_triggered requires max_datagrams_per_tick => 0"
        if $option{edge_triggered} && $option{max_datagrams_per_tick};
    return $CLASS_DESCRIPTOR{$class} = {
        class => $class, callbacks => \%callback, options => \%option,
    };
}

sub _effective_descriptor ($class, $method, $option) {
    my $descriptor = _descriptor_for($class);
    my %override;
    for my $name (@APPLICATION_CALLBACK) {
        next if !exists $option->{$name};
        my $callback = delete $option->{$name};
        croak "$method(): $name must be a coderef"
            if ref($callback) ne 'CODE';
        $override{$name} = $callback;
    }
    my %callback = (%{ $descriptor->{callbacks} }, %override);
    croak "$method(): on_datagram callback is required"
        if !$callback{on_datagram};
    return $descriptor if !%override;
    return { %$descriptor, callbacks => \%callback };
}

sub new ($class, %option) {
    return $class->_construct(0, %option);
}

sub connect ($class, %option) {
    return $class->_construct(1, %option);
}

sub _construct ($class, $connect, %option) {
    croak(($connect ? 'connect' : 'new') .
        '(): must be called as a class method') if ref $class;
    my $method = $connect ? 'connect' : 'new';
    my $descriptor = _effective_descriptor($class, $method, \%option);
    my %known = map { $_ => 1 } qw(
        loop data bind_device
        max_datagram_size max_datagrams_per_tick edge_triggered
        high_watermark low_watermark max_pending_bytes
        max_pending_datagrams reuseaddr reuseport broadcast v6only
        send_buffer receive_buffer
        unlink unlink_on_close permissions owns_socket
        fh host port unix local_host local_port local_unix
    );
    my @unknown = sort grep { !$known{$_} } keys %option;
    croak "$method(): unknown options: " . join(', ', @unknown) if @unknown;
    my %supplied = map { $_ => 1 } keys %option;
    my $loop = delete $option{loop};
    croak "$method(): loop must be an object implementing add() and watch()"
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    my $bind_device = delete $option{bind_device};
    croak "$method(): bind_device must be a non-empty interface name"
        if defined($bind_device)
        && (ref($bind_device) || $bind_device eq '' || $bind_device =~ /\0/);

    my %effective = %{ $descriptor->{options} };
    for my $name (keys %effective) {
        next if !exists $option{$name};
        $effective{$name} = delete $option{$name};
    }
    $effective{max_datagram_size} = _integer(
        "$method():", 'max_datagram_size', $effective{max_datagram_size},
        1, 16_777_216,
    );
    $effective{max_datagrams_per_tick} = _integer(
        "$method():", 'max_datagrams_per_tick',
        $effective{max_datagrams_per_tick}, 0,
    );
    for my $name (qw(high_watermark low_watermark max_pending_bytes
        max_pending_datagrams)) {
        $effective{$name} = _integer(
            "$method():", $name, $effective{$name}, 0,
        );
    }
    croak "$method(): low_watermark must be <= high_watermark"
        if $effective{low_watermark} > $effective{high_watermark};
    for my $name (qw(edge_triggered reuseaddr reuseport broadcast)) {
        $effective{$name} = _boolean(
            "$method():", $name, $effective{$name},
        );
    }
    $effective{v6only} = _boolean(
        "$method():", 'v6only', $effective{v6only},
    ) if defined $effective{v6only};
    for my $name (qw(send_buffer receive_buffer)) {
        $effective{$name} = Linux::Event::_SocketConfig::normalize(
            $method, $name, $effective{$name},
        ) if defined $effective{$name};
    }
    croak "$method(): edge_triggered requires max_datagrams_per_tick => 0"
        if $effective{edge_triggered} && $effective{max_datagrams_per_tick};
    croak "$method(): broadcast and v6only cannot be combined"
        if $effective{broadcast} && defined $effective{v6only};

    my $unlink_existing = exists($option{unlink})
        ? _boolean("$method():", 'unlink', delete $option{unlink}) : 0;
    my $unlink_on_close = exists($option{unlink_on_close})
        ? _boolean("$method():", 'unlink_on_close',
            delete $option{unlink_on_close}) : 1;
    my $permissions = delete $option{permissions};
    $permissions = _integer("$method():", 'permissions', $permissions, 0, 07777)
        if defined $permissions;
    my $owns_socket_supplied = exists $option{owns_socket};
    my $owns_socket = $owns_socket_supplied
        ? _boolean("$method():", 'owns_socket', delete $option{owns_socket})
        : 0;

    my ($fh, $family, $local, $peer, $path, $local_path);
    my $adopted = 0;
    my ($host, $port, $local_host, $local_port, $needs_resolution,
        $local_bind, $required_family, $required_family_option);
    if (!$connect && exists $option{fh}) {
        $adopted = 1;
        $fh = delete $option{fh};
        croak 'new(): fh must be a datagram socket filehandle'
            if !defined($fh) || !defined(fileno($fh));
        croak 'new(): address options are not valid with fh'
            if grep { exists $option{$_} } qw(host port unix local_host
                local_port local_unix);
        my $type = getsockopt($fh, SOL_SOCKET, SO_TYPE);
        croak 'new(): fh must be a datagram socket'
            if !defined($type) || length($type) < 4
            || unpack('i', $type) != SOCK_DGRAM;
        $local = Linux::Event::Address->new(getsockname($fh));
        $family = $local->family_number;
        croak 'new(): fh must use an IPv4, IPv6, or Unix address family'
            if !defined($family) || ($family != AF_INET
                && $family != AF_INET6 && $family != AF_UNIX);
        my @invalid = grep { $supplied{$_} }
            qw(unlink unlink_on_close permissions);
        if ($family == AF_UNIX) {
            push @invalid, grep { $supplied{$_} }
                qw(bind_device v6only broadcast reuseaddr reuseport);
            push @invalid, 'broadcast'
                if $effective{broadcast} && !$supplied{broadcast};
            push @invalid, 'reuseaddr'
                if $effective{reuseaddr} && !$supplied{reuseaddr};
            push @invalid, 'reuseport'
                if $effective{reuseport} && !$supplied{reuseport};
            push @invalid, 'v6only'
                if defined($effective{v6only}) && !$supplied{v6only};
        }
        croak 'new(): options not valid for this socket source: '
            . join(', ', sort @invalid) if @invalid;
        _set_adopted_flags($fh);
        my $packed_peer = eval { getpeername($fh) };
        $peer = Linux::Event::Address->new($packed_peer)
            if defined $packed_peer;
        $connect = defined($peer) ? 1 : 0;
    } elsif (!$connect && (exists($option{host}) || exists($option{port}))) {
        $host = delete $option{host};
        $port = delete $option{port};
        croak 'new(): host is required' if !defined $host;
        croak 'new(): host must be a non-empty string without NUL bytes'
            if ref($host) || $host eq '' || $host =~ /\0/;
        $port = _integer('new():', 'port', $port, 0, 65535);
        my @invalid = grep { $supplied{$_} }
            qw(unix local_host local_port local_unix unlink unlink_on_close
               permissions owns_socket);
        croak 'new(): options not valid for UDP: '
            . join(', ', sort @invalid) if @invalid;
        ($fh, $family) = _create_bound_inet(
            $host, $port, \%effective, $bind_device,
        );
        $local = Linux::Event::Address->new(getsockname($fh));
        $owns_socket = 1;
    } elsif (!$connect && exists $option{unix}) {
        $path = delete $option{unix};
        croak 'new(): unix must be a non-empty path without NUL bytes'
            if !defined($path) || ref($path) || $path eq '' || $path =~ /\0/;
        my @invalid = grep { $supplied{$_} }
            qw(local_host local_port local_unix bind_device v6only broadcast
               reuseaddr reuseport owns_socket);
        push @invalid, 'broadcast'
            if $effective{broadcast} && !$supplied{broadcast};
        push @invalid, 'reuseaddr'
            if $effective{reuseaddr} && !$supplied{reuseaddr};
        push @invalid, 'reuseport'
            if $effective{reuseport} && !$supplied{reuseport};
        push @invalid, 'v6only'
            if defined($effective{v6only}) && !$supplied{v6only};
        croak 'new(): options not valid for Unix datagrams: '
            . join(', ', sort @invalid) if @invalid;
        ($fh, $family) = _create_bound_unix(
            $path, $unlink_existing, $permissions, \%effective,
        );
        $local = Linux::Event::Address->new(getsockname($fh));
        $owns_socket = 1;
    } elsif ($connect && (exists($option{host}) || exists($option{port}))) {
        $host = delete $option{host};
        $port = delete $option{port};
        croak 'connect(): host is required' if !defined $host;
        croak 'connect(): host must be a non-empty string without NUL bytes'
            if ref($host) || $host eq '' || $host =~ /\0/;
        $port = _integer('connect():', 'port', $port, 0, 65535);
        my $has_local_host = exists $option{local_host};
        $local_host = delete $option{local_host};
        my $has_local_port = exists $option{local_port};
        $local_port = $has_local_port ? _integer(
            'connect():', 'local_port', delete($option{local_port}), 0, 65535,
        ) : 0;
        $local_bind = $has_local_host || $has_local_port ? 1 : 0;
        if ($has_local_host) {
            croak 'connect(): local_host must be a non-empty numeric IP address'
                if !defined($local_host) || ref($local_host) || $local_host eq '';
            croak 'connect(): local_host must be a numeric IPv4 or IPv6 address'
                if !defined(inet_pton(AF_INET, $local_host))
                && !defined(inet_pton(AF_INET6, $local_host));
            $required_family = defined(inet_pton(AF_INET, $local_host))
                ? AF_INET : AF_INET6;
            $required_family_option = 'local_host';
        }
        if (defined $effective{v6only}) {
            croak 'connect(): local_host conflicts with v6only'
                if defined($required_family) && $required_family != AF_INET6;
            $required_family = AF_INET6;
            $required_family_option = 'v6only';
        }
        if ($effective{broadcast}) {
            croak 'connect(): local_host conflicts with broadcast'
                if defined($required_family) && $required_family != AF_INET;
            $required_family = AF_INET;
            $required_family_option = 'broadcast';
        }
        my @invalid = grep { $supplied{$_} }
            qw(fh unix local_unix unlink unlink_on_close permissions
               owns_socket);
        croak 'connect(): options not valid for UDP: '
            . join(', ', sort @invalid) if @invalid;
        $needs_resolution = !defined(inet_pton(AF_INET, $host))
            && !defined(inet_pton(AF_INET6, $host));
        $owns_socket = 1;
    } elsif ($connect && exists $option{unix}) {
        $path = delete $option{unix};
        $local_path = delete $option{local_unix};
        croak 'connect(): unix must be a non-empty path without NUL bytes'
            if !defined($path) || ref($path) || $path eq '' || $path =~ /\0/;
        croak 'connect(): local_unix must be a non-empty path without NUL bytes'
            if defined($local_path)
            && (ref($local_path) || $local_path eq '' || $local_path =~ /\0/);
        my @invalid = grep { $supplied{$_} }
            qw(fh host port local_host local_port bind_device v6only broadcast
               reuseaddr reuseport owns_socket);
        push @invalid, grep { $supplied{$_} }
            qw(unlink unlink_on_close permissions) if !defined $local_path;
        push @invalid, 'broadcast'
            if $effective{broadcast} && !$supplied{broadcast};
        push @invalid, 'reuseaddr'
            if $effective{reuseaddr} && !$supplied{reuseaddr};
        push @invalid, 'reuseport'
            if $effective{reuseport} && !$supplied{reuseport};
        push @invalid, 'v6only'
            if defined($effective{v6only}) && !$supplied{v6only};
        croak 'connect(): options not valid for Unix datagrams: '
            . join(', ', sort @invalid) if @invalid;
        $owns_socket = 1;
    } else {
        croak "$method(): exactly one socket source is required "
            . ($connect ? '(host/port or unix)' : '(fh, host/port, or unix)');
    }
    my $validation_error = !$adopted && $owns_socket_supplied
        ? "$method(): owns_socket is valid only with fh"
        : %option
            ? "$method(): options not valid for this socket source: "
                . join(', ', sort keys %option)
            : undef;
    if (defined $validation_error) {
        if (!$adopted && defined $fh) {
            close $fh;
            unlink $path if !$connect && defined($path) && -S $path;
        }
        croak $validation_error;
    }

    my $self = bless {
        descriptor => $descriptor,
        options     => \%effective,
        loop        => undef,
        data        => $data,
        fh          => $fh,
        watcher     => undef,
        family_number => $family,
        local       => $local,
        peer        => $peer,
        connected   => $connect ? 1 : 0,
        host        => $host,
        port        => $port,
        path        => $path,
        local_host  => $local_host,
        local_port  => $local_port,
        local_bind  => $local_bind ? 1 : 0,
        local_path  => $local_path,
        bind_device => $bind_device,
        required_family => $required_family,
        required_family_option => $required_family_option,
        needs_resolution => $needs_resolution ? 1 : 0,
        resolver    => undef,
        resolver_request => undef,
        owns_socket => $owns_socket ? 1 : 0,
        unlink_existing => $unlink_existing,
        unlink_on_close => $unlink_on_close,
        permissions => $permissions,
        queue       => [],
        pending_bytes => 0,
        above_high => 0,
        read_paused => 0,
        state       => 'unattached',
        last_error  => undef,
        ready_fired => 0,
        ready_timer => undef,
    }, $class;

    if ($fh) {
        my $configured = eval {
            $self->_apply_socket_policy($fh, $family) if $adopted;
            $self->_configure_socket(
                $fh, $adopted ? 'adopted' : 'bind',
                $adopted ? ($peer // $local) : $local,
            );
            1;
        };
        if (!$configured) {
            my $error = $@ || 'socket configuration failed';
            close $fh if $self->{owns_socket};
            unlink $path
                if $self->{owns_socket} && defined($path) && -S $path;
            $self->{fh} = undef;
            die $error;
        }
    }
    $loop->add($self) if defined $loop;
    return $self;
}

sub _message ($errno) { local $! = $errno; return "$!" }

sub _setup_error ($operation, $errno, %field) {
    die Linux::Event::Error->new(
        type => 'setup', operation => $operation, errno => $errno,
        message => _message($errno), fatal => 1, %field,
    );
}

sub _set_adopted_flags ($fh) {
    my $status = fcntl($fh, F_GETFL, 0);
    _setup_error('fcntl', 0 + $!) if !defined $status;
    fcntl($fh, F_SETFL, $status | O_NONBLOCK)
        or _setup_error('fcntl', 0 + $!);
    my $descriptor = fcntl($fh, F_GETFD, 0);
    _setup_error('fcntl', 0 + $!) if !defined $descriptor;
    fcntl($fh, F_SETFD, $descriptor | FD_CLOEXEC)
        or _setup_error('fcntl', 0 + $!);
    return;
}

sub _create_bound_inet ($host, $port, $option, $bind_device) {
    my $node = $host eq '*' ? undef : $host;
    my ($error, @candidate) = getaddrinfo(
        $node, $port, { socktype => SOCK_DGRAM, flags => AI_PASSIVE },
    );
    die Linux::Event::Error->new(
        type => 'resolve', operation => 'resolve', message => "$error",
        host => $host, port => $port,
    ) if $error;
    my $last_errno = Errno::EADDRNOTAVAIL();
    my $compatible = 0;
    for my $candidate (@candidate) {
        next if $candidate->{family} != AF_INET
            && $candidate->{family} != AF_INET6;
        next if defined($option->{v6only})
            && $candidate->{family} != AF_INET6;
        next if $option->{broadcast} && $candidate->{family} != AF_INET;
        $compatible = 1;
        my $fh;
        if (!socket($fh, $candidate->{family},
            SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC,
            $candidate->{protocol} // 0)) {
            $last_errno = 0 + $!;
            next;
        }
        my $ok = eval {
            _apply_creation_policy(
                $fh, $candidate->{family}, $option, $bind_device,
            );
            bind($fh, $candidate->{addr})
                or _setup_error('bind', 0 + $!, host => $host, port => $port);
            1;
        };
        return ($fh, $candidate->{family}) if $ok;
        my $failure = $@;
        close $fh;
        die $failure if blessed($failure)
            && $failure->isa('Linux::Event::Error')
            && $failure->type eq 'socket_configuration';
        $last_errno = blessed($failure) && defined($failure->errno)
            ? $failure->errno : 0 + $!;
    }
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => 'setsockopt',
        option => 'v6only',
        message => 'v6only requires an IPv6 bind address',
        host => $host, port => $port,
    ) if defined($option->{v6only}) && !$compatible;
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => 'setsockopt',
        option => 'broadcast',
        message => 'broadcast requires an IPv4 bind address',
        host => $host, port => $port,
    ) if $option->{broadcast} && !$compatible;
    _setup_error('bind', $last_errno, host => $host, port => $port);
}

sub _prepare_unix_path ($path, $unlink_existing) {
    if (-e $path || -l $path) {
        croak "Unix datagram path already exists: $path" if !$unlink_existing;
        croak "refusing to unlink non-socket path: $path" if !-S $path;
        unlink($path) or _setup_error('unlink', 0 + $!, path => $path);
    }
    return;
}

sub _create_bound_unix ($path, $unlink_existing, $permissions, $option) {
    _prepare_unix_path($path, $unlink_existing);
    socket(my $fh, AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0)
        or _setup_error('socket', 0 + $!, path => $path);
    my $ok = eval {
        Linux::Event::_SocketConfig::apply_policy($fh, AF_UNIX, {
            send_buffer => $option->{send_buffer},
            receive_buffer => $option->{receive_buffer},
        });
        bind($fh, pack_sockaddr_un($path))
            or _setup_error('bind', 0 + $!, path => $path);
        if (defined($permissions) && !chmod($permissions, $path)) {
            _setup_error('chmod', 0 + $!, path => $path);
        }
        1;
    };
    if (!$ok) {
        my $failure = $@;
        close $fh;
        unlink $path if -S $path;
        die $failure;
    }
    return ($fh, AF_UNIX);
}

sub _socket_option_error ($name, $errno, $message = undef,
    $operation = 'setsockopt') {
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => $operation,
        option => $name, errno => $errno || undef,
        message => $message // _message($errno),
    );
}

sub _apply_creation_policy ($fh, $family, $option, $bind_device) {
    for my $item (
        ['reuseaddr', SO_REUSEADDR, $option->{reuseaddr}],
        ['reuseport', SO_REUSEPORT, $option->{reuseport}],
        ['broadcast', SO_BROADCAST, $option->{broadcast}],
    ) {
        next if !$item->[2];
        _socket_option_error(
            'broadcast', 0, 'broadcast is valid only for IPv4 sockets',
        ) if $item->[0] eq 'broadcast' && $family != AF_INET;
        setsockopt($fh, SOL_SOCKET, $item->[1], pack('i', 1))
            or _socket_option_error($item->[0], 0 + $!);
    }
    if (defined($option->{v6only}) && $family != AF_INET6) {
        die Linux::Event::Error->new(
            type => 'socket_configuration', operation => 'setsockopt',
            option => 'v6only',
            message => 'v6only is valid only for IPv6 sockets',
        );
    }
    if (defined($option->{v6only})) {
        setsockopt($fh, IPPROTO_IPV6, IPV6_V6ONLY,
            pack('i', $option->{v6only}))
            or _socket_option_error('v6only', 0 + $!);
    }
    Linux::Event::_SocketConfig::apply_policy($fh, $family, {
        send_buffer => $option->{send_buffer},
        receive_buffer => $option->{receive_buffer},
    });
    Linux::Event::_SocketConfig::bind_device($fh, $bind_device)
        if defined $bind_device;
    return;
}

sub _apply_socket_policy ($self, $fh, $family) {
    _apply_creation_policy(
        $fh, $family, $self->{options}, $self->{bind_device},
    );
    return;
}

sub _configure_socket ($self, $fh, $role, $address) {
    my $callback = $self->{descriptor}{callbacks}{configure_socket};
    return if !$callback;
    my $ok = eval { $callback->($self, $fh, $role, $address); 1 };
    return if $ok;
    my $message = "$@";
    $message =~ s/\s+\z//;
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => 'configure_socket',
        message => $message || 'configure_socket callback failed',
    );
}

sub _attach_to_loop ($self, $loop) {
    croak 'add(): Datagram is not unattached'
        if $self->{state} ne 'unattached' || $self->{loop};
    $self->{loop} = $loop;
    if ($self->{fh}) {
        $self->{state} = 'active';
        my $registered = eval {
            $self->_register;
            $self->_schedule_ready;
            1;
        };
        if (!$registered) {
            my $failure = $@ || 'could not register Datagram socket';
            if (my $timer = delete $self->{ready_timer}) {
                $timer->cancel if !$timer->is_terminal;
            }
            if (my $watcher = delete $self->{watcher}) {
                $watcher->cancel;
            }
            $self->{state} = 'unattached';
            $self->{loop} = undef;
            die $failure if blessed($failure)
                && $failure->isa('Linux::Event::Error');
            die Linux::Event::Error->new(
                type      => 'setup',
                operation => 'watch',
                fatal     => 0,
                message   => "$failure",
            );
        }
        return $self;
    }
    if ($self->{needs_resolution}) {
        $self->{state} = 'resolving';
        my ($resolver, $id);
        my $submitted = eval {
            $resolver = Linux::Event::_Resolver->for_loop($loop);
            $self->{resolver} = $resolver;
            $id = $resolver->submit(
                $self, $self->{host}, $self->{port}, SOCK_DGRAM,
            );
            1;
        };
        if (!$submitted || !$id) {
            my $message = "$@" || 'could not submit hostname resolution';
            $self->_fail(Linux::Event::Error->new(
                type => 'resolve', operation => 'resolve', message => $message,
                host => $self->{host}, port => $self->{port},
            ));
        } else {
            $self->{resolver_request} = $id;
        }
        return $self;
    }
    my $activated = eval {
        if ($self->{path}) {
            $self->_activate_unix;
        } else {
            my $packed4 = inet_pton(AF_INET, $self->{host});
            my ($family, $sockaddr);
            if (defined $packed4) {
                $family = AF_INET;
                $sockaddr = pack_sockaddr_in($self->{port}, $packed4);
            } else {
                $family = AF_INET6;
                $sockaddr = pack_sockaddr_in6(
                    $self->{port}, inet_pton(AF_INET6, $self->{host}),
                );
            }
            $self->_activate_inet_candidate({
                family => $family, protocol => 0, sockaddr => $sockaddr,
            });
        }
        1;
    };
    if (!$activated) {
        my $failure = $@;
        my $error = blessed($failure)
            && $failure->isa('Linux::Event::Error')
            ? $failure
            : Linux::Event::Error->new(
                type => 'connect', operation => 'connect',
                message => "$failure" || 'datagram connection failed',
                host => $self->{host}, port => $self->{port},
                path => $self->{path},
            );
        $self->_fail($error);
    }
    return $self;
}

sub _resolver_completed ($self, $result) {
    return if $self->{state} ne 'resolving';
    return if !defined($self->{resolver_request})
        || $result->{id} != $self->{resolver_request};
    delete $self->{resolver_request};
    delete $self->{resolver};
    if ($result->{error_code}) {
        $self->_fail(Linux::Event::Error->new(
            type => 'resolve', operation => 'resolve',
            errno => $result->{system_errno} || undef,
            message => $result->{message} || 'hostname resolution failed',
            resolver_message => $result->{message},
            host => $self->{host}, port => $self->{port},
        ));
        return;
    }
    my $last_error;
    my $compatible = 0;
    for my $candidate (@{ $result->{candidates} }) {
        next if $candidate->{family} != AF_INET
            && $candidate->{family} != AF_INET6;
        next if defined($self->{required_family})
            && $candidate->{family} != $self->{required_family};
        $compatible = 1;
        my $ok = eval { $self->_activate_inet_candidate($candidate); 1 };
        return if $ok;
        $last_error = $@;
        if (blessed($last_error)
            && $last_error->isa('Linux::Event::Error')
            && ($last_error->type eq 'socket_configuration'
                || $last_error->type eq 'setup')) {
            $self->_fail($last_error);
            return;
        }
    }
    if (defined($self->{required_family}) && !$compatible) {
        my $option = $self->{required_family_option};
        my $message = $option eq 'local_host'
            ? 'local_host address family does not match any peer address'
            : "$option has no compatible peer address";
        $self->_fail(Linux::Event::Error->new(
            type => 'socket_configuration', operation => 'bind',
            option => $option,
            message => $message,
            host => $self->{host}, port => $self->{port},
        ));
        return;
    }
    $self->_fail(blessed($last_error)
        && $last_error->isa('Linux::Event::Error')
        ? $last_error
        : Linux::Event::Error->new(
            type => 'connect', operation => 'connect',
            message => "$last_error" || 'no compatible datagram address',
            host => $self->{host}, port => $self->{port},
        ));
    return;
}

sub _activate_inet_candidate ($self, $candidate) {
    my $fh;
    socket($fh, $candidate->{family},
        SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC,
        $candidate->{protocol} // 0)
        or _setup_error('socket', 0 + $!,
            host => $self->{host}, port => $self->{port});
    my $ok = eval {
        $self->_apply_socket_policy($fh, $candidate->{family});
        $self->_configure_socket(
            $fh, 'connect', Linux::Event::Address->new($candidate->{sockaddr}),
        );
        if ($self->{local_bind}) {
            my $packed;
            if (defined $self->{local_host}) {
                $packed = inet_pton($candidate->{family}, $self->{local_host});
                die Linux::Event::Error->new(
                    type => 'socket_configuration', operation => 'bind',
                    option => 'local_host',
                    message => 'local_host address family does not match peer',
                ) if !defined $packed;
            } else {
                $packed = inet_pton(
                    $candidate->{family},
                    $candidate->{family} == AF_INET ? '0.0.0.0' : '::',
                );
            }
            my $local = $candidate->{family} == AF_INET
                ? pack_sockaddr_in($self->{local_port}, $packed)
                : pack_sockaddr_in6($self->{local_port}, $packed);
            if (!bind($fh, $local)) {
                my $errno = 0 + $!;
                die Linux::Event::Error->new(
                    type      => 'socket_configuration',
                    operation => 'bind',
                    option    => defined($self->{local_host})
                        ? 'local_host' : 'local_port',
                    errno     => $errno,
                    message   => _message($errno),
                    host      => $self->{local_host},
                    port      => $self->{local_port},
                );
            }
        }
        CORE::connect($fh, $candidate->{sockaddr})
            or _setup_error('connect', 0 + $!,
                host => $self->{host}, port => $self->{port});
        1;
    };
    if (!$ok) {
        my $failure = $@;
        close $fh;
        die $failure;
    }
    $self->_finish_activation($fh, $candidate->{family});
    return;
}

sub _activate_unix ($self) {
    my $fh;
    socket($fh, AF_UNIX, SOCK_DGRAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0)
        or _setup_error('socket', 0 + $!, path => $self->{path});
    my $ok = eval {
        $self->_apply_socket_policy($fh, AF_UNIX);
        $self->_configure_socket(
            $fh, 'connect', Linux::Event::Address->new(
                pack_sockaddr_un($self->{path}),
            ),
        );
        if (defined $self->{local_path}) {
            _prepare_unix_path($self->{local_path}, $self->{unlink_existing});
            bind($fh, pack_sockaddr_un($self->{local_path}))
                or _setup_error('bind', 0 + $!, path => $self->{local_path});
            chmod($self->{permissions}, $self->{local_path})
                or _setup_error('chmod', 0 + $!, path => $self->{local_path})
                if defined $self->{permissions};
        }
        CORE::connect($fh, pack_sockaddr_un($self->{path}))
            or _setup_error('connect', 0 + $!, path => $self->{path});
        1;
    };
    if (!$ok) {
        my $failure = $@;
        close $fh;
        unlink $self->{local_path}
            if defined($self->{local_path}) && -S $self->{local_path};
        die $failure;
    }
    my $activated = eval { $self->_finish_activation($fh, AF_UNIX); 1 };
    if (!$activated) {
        my $failure = $@;
        unlink $self->{local_path}
            if defined($self->{local_path}) && -S $self->{local_path};
        die $failure;
    }
    return;
}

sub _finish_activation ($self, $fh, $family) {
    my $previous_state = $self->{state};
    $self->{fh} = $fh;
    $self->{family_number} = $family;
    my $activated = eval {
        $self->{local} = Linux::Event::Address->new(getsockname($fh));
        $self->{peer} = Linux::Event::Address->new(getpeername($fh));
        $self->{state} = 'active';
        $self->_register;
        $self->_schedule_ready;
        $self->_flush_output;
        1;
    };
    return if $activated;

    my $failure = $@ || 'could not register Datagram socket';
    if (my $timer = delete $self->{ready_timer}) {
        $timer->cancel if $timer->is_active;
    }
    if (my $watcher = delete $self->{watcher}) {
        $watcher->cancel;
    }
    close delete $self->{fh} if $self->{fh};
    $self->{family_number} = undef;
    $self->{local} = undef;
    $self->{peer} = undef;
    $self->{state} = $previous_state;
    die $failure if blessed($failure)
        && $failure->isa('Linux::Event::Error');
    die Linux::Event::Error->new(
        type => 'setup', operation => 'watch', fatal => 1,
        message => "$failure",
    );
}

sub _register ($self) {
    return if !$self->{loop} || !$self->{fh};
    $self->{watcher} = $self->{loop}->watch(
        fh => $self->{fh}, _internal => 1, data => $self,
        read => \&_read_ready, write => \&_write_ready,
        error => \&_error_ready,
        edge_triggered => $self->{options}{edge_triggered},
        _callback_data_arg => 1,
    );
    $self->{watcher}->disable_write if !@{ $self->{queue} };
    $self->{watcher}->disable_read if $self->{read_paused};
    return;
}

sub _schedule_ready ($self) {
    return if $self->{ready_fired} || !$self->{loop};
    my $timer = Linux::Event::_Socket::Dgram::_ReadyTimer->new(
        after => 0, data => $self,
    );
    $self->{ready_timer} = $timer;
    $self->{loop}->add($timer);
    return;
}

sub _fire_ready ($self) {
    delete $self->{ready_timer};
    return if $self->{state} ne 'active' || $self->{ready_fired}++;
    my $callback = $self->{descriptor}{callbacks}{on_ready};
    $callback->($self) if $callback;
    return;
}

sub _report ($self, $error) {
    $self->{last_error} = $error;
    if (my $callback = $self->{descriptor}{callbacks}{on_error}) {
        $callback->($self, $error);
    } else {
        warn "$error\n";
    }
    return;
}

sub _fail ($self, $error) {
    return if $self->is_terminal;
    $self->{last_error} = $error;
    $self->_shutdown('failed', 0, 1);
    my $reported = eval { $self->_report($error); 1 };
    my $failure = $@;
    $self->{descriptor} = undef;
    $self->{loop} = undef;
    die $failure if !$reported;
    return;
}

sub _read_ready ($self) {
    return if $self->{state} ne 'active' || $self->{read_paused};
    my $batch = Linux::Event::_Socket::Dgram::_recv_batch(
        fileno($self->{fh}), $self->{options}{max_datagram_size},
        $self->{options}{max_datagrams_per_tick},
    );
    my $errno = $batch->[0];
    for (my $at = 1; $at < @$batch; $at += 4) {
        last if $self->{state} ne 'active' || $self->{read_paused};
        my ($payload, $sockaddr, $length, $truncated)
            = @$batch[$at .. $at + 3];
        my $peer = Linux::Event::Address->new($sockaddr);
        if ($truncated) {
            $self->_report(Linux::Event::Error->new(
                type => 'datagram_size', operation => 'receive',
                message => "received datagram exceeds "
                    . "$self->{options}{max_datagram_size} bytes",
                datagram_size => $length,
                limit => $self->{options}{max_datagram_size},
            ));
            next;
        }
        $self->{descriptor}{callbacks}{on_datagram}->($self, $payload, $peer);
    }
    if ($errno && $self->{state} eq 'active') {
        $self->_report(Linux::Event::Error->new(
            type => 'io', operation => 'receive', errno => $errno,
            message => _message($errno),
        ));
    }
    return;
}

sub send ($self, $payload, %option) {
    croak 'send(): Datagram is terminal' if $self->is_terminal;
    croak 'send(): payload must be a defined scalar'
        if !defined($payload) || ref($payload);
    $payload = "$payload";
    croak 'send(): payload must be a byte string'
        if !utf8::downgrade($payload, 1);
    croak "send(): payload exceeds $self->{options}{max_datagram_size} bytes"
        if length($payload) > $self->{options}{max_datagram_size};
    my $to = delete $option{to};
    croak 'send(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    if ($self->{connected}) {
        croak 'send(): to is not valid for a connected Datagram'
            if defined $to;
    } else {
        croak 'send(): to requires a Linux::Event::Address'
            if !blessed($to) || !$to->isa('Linux::Event::Address');
    }
    my $address = defined($to) ? $to->sockaddr : undef;
    croak 'send(): destination Address has no packed socket address'
        if defined($to) && (!defined($address) || ref($address));
    return $self->_queue_packet($payload, $address)
        if !$self->{fh} || @{ $self->{queue} };
    my ($sent, $errno) = Linux::Event::_Socket::Dgram::_send_packet(
        fileno($self->{fh}), $payload,
        defined($address) ? $address : undef,
    );
    return 1 if $sent == length($payload);
    if ($errno == Errno::EAGAIN() || $errno == Errno::EWOULDBLOCK()
        || $errno == Errno::ENOBUFS()) {
        return $self->_queue_packet($payload, $address);
    }
    $self->_report(Linux::Event::Error->new(
        type => 'io', operation => 'send', errno => $errno,
        message => $errno ? _message($errno)
            : "short datagram send ($sent of " . length($payload) . ' bytes)',
    ));
    return undef;
}

sub _queue_packet ($self, $payload, $address) {
    my $bytes = $self->{pending_bytes} + length($payload);
    my $datagrams = @{ $self->{queue} } + 1;
    my $byte_limit = $self->{options}{max_pending_bytes};
    my $packet_limit = $self->{options}{max_pending_datagrams};
    if (($byte_limit && $bytes > $byte_limit)
        || ($packet_limit && $datagrams > $packet_limit)) {
        my $limit = $byte_limit && $bytes > $byte_limit
            ? $byte_limit : $packet_limit;
        $self->_report(Linux::Event::Error->new(
            type => 'output_limit', operation => 'send',
            message => 'pending datagram output limit would be exceeded',
            pending_bytes => $bytes,
            pending_datagrams => $datagrams,
            limit => $limit,
        ));
        return undef;
    }
    push @{ $self->{queue} }, [$payload, $address];
    $self->{pending_bytes} = $bytes;
    if ($bytes > $self->{options}{high_watermark}) {
        $self->{above_high} = 1;
    }
    $self->{watcher}->enable_write if $self->{watcher};
    return $self->{above_high} ? 0 : 1;
}

sub _write_ready ($self) {
    return if $self->{state} ne 'active';
    $self->_flush_output;
    return;
}

sub _flush_output ($self) {
    return if !$self->{fh};
    while (my $packet = $self->{queue}[0]) {
        my ($payload, $address) = @$packet;
        my ($sent, $errno) = Linux::Event::_Socket::Dgram::_send_packet(
            fileno($self->{fh}), $payload,
            defined($address) ? $address : undef,
        );
        if ($sent == length($payload)) {
            shift @{ $self->{queue} };
            $self->{pending_bytes} -= length($payload);
            next;
        }
        last if $errno == Errno::EAGAIN() || $errno == Errno::EWOULDBLOCK()
            || $errno == Errno::ENOBUFS();
        shift @{ $self->{queue} };
        $self->{pending_bytes} -= length($payload);
        $self->_report(Linux::Event::Error->new(
            type => 'io', operation => 'send', errno => $errno,
            message => $errno ? _message($errno)
                : "short datagram send ($sent of "
                    . length($payload) . ' bytes)',
        ));
        last if $self->{state} ne 'active';
    }
    $self->{watcher}->disable_write
        if $self->{watcher} && !@{ $self->{queue} };
    if ($self->{above_high}
        && $self->{pending_bytes} <= $self->{options}{low_watermark}) {
        $self->{above_high} = 0;
        my $callback = $self->{descriptor}{callbacks}{on_drain};
        $callback->($self) if $callback;
    }
    return;
}

sub _error_ready ($self) {
    return if $self->{state} ne 'active';
    my $packed = getsockopt($self->{fh}, SOL_SOCKET, SO_ERROR);
    my $errno = defined($packed) && length($packed) >= 4
        ? unpack('i', $packed) : 0 + $!;
    $self->_report(Linux::Event::Error->new(
        type => 'io', operation => 'socket', errno => $errno || undef,
        message => $errno ? _message($errno) : 'datagram socket error',
    ));
    return;
}

sub _fork_preflight ($self, $mode, $loop) {
    croak "fork(): Datagram does not support '$mode'" if $mode ne 'drop';
    croak 'fork(): Datagram must be active before fork'
        if $self->{state} ne 'active' || !$self->{loop}
        || Scalar::Util::refaddr($self->{loop}) != Scalar::Util::refaddr($loop);
    return 1;
}

sub _fork_child_drop ($self, $loop) {
    $self->{watcher} = undef;
    delete $self->{resolver_request};
    delete $self->{resolver};
    if (my $timer = delete $self->{ready_timer}) {
        eval { $timer->cancel; 1 } if !$timer->is_terminal;
    }
    if (my $fh = delete $self->{fh}) {
        close $fh if $self->{owns_socket};
    }
    $self->{unlink_on_close} = 0;
    $self->{queue} = [];
    $self->{pending_bytes} = 0;
    $self->{above_high} = 0;
    $self->{loop} = undef;
    $self->{descriptor} = undef;
    $self->{state} = 'not_inherited';
    return;
}

sub _shutdown ($self, $state, $fire_close = 1, $retain_loop = 0) {
    return if $self->is_terminal;
    $self->{state} = $state;
    my $request = delete $self->{resolver_request};
    my $resolver = delete $self->{resolver};
    $resolver->cancel($request) if $resolver && defined $request;
    if (my $timer = delete $self->{ready_timer}) {
        $timer->cancel if $timer->is_active;
    }
    if (my $watcher = delete $self->{watcher}) {
        $watcher->cancel;
    }
    if (my $fh = delete $self->{fh}) {
        close $fh if $self->{owns_socket};
    }
    my $remove_path = $self->{connected}
        ? $self->{local_path} : $self->{path};
    unlink $remove_path if $self->{unlink_on_close}
        && defined($remove_path) && -S $remove_path;
    $self->{queue} = [];
    $self->{pending_bytes} = 0;
    my ($called, $failure) = (1, undef);
    if ($fire_close && (my $callback = $self->{descriptor}{callbacks}{on_close})) {
        $called = eval { $callback->($self); 1 };
        $failure = $@;
    }
    $self->{descriptor} = undef if !$retain_loop;
    $self->{loop} = undef if !$retain_loop;
    die $failure if !$called;
    return;
}

sub close ($self) {
    $self->_shutdown('closed');
    return $self;
}

sub detach ($self) {
    croak 'detach(): Datagram has no active socket' if !$self->{fh};
    my $fh = $self->{fh};
    $self->{owns_socket} = 0;
    $self->{unlink_on_close} = 0;
    $self->_shutdown('detached', 0);
    return $fh;
}

sub pause_read ($self) {
    return $self if $self->{read_paused};
    $self->{read_paused} = 1;
    $self->{watcher}->disable_read if $self->{watcher};
    return $self;
}

sub resume_read ($self) {
    return $self if !$self->{read_paused};
    $self->{read_paused} = 0;
    $self->{watcher}->enable_read if $self->{watcher};
    return $self;
}

sub _buffer_option ($self, $name, @argument) {
    croak "$name(): Datagram has no active socket" if !$self->{fh};
    croak "$name(): expected zero or one argument" if @argument > 1;
    Linux::Event::_SocketConfig::set_option(
        $self->{fh}, $self->{family_number}, $name, $argument[0],
    ) if @argument;
    return Linux::Event::_SocketConfig::get_option(
        $self->{fh}, $self->{family_number}, $name,
    );
}

sub send_buffer ($self, @argument) {
    return $self->_buffer_option('send_buffer', @argument);
}
sub receive_buffer ($self, @argument) {
    return $self->_buffer_option('receive_buffer', @argument);
}

sub broadcast ($self, @argument) {
    croak 'broadcast(): Datagram has no active socket' if !$self->{fh};
    croak 'broadcast(): expected zero or one argument' if @argument > 1;
    _socket_option_error(
        'broadcast', 0, 'broadcast is valid only for IPv4 sockets',
        @argument ? 'setsockopt' : 'getsockopt',
    ) if $self->{family_number} != AF_INET;
    if (@argument) {
        my $value = _boolean('broadcast():', 'value', $argument[0]);
        setsockopt($self->{fh}, SOL_SOCKET, SO_BROADCAST, pack('i', $value))
            or die Linux::Event::Error->new(
                type => 'socket_configuration', operation => 'setsockopt',
                option => 'broadcast', errno => 0 + $!,
                message => _message(0 + $!),
            );
    }
    my $packed = getsockopt($self->{fh}, SOL_SOCKET, SO_BROADCAST);
    die Linux::Event::Error->new(
        type => 'socket_configuration', operation => 'getsockopt',
        option => 'broadcast', errno => 0 + $!, message => _message(0 + $!),
    ) if !defined $packed;
    return unpack('i', $packed) ? 1 : 0;
}

sub fh ($self) { $self->{fh} }
sub fd ($self) { $self->{fh} ? fileno($self->{fh}) : undef }
sub loop ($self) { $self->{loop} }
sub local ($self) { $self->{local} }
sub peer ($self) { $self->{peer} }
sub is_connected ($self) { !!$self->{connected} }
sub state ($self) { $self->{state} }
sub last_error ($self) { $self->{last_error} }
sub pending_bytes ($self) { $self->{pending_bytes} }
sub pending_datagrams ($self) { scalar @{ $self->{queue} } }
sub is_read_paused ($self) { !!$self->{read_paused} }
sub is_active ($self) { $self->{state} eq 'active' }
sub is_terminal ($self) {
    return $self->{state} eq 'closed' || $self->{state} eq 'failed'
        || $self->{state} eq 'detached' || $self->{state} eq 'not_inherited'
        || $self->{state} eq 'moved';
}

sub data ($self, @argument) {
    $self->{data} = $argument[0] if @argument;
    return $self->{data};
}

sub CLONE_SKIP ($class) { 1 }

sub DESTROY ($self) {
    eval { $self->_shutdown('closed', 0) } if !$self->is_terminal;
    return;
}

package Linux::Event::_Socket::Dgram::_ReadyTimer;
use v5.36;
use strict;
use warnings;
use parent -norequire, 'Linux::Event::Kernel::Timer';

sub on_timer ($timer) {
    my $datagram = $timer->data;
    $datagram->_fire_ready if $datagram;
    return;
}

1;

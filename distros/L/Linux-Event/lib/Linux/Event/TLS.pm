package Linux::Event::TLS;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use POSIX qw(isfinite);
use utf8 ();

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub CLONE_SKIP ($class) { 1 }

sub import ($class, @arg) {
    my $target = caller;
    require Linux::Event::IO::Sock::Stream;
    require Linux::Event::_Socket::Descriptor;

    my $base = $target->isa('Linux::Event::IO::Sock::Stream')
        ? 'Linux::Event::IO::Sock::Stream' : undef;

    return if $target eq 'main' && !defined($base) && !@arg;
    croak "$target must be a Linux::Event IO stream-socket subclass before declaring TLS"
        if !defined $base;
    croak 'TLS declaration options must be key/value pairs' if @arg % 2;

    Linux::Event::_Socket::Descriptor::declare_tls(
        $base,
        $target,
        $class->_build_declaration($target, @arg),
    );
    return;
}

sub _alpn_wire ($protocols) {
    return '' if !defined $protocols;
    croak 'alpn must be an array reference' if ref($protocols) ne 'ARRAY';
    my $wire = '';
    for my $protocol (@$protocols) {
        my $bytes = defined($protocol) && !ref($protocol)
            ? "$protocol" : undef;
        my $is_bytes = defined($bytes) && utf8::downgrade($bytes, 1);
        croak 'each ALPN protocol must be a byte string of 1..255 bytes'
            if !$is_bytes || length($bytes) < 1 || length($bytes) > 255;
        $wire .= pack('C', length($bytes)) . $bytes;
        croak 'the encoded ALPN protocol list must not exceed 65535 bytes'
            if length($wire) > 65_535;
    }
    return $wire;
}

sub _timeout ($method, $name, $value, $default) {
    $value = $default if !defined $value;
    my $where = $method =~ /\s/ ? $method : "$method()";
    croak "$where: $name must be a non-negative number of seconds"
        if ref($value)
        || $value !~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/
        || $value < 0;
    $value = 0 + $value;
    croak "$where: $name must be a finite number of seconds"
        if !isfinite($value);
    croak "$where: $name exceeds the supported timer range"
        if $value > 2_147_483_647;
    return $value;
}

sub _optional_string ($target, $name, $value) {
    return undef if !defined $value;
    croak "$target TLS $name must be a non-empty string without NUL bytes"
        if ref($value) || $value eq '' || $value =~ /\0/;
    return "$value";
}

sub _server_name ($target, $value) {
    my $server_name = _optional_string($target, 'server_name', $value);
    return undef if !defined $server_name;
    $server_name = substr($server_name, 1, length($server_name) - 2)
        if length($server_name) >= 2
        && substr($server_name, 0, 1) eq '['
        && substr($server_name, -1, 1) eq ']';
    croak "$target TLS server_name must not be empty after removing brackets"
        if $server_name eq '';
    return $server_name;
}

sub _build_declaration ($class, $target, @arg) {
    my %opt = @arg;
    my @known = qw(
        cert_file key_file server_name verify ca_file ca_path alpn
        handshake_timeout shutdown_timeout
    );
    my %known = map { $_ => 1 } @known;
    my @unknown = grep { !$known{$_} } keys %opt;
    croak "$target TLS declaration has unknown options: "
        . join(', ', sort @unknown) if @unknown;

    my $cert_file = _optional_string(
        $target, 'cert_file', delete $opt{cert_file},
    );
    my $key_file = _optional_string(
        $target, 'key_file', delete $opt{key_file},
    );
    croak "$target TLS declaration requires cert_file and key_file together"
        if defined($cert_file) != defined($key_file);
    my $server_name = _server_name($target, delete $opt{server_name});
    my $ca_file = _optional_string(
        $target, 'ca_file', delete $opt{ca_file},
    );
    my $ca_path = _optional_string(
        $target, 'ca_path', delete $opt{ca_path},
    );
    my $verify = exists($opt{verify}) ? delete($opt{verify}) : 1;
    croak "$target TLS verify must be 0 or 1"
        if ref($verify) || $verify !~ /\A[01]\z/;

    return {
        target            => $target,
        cert_file         => $cert_file,
        key_file          => $key_file,
        server_name       => $server_name,
        verify            => $verify ? 1 : 0,
        ca_file           => $ca_file,
        ca_path           => $ca_path,
        alpn_wire         => _alpn_wire(delete $opt{alpn}),
        handshake_timeout => _timeout(
            "$target TLS declaration", 'handshake_timeout',
            delete($opt{handshake_timeout}), 10,
        ),
        shutdown_timeout => _timeout(
            "$target TLS declaration", 'shutdown_timeout',
            delete($opt{shutdown_timeout}), 5,
        ),
    };
}

sub _validate_server_declaration ($class, $definition) {
    my $target = $definition->{target};
    croak "$target is used for accepted TLS stream sockets but does not declare "
        . 'cert_file and key_file'
        if !defined($definition->{cert_file});
    return;
}

sub _client_from_declaration ($class, $definition, $connect_host = undef) {
    my $target = $definition->{target};
    my $server_name = $definition->{server_name} // $connect_host;
    croak "$target TLS client requires server_name when connect() has no host"
        if !defined($server_name) || ref($server_name) || $server_name eq '';
    $server_name = _server_name($target, $server_name);
    return $class->_new_client(
        $server_name,
        $definition->{verify},
        $definition->{ca_file},
        $definition->{ca_path},
        $definition->{alpn_wire},
        $definition->{handshake_timeout},
        $definition->{shutdown_timeout},
    );
}

sub _server_from_declaration ($class, $definition) {
    $class->_validate_server_declaration($definition);
    return $class->_new_server(
        $definition->{cert_file},
        $definition->{key_file},
        $definition->{alpn_wire},
        $definition->{handshake_timeout},
        $definition->{shutdown_timeout},
    );
}

sub _class_tls_defaults ($stream_class) {
    my $method = $stream_class->can('tls_defaults') or return {};
    my @value = $method->($stream_class);
    my %option;
    if (@value == 1 && ref($value[0]) eq 'HASH') {
        %option = %{ $value[0] };
    } else {
        croak "$stream_class tls_defaults() returned an odd option list"
            if @value % 2;
        %option = @value;
    }
    return \%option;
}

sub _prepare_listener_server ($class, $stream_class, $recipe) {
    croak 'Listener TLS recipe must be a hash reference'
        if defined($recipe) && ref($recipe) ne 'HASH';
    my %option = (%{ _class_tls_defaults($stream_class) }, %{ $recipe // {} });

    my %known = map { $_ => 1 } qw(
        cert_file key_file alpn handshake_timeout shutdown_timeout
    );
    my @unknown = grep { !$known{$_} } keys %option;
    croak 'Listener TLS recipe has unknown options: '
        . join(', ', sort @unknown) if @unknown;

    my $cert_file = _optional_string(
        "$stream_class Listener", 'cert_file', delete $option{cert_file},
    );
    my $key_file = _optional_string(
        "$stream_class Listener", 'key_file', delete $option{key_file},
    );
    croak 'Listener TLS recipe requires cert_file and key_file together'
        if defined($cert_file) != defined($key_file);
    croak 'Listener TLS recipe requires cert_file and key_file'
        if !defined $cert_file;
    my $alpn = _alpn_wire(delete $option{alpn});
    my $handshake_timeout = _timeout(
        'Listener TLS', 'handshake_timeout',
        delete($option{handshake_timeout}), 10,
    );
    my $shutdown_timeout = _timeout(
        'Listener TLS', 'shutdown_timeout',
        delete($option{shutdown_timeout}), 5,
    );

    return $class->_new_server_template(
        $cert_file, $key_file, $alpn,
        $handshake_timeout, $shutdown_timeout,
    );
}

sub _listener_server_connection ($class, $template) {
    return undef if !defined $template;
    return $template->_clone_server;
}

sub client ($class, %opt) {
    croak 'client(): must be called as a class method' if ref $class;
    my $server_name = delete $opt{server_name}
        // croak 'client(): missing server_name';
    my $verify = exists $opt{verify} ? delete($opt{verify}) : 1;
    croak 'client(): verify must be 0 or 1'
        if !defined($verify) || ref($verify) || $verify !~ /\A[01]\z/;
    $server_name = _server_name('client()', $server_name);
    my $ca_file = _optional_string(
        'client()', 'ca_file', delete $opt{ca_file},
    );
    my $ca_path = _optional_string(
        'client()', 'ca_path', delete $opt{ca_path},
    );
    my $alpn = _alpn_wire(delete $opt{alpn});
    my $handshake_timeout = _timeout(
        'client', 'handshake_timeout', delete($opt{handshake_timeout}), 10,
    );
    my $shutdown_timeout = _timeout(
        'client', 'shutdown_timeout', delete($opt{shutdown_timeout}), 5,
    );
    croak 'client(): unknown options: ' . join(', ', sort keys %opt) if %opt;
    return $class->_new_client(
        $server_name, $verify ? 1 : 0, $ca_file, $ca_path, $alpn,
        $handshake_timeout, $shutdown_timeout,
    );
}

sub server ($class, %opt) {
    croak 'server(): must be called as a class method' if ref $class;
    my $cert_file = delete $opt{cert_file}
        // croak 'server(): missing cert_file';
    my $key_file = delete $opt{key_file}
        // croak 'server(): missing key_file';
    $cert_file = _optional_string('server()', 'cert_file', $cert_file);
    $key_file = _optional_string('server()', 'key_file', $key_file);
    my $alpn = _alpn_wire(delete $opt{alpn});
    my $handshake_timeout = _timeout(
        'server', 'handshake_timeout', delete($opt{handshake_timeout}), 10,
    );
    my $shutdown_timeout = _timeout(
        'server', 'shutdown_timeout', delete($opt{shutdown_timeout}), 5,
    );
    croak 'server(): unknown options: ' . join(', ', sort keys %opt) if %opt;
    return $class->_new_server(
        $cert_file, $key_file, $alpn,
        $handshake_timeout, $shutdown_timeout,
    );
}

sub _stream_transport_bind ($self, $fd) {
    return $self->_bind_fd($fd);
}

sub _install_deadline ($self, $stream, $operation) {
    my $fd = $self->_arm_deadline($operation);
    return if !defined $fd;
    return if $stream->_has_transport_deadline_watcher;
    my $watcher = $stream->loop->watch(
        fd   => $fd,
        _internal => 1,
        data => {
            provider  => $self,
            stream    => $stream,
        },
        read => \&_deadline_ready,
    );
    $stream->_set_transport_deadline_watcher($watcher);
    return;
}

sub _deadline_ready ($watcher) {
    my $state = $watcher->data;
    my $stream = $state->{stream};
    my $operation = $state->{provider}->_deadline_operation;
    my $message = $state->{provider}->_consume_deadline($operation);
    $stream->_transport_deadline_expired($operation, $message);
    return;
}

sub _stream_transport_start ($self, $stream) {
    $self->_install_deadline($stream, 'handshake');
}

sub _stream_transport_ready ($self, $stream) {
    $stream->_clear_transport_deadline;
}

sub _stream_transport_begin_shutdown ($self, $stream) {
    $self->_install_deadline($stream, 'shutdown');
}

sub _stream_transport_cancel_deadline ($self) {
    $self->_cancel_deadline;
}

sub _stream_transport_close_deadline ($self) {
    $self->_close_deadline;
}

1;

__END__

=head1 NAME

Linux::Event::TLS - OpenSSL transport for Linux::Event stream sockets

=head1 DESCRIPTION

TLS is transport policy for L<Linux::Event::IO::Sock::Stream>. It does not
change framing, buffering, backpressure, or callback semantics.

For servers, normal application code configures TLS in the Listener's generated
Stream recipe and does not need to C<use Linux::Event::TLS> directly:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 443,
      stream => {
          tls => {
              cert_file => '/etc/app/server.crt',
              key_file  => '/etc/app/server.key',
              alpn      => ['h2', 'http/1.1'],
          },
          on_data => sub ($stream, $bytes) { ... },
      },
  );

The Listener validates the TLS recipe and builds one reusable OpenSSL
C<SSL_CTX>. Every accepted connection creates only fresh per-connection
C<SSL> state and binds it to the accepted file descriptor. The shared context
uses OpenSSL reference counting, so established TLS Streams remain valid even
if the Listener closes.

A Stream subclass may provide ordinary C<tls_defaults()> policy without
becoming a special TLS class:

  package SecureConnection;
  use parent 'Linux::Event::IO::Sock::Stream';

  sub tls_defaults ($class) {
      return (
          alpn              => ['echo/1'],
          handshake_timeout => 10,
          shutdown_timeout  => 5,
      );
  }

  sub on_data ($self, $bytes) { ... }

Listener C<stream =E<gt> { tls =E<gt> {...} }> values override those defaults.
C<tls_defaults()> does not activate TLS by itself: an accepted connection is TLS
only when its Listener recipe contains a C<tls> key. Certificate and key paths
are normally deployment values in that Listener recipe. A Listener without a
C<tls> recipe generates plain Streams and allocates no TLS state even when the
Stream class defines C<tls_defaults()>.

=head1 SERVER TLS OPTIONS

Listener server TLS accepts C<cert_file>, C<key_file>, C<alpn>,
C<handshake_timeout>, and C<shutdown_timeout>. The certificate and key are
required together. Handshake and shutdown timeouts default to 10 and 5 seconds;
zero disables the corresponding timeout.

C<on_ready> runs only after the handshake succeeds. Application data callbacks
receive plaintext. C<selected_alpn>, C<tls_protocol>, C<tls_cipher>, and
C<tls_stats> on the Stream report the established transport.

=head1 CLIENT AND DIRECT TRANSPORT API

C<< Linux::Event::TLS->client(...) >> and C<< Linux::Event::TLS->server(...) >>
remain available when an application wants to construct a transport object
directly. Existing subclass declarations with C<use Linux::Event::TLS ...> also
remain supported for explicit class-level acquisition policy, including
outbound client verification.

Client verification is enabled by default. C<server_name> is required by the
direct client constructor; C<ca_file> and C<ca_path> optionally override trust
roots. C<alpn>, C<handshake_timeout>, and C<shutdown_timeout> work in both
roles.

=head1 TRANSPORT MODEL

OpenSSL owns handshake state, cryptography, verification, ALPN, retry
direction, and TLS close notification. Linux::Event's ordered-byte engine owns
readiness, plaintext buffering, framing, backpressure, protocol transitions,
and established Stream deadlines.

TLS uses the native transport ABI directly. It does not install a per-I/O Perl
callback layer.

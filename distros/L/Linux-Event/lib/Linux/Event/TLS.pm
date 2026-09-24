package Linux::Event::TLS;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

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

Linux::Event::TLS - OpenSSL TLS transport for Linux::Event Stream sockets

=head1 SYNOPSIS

For a TLS server, configure TLS in the Listener's Stream recipe:

  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Listener;

  my $loop = Linux::Event::Loop->new;

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 443,

      stream => {
          tls => {
              cert_file => '/etc/myapp/server.crt',
              key_file  => '/etc/myapp/server.key',
              alpn      => ['http/1.1'],
          },

          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

For an outbound TLS client, declare TLS policy on a Stream subclass:

  package SecureClient;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::TLS
      verify => 1,
      alpn   => ['http/1.1'];

  sub on_data ($self, $bytes) {
      ...
  }

  package main;

  my $stream = SecureClient->connect(
      loop => $loop,
      host => 'example.com',
      port => 443,

      on_ready => sub ($self) {
          $self->write("hello");
      },
  );

=head1 DESCRIPTION

C<Linux::Event::TLS> adds OpenSSL TLS transport to
L<Linux::Event::IO::Sock::Stream>.

TLS changes how bytes travel across the socket.

It does not change the Stream's application model.

A TLS Stream still uses the normal:

  on_ready
  on_data
  on_message
  write
  send
  backpressure
  deadlines
  close
  end

interfaces.

Application callbacks see plaintext.

If framing is enabled, the framer also sees plaintext.

Conceptually:

  socket
    -> TLS encryption/decryption
    -> ordered plaintext bytes
    -> optional framing
    -> application callback

TLS is therefore transport policy, not a different public Stream class.

=head1 THE NORMAL SERVER API

Most TLS servers should configure TLS through
L<Linux::Event::IO::Sock::Listener>.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9443,

      stream => {
          class => 'MyConnection',

          tls => {
              cert_file => '/etc/myapp/server.crt',
              key_file  => '/etc/myapp/server.key',
          },

          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

Ordinary server applications do not need to load C<Linux::Event::TLS>
directly.

The Listener loads the TLS provider when its Stream recipe contains:

  tls => { ... }

Without that C<tls> key, accepted Streams are plain.

=head1 TLS DOES NOT CHANGE THE STREAM CLASS

The same Stream subclass may be used by both plain and TLS Listeners.

For example:

  package MyConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub on_data ($self, $bytes) {
      ...
  }

One Listener can use it plainly:

  stream => {
      class => 'MyConnection',
  }

while another can use TLS:

  stream => {
      class => 'MyConnection',

      tls => {
          cert_file => $cert_file,
          key_file  => $key_file,
      },
  }

The class describes application Stream behavior.

The Listener recipe selects whether accepted connections use TLS.

=head1 SERVER CERTIFICATE AND KEY

A TLS server requires both:

  cert_file
  key_file

For example:

  tls => {
      cert_file => '/etc/myapp/server.crt',
      key_file  => '/etc/myapp/server.key',
  }

They must be supplied together.

The Listener validates server TLS configuration before it begins accepting
connections.

Certificate and key loading therefore happens during Listener setup rather than
being rediscovered independently for every accepted connection.

=head1 PREPARED SERVER CONTEXT

A TLS Listener prepares one reusable OpenSSL server context.

Each accepted connection then creates its own per-connection TLS state while
sharing the prepared server context.

This means expensive server certificate and context setup does not need to be
repeated from scratch for every accepted socket.

Established connections remain valid if the Listener later closes because the
shared OpenSSL context uses normal OpenSSL reference counting.

=head1 SERVER TLS DEFAULTS

A Stream subclass may define reusable server TLS defaults:

  package SecureConnection;

  use parent 'Linux::Event::IO::Sock::Stream';

  sub tls_defaults ($class) {
      return (
          alpn              => ['my-protocol/1'],
          handshake_timeout => 10,
          shutdown_timeout  => 5,
      );
  }

These defaults are consulted when a Listener explicitly selects TLS:

  stream => {
      class => 'SecureConnection',

      tls => {
          cert_file => $cert_file,
          key_file  => $key_file,
      },
  }

Values in the Listener's C<tls> hash override C<tls_defaults()>.

C<tls_defaults()> does B<not> activate TLS by itself.

A Listener without:

  tls => { ... }

still produces plain Streams even when the Stream class defines
C<tls_defaults()>.

Certificate and key paths are therefore normally deployment configuration in
the Listener recipe rather than hard-coded into a protocol class.

=head1 SERVER TLS OPTIONS

The normal Listener C<tls> recipe accepts:

  cert_file
  key_file
  alpn
  handshake_timeout
  shutdown_timeout

C<cert_file> and C<key_file> are required.

=head1 OUTBOUND TLS CLIENTS

For outbound connections, TLS policy can be declared on the Stream subclass:

  package HTTPSConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::TLS
      verify => 1,
      alpn   => ['http/1.1'];

Then connect normally:

  my $stream = HTTPSConnection->connect(
      loop => $loop,
      host => 'example.com',
      port => 443,

      on_ready => sub ($self) {
          ...
      },
  );

The same Stream object exists through:

  DNS resolution
  socket connection
  TLS handshake
  certificate verification
  normal application I/O
  final close

Linux::Event does not replace it with a second TLS-specific application object.

=head1 CLIENT SERVER NAME

TLS clients need a server identity for SNI and hostname verification.

When a TLS-declared Stream uses:

  ->connect(
      host => 'example.com',
      port => 443,
  )

the connection host is used as the TLS server name by default.

Usually no additional option is necessary.

Use an explicit class declaration only when the verified TLS identity must
differ from the connection host:

  use Linux::Event::TLS
      server_name => 'service.example.com';

Bracketed IPv6-style server names are normalized before use.

An empty server name is rejected.

=head1 CLIENT VERIFICATION

Client certificate verification is enabled by default:

  verify => 1

This includes certificate-chain and hostname verification.

It may be disabled explicitly:

  verify => 0

Disabling verification removes an important security property and should only
be done when the application deliberately provides some other trust model.

A verification failure is reported as a structured
L<Linux::Event::Error> with TLS context rather than allowing the connection to
become application-ready.

=head1 CUSTOM TRUST ROOTS

A TLS client may override the trust roots with:

  ca_file => '/path/to/ca.pem'

or:

  ca_path => '/path/to/ca-directory'

For example:

  package InternalClient;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::TLS
      ca_file => '/etc/myapp/private-ca.pem';

These options affect client verification.

=head1 WHEN ON_READY RUNS

For a plain outbound Stream, C<on_ready> means the socket connection has been
established.

For a TLS Stream, C<on_ready> runs only after:

  socket connection
  TLS handshake
  required certificate verification
  hostname verification

have succeeded.

For example:

  on_ready => sub ($self) {
      $self->write("application data");
  }

can begin the application protocol without separately checking whether the TLS
handshake has finished.

The same rule applies to accepted TLS Streams.

A Listener's C<on_accept> runs before the accepted TLS Stream has necessarily
completed its handshake.

The Stream's C<on_ready> is the application-level notification that the TLS
transport is ready.

=head1 PLAINTEXT CALLBACKS

Application input callbacks receive decrypted bytes:

  on_data => sub ($self, $bytes) {
      ...
  }

A framed TLS Stream also frames plaintext:

  socket ciphertext
      ->
  OpenSSL
      ->
  plaintext ordered bytes
      ->
  Linux::Event::Framer
      ->
  on_message

Applications do not need separate TLS-aware framing logic.

=head1 WRITING BEFORE THE HANDSHAKE

The normal Stream output queue remains available while a TLS connection is
being established.

For example:

  my $stream = SecureClient->connect(
      host => 'example.com',
      port => 443,
      ...
  );

  $stream->write("hello");

can queue plaintext before C<on_ready>.

The queued bytes are not sent as plaintext on the socket.

They remain ordered Stream output and are processed by the TLS transport once
the connection becomes usable.

Backpressure and hard pending-output limits continue to apply.

=head1 ALPN

TLS server and client policy may include:

  alpn => ['h2', 'http/1.1']

Each ALPN protocol name must be a byte string between 1 and 255 bytes.

The complete encoded ALPN list must fit within 65,535 bytes.

After negotiation, a Stream can inspect the selected protocol:

  my $protocol = $stream->selected_alpn;

If no protocol was selected, the result may be undefined.

=head1 TLS INFORMATION

An established TLS Stream provides transport information without requiring
application code to reach into the OpenSSL provider.

=head2 selected_alpn

  my $alpn = $stream->selected_alpn;

Return the negotiated ALPN protocol when one was selected.

=head2 tls_protocol

  my $version = $stream->tls_protocol;

Return the negotiated TLS protocol version, such as:

  TLSv1.3

=head2 tls_cipher

  my $cipher = $stream->tls_cipher;

Return the negotiated TLS cipher description when available.

=head2 tls_stats

  my $stats = $stream->tls_stats;

Return native TLS statistics for the Stream.

This is primarily useful for diagnostics, testing, and performance
investigation.

=head1 HANDSHAKE TIMEOUT

=head2 handshake_timeout

The TLS handshake timeout defaults to:

  10

seconds.

For example:

  tls => {
      cert_file         => $cert_file,
      key_file          => $key_file,
      handshake_timeout => 5,
  }

or for a client declaration:

  use Linux::Event::TLS
      handshake_timeout => 5;

The value is a non-negative number of seconds.

Fractional values are allowed.

A value of:

  0

disables the handshake timeout.

This timeout belongs specifically to TLS handshake progress.

It is separate from the Stream connection-acquisition timeout and from
established Stream idle/read/write deadlines.

=head1 SHUTDOWN TIMEOUT

=head2 shutdown_timeout

Graceful TLS shutdown has its own timeout.

The default is:

  5

seconds.

A value of zero disables it.

This timeout is used when Linux::Event performs the TLS close-notification
exchange during graceful Stream shutdown.

=head1 TIMEOUT LAYERS

The lifecycle deliberately has separate timeout ownership:

  resolve/connect
      ->
  TLS handshake
      ->
  established Stream I/O
      ->
  TLS shutdown

The Stream connection C<timeout> covers connection acquisition.

C<handshake_timeout> covers TLS negotiation.

Established C<idle_timeout>, C<read_timeout>, C<write_timeout>, and explicit
Stream deadlines apply after the transport becomes ready.

C<shutdown_timeout> covers graceful TLS shutdown.

Keeping these separate makes timeout errors identify the actual lifecycle stage
that failed.

=head1 PAUSING APPLICATION INPUT

C<pause_read> pauses application plaintext delivery.

It does not prevent TLS from processing control traffic required for:

  handshake progress
  pending writes
  graceful shutdown

For example:

  $stream->pause_read;

can withhold application C<on_data> callbacks while OpenSSL still makes the
protocol progress needed to establish or maintain the transport.

C<resume_read> later resumes plaintext application delivery.

=head1 GRACEFUL SHUTDOWN

C<end> retains the ordinary Stream meaning:

  $stream->end;

Accepted plaintext output is drained in order.

Linux::Event then performs the TLS transport's graceful writable shutdown,
including TLS C<close_notify> handling.

A peer C<close_notify> becomes normal readable EOF.

C<close> remains immediate:

  $stream->close;

It does not promise that queued output or a graceful TLS shutdown exchange will
finish first.

=head1 UNCLEAN TLS EOF

TLS distinguishes a proper protocol close from the underlying socket simply
disappearing.

A valid peer C<close_notify> enters the normal Stream EOF lifecycle.

If the underlying socket reaches EOF without the required TLS close semantics,
Linux::Event reports a TLS read error instead of silently treating that as a
clean encrypted shutdown.

=head1 TLS ERRORS

TLS failures are reported using L<Linux::Event::Error>.

For example, certificate verification failure produces an error with:

  type       tls
  operation  handshake

Other TLS failures may identify operations such as:

  read
  write
  shutdown

The error message retains the useful OpenSSL diagnostic where available.

=head1 CLASS-LEVEL TLS DECLARATIONS

The declaration form:

  package SecureClient;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::TLS
      verify => 1;

must appear after the Stream parent has been established.

This is invalid:

  package SecureClient;

  use Linux::Event::TLS;
  use parent 'Linux::Event::IO::Sock::Stream';

because Linux::Event must first know that the target class is a Stream subclass.

A concrete Stream class may declare TLS only once.

=head1 CLASS DECLARATION OPTIONS

A class-level C<use Linux::Event::TLS ...> declaration recognizes:

  cert_file
  key_file
  server_name
  verify
  ca_file
  ca_path
  alpn
  handshake_timeout
  shutdown_timeout

Unknown options are rejected during class setup.

C<cert_file> and C<key_file> must appear together when supplied.

For normal accepted server connections, prefer the Listener C<tls> recipe
rather than embedding deployment credentials in the Stream class.

=head1 DIRECT CLIENT TRANSPORT

Advanced code may create a TLS client transport object directly:

  my $tls = Linux::Event::TLS->client(
      server_name => 'localhost',
      ca_file     => $ca_file,
      alpn        => ['my-protocol/1'],
  );

and supply it to an already-connected Stream:

  my $stream = MyStream->new(
      loop      => $loop,
      fh        => $socket,
      transport => $tls,
  );

The direct client API requires C<server_name> explicitly.

It accepts:

  server_name
  verify
  ca_file
  ca_path
  alpn
  handshake_timeout
  shutdown_timeout

Verification defaults to enabled.

Most ordinary outbound applications should use a TLS-declared Stream subclass
and C<connect()> instead.

=head1 DIRECT SERVER TRANSPORT

Advanced code may construct a server transport directly:

  my $tls = Linux::Event::TLS->server(
      cert_file => $cert_file,
      key_file  => $key_file,
      alpn      => ['my-protocol/1'],
  );

and bind it to an already-connected Stream:

  my $stream = MyStream->new(
      loop      => $loop,
      fh        => $accepted_socket,
      transport => $tls,
  );

The direct server API accepts:

  cert_file
  key_file
  alpn
  handshake_timeout
  shutdown_timeout

For normal listening servers, the Listener recipe is simpler and more
efficient because it prepares reusable server context before connections are
accepted.

=head1 ADOPTED TLS SOCKETS

A Stream class with explicit TLS acquisition policy cannot guess whether an
already-connected adopted handle should perform the client or server handshake.

Advanced adopted-handle use must therefore supply the appropriate transport or
explicit TLS role required by the Stream API.

Normal C<connect()> and Listener acceptance do not have this ambiguity because
the role is known from how the socket was acquired.

=head1 DETACHING

A live encrypted Stream cannot be detached as though its file descriptor were a
plain socket:

  $stream->detach;

is rejected while a non-plain TLS transport is active.

The OpenSSL state and the socket descriptor together represent the transport;
returning only the bare descriptor would lose required TLS state.

=head1 PROTOCOL TRANSITIONS

C<transition_to()> changes application protocol policy while keeping the current
byte transport.

For a TLS Stream, that means TLS remains TLS across the transition.

For example:

  TLS socket
      ->
  HTTP parser
      ->
  WebSocket parser

can change application protocol handling without recreating the socket or
discarding encryption.

Transport replacement itself is not currently a public protocol-transition
operation.

=head1 PERFORMANCE MODEL

TLS uses Linux::Event's native transport ABI.

OpenSSL handles:

  handshake
  encryption and decryption
  certificate verification
  hostname verification
  ALPN
  TLS retry direction
  close notification

Linux::Event continues to handle:

  epoll readiness
  plaintext buffering
  framing
  output ordering
  backpressure
  protocol transitions
  established Stream deadlines

TLS does not install a Perl callback between every encrypted read or write.

Plain Streams do not allocate TLS state and retain their direct native socket
path.

=head1 OPENSSL REQUIREMENT

Linux::Event's TLS extension is built against OpenSSL 1.1.1 or newer.

The OpenSSL dependency is isolated to the TLS extension.

The reactor and plain ordered-byte engine do not require OpenSSL for ordinary
plain I/O.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::Framer>,
L<Linux::Event::Error>,
F<docs/TRANSPORT-BOUNDARY.md>,
F<docs/SOCKET-CONNECTIONS.md>.

=cut

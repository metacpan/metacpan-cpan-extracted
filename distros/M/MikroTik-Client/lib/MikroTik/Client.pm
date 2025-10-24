package MikroTik::Client;
use MikroTik::Client::Mo;

use MikroTik::Client::Response;
use MikroTik::Client::Sentence qw(encode_sentence);
use Carp                       ();
use Mojo::Collection;
use Mojo::IOLoop;
use Mojo::Util qw(md5_sum term_escape);
use Scalar::Util 'weaken';

use constant CONN_TIMEOUT => $ENV{MIKROTIK_CLIENT_CONNTIMEOUT};
use constant DEBUG        => $ENV{MIKROTIK_CLIENT_DEBUG} || 0;

# Mojolicious 8.72 deprecated bunch of specific TLS negotiation options
# in favour of single tls_options
use constant MOJO_TLS_OPTS => !!
    eval { require Mojolicious; Mojolicious->VERSION('8.72'); 1 };

our $VERSION = 'v0.601';

has ca        => sub { $ENV{MIKROTIK_CLIENT_CA} };
has cert      => sub { $ENV{MIKROTIK_CLIENT_CERT} };
has error     => '';
has host      => '192.168.88.1';
has insecure  => sub { $ENV{MIKROTIK_CLIENT_INSECURE} // 1 };
has key       => sub { $ENV{MIKROTIK_CLIENT_KEY} };
has ioloop    => sub { Mojo::IOLoop->new() };
has new_login => 1;
has password  => '';
has port      => sub { $_[0]->tls ? 8729 : 8728 };
has timeout   => 10;
has tls       => 1;
has user      => 'admin';
has _tag      => 0;

# Aliases
# {
#     no strict 'refs';
#     *{__PACKAGE__ . "::cmd"}   = \&command;
#     *{__PACKAGE__ . "::cmd_p"} = \&command_p;
#     *{__PACKAGE__ . "::_fail"} = \&_finish;
# }
Mojo::Util::monkey_patch(__PACKAGE__, 'cmd',   \&command);
Mojo::Util::monkey_patch(__PACKAGE__, 'cmd_p', \&command_p);
Mojo::Util::monkey_patch(__PACKAGE__, '_fail', \&_finish);

sub DESTROY { shift->_cleanup unless ${^GLOBAL_PHASE} eq 'DESTRUCT' }

sub cancel {
    my $cb = ref $_[-1] eq 'CODE' ? pop : sub { };
    return
        shift->_command(Mojo::IOLoop->singleton, '/cancel', {'tag' => shift}, undef, $cb);
}

sub command {
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($self, $cmd, $attr, $query) = @_;

    # non-blocking
    return $self->_command(Mojo::IOLoop->singleton, $cmd, $attr, $query, $cb) if $cb;

    # blocking
    my $res;
    $self->_command($self->ioloop, $cmd, $attr, $query,
        sub { $_[0]->ioloop->stop(); $res = $_[2]; });
    $self->ioloop->start();

    return $res;
}

sub command_p {
    return shift->_promisify(Mojo::IOLoop->singleton, @_);
}

sub subscribe {
    do { $_[0]->{error} = 'can\'t subscribe in blocking mode'; return; }
        unless ref $_[-1] eq 'CODE';
    my $cb = pop;
    my ($self, $cmd, $attr, $query) = @_;
    $attr->{'.subscription'} = 1;
    return $self->_command(Mojo::IOLoop->singleton, $cmd, $attr, $query, $cb);
}

sub _cleanup {
    my $self = shift;
    $_->{timeout} && $_->{loop}->remove($_->{timeout}) for values %{$self->{requests}};
    $_->{stream}  && $_->{stream}->unsubscribe('close')->close()
        for values %{$self->{connections}};
    delete @{$self}{qw(connections requests)};
}

sub _close {
    my ($self, $loop, $err) = @_;
    $self->_fail_all($loop, $err // 'closed prematurely');
    delete $self->{connections}{$loop};
}

sub _command {
    my ($self, $loop, $cmd, $attr, $query, $cb) = @_;

    my $tag = ++$self->{_tag};
    my $r   = $self->{requests}{$tag} = {tag => $tag, loop => $loop, cb => $cb};
    $r->{subscription} = delete $attr->{'.subscription'};

    warn "-- got request for command '$cmd' (tag: $tag)\n" if DEBUG;

    $r->{sentence} = encode_sentence($cmd, $attr, $query, $tag);
    return $self->_send_request($r);
}

sub _connect {
    my ($self, $loop) = @_;

    warn "-- creating new connection\n" if DEBUG;
    my $c = $self->{connections}{$loop};

    # define SSL_VERIFY_NONE 0x00
    # define SSL_VERIFY_PEER 0x01
    my $verify_mode = $self->insecure ? 0x00 : 0x01;
    my %tls_opts    = (
        tls      => $self->tls,
        tls_ca   => $self->ca,
        tls_cert => $self->cert,
        tls_key  => $self->key,
        (
            MOJO_TLS_OPTS
            ? (tls_options => {SSL_cipher_list => 'HIGH', SSL_verify_mode => $verify_mode})
            : (tls_ciphers => 'HIGH', tls_verify => $verify_mode)
        )
    );

    $c->{id} = $loop->client(
        {
            address => $self->host,
            port    => $self->port,
            timeout => CONN_TIMEOUT,
            %tls_opts

        } => sub {
            my ($loop, $err, $stream) = @_;

            if ($err) { $self->_close($loop, $err); return }

            warn "-- connection established\n" if DEBUG;

            $c->{stream} = $stream;

            weaken $self;
            $stream->on(read  => sub { $self->_read($loop, $_[1]) });
            $stream->on(error => sub { $self and $self->_fail_all($loop, $_[1]) });
            $stream->on(close => sub { $self and $self->_close($loop) });

            $self->_login($loop);
        }
    );
}

sub _enqueue {
    my ($self, $r) = @_;
    my $c = $self->{connections}{$r->{loop}};
    $self->_connect($r->{loop}) unless $c->{id};
    push @{$c->{queue} ||= []}, $r;
    return $r->{tag};
}

sub _fail_all {
    $_[0]->_fail($_, $_[2]) for grep { $_->{loop} eq $_[1] } values %{$_[0]->{requests}};
}

sub _finish {
    my ($self, $r, $err) = @_;
    delete $self->{requests}{$r->{tag}};
    if (my $timer = $r->{timeout}) { $r->{loop}->remove($timer) }
    $r->{cb}->($self, ($self->{error} = $err // ''), $r->{data});
}

sub _login {
    my ($self, $loop) = @_;
    warn "-- trying to log in\n" if DEBUG;

    $self->_promisify(
        $loop, '/login',
        ($self->new_login ? {name => $self->user, password => $self->password} : {})

    )->then(sub {
        my $res = shift;
        return $res if !$res->[0]{ret};    # New style login post-v6.43

        my $secret = md5_sum("\x00", $self->password, pack 'H*', $res->[0]{ret});
        return $self->_promisify($loop, '/login',
            {name => $self->user, response => "00$secret"});

    })->then(sub {
        my $c = $self->{connections}{$loop};
        $self->_write_sentence($c->{stream}, $_) for @{delete $c->{queue}};

    })->catch(sub {
        $self->_close($loop, $_[0]);

    })->wait;
}

sub _promisify {
    my ($self, $loop) = (shift, shift);
    my $p = Mojo::Promise->new()->ioloop($loop);
    $self->_command(
        $loop,
        (shift, shift, shift) => sub {
            return $p->reject($_[1], $_[2]) if $_[1];
            $p->resolve($_[2]);
        }
    );
    return $p;
}

sub _read {
    my ($self, $loop, $bytes) = @_;

    warn term_escape "-- read from socket: " . length($bytes) . "\n$bytes\n" if DEBUG;

    my $resp = $self->{connections}{$loop}{response} ||= MikroTik::Client::Response->new();
    my $data = $resp->parse(\$bytes);

    for (@$data) {
        next unless my $r = $self->{requests}{delete $_->{'.tag'}};
        my $type = delete $_->{'.type'};
        push @{$r->{data} ||= Mojo::Collection->new()}, $_ if %$_ && !$r->{subscription};

        if ($type eq '!re' && $r->{subscription}) {
            $r->{cb}->($self, '', $_);

        }
        elsif ($type eq '!done') {
            $r->{data} ||= Mojo::Collection->new();
            $self->_finish($r);

        }
        elsif ($type eq '!trap' || $type eq '!fatal') {
            $self->_fail($r, $_->{message});
        }
    }
}

sub _send_request {
    my ($self, $r) = @_;
    return $self->_enqueue($r) unless my $stream = $self->{connections}{$r->{loop}}{stream};
    return $self->_write_sentence($stream, $r);
}

sub _write_sentence {
    my ($self, $stream, $r) = @_;
    warn term_escape "-- writing sentence for tag: $r->{tag}\n$r->{sentence}\n" if DEBUG;

    $stream->write($r->{sentence});

    return $r->{tag} if $r->{subscription};

    weaken $self;
    $r->{timeout}
        = $r->{loop}->timer($self->timeout => sub { $self->_fail($r, 'response timeout') });

    return $r->{tag};
}

1;


=encoding utf8

=head1 NAME

MikroTik::Client - Non-blocking interface to MikroTik API

=head1 SYNOPSIS

  my $api = MikroTik::Client->new();

  # Blocking
  my $list = $api->command(
      '/interface/print',
      {'.proplist' => '.id,name,type'},
      {type        => ['ipip-tunnel', 'gre-tunnel'], running => 'true'}
  );
  if (my $err = $api->error) { die "$err\n" }
  printf "%s: %s\n", $_->{name}, $_->{type} for @$list;


  # Non-blocking
  my $tag = $api->command(
      '/system/resource/print',
      {'.proplist' => 'board-name,version,uptime'} => sub {
          my ($api, $err, $list) = @_;
          ...;
      }
  );
  Mojo::IOLoop->start();

  # Subscribe
  $tag = $api->subscribe(
      '/interface/listen' => sub {
          my ($api, $err, $el) = @_;
          ...;
      }
  );
  Mojo::IOLoop->timer(3 => sub { $api->cancel($tag) });
  Mojo::IOLoop->start();

  # Errors handling
  $api->command(
      '/random/command' => sub {
          my ($api, $err, $list) = @_;

          if ($err) {
              warn "Error: $err, category: " . $list->[0]{category};
              return;
          }

          ...;
      }
  );
  Mojo::IOLoop->start();

  # Promises
  $api->cmd_p('/interface/print')
      ->then(sub { my $res = shift }, sub { my ($err, $attr) = @_ })
      ->finally(sub { Mojo::IOLoop->stop() });
  Mojo::IOLoop->start();

=head1 DESCRIPTION

Both blocking and non-blocking interface to a MikroTik API service. With queries,
command subscriptions and Promises/A+.

=head1 ATTRIBUTES

L<MikroTik::Client> implements the following attributes.

=head2 ca

    my $ca = $api->ca;
    $api->ca("/etc/ssl/certs/ca-bundle.crt")

Path to TLS authority file.

Can be changed with C<MIKROTIK_CLIENT_CA> environment variable.

=head2 cert

    my $cert = $api->cert;
    $api->cert("./client.crt")

Path to the TLS cert file.

Can be bundled with a private key and intermediate public certificates.
If it's contains a private key, L<key> attribute is optional.

Can be changed with C<MIKROTIK_CLIENT_CERT> environment variable.

=head2 error

  my $last_error = $api->error;

Keeps an error from last L</command> call. Empty string on successful commands.

=head2 host

  my $host = $api->host;
  $api     = $api->host('border-gw.local');

Host name or IP address to connect to. Defaults to C<192.168.88.1>.

=head2 insecure

  my $insecure = $api->insecure;
  $api->insecure(0);

Do not verify TLS certificates. Connection will be encrypted, but peer certificate
won't be validated. B<Enabled by default>.

Can be changed with C<MIKROTIK_CLIENT_INSECURE> environment variable.

=head2 ioloop

  my $loop = $api->ioloop;
  $api     = $api->loop(Mojo::IOLoop->new());

Event loop instance to use for blocking calls. Defaults to L<Mojo::IOLoop>
object.

=head2 key

    my $key = $api->key;
    $api->key("./client.crt")

Path to TLS key file. Optional if a private key is bundled with L<cert> file.

Can be changed with C<MIKROTIK_CLIENT_KEY> environment variable.

=head2 new_login

  my $new_login = $api->new_login;
  $api          = $api->new_login(0);

Used to enable new login scheme introduced in RouterOS C<v6.43>. Now it's a way to
disable it, if required for some reason. Enabled by default.

=head2 password

  my $pass = $api->password;
  $api     = $api->password('secret');

Password for authentication. Empty string by default.

=head2 port

  my $port = $api->port;
  $api     = $api->port(8000);

API service port for connection. Defaults to C<8729> and C<8728> for TLS and
clear text connections respectively.

=head2 timeout

  my $timeout = $api->timeout;
  $api        = $api->timeout(15);

Timeout in seconds for sending request and receiving response before command
will be canceled. Default is C<10> seconds.

=head2 tls

  my $tls = $api->tls;
  $api    = $api->tls(1);

Use TLS for connection. Enabled by default.

CAVEAT: It's enabled by default, but it requires TLS support from
L<Mojo::IOLoop::Client/connect1>

=head2 user

  my $user = $api->user;
  $api     = $api->user('admin');

User name for authentication. Defaults to C<admin>.

=head1 METHODS

=head2 cancel

  # subscribe to a command output
  my $tag = $api->subscribe('/ping', {address => '127.0.0.1'} => sub {...});

  # cancel command after 10 seconds
  Mojo::IOLoop->timer(10 => sub { $api->cancel($tag) });

  # or with callback
  $api->cancel($tag => sub {...});

Cancels background commands. Can accept a callback as last argument.

=head2 cmd

  my $list = $api->cmd('/interface/print');

An alias for L</command>.

=head2 cmd_p

  my $p = $api->cmd_p('/interface/print');

An alias for L</command_p>.

=head2 command

  my $command = '/interface/print';
  my $attr    = {'.proplist' => '.id,name,type'};
  my $query   = {type => ['ipip-tunnel', 'gre-tunnel'], running => 'true'};

  my $list = $api->command($command, $attr, $query);
  die $api->error if $api->error;
  for (@$list) {...}

  $api->command('/user/set', {'.id' => 'admin', comment => 'System admin'});

  # Non-blocking
  $api->command('/ip/address/print' => sub {
      my ($api, $err, $list) = @_;

      return if $err;

      for (@$list) {...}
  });

  # Omit attributes
  $api->command('/user/print', undef, {name => 'admin'} => sub {...});

  # Errors handling
  $list = $api->command('/random/command');
  if (my $err = $api->error) {
      die "Error: $err, category: " . $list->[0]{category};
  }

Executes commands on a device. Returns L<Mojo::Collection> of hashrefs with results.
Can accept a callback for non-blocking calls.

On errors it may pass extra info in return argument in addition to an error value.

For a query syntax refer to L<MikroTik::Client::Query>.

=head2 command_p

  my $promise = $api->command_p('/interface/print');

  $promise->then(
  sub {
      my $res = shift;
      ...
  })->catch(sub {
      my ($err, $attr) = @_;
  });

Same as L</command>, but always performs requests non-blocking and returns a
L<Mojo::Promise> object instead of accepting a callback.

=head2 subscribe

  my $tag = $api->subscribe('/ping',
      {address => '127.0.0.1'} => sub {
        my ($api, $err, $res) = @_;
      });

  Mojo::IOLoop->timer(
      3 => sub { $api->cancel($tag) }
  );

Subscribe to a command with continuous responses such as C<listen> or C<ping>.
Should be terminated with L</cancel>.

=head1 DEBUGGING

You can set the MIKROTIK_CLIENT_DEBUG environment variable to get some debug output
printed to stderr.

Also, you can change connection timeout with the MIKROTIK_CLIENT_CONNTIMEOUT variable.

=head1 COPYRIGHT AND LICENSE

Andre Parker, 2017-2025.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://help.mikrotik.com/docs/spaces/ROS/pages/47579160/API>, L<https://codeberg.org/anparker/mikrotik-client>

=cut


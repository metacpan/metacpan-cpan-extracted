package MikroTik::Client;
use MikroTik::Client::Mo;

use AnyEvent;
use AnyEvent::Handle;
use Digest::MD5 'md5_hex';
use MikroTik::Client::Response;
use MikroTik::Client::Sentence 'encode_sentence';
use Carp ();
use Scalar::Util 'weaken';

use constant CONN_TIMEOUT => $ENV{MIKROTIK_CLIENT_CONNTIMEOUT};
use constant DEBUG        => $ENV{MIKROTIK_CLIENT_DEBUG} || 0;
use constant PROMISES     => !!(eval { require Promises; 1 });

our $VERSION = "v0.530";

has ca   => sub { $ENV{MIKROTIK_CLIENT_CA} };
has cert => sub { $ENV{MIKROTIK_CLIENT_CERT} };
has error     => '';
has host      => '192.168.88.1';
has insecure  => 0;
has key       => sub { $ENV{MIKROTIK_CLIENT_KEY} };
has new_login => sub { $_[0]->tls || 0 };
has password  => '';
has port      => 0;
has timeout   => 10;
has tls       => 1;
has user      => 'admin';
has _tag      => 0;

# Aliases
{
    no strict 'refs';
    *{__PACKAGE__ . "::cmd"}   = \&command;
    *{__PACKAGE__ . "::cmd_p"} = \&command_p;
    *{__PACKAGE__ . "::_fail"} = \&_finish;
}

sub DESTROY {
    (defined ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT')
        or shift->_cleanup();
}

sub cancel {
    my $cb = ref $_[-1] eq 'CODE' ? pop : sub { };
    return shift->_command('/cancel', {'tag' => shift}, undef, $cb);
}

sub command {
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my ($self, $cmd, $attr, $query) = @_;

    # non-blocking
    return $self->_command($cmd, $attr, $query, $cb) if $cb;

    # blocking
    my $cv = AnyEvent->condvar;
    $self->_command($cmd, $attr, $query, sub { $cv->send($_[2]) });
    return $cv->recv;
}

sub command_p {
    Carp::croak 'Promises 0.99+ is required for this functionality.'
        unless PROMISES;
    my ($self, $cmd, $attr, $query) = @_;

    my $d = Promises::deferred();
    $self->_command($cmd, $attr, $query,
        sub { $_[1] ? $d->reject(@_[1, 2]) : $d->resolve($_[2]) });

    return $d->promise;
}

sub subscribe {
    do { $_[0]->{error} = 'can\'t subscribe in blocking mode'; return; }
        unless ref $_[-1] eq 'CODE';
    my $cb = pop;
    my ($self, $cmd, $attr, $query) = @_;
    $attr->{'.subscription'} = 1;
    return $self->_command($cmd, $attr, $query, $cb);
}

sub _cleanup {
    my $self = shift;
    delete $_->{timeout} for values %{$self->{requests}};
    delete $self->{handle};
}

sub _close {
    my ($self, $err) = @_;
    $self->_fail_all($err || 'closed prematurely');
    delete @{$self}{qw(handle response requests)};
}

sub _command {
    my ($self, $cmd, $attr, $query, $cb) = @_;

    my $tag = ++$self->{_tag};
    my $r = $self->{requests}{$tag} = {tag => $tag, cb => $cb};
    $r->{subscription} = delete $attr->{'.subscription'};

    warn "-- got request for command '$cmd' (tag: $tag)\n" if DEBUG;

    $r->{sentence} = encode_sentence($cmd, $attr, $query, $tag);
    return $self->_send_request($r);
}

sub _connect {
    my ($self, $r) = @_;

    warn "-- creating new connection\n" if DEBUG;

    my $queue = $self->{queue} = [$r];

    my $tls = $self->tls;
    my $port = $self->port ? $self->{port} : $tls ? 8729 : 8728;

    my $tls_opts = {verify => !$self->insecure, cipher_list => "HIGH"};
    $self->{$_} && ($tls_opts->{$_ . "_file"} = $self->{$_})
        for qw(ca cert key);

    weaken $self;
    $self->{handle} = AnyEvent::Handle->new(
        connect => [$self->host, $port],
        timeout => 60,

        $tls ? (tls => "connect", tls_ctx => $tls_opts) : (),

        on_connect => sub {
            warn "-- connection established\n" if DEBUG;

            delete $self->{queue};

            $self->_login(sub {
                return $self->_close($_[1]) if $_[1];
                $self->_write_sentence($_) for @$queue;
            });
        },

        on_connect_error => sub {
            delete @{$self}{qw(handle queue)};
            $self->_close($_[1]);
        },

        on_eof   => sub { $self && $self->_close },
        on_error => sub { $self && $self->_close($_[2]) },
        on_read    => sub { $self->_read(\$_[0]->{rbuf}) },
        on_prepare => sub {CONN_TIMEOUT},
        on_timeout => sub { $self && $self->_close }
    );

    return $r->{tag};
}

sub _enqueue {
    my ($self, $r) = @_;
    return $self->_connect($r) unless my $queue = $self->{queue};
    push @$queue, $r;
    return $r->{tag};
}

sub _fail_all {
    my @requests = values %{$_[0]->{requests}};
    $_[0]->_fail($_, $_[1]) for @requests;
}

sub _finish {
    my ($self, $r, $err) = @_;
    delete $self->{requests}{$r->{tag}};
    delete $r->{timeout};
    $r->{cb}->($self, ($self->{error} = $err // ''), $r->{data});
}

sub _login {
    my ($self, $cb) = @_;
    warn "-- trying to log in\n" if DEBUG;

    $self->_command(
        '/login',
        (
            $self->new_login
            ? {name => $self->user, password => $self->password}
            : {}
        ),
        undef,
        sub {
            my ($self, $err, $res) = @_;
            return $self->$cb($err) if $err;
            return $self->$cb() if !$res->[0]{ret};    # New style login

            my $secret
                = md5_hex("\x00", $self->password, pack 'H*', $res->[0]{ret});

            $self->_command('/login',
                {name => $self->user, response => "00$secret"},
                undef, $cb);
        }
    );
}

sub _read {
    my ($self, $buf) = @_;

    warn _term_esc("-- read buffer (" . length($$buf) . " bytes)\n$$buf\n")
        if DEBUG;

    my $response = $self->{response} ||= MikroTik::Client::Response->new();
    my $data = $response->parse($buf);

    for (@$data) {
        next unless my $r = $self->{requests}{delete $_->{'.tag'}};
        my $type = delete $_->{'.type'};
        push @{$r->{data} ||= []}, $_ if %$_ && !$r->{subscription};

        if ($type eq '!re' && $r->{subscription}) {
            $r->{cb}->($self, '', $_);

        }
        elsif ($type eq '!done') {
            $r->{data} ||= [];
            $self->_finish($r);

        }
        elsif ($type eq '!trap' || $type eq '!fatal') {
            $self->_fail($r, $_->{message});
        }
    }
}

sub _send_request {
    my ($self, $r) = @_;
    return $self->_enqueue($r) unless $self->{handle};
    return $self->_write_sentence($r);
}

sub _term_esc {
    my $str = shift;
    $str =~ s/([\x00-\x09\x0b-\x1f\x7f\x80-\x9f])/sprintf '\\x%02x', ord $1/ge;
    return $str;
}

sub _write_sentence {
    my ($self, $r) = @_;
    warn _term_esc("-- writing sentence for tag: $r->{tag}\n$r->{sentence}\n")
        if DEBUG;

    $self->{handle}->push_write($r->{sentence});

    return $r->{tag} if $r->{subscription};

    weaken $self;
    $r->{timeout} = AnyEvent->timer(
        after => $self->timeout,
        cb    => sub { $self->_fail($r, 'response timeout') }
    );

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
  my $cv  = AE::cv;
  my $tag = $api->command(
      '/system/resource/print',
      {'.proplist' => 'board-name,version,uptime'} => sub {
          my ($api, $err, $list) = @_;
          ...;
          $cv->send;
      }
  );
  $cv->recv;

  # Subscribe
  $tag = $api->subscribe(
      '/interface/listen' => sub {
          my ($api, $err, $el) = @_;
          ...;
      }
  );
  AE::timer 3, 0, cb => sub { $api->cancel($tag) };

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
 
  # Promises
  $cv  = AE::cv;
  $api->cmd_p('/interface/print')
      ->then(sub { my $res = shift }, sub { my ($err, $attr) = @_ })
      ->finally($cv);
  $cv->recv;

=head1 DESCRIPTION

Both blocking and non-blocking (don't mix them though) interface to a MikroTik
API service. With queries, command subscriptions and optional Promises.

=head1 ATTRIBUTES

L<MikroTik::Client> implements the following attributes.

=head2 ca

    my $ca = $api->ca;
    $api->ca("/etc/ssl/certs/ca-bundle.crt")

Path to TLS certificate authority file used to verify the peer certificate,
defaults to the value of the C<MIKROTIK_CLIENT_CA> environment variable.

=head2 cert

    my $cert = $api->cert;
    $api->cert("./client.crt")

Path to TLS certificate file used to authenticate against the peer. Can be bundled
with a private key and additional signing certificates. If file contains the private key,
L<key> attribute is optional. Defaults to the value of the C<MIKROTIK_CLIENT_CERT>
environment variable.

=head2 error

  my $last_error = $api->error;

Keeps an error from last L</command> call. Empty string on successful commands.

=head2 host

  my $host = $api->host;
  $api     = $api->host('border-gw.local');

Host name or IP address to connect to. Defaults to C<192.168.88.1>.

=head2 insecure

  my $insecure = $api->insecure;
  $api->insecure(1);

Do not verify TLS certificates I<(highly discouraged)>. Connection will be encrypted,
but a peer certificate won't be validated. Disabled by default.

=head2 key

    my $key = $api->key;
    $api->key("./client.crt")

Path to TLS key file. Optional if a private key bundled with a L<cert> file. Defaults to
the value of the C<MIKROTIK_CLIENT_KEY> environment variable.

=head2 new_login

  my $new_login = $api->new_login;
  $api          = $api->new_login(1);

Use new login scheme introduced in RouterOS C<v6.43> and fallback to previous
one for older systems. Since in this mode a password will be send in clear text,
it will be default only for L</tls> connections.

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

=head2 user

  my $user = $api->user;
  $api     = $api->user('admin');

User name for authentication purposes. Defaults to C<admin>.

=head1 METHODS

=head2 cancel

  # subscribe to a command output
  my $tag = $api->subscribe('/ping', {address => '127.0.0.1'} => sub {...});

  # cancel command after 10 seconds
  my $t = AE::timer 10, 0, sub { $api->cancel($tag) };

  # or with callback
  $api->cancel($tag => sub {...});

Cancels background commands. Can accept a callback as last argument.

=head2 cmd

  my $list = $api->cmd('/interface/print');

An alias for L</command>.

=head2 cmd_p

  my $promise = $api->cmd_p('/interface/print');

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

Executes a command on a remote host and returns list with hashrefs containing
elements returned by a host. You can append a callback for non-blocking calls.

In a case of error, returned value may keep additional attributes such as category
or an error code. You should never rely on defines of the result to catch errors.

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
promise instead of accepting a callback. L<Promises> v0.99+ is required for
this functionality.

=head2 subscribe

  my $tag = $api->subscribe('/ping',
      {address => '127.0.0.1'} => sub {
        my ($api, $err, $res) = @_;
      });

  AE::timer 3, 0, sub { $api->cancel($tag) };

Subscribe to an output of commands with continuous responses such as C<listen> or
C<ping>. Should be terminated with L</cancel>.

=head1 DEBUGGING

You can set the MIKROTIK_CLIENT_DEBUG environment variable to get some debug output
printed to stderr.

Also, you can change connection timeout with the MIKROTIK_CLIENT_CONNTIMEOUT variable.

=head1 COPYRIGHT AND LICENSE

Andre Parker, 2017-2019.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://wiki.mikrotik.com/wiki/Manual:API>, L<https://github.com/anparker/api-mikrotik>

=cut

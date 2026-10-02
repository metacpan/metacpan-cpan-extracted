package Langertha::Raider::Hall::Telegram;
our $VERSION = '0.503';
# ABSTRACT: Internal multi-bot Telegram long-poll adapter for the raider hall


use Moose;
use namespace::autoclean;
use JSON::MaybeXS;
use URI;
use HTTP::Request::Common ();
use IO::Async::Timer::Countdown;
use Scalar::Util qw( weaken );
use Net::Async::HTTP;
use Langertha::Raider::ConnectCheck qw( connect_error );

has hall => (
  is => 'ro',
  isa => 'Langertha::Raider::Hall',
  required => 1,
  weak_ref => 1,
);

has _workers => (
  is => 'ro',
  default => sub { {} },
);

has _history_dir => (
  is => 'ro',
  lazy => 1,
  builder => '_build_history_dir',
);

sub _build_history_dir {
  my ($self) = @_;
  my $d = $self->hall->state_dir->child('telegram');
  $d->mkpath unless -d $d;
  $d;
}

sub setup_bots {
  my ($self) = @_;
  my $conf = $self->hall->config->{telegram} // {};
  my $bots = $conf->{bots} // {};
  for my $name (keys %$bots) {
    $self->_start_bot($name, $bots->{$name});
  }
}

sub _start_bot {
  my ($self, $name, $bot_conf) = @_;
  my $token = $bot_conf->{token} // return;
  $self->_check_bot_config($name, $bot_conf);
  my $allowlist = $bot_conf->{allowlist} // [];
  my $allowed_chats = $bot_conf->{allowed_chats} // [];
  my $routing = $bot_conf->{routing} // {};

  my $ua = Net::Async::HTTP->new(
    max_connections_per_host => 1,
    timeout => 60,
  );
  $self->hall->loop->add($ua);

  $self->_workers->{$name} = {
    token => $token,
    allowlist => $allowlist,
    allowed_chats => $allowed_chats,
    routing => $routing,
    ua => $ua,
    offset => 0,
    active => 1,
  };

  $self->_poll($name);
}

sub _check_bot_config {
  my ($self, $name, $bot_conf) = @_;
  my @allowlist = @{ $bot_conf->{allowlist} // [] };
  my @problems;
  push @problems, 'empty allowlist, every message will be rejected'
    unless @allowlist;
  # Telegram group/channel ids are negative, user ids positive.
  push @problems, 'allowlist entry '.$_.' is a chat id, not a user id;'
    .' list it under allowed_chats and put the members\' user ids in allowlist'
    for grep { /^-/ } @allowlist;
  for my $problem (@problems) {
    warn 'Telegram bot '.$name.': '.$problem."\n";
    $self->hall->_emit('telegram.config_warning', { bot => $name, warning => $problem });
  }
}

sub _reject_reason {
  my ($self, $worker, $msg) = @_;
  my $from_id = $msg->{from}{id} // return 'no_sender';
  my $chat_id = $msg->{chat}{id};
  return 'sender_not_allowed'
    unless grep { $_ eq $from_id } @{ $worker->{allowlist} // [] };
  return if $chat_id eq $from_id;
  return 'chat_not_allowed'
    unless grep { $_ eq $chat_id } @{ $worker->{allowed_chats} // [] };
  return;
}

# Why no request can reach the Bot API, or undef. A module that fails to
# load while Net::Async::HTTP connects keeps the host's only connection
# slot taken, and every later request waits forever (karr k107).
sub _connect_error { connect_error('https://api.telegram.org') }

sub _poll {
  my ($self, $name) = @_;
  my $worker = $self->_workers->{$name} or return;
  return unless $worker->{active};

  # A module that does not load now will not later: stop polling, loudly.
  if (my $error = $self->_connect_error) {
    $worker->{active} = 0;
    warn 'Telegram bot '.$name.': '.$error."\n";
    $self->hall->_emit('telegram.poll_error', { bot => $name, error => $error });
    return;
  }

  my $ua = $worker->{ua};
  my $token = $worker->{token};

  my $uri = URI->new("https://api.telegram.org/bot$token/getUpdates");
  my %q = (timeout => 30);
  $q{offset} = $worker->{offset} if $worker->{offset};
  $uri->query_form(%q);

  my $f = $ua->GET($uri);
  $worker->{poll_future} = $f;
  weaken(my $weak = $self);
  $f->on_done(sub {
    my $self = $weak or return;
    delete $worker->{poll_future};
    my ($resp) = @_;
    my $updates = eval {
      JSON::MaybeXS->new->decode($resp->decoded_content)->{result} // []
    } // [];
    for my $update (@$updates) {
      $self->_handle_update($name, $update);
      $worker->{offset} = $update->{update_id} + 1;
    }
    $self->hall->loop->later(sub { $self->_poll($name) });
  });
  $f->on_fail(sub {
    my $self = $weak or return;
    delete $worker->{poll_future};
    $self->hall->_emit('telegram.poll_error', { bot => $name, error => "$_[0]" });
    # Back off a bit on failure so we don't hot-loop against a dead network.
    my $timer = IO::Async::Timer::Countdown->new(
      delay => 5,
      on_expire => sub { $self->_poll($name) },
    );
    $self->hall->loop->add($timer);
    $timer->start;
  });
}

sub _handle_update {
  my ($self, $bot_name, $update) = @_;
  my $worker = $self->_workers->{$bot_name} or return;
  my $msg = $update->{message} // $update->{edited_message} // return;

  my $chat_id = $msg->{chat}{id} // return;
  my $text = $msg->{text} // '';

  if (my $reason = $self->_reject_reason($worker, $msg)) {
    $self->hall->_emit('telegram.rejected', {
      bot => $bot_name,
      chat_id => $chat_id,
      from_id => $msg->{from}{id},
      reason => $reason,
      update_id => $update->{update_id},
    });
    return;
  }

  my $routing = $worker->{routing};
  my $target_raider = $routing->{$chat_id} // $routing->{'*'} // undef;

  $self->hall->_emit('telegram.in', {
    bot => $bot_name,
    chat_id => $chat_id,
    defined $msg->{message_thread_id} ? ( message_thread_id => $msg->{message_thread_id} ) : (),
    text => $text,
    first_name => $msg->{from}{first_name} // '',
    username => $msg->{from}{username} // '',
    update_id => $update->{update_id},
  });

  $self->_save_history($bot_name, $chat_id, $update);

  # One session per chat (per forum topic), continued by every message.
  my $thread = $msg->{message_thread_id};
  my %target = (
    bot => $bot_name,
    chat_id => $chat_id,
    defined $thread ? ( message_thread_id => $thread ) : (),
  );
  my $binding = join(':', 'telegram', $bot_name, $chat_id, defined $thread ? $thread : ());

  return $self->_start_new_session($binding, %target) if $self->_is_new_command($text);

  if ($target_raider) {
    $self->hall->spawn(
      name => $target_raider,
      mission => $text,
      telegram => \%target,
      binding => $binding,
    );
  }
}

# /new, or /new@BOTNAME in a group.
sub _is_new_command {
  my ($self, $text) = @_;
  return $text =~ m{\A\s*/new(?:\@\w+)?\s*\z};
}

# /new: the chat's next message starts a new session. Not a mission;
# answered with a short confirmation into the same chat and topic.
sub _start_new_session {
  my ($self, $binding, %target) = @_;
  $self->hall->reset_session($binding);
  $self->send_message(%target, text => 'Started a new session.');
  return;
}

sub _save_history {
  my ($self, $bot_name, $chat_id, $update) = @_;
  my $dir = $self->_history_dir->child($bot_name);
  $dir->mkpath unless -d $dir;
  my $file = $dir->child("$chat_id.json");
  my $history = eval { JSON::MaybeXS->new->decode($file->slurp_utf8) } // [];
  push @$history, $update;
  $file->spew_utf8(JSON::MaybeXS->new->encode($history));
}

sub send_message {
  my ($self, %args) = @_;
  my $bot_name = $args{bot} // return { error => 'bot name required' };
  my $chat_id = $args{chat_id} // return { error => 'chat_id required' };
  my $text = $args{text} // return { error => 'text required' };

  my $worker = $self->_workers->{$bot_name} or return { error => "bot $bot_name not running" };
  my $token = $worker->{token};
  my $ua = $worker->{ua};

  if (my $error = $self->_connect_error) {
    return { error => $error };
  }

  my $uri = URI->new("https://api.telegram.org/bot$token/sendMessage");
  my $req = HTTP::Request::Common::POST($uri, [
    chat_id => $chat_id,
    defined $args{message_thread_id} ? ( message_thread_id => $args{message_thread_id} ) : (),
    text => $text,
    parse_mode => 'Markdown',
  ]);

  # Fire-and-forget: return the Future so callers can await if they want.
  my $f = $ua->do_request(request => $req);
  my $id = time . '-' . int(rand(1_000_000));
  $worker->{send_futures}{$id} = $f;
  weaken(my $weak = $self);
  $f->on_done(sub {
    delete $worker->{send_futures}{$id};
  });
  $f->on_fail(sub {
    my $self = $weak or return;
    delete $worker->{send_futures}{$id};
    $self->hall->_emit('telegram.send_error', {
      bot => $bot_name, chat_id => $chat_id, error => "$_[0]",
    });
  });
  return { ok => 1, future => $f };
}

sub stop {
  my ($self) = @_;
  $_->{active} = 0 for values %{$self->_workers};
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::Telegram - Internal multi-bot Telegram long-poll adapter for the raider hall

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Long-polls every Telegram bot configured for a L<Langertha::Raider::Hall>,
routes incoming messages to raiders and sends replies.

Access is fail-closed and checked per message:

  telegram:
    bots:
      ops:
        token: '...'
        allowlist:     [1234567890]      # Telegram user ids (message.from.id)
        allowed_chats: [-1001234567890]  # optional: group chats to answer in

A message is accepted only when its sender (C<from.id>) is in C<allowlist>
B<and> its chat is either the private chat with that sender or listed in
C<allowed_chats>. An empty or missing C<allowlist> accepts nobody. Rejected
messages emit a C<telegram.rejected> event and are neither stored nor routed.

A routed message runs in the session bound to its chat --
C<telegram:BOT:CHAT_ID>, with C<:THREAD> for a forum topic -- so the
conversation continues across messages (see
L<Langertha::Raider::Hall/session_bindings>). The raider's
C<telegram_reply> answers into the same chat and forum topic.

C</new> (or C</new@BOTNAME>) from an accepted sender is not a mission: the
chat's (topic's) next message starts a new session, and the bot confirms
with a short message. The old journal stays.

When a module the https connection to the Bot API needs does not load
(L<IO::Async::SSL> and what it needs, see L<Langertha::Raider::ConnectCheck>),
a bot does not poll: the hall warns and emits C<telegram.poll_error> with the
module's name, and a reply is an C<error> result. Nothing is sent, so
nothing waits for a connection that cannot open.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

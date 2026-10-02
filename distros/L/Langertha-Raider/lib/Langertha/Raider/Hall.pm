package Langertha::Raider::Hall;
our $VERSION = '0.503';
# ABSTRACT: Hall daemon — spawns and manages raider processes


use strict;
use warnings;
use Path::Tiny;
use IO::Async::Loop;
use IO::Async::Stream;
use IO::Async::Timer;
use JSON::MaybeXS;
use POSIX qw(WNOHANG);
use YAML::PP;
use Moose;
use namespace::autoclean;
use IO::Async::Listener;
use IO::Async::Process;
use IO::Async::Timer::Countdown;
use IO::Socket::UNIX;
use File::Which ();
use Net::Async::HTTP;
use Langertha::Raider::Binary qw( packed_binary );
use Langertha::Raider::Hall::ACP;
use Langertha::Raider::Hall::Cron;
use Langertha::Raider::Hall::MCP;
use Langertha::Raider::Hall::Protocol;
use Langertha::Raider::Hall::Raider;
use Langertha::Raider::Hall::Telegram;
use Langertha::Raider::SessionStore;

has root => (
  is => 'ro',
  isa => 'Path::Tiny',
  required => 1,
);

has loop => (
  is => 'ro',
  lazy => 1,
  builder => '_build_loop',
);

has _loop => (
  is => 'ro',
  init_arg => undef,
  default => sub { IO::Async::Loop->new },
);

sub _build_loop { $_[0]->_loop }

has config => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_config',
);

sub _build_config {
  my ($self) = @_;
  my $yml_file = $self->root->child('.raider-hall.yml');
  return {} unless -f $yml_file;
  YAML::PP->new->load_string($yml_file->slurp_utf8);
}

has socket_path => (
  is => 'ro',
  lazy => 1,
  builder => '_build_socket_path',
);

sub _build_socket_path {
  my ($self) = @_;
  $self->root->child('.raider-hall.socket')->stringify;
}

has mcpserver_socket_path => (
  is => 'ro',
  lazy => 1,
  builder => '_build_mcpserver_socket_path',
);

sub _build_mcpserver_socket_path {
  my ($self) = @_;
  $self->root->child('.raider-hall.mcp')->stringify;
}

has longhouse_lib_path => (
  is => 'ro',
  lazy => 1,
  builder => '_build_longhouse_lib_path',
);

sub _build_longhouse_lib_path {
  my ($self) = @_;
  $self->root->child('longhouse', 'lib');
}

has state_dir => (
  is => 'ro',
  lazy => 1,
  builder => '_build_state_dir',
);

sub _build_state_dir {
  my ($self) = @_;
  my $d = $self->root->child('.raider-hall', 'state');
  $d->mkpath unless -d $d;
  $d;
}

has raiders => (
  is => 'ro',
  default => sub { {} },
);


sub session_store_class { 'Langertha::Raider::SessionStore' }

has session_store => (
  is => 'ro',
  lazy => 1,
  builder => '_build_session_store',
);

sub _build_session_store {
  my ($self) = @_;
  return $self->session_store_class->new(root => $self->root->stringify);
}


has session_bindings => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_session_bindings',
);

sub _session_bindings_file { $_[0]->state_dir->child('sessions.json') }

sub _build_session_bindings {
  my ($self) = @_;
  my $file = $self->_session_bindings_file;
  return {} unless -f $file;
  my $map = eval { JSON::MaybeXS->new->decode($file->slurp_utf8) };
  return ref $map eq 'HASH' ? $map : {};
}

sub _persist_session_bindings {
  my ($self) = @_;
  $self->_session_bindings_file->spew_utf8(
    JSON::MaybeXS->new(canonical => 1)->encode($self->session_bindings));
}


sub session_for {
  my ($self, $binding) = @_;
  my $bindings = $self->session_bindings;
  my $store = $self->session_store;
  my $id = $bindings->{$binding};
  return $id if defined $id && $store->exists($id);
  my $session = $store->create;
  $id = $session->id;
  $session->release;
  $bindings->{$binding} = $id;
  $self->_persist_session_bindings;
  $self->_emit('session.bound', { binding => $binding, session => $id });
  return $id;
}


sub unbind_session {
  my ($self, $binding) = @_;
  return unless defined delete $self->session_bindings->{$binding};
  $self->_persist_session_bindings;
  return;
}


sub reset_session {
  my ($self, $binding) = @_;
  return { error => 'session_reset requires a binding' }
    unless defined $binding && length $binding;
  my $id = $self->session_bindings->{$binding};
  return { error => 'no session bound to '.$binding } unless defined $id;
  $self->unbind_session($binding);
  $self->_emit('session.reset', { binding => $binding, session => $id });
  return { reset => 1, binding => $binding, session => $id };
}

# ACP bindings live as long as their connection, which a hall restart
# ends: forget them and the prompts they left waiting. Journals stay.
sub _forget_acp_bindings {
  my ($self) = @_;
  my @acp = grep { /^acp:/ } keys %{$self->session_bindings};
  delete @{$self->session_bindings}{@acp};
  $self->_persist_session_bindings if @acp;
  $self->drop_queued($_) for grep { /^acp:/ } $self->_waiting_bindings;
  return;
}

# Bindings of cron jobs no longer in the config are forgotten at a start,
# and the missions they left waiting are dropped. Journals stay.
sub _forget_removed_cron_bindings {
  my ($self) = @_;
  my %job = map { ( 'cron:'.( $_->{id} // $_->{name} // '' ) => 1 ) }
    @{ $self->config->{cron} // [] };
  my %gone = map { $_ => 1 } grep { /^cron:/ && !$job{$_} }
    keys %{$self->session_bindings}, $self->_waiting_bindings;
  for my $binding (sort keys %gone) {
    $self->unbind_session($binding);
    $self->drop_queued($binding);
  }
  return;
}

# The binding of a run: the one it was spawned with, else its numbered
# slot; a plain-name run has none.
sub _binding_key {
  my ($self, $slot, $binding) = @_;
  return $binding if defined $binding;
  return 'slot:'.$slot if $slot =~ /^\d+[a-z]/;
  return;
}


has singleton_queues => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_singleton_queues',
);

sub _build_singleton_queues {
  my ($self) = @_;
  my %queues;
  for my $queue_file ($self->state_dir->children(qr/^\d+[a-z][-a-z0-9]*\.queue\.json$/)) {
    my $slot = $queue_file->basename =~ s/\.queue\.json$//r;
    my $q = eval { JSON::MaybeXS->new->decode($queue_file->slurp_utf8) };
    $queues{$slot} = ref $q eq 'ARRAY' ? $q : [];
  }
  return \%queues;
}

# Start the missions waiting for a numbered slot, once nothing runs in it.
# One whose binding is busy moves on to that binding's queue, and the next
# one gets the slot.
sub _drain_singleton_queue {
  my ($self, $slot) = @_;
  my $queue = $self->singleton_queues->{$slot} or return;
  my ($base) = $slot =~ /^\d+(.+)$/;
  while (@$queue && !$self->_slot_busy($slot)) {
    my $next = shift @$queue;
    $self->_persist_queue($slot);
    $self->_spawn_next_in_queue($slot, $base, $next);
  }
  return;
}

sub _drain_singleton_queues {
  my ($self) = @_;
  $self->_drain_singleton_queue($_) for sort keys %{$self->singleton_queues};
  return;
}


sub drop_queued {
  my ($self, $binding) = @_;
  my $dropped = 0;
  if (my $queue = delete $self->binding_queues->{$binding}) {
    $dropped += @$queue;
    $self->_persist_binding_queues;
  }
  my $slots = $self->singleton_queues;
  for my $slot (sort keys %$slots) {
    my $queue = $slots->{$slot};
    my @keep = grep { ($_->{binding} // '') ne $binding } @$queue;
    next if @keep == @$queue;
    $dropped += @$queue - @keep;
    @$queue = @keep;
    $self->_persist_queue($slot);
  }
  return $dropped;
}

# Every binding a waiting mission names, in the binding queues or the slot
# queues.
sub _waiting_bindings {
  my ($self) = @_;
  my %waiting = map { $_ => 1 } keys %{$self->binding_queues};
  for my $queue (values %{$self->singleton_queues}) {
    $waiting{$_->{binding}} = 1 for grep { defined $_->{binding} } @$queue;
  }
  return sort keys %waiting;
}


has binding_queues => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  builder => '_build_binding_queues',
);

sub _binding_queues_file { $_[0]->state_dir->child('binding_queues.json') }

sub _build_binding_queues {
  my ($self) = @_;
  my $file = $self->_binding_queues_file;
  return {} unless -f $file;
  my $queues = eval { JSON::MaybeXS->new->decode($file->slurp_utf8) };
  return ref $queues eq 'HASH' ? $queues : {};
}

sub _persist_binding_queues {
  my ($self) = @_;
  $self->_binding_queues_file->spew_utf8(
    JSON::MaybeXS->new(canonical => 1)->encode($self->binding_queues));
}

sub _binding_busy {
  my ($self, $binding) = @_;
  return scalar grep { $_->has_binding && $_->binding eq $binding } values %{$self->raiders};
}

sub _queue_on_binding {
  my ($self, $binding, $entry) = @_;
  my $queue = $self->binding_queues->{$binding} //= [];
  push @$queue, $entry;
  $self->_persist_binding_queues;
  $self->_emit('raider.queued', {
    slot => $entry->{name},
    binding => $binding,
    queue_depth => scalar @$queue,
  });
  return { queued => 1, slot => $entry->{name}, binding => $binding, queue_depth => scalar @$queue };
}

# Start the missions waiting for a binding, once nothing runs on it. One
# that has to wait for its slot moves on to the slot queue, and the next
# one follows it there.
sub _drain_binding_queue {
  my ($self, $binding) = @_;
  my $queues = $self->binding_queues;
  while (!$self->_binding_busy($binding)) {
    my $queue = $queues->{$binding} or return;
    my $next = shift @$queue;
    delete $queues->{$binding} unless @$queue;
    $self->_persist_binding_queues;
    $self->_spawn(%$next) if $next;
  }
  return;
}

sub _drain_binding_queues {
  my ($self) = @_;
  $self->_drain_binding_queue($_) for sort keys %{$self->binding_queues};
  return;
}

has cron_scheduler => (
  is => 'ro',
  lazy => 1,
  builder => '_build_cron_scheduler',
);

sub _build_cron_scheduler {
  my ($self) = @_;
  Langertha::Raider::Hall::Cron->new(hall => $self);
}

has telegram => (
  is => 'ro',
  lazy => 1,
  builder => '_build_telegram',
);

sub _build_telegram {
  my ($self) = @_;
  Langertha::Raider::Hall::Telegram->new(hall => $self);
}

has mcp_adapter => (
  is => 'ro',
  lazy => 1,
  builder => '_build_mcp_adapter',
);

sub _build_mcp_adapter {
  my ($self) = @_;
  Langertha::Raider::Hall::MCP->new(hall => $self);
}

has acp_adapter => (
  is => 'ro',
  lazy => 1,
  builder => '_build_acp_adapter',
);

sub _build_acp_adapter {
  my ($self) = @_;
  my $conf = $self->config->{acp} // {};
  Langertha::Raider::Hall::ACP->new(
    hall => $self,
    port => ($ENV{RAIDER_HALL_ACP_PORT} // $conf->{port} // 0),
    host => ($ENV{RAIDER_HALL_ACP_HOST} // $conf->{host} // '127.0.0.1'),
  );
}

has protocol => (
  is => 'ro',
  lazy => 1,
  builder => '_build_protocol',
);

sub _build_protocol {
  my ($self) = @_;
  my $p = Langertha::Raider::Hall::Protocol->new(hall => $self);
  $p->setup_handlers;
  $p;
}

sub BUILD {
  my ($self) = @_;
  $self->root->mkpath unless -d $self->root;
}

sub run {
  my ($self) = @_;
  my $loop = $self->loop;

  $self->_setup_socket;
  $self->_setup_mcp_socket if $self->_want_mcp_socket;
  $self->_setup_event_broadcaster;
  $self->_setup_signal_handlers;
  $self->protocol;
  $self->_setup_cron;
  $self->_setup_telegram;
  $self->_setup_acp;
  $self->_forget_acp_bindings;
  $self->_forget_removed_cron_bindings;
  $self->_drain_singleton_queues;
  $self->_drain_binding_queues;

  $self->_emit('hall.started', { root => $self->root->stringify });

  $loop->run;
}

sub _want_mcp_socket {
  my ($self) = @_;
  my $conf = $self->config;
  return $conf->{mcp} && $conf->{mcp}{enable};
}

sub _setup_socket {
  my ($self) = @_;
  my $loop = $self->loop;
  my $path = $self->socket_path;

  my $sock = IO::Socket::UNIX->new(
    Local => $path,
    Listen => 1,
  ) or die "Cannot create UNIX socket at $path: $!";

  chmod 0600, $path or die "Cannot chmod 0600 $path: $!";

  my $listener = IO::Async::Listener->new(
    on_accept => sub {
      my ($listener, $sock, $peeraddr) = @_;
      $self->_handle_client($sock);
    },
  );

  $loop->add($listener);

  $listener->listen(handle => $sock);
  $self->{_listener} = $listener;
}

sub _setup_mcp_socket {
  my ($self) = @_;
}

sub _setup_event_broadcaster {
  my ($self) = @_;
  $self->{_subscribers} = [];
}

sub _setup_cron {
  my ($self) = @_;
  return unless $self->config->{cron} && @{$self->config->{cron}};
  $self->cron_scheduler->start;
}

sub _setup_telegram {
  my ($self) = @_;
  return unless $self->config->{telegram} && $self->config->{telegram}{bots};
  $self->telegram->setup_bots;
}

sub _setup_acp {
  my ($self) = @_;
  my $enabled = $ENV{RAIDER_HALL_ACP_PORT}
    || ($self->config->{acp} && $self->config->{acp}{port});
  return unless $enabled;
  $self->acp_adapter->start;
}

sub _acp_running {
  my ($self) = @_;
  return $ENV{RAIDER_HALL_ACP_PORT}
    || ($self->config->{acp} && $self->config->{acp}{port});
}

sub _handle_client {
  my ($self, $sock) = @_;
  my $stream = IO::Async::Stream->new(
    handle => $sock,
    on_read => sub {
      my ($stream, $bufref, $eof) = @_;
      $self->_process_client_frames($stream, $bufref, $eof);
    },
    on_closed => sub {
      my ($stream) = @_;
      $self->_unsubscribe_stream($stream);
    },
  );
  $self->loop->add($stream);
  push @{$self->{_client_streams}}, $stream;
}

sub _process_client_frames {
  my ($self, $stream, $bufref, $eof) = @_;
  return unless $$bufref =~ s/^(.*?)\n//;
  my $line = $1;
  return if $line eq '';

  my $msg = eval { JSON::MaybeXS->new->decode($line) };
  if (!$msg || $@) {
    my $err = JSON::MaybeXS->new->encode({error => "invalid JSON: $@"});
    $stream->write("$err\n");
    return;
  }

  my $type = $msg->{type} // '';
  my $payload = $msg->{payload} // {};

  if ($type eq 'subscribe') {
    push @{$self->{_subscribers}}, { stream => $stream, filter => $payload->{filter} // '' };
    return;
  }

  if ($type eq 'command') {
    $self->_handle_command($stream, $payload);
    return;
  }

  my $err = JSON::MaybeXS->new->encode({error => "unknown message type: $type"});
  $stream->write("$err\n");
}

sub _handle_command {
  my ($self, $stream, $payload) = @_;
  my $cmd = $payload->{cmd} // '';

  my $handler = $self->{_cmd_handlers}{$cmd};
  if (!$handler) {
    my $err = JSON::MaybeXS->new->encode({error => "unknown command: $cmd"});
    $stream->write("$err\n");
    return;
  }

  eval { $handler->($self, $stream, $payload) };
  if ($@) {
    my $err = JSON::MaybeXS->new->encode({error => "command failed: $@"});
    $stream->write("$err\n");
  }
}

sub _emit {
  my ($self, $type, $data) = @_;
  $data->{type} = $type;
  $data->{ts} //= time();

  my $json = JSON::MaybeXS->new->encode($data);
  # Closed streams leave the list; a subscriber whose filter does not match
  # stays, and so does one added while this event went out.
  my %closed;
  for my $sub (@{[ @{$self->{_subscribers} // []} ]}) {
    my $stream = $sub->{stream};
    unless ($stream && $stream->handle && $stream->handle->opened) {
      $closed{$sub} = 1;
      next;
    }
    my $filter = $sub->{filter} // '';
    next if $filter ne '' && substr($type, 0, length($filter)) ne $filter;
    eval { $stream->write("$json\n") };
  }
  $self->{_subscribers} = [ grep { !$closed{$_} } @{$self->{_subscribers} // []} ];
}

sub _broadcast_to_socket {
  my ($self, $type, $data) = @_;
  $self->_emit($type, $data);
}

sub _unsubscribe_stream {
  my ($self, $stream) = @_;
  @{$self->{_subscribers}} = grep { $_->{stream} ne $stream } @{$self->{_subscribers}};
  @{$self->{_client_streams}} = grep { $_ ne $stream } @{$self->{_client_streams}};
}

sub _register_cmd {
  my ($self, $name, $handler) = @_;
  $self->{_cmd_handlers}{$name} = $handler;
}

sub _persist_queue {
  my ($self, $slot) = @_;
  my $queue = $self->singleton_queues->{$slot} // [];
  my $file = $self->state_dir->child("$slot.queue.json");
  $file->spew_utf8(JSON::MaybeXS->new->encode($queue));
}

sub _setup_signal_handlers {
  my ($self) = @_;
  my $loop = $self->loop;

  # CHLD is handled per-process via IO::Async::Process->on_finish; no
  # global watcher needed (and mixing would double-reap).

  $loop->watch_signal(TERM => sub { $self->shutdown });
  $loop->watch_signal(INT  => sub { $self->shutdown });
}

sub _reap_raider {
  my ($self, $pid, $status) = @_;
  my $raider = $self->_find_raider_by_pid($pid);
  return unless $raider;

  my $slot = $raider->slot_name;
  my $result = $self->_raider_result($raider, $status);
  $result->{session} = $raider->session_id if $raider->has_session_id;
  # Before the raider leaves the table: logs --follow stops once it is gone.
  $self->_log_result($raider, $result);
  $self->_emit('raider.done', {
    id => $raider->id,
    slot => $slot,
    pid => $pid,
    exit_code => $status >> 8,
    signaled => ($status & 127) ? 1 : 0,
    %$result,
    $raider->has_binding ? ( binding => $raider->binding ) : (),
  });

  delete $self->raiders->{$raider->id};
  $self->_prune_events($slot);

  $self->_drain_singleton_queue($slot) if $slot =~ /^\d+/;

  $self->_drain_binding_queue($raider->binding) if $raider->has_binding;
}

# The run's outcome for raider.done: status plus response or error, taken
# from the last run.finished event of the run. Without one (killed, crashed
# before it could write it) the run counts as failed, with an error that
# says so instead of whatever text the process left behind.
sub _result_of {
  my ($self, $doc) = @_;
  return {
    status => $doc->{status} // 'failed',
    defined $doc->{response} ? ( response => $doc->{response} ) : (),
    defined $doc->{error}    ? ( error    => $doc->{error} )    : (),
    ref $doc->{session} eq 'HASH' && defined $doc->{session}{id}
      ? ( session => $doc->{session}{id} ) : (),
  };
}

sub _raider_result {
  my ($self, $raider, $status) = @_;
  if (my $doc = $raider->run_finished) {
    return $self->_result_of($doc);
  }
  # Exit 4: the session is held by another writer; raider ran nothing.
  if (!($status & 127) && ($status >> 8) == 4 && $raider->has_session_id) {
    return {
      status => 'failed',
      error  => 'session '.$raider->session_id.' of '.$raider->binding
        .' is in use by another run; mission not run',
    };
  }
  my $how = ($status & 127) ? 'killed by signal '.($status & 127)
                            : 'exit code '.($status >> 8);
  return {
    status => 'failed',
    error  => 'raider '.$raider->id.' ended without a result ('.$how.')',
  };
}

# One human-readable line per finished run at the end of the slot log, so
# logs and logs --follow show the outcome next to the raider's stderr. The
# full response stays in raider.done and the events file.
sub _log_result {
  my ($self, $raider, $result) = @_;
  $raider->log_path->append_utf8($self->_result_line($raider->id, $result));
}

sub _result_line {
  my ($self, $id, $result) = @_;
  my $text = $result->{status} eq 'completed' ? $result->{response} : $result->{error};
  $text = join ' ', split ' ', $text // '';
  $text = substr($text, 0, 300).'...' if length $text > 300;
  return '[hall] raider '.$id.' '.$result->{status}.': '.$text."\n";
}


has keep_events => (
  is => 'ro',
  lazy => 1,
  builder => '_build_keep_events',
);

sub _build_keep_events {
  my ($self) = @_;
  my $logs = $self->config->{logs} // {};
  return $logs->{keep_events} // 20;
}


has max_log_size => (
  is => 'ro',
  lazy => 1,
  builder => '_build_max_log_size',
);

sub _build_max_log_size {
  my ($self) = @_;
  my $logs = $self->config->{logs} // {};
  return $logs->{max_log_size} // 1024 * 1024;
}

sub _log_dir { $_[0]->root->child('.raider-hall', 'logs') }

sub _rotate_log {
  my ($self, $slot) = @_;
  my $max = $self->max_log_size;
  return unless $max > 0 && !$self->_slot_busy($slot);
  my $log = $self->_log_dir->child("${slot}.log");
  return unless -f $log && -s $log > $max;
  $log->move($self->_log_dir->child("${slot}.log.1"));
}

sub _prune_events {
  my ($self, $slot) = @_;
  my $keep = $self->keep_events;
  my $dir = $self->_log_dir;
  return unless $keep > 0 && -d $dir;
  # SLOT-TIME or SLOT-TIME.N: the hyphen before TIME keeps SLOT-x-TIME of
  # another slot out.
  my @runs = sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] }
    map { $_->basename =~ /^\Q$slot\E-(\d+)(?:\.(\d+))?\.events\.jsonl$/ ? [ $_, $1, $2 // 1 ] : () }
    $dir->children;
  $_->[0]->remove for @runs[ 0 .. $#runs - $keep ];
}

sub _slot_busy {
  my ($self, $slot) = @_;
  return scalar grep { $_->slot_name eq $slot } values %{$self->raiders};
}

# The slots with at least one running raider, each named once.
sub _running_slots {
  my ($self) = @_;
  my %slots = map { $_->slot_name => 1 } values %{$self->raiders};
  return [ sort keys %slots ];
}

sub _find_raider_by_pid {
  my ($self, $pid) = @_;
  for my $r (values %{$self->raiders}) {
    return $r if $r->pid && $r->pid == $pid;
  }
  return;
}

sub _spawn_next_in_queue {
  my ($self, $slot, $base_name, $mission) = @_;
  my ($telegram, $binding);
  if (ref $mission eq 'HASH') {
    $telegram = $mission->{telegram};
    $binding = $mission->{binding};
    $mission = $mission->{mission};
  }
  return $self->_queue_on_binding($binding, {
    name => $slot,
    mission => $mission,
    $telegram ? ( telegram => $telegram ) : (),
    binding => $binding,
  }) if defined $binding && $self->_binding_busy($binding);
  $self->_spawn_raider($slot, $base_name, $mission, $telegram, $binding);
}

sub spawn {
  my ($self, %args) = @_;
  # Missions already waiting for the binding go first.
  $self->_drain_binding_queue($args{binding}) if defined $args{binding};
  return $self->_spawn(%args);
}

sub _spawn {
  my ($self, %args) = @_;
  my $name = $args{name} // '';
  my $mission = $args{mission} // '';
  my $telegram = $args{telegram};
  my $binding = $args{binding};

  my ($slot, $base_name) = $self->_parse_name($name);

  # Only numbered names have a slot here: singletons, queued while busy.
  # A plain name runs in parallel. Missions already waiting go first.
  $self->_drain_singleton_queue($slot) if $slot;
  if ($slot && $self->_slot_busy($slot)) {
    push @{$self->singleton_queues->{$slot} //= []}, {
      mission => $mission,
      $telegram ? ( telegram => $telegram ) : (),
      defined $binding ? ( binding => $binding ) : (),
    };
    $self->_persist_queue($slot);
    my $depth = scalar @{$self->singleton_queues->{$slot}};
    $self->_emit('raider.queued', {
      slot => $slot,
      queue_depth => $depth,
    });
    return { queued => 1, slot => $slot, queue_depth => $depth };
  }

  # One writer per session: a mission for a binding that is running waits
  # for it. Parallel runs of a plain name need their own bindings.
  return $self->_queue_on_binding($binding, {
    name => $name,
    mission => $mission,
    $telegram ? ( telegram => $telegram ) : (),
    binding => $binding,
  }) if defined $binding && $self->_binding_busy($binding);

  return $self->_spawn_raider($slot // $name, $base_name // $name, $mission, $telegram, $binding);
}

sub _parse_name {
  my ($self, $name) = @_;
  if ($name =~ /^(\d+)([a-z][-a-z0-9]*)$/) {
    return ($1.$2, $2);
  }
  return (undef, $name);
}

sub _spawn_raider {
  my ($self, $slot, $base_name, $mission, $telegram, $binding) = @_;

  my $raider_config = $self->config->{raiders}{$base_name} // {};
  # No engine configured: leave it to raider (.raider.yml, then key autodetection).
  my $engine = $raider_config->{engine};
  my $model = $raider_config->{model};
  my @packs = @{ $raider_config->{packs} // [] };
  # The persona is one more pack.
  my $persona = $raider_config->{persona};
  push @packs, $persona
    if defined $persona && length $persona && !grep { $_ eq $persona } @packs;
  my $lib_target = $self->lib_target;

  my @cmd = ($self->_raider_command, '--stream-json');
  push @cmd, '--engine', $engine if $engine;
  push @cmd, '--model', $model if $model;
  push @cmd, '--pack', $_ for @packs;
  push @cmd, '-o', 'preferred_lib_target='.$lib_target;
  push @cmd, '--root', $self->root->stringify;
  # A bound run resumes its binding's session; an unbound one gets a
  # fresh session from the raider itself.
  $binding = $self->_binding_key($slot, $binding);
  my ($session_id, $session_error);
  if (defined $binding) {
    $session_id = eval { $self->session_for($binding) };
    unless (defined $session_id) {
      $session_error = { binding => $binding, error => $@ =~ s/\s+\z//r };
      undef $binding;
    }
  }
  push @cmd, '--session', $session_id if defined $session_id;
  # Mission is one single argv (bin/raider does join(' ', @ARGV)).
  push @cmd, '--', $mission;

  my $log_dir = $self->_log_dir;
  $log_dir->mkpath unless -d $log_dir;

  # stderr is the human-readable log, appended across runs of the slot;
  # stdout is the event stream, a fresh file per run. The ID is SLOT-TIME,
  # SLOT-TIME.2 and up when that one is taken in the same second; touching
  # the file reserves it before the child opens it.
  $self->_rotate_log($slot);
  my $log_path = $log_dir->child("${slot}.log");
  my $id = my $base_id = "$slot-" . time;
  my $n = 1;
  $id = $base_id.'.'.++$n while -e $log_dir->child("${id}.events.jsonl");
  my $events_path = $log_dir->child("${id}.events.jsonl");
  $events_path->touch;
  $log_path->append_utf8($self->_start_line($id));
  $self->_note_ignored_keys($base_name, $raider_config, $log_path);

  # perl_cpanm installs with --local-lib, so the modules land in lib/perl5.
  my $extra_perl5lib = join ':', path($lib_target)->child('lib', 'perl5')->stringify,
    ($self->config->{longhouse} ? $self->longhouse_lib_path->stringify : ());

  # The Telegram chat (and forum topic) this raider answers; telegram_reply
  # is bound to it. Never inherited from the hall's own env.
  my %env = %ENV;
  delete @env{qw( RAIDER_HALL_TELEGRAM_BOT RAIDER_HALL_TELEGRAM_CHAT_ID RAIDER_HALL_TELEGRAM_THREAD_ID )};
  if ($telegram) {
    $env{RAIDER_HALL_TELEGRAM_BOT}     = $telegram->{bot};
    $env{RAIDER_HALL_TELEGRAM_CHAT_ID} = $telegram->{chat_id};
    $env{RAIDER_HALL_TELEGRAM_THREAD_ID} = $telegram->{message_thread_id}
      if defined $telegram->{message_thread_id};
  }

  my $process = IO::Async::Process->new(
    command => \@cmd,
    setup => [
      stdin  => [ 'open', '<', '/dev/null' ],
      stdout => [ 'open', '>', "$events_path" ],
      stderr => [ 'open', '>>', "$log_path" ],
      env => {
        %env,
        RAIDER_HALL_MODE   => '1',
        RAIDER_HALL_ROOT   => $self->root->stringify,
        RAIDER_HALL_SLOT   => $slot,
        RAIDER_HALL_SOCKET => $self->socket_path,
        PERL5LIB => join(':', grep { defined && length }
                          ($ENV{PERL5LIB}, $extra_perl5lib)),
      },
    ],
    on_finish => sub {
      my ($proc, $exitcode) = @_;
      my $pid = $proc->pid;
      $self->loop->later(sub { $self->_reap_raider($pid, $exitcode) });
    },
  );

  $self->loop->add($process);

  my $raider = Langertha::Raider::Hall::Raider->new({
    id => $id,
    pid => $process->pid,
    slot_name => $slot,
    base_name => $base_name,
    log_path => $log_path,
    events_path => $events_path,
    mission => $mission,
    defined $session_id ? ( session_id => $session_id, binding => $binding ) : (),
  });
  $self->raiders->{$id} = $raider;

  $self->_emit('raider.spawned', {
    id => $id,
    pid => $process->pid,
    slot => $slot,
    base_name => $base_name,
    $self->_session_fields($raider),
  });
  # The binding's session could not be had: the run goes on unbound.
  $self->_emit('hall.session_error', { %$session_error, id => $id }) if $session_error;

  return {
    id => $id, pid => $process->pid, slot => $slot,
    events_path => $events_path->stringify,
    $self->_session_fields($raider),
  };
}

# session and binding of a bound run, for events and replies.
sub _session_fields {
  my ($self, $raider) = @_;
  return () unless $raider->has_session_id;
  return ( session => $raider->session_id, binding => $raider->binding );
}

# The argv prefix that starts a raider. A Perl script runs with this perl;
# inside the standalone binary there is no such perl ($^X is a bare
# "perl" off PATH, and "perl <binary>" dies on the ELF), so whatever
# _raider_bin names is exec'd directly.
sub _raider_command {
  my ($self) = @_;
  my $raider_bin = $self->_raider_bin;
  return packed_binary() ? ($raider_bin) : ($^X, $raider_bin);
}

sub _raider_bin {
  my ($self) = @_;
  # Explicit override wins — useful in tests and non-standard installs.
  return $ENV{RAIDER_HALL_RAIDER_BIN}
    if $ENV{RAIDER_HALL_RAIDER_BIN} && -x $ENV{RAIDER_HALL_RAIDER_BIN};

  # The standalone binary starts its raiders with itself, whatever it is
  # called and whatever raider is on PATH.
  my $packed = packed_binary();
  return $packed if defined $packed;

  # Otherwise: next to the currently-running script (raider-hall lives
  # alongside raider in a normal install), then $PATH.
  my $here = path($0)->absolute;
  my $sibling = $here->parent->child('raider');
  return $sibling->stringify if -x $sibling;
  my $which = File::Which::which('raider');
  return $which if $which;
  die "Cannot find 'raider' binary (set RAIDER_HALL_RAIDER_BIN or put it in \$PATH)";
}


has lib_target => (
  is => 'ro',
  lazy => 1,
  builder => '_build_lib_target',
);

sub _build_lib_target {
  my ($self) = @_;
  my $target = $self->config->{preferred_lib_target} // '.raider/lib';
  return path($target)->absolute($self->root)->stringify;
}

# Raider entry keys the hall does not read. A config that still carries
# one gets a note in the slot log, once per raider and hall process.
has _ignored_keys_noted => (
  is => 'ro',
  default => sub { {} },
);

sub _note_ignored_keys {
  my ($self, $base_name, $raider_config, $log_path) = @_;
  return if $self->_ignored_keys_noted->{$base_name}++;
  my @keys = grep { exists $raider_config->{$_} } qw( isolated mcp );
  return unless @keys;
  $log_path->append_utf8('[hall] raider '.$base_name.': '.join(', ', @keys)
    ." in .raider-hall.yml ignored\n");
}

sub ps {
  my ($self) = @_;
  my @list;
  for my $r (sort { $a->slot_name cmp $b->slot_name || $a->id cmp $b->id }
             values %{$self->raiders}) {
    push @list, {
      slot => $r->slot_name,
      pid => $r->pid,
      base_name => $r->base_name,
      mission => $r->mission,
      id => $r->id,
      $self->_session_fields($r),
    };
  }
  return @list;
}

sub attach {
  my ($self, $id) = @_;
  for my $r (values %{$self->raiders}) {
    next unless $r->id eq $id;
    return {
      id => $r->id,
      slot => $r->slot_name,
      pid => $r->pid,
      log_path => $r->log_path->stringify,
      $r->has_events_path ? ( events_path => $r->events_path->stringify ) : (),
      $self->_session_fields($r),
    };
  }
  return { error => 'raider not found' };
}

sub kill_raider {
  my ($self, $id) = @_;
  return $self->_signal_raider(TERM => $id) ? { killed => 1, id => $id } : { error => 'raider not found' };
}


sub cancel_raider {
  my ($self, $id) = @_;
  return { error => 'raider not found' } unless $self->_signal_raider(INT => $id);
  $self->_escalate_cancel($id, $self->raiders->{$id}->pid, qw( TERM KILL ));
  return { cancelled => 1, id => $id };
}


has cancel_grace => (
  is => 'ro',
  lazy => 1,
  builder => '_build_cancel_grace',
);

sub _build_cancel_grace { $_[0]->config->{cancel_grace} // 5 }

# After cancel_grace, sends the first of @signals to raider $id if that
# process ($pid) still runs, and goes on with the rest.
sub _escalate_cancel {
  my ($self, $id, $pid, @signals) = @_;
  my $grace = $self->cancel_grace;
  return unless @signals && $grace > 0 && $pid;
  my $timer = IO::Async::Timer::Countdown->new(
    delay => $grace,
    remove_on_expire => 1,
    on_expire => sub {
      my $r = $self->raiders->{$id} or return;
      return unless ($r->pid // 0) == $pid;
      my ($signal, @rest) = @signals;
      kill $signal, $pid;
      $self->_escalate_cancel($id, $pid, @rest);
    },
  );
  $self->loop->add($timer);
  $timer->start;
}

# Sends $signal to the process of raider $id; false when there is no such raider.
sub _signal_raider {
  my ($self, $signal, $id) = @_;
  for my $r (values %{$self->raiders}) {
    next unless $r->id eq $id;
    kill $signal, $r->pid if $r->pid;
    return 1;
  }
  return 0;
}


sub logs {
  my ($self, %args) = @_;
  my $id = $args{id} // '';
  for my $r (values %{$self->raiders}) {
    next unless $r->id eq $id;
    my $log = -f $r->log_path ? $r->log_path->slurp_utf8 : '';
    return { log => $self->_run_section($log, $id) // $log };
  }
  return $self->_ended_logs($id);
}

sub _ended_logs {
  my ($self, $id) = @_;
  my $missing = { error => 'raider not found' };
  # The ID names files in the log dir: no path parts, no leading dot.
  return $missing unless $id =~ /\A([^\/.][^\/]*)-\d+(?:\.\d+)?\z/;
  my $slot = $1;
  my $dir = $self->_log_dir;
  my $log_path = $dir->child("${slot}.log");
  my $log = -f $log_path ? $log_path->slurp_utf8 : '';
  my $section = $self->_run_section($log, $id);
  $log = $section if defined $section;
  my $logged = $log =~ /^\[hall\] raider \Q$id\E \w+: /m;
  my $events = $dir->child("${id}.events.jsonl");
  return $missing unless defined $section || $logged || -f $events;
  return { log => $log } if $logged;
  my $doc = Langertha::Raider::Hall::Raider->new(
    id => $id, slot_name => $slot, base_name => $slot, mission => '',
    log_path => $log_path, events_path => $events,
  )->run_finished;
  return { log => $log.( $doc ? $self->_result_line($id, $self->_result_of($doc)) : '' ) };
}

sub _start_line {
  my ($self, $id) = @_;
  return '[hall] raider '.$id." started\n";
}

# From the run's start line to its result line, or to the end of the log;
# undef when the log has no start line for it.
sub _run_section {
  my ($self, $log, $id) = @_;
  my $start = quotemeta $self->_start_line($id);
  return $1 if $log =~ /^($start.*?(?:^\[hall\] raider \Q$id\E \w+: [^\n]*\n|\z))/ms;
  return;
}

sub shutdown {
  my ($self) = @_;
  $self->_emit('hall.stopping', {});

  if ($self->_acp_running) {
    eval { $self->acp_adapter->stop };
  }

  if ($self->telegram) {
    eval { $self->telegram->stop };
  }

  for my $r (values %{$self->raiders}) {
    kill 'TERM', $r->pid if $r->pid && $r->pid > 0;
  }

  my $timer = IO::Async::Timer::Countdown->new(
    delay => 5,
    on_expire => sub {
      for my $r (values %{$self->raiders}) {
        kill 'KILL', $r->pid if $r->pid && $r->pid > 0;
      }
      $self->loop->stop;
    },
  );
  $self->loop->add($timer);
  $timer->start;

  # With no children running, stop immediately rather than waiting the
  # full 5s grace period.
  if (!keys %{$self->raiders}) {
    $self->loop->later(sub { $self->loop->stop });
  }
}

sub _write_pidfile {
  my ($self) = @_;
  my $pidfile = $self->root->child('.raider-hall.pid');
  $pidfile->spew_utf8("$$\n");
}

sub _remove_pidfile {
  my ($self) = @_;
  return unless $self->root;
  my $pidfile = $self->root->child('.raider-hall.pid');
  $pidfile->remove if -f $pidfile;
}

sub DEMOLISH {
  my ($self) = @_;
  $self->_remove_pidfile if $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall - Hall daemon — spawns and manages raider processes

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Raider::Hall;
    my $hall = Langertha::Raider::Hall->new(root => Path::Tiny::path('.'));
    $hall->run;   # blocks on the IO::Async loop

From the shell:

    raider hall init --name bjorn
    raider hall start --daemon --acp-port 38421
    raider hall spawn bjorn "summarise today's git log"

=head1 DESCRIPTION

Hall is the multi-raider daemon. It owns a UNIX command/event socket,
spawns named raiders as child processes, enforces C<1name> singleton
slots with persistent FIFO queueing, and wires in optional features:

=over

=item * Non-blocking L<Schedule::Cron> scheduler for timed raids.

=item * Multi-bot Telegram long-poll with routing + per-chat history.

=item * ACP (Agent Client Protocol) adapter on a TCP port for Zed and
other ACP-capable clients — see L<Langertha::Raider::Hall::ACP>.

=back

The name picks the slot. A name with a leading number (C<1bjorn>) is a
singleton: one run at a time, further missions wait in a queue that
survives a hall restart. A plain name (C<bjorn>) runs every mission at
once, in parallel; its runs share the slot log. The hall keeps its running
raiders by run ID, so each run is reaped and reported on its own.

An MCP adapter on C<.raider-hall.mcp> is B<not implemented>:
L<Langertha::Raider::Hall::MCP> describes the hall tools, but no socket is
opened and an C<mcp> section in the config has no effect.

All state flows through the event bus (JSONL pub/sub). Clients
subscribe with C<{type: subscribe, payload: {filter: 'raider.'}}> and
commands are separate frames (C<{type: command, payload: {cmd: ...}}>).

Each raider runs with C<--stream-json>. Its stdout goes to a file of its
own per run, F<.raider-hall/logs/ID.events.jsonl>; its stderr is appended
to the human-readable F<.raider-hall/logs/SLOT.log>. When the process
ends, C<raider.done> carries C<status> and C<response> or C<error> from
the run's last C<run.finished> event. A run that ended without one
(killed, crashed) is C<failed>, with an error saying so.
The hall then appends one line to the slot log,
C<[hall] raider ID STATUS: TEXT> with the response or error cut to 300
characters, so C<raider hall logs> shows the outcome.

Each run starts its part of the slot log with C<[hall] raider ID started>.
Run IDs are C<SLOT-TIME>, with C<.2>, C<.3>, ... appended when a run of the
same slot started in the same second. Only the newest L</keep_events>
events files per slot are kept. A slot log larger than L</max_log_size> is
moved to F<SLOT.log.1> when the next run of the slot starts.

Every run is recorded in a session journal (ADR 0015) under
F<.raider/sessions/> of the hall root. A bound run -- a Telegram chat, a
cron job, an ACP session, a numbered slot; see L</session_bindings> --
is started with C<--session ID> and continues its binding's session; a
plain-name run gets a fresh session. C<raider.spawned>, C<ps> and
C<attach> name the C<session> and C<binding> of a bound run,
C<raider.done> names the C<session> of every run that has one. A mission
for a binding that already has a running raider waits in that binding's
queue and starts when the run ends (see L</binding_queues>). Only when the
session is held by a writer outside the hall does a bound run fail at
once, as C<raider.done> with status C<failed> and an error naming the
session and binding; its mission is not run. When the hall cannot get the
binding's session at all, the run starts unbound, and
C<hall.session_error> names the C<binding>, the C<error> and the run C<id>.

C<raider hall logs ID> shows the part of the slot log from that run's start
line to its result line, and works for ended runs too: the slot is taken
from the ID; see L</logs>.

The C<spawn> reply and C<attach> name the run's C<events_path>;
C<raider hall attach ID> and C<raider hall spawn --attach> print that
file as it grows, until the hall has reaped the raider.

=head1 CONFIG FILE

C<.raider-hall.yml> in the hall root:

    longhouse: false
    preferred_lib_target: .raider-hall/lib
    raiders:
      bjorn:   { engine: anthropic, persona: caveman }
      lagertha:{ engine: openai,    persona: polite, packs: [git-guru] }
    cron:
      - { name: 1bjorn, cron: '*/15 * * * *', mission: 'ping CI' }
    telegram:
      bots:
        ops: { token: '...', allowlist: [42], routing: { '*': lagertha } }
    acp: { port: 38421, host: 127.0.0.1 }
    logs: { keep_events: 20, max_log_size: 1048576 }
    cancel_grace: 5

C<persona> on a raider entry is a pack used as the raider's persona: the
hall passes it as one more C<--pack>, after those in C<packs>, unless
C<packs> already names it. The hall ignores C<mcp> and C<isolated> on a
raider entry; the first run of such a raider notes that in its slot log.

C<preferred_lib_target> sets the hall's L</lib_target>. C<longhouse: true>
adds F<longhouse/lib> of the hall root to every raider's C<PERL5LIB> as
well.

C<engine> on a raider entry is optional. Without it the hall passes no
C<--engine> and the spawned raider decides itself: the engine from its
F<.raider.yml> first, then autodetection from the API keys in the
environment.

=head1 ENVIRONMENT

=head2 RAIDER_HALL_RAIDER_BIN

The F<raider> executable the hall starts its raiders with. Without it, or
when it is not executable, the standalone binary the hall itself runs
from, else the F<raider> next to the running script, then the one on
C<PATH>. From a standalone binary the hall execs it directly; otherwise
it runs it with the perl that runs the hall.

=head2 RAIDER_HALL_ACP_PORT

A TCP port opens the ACP adapter on it, over C<acp: { port: ... }> of the
config. C<raider hall start --acp-port N> sets it.

=head2 RAIDER_HALL_ACP_HOST

The address the ACP adapter binds to, over C<acp: { host: ... }>; default
C<127.0.0.1>. C<raider hall start --acp-port N --acp-host H> sets it.

Every raider the hall starts gets the hall's environment without the
C<RAIDER_HALL_TELEGRAM_*> variables, plus:

=over

=item * C<RAIDER_HALL_SOCKET> -- the hall's control socket. F<raider>
mounts the Hall tools (L<Langertha::Raider::HallTools>) when it is set.

=item * C<RAIDER_HALL_ROOT>, C<RAIDER_HALL_SLOT> -- the hall root and the
run's slot; C<RAIDER_HALL_MODE> is C<1>.

=item * C<RAIDER_HALL_TELEGRAM_BOT>, C<RAIDER_HALL_TELEGRAM_CHAT_ID> and,
for a forum topic, C<RAIDER_HALL_TELEGRAM_THREAD_ID> -- for a Telegram
mission, the chat C<telegram_reply> answers.

=item * C<PERL5LIB> -- extended by F<lib/perl5> of L</lib_target> (and
F<longhouse/lib> with C<longhouse: true>).

=back

=head1 SEE ALSO

L<raider-hall>, L<Langertha::Raider::CLI>, L<Langertha::Raider::Hall::ACP>,
L<Langertha::Raider::HallTools>, L<Langertha::Raider::Hall::CLI>.

=head2 session_store

The L<Langertha::Raider::SessionStore> of the hall's runs: the hall root
is their project, so journals live in F<.raider/sessions/> under it --
where a spawned raider, started with C<--root> on the hall root, keeps
them too.

=head2 session_bindings

The map from binding key to session id (ADR 0015, Hall bindings), kept in
F<.raider-hall/state/sessions.json>. Keys:

=over

=item * C<telegram:BOT:CHAT_ID>, C<telegram:BOT:CHAT_ID:THREAD> -- a
Telegram chat (or forum topic): the conversation continues across
messages;

=item * C<cron:ID> -- a cron job, its own session per job;

=item * C<acp:SESSION> -- an ACP session, for as long as its connection
lasts; a hall start forgets any left over;

=item * C<slot:1NAME> -- a numbered slot, continued by each queued
mission that has no binding of its own.

=back

A run of a plain name (C<bjorn>) without such a binding is not bound: the
raider starts a fresh session of its own.

Telegram, cron and slot bindings stay until they are reset (see
L</reset_session>); a hall start also forgets the bindings of cron jobs
no longer in the config, and drops the missions they left waiting.
Journals are never deleted by the hall.

=head2 session_for

    my $id = $hall->session_for('telegram:ops:42');

The session id bound to a binding key. A key without a session -- or
whose journal is gone -- gets a new session: the hall creates the journal
(C<session.created> naming the hall root) and records the binding, so the
raider it starts can resume it with C<--session ID>.

=head2 unbind_session

    $hall->unbind_session('acp:acp-1f2e3d4c');

Forgets a binding. The journal stays.

=head2 reset_session

    my $res = $hall->reset_session('telegram:ops:42');
    # { reset => 1, binding => ..., session => OLD_ID } or { error => ... }

Starts a binding over: its next mission gets a new session. The old
journal stays, and a run still going on the binding finishes in it.
Emits C<session.reset>. C<raider hall session reset BINDING> and C</new>
in a Telegram chat end up here.

=head2 singleton_queues

The missions waiting for a busy numbered slot, as a map from slot to a
FIFO list; each slot's list is kept in F<.raider-hall/state/SLOT.queue.json>.
A hall start runs what a previous hall left waiting before any new
mission, and a new mission for a slot never overtakes the missions
already waiting for it.

=head2 drop_queued

    my $n = $hall->drop_queued('acp:acp-1f2e3d4c');

Drops every mission waiting for a binding, from the binding's queue and
from the slot queues, and returns how many there were.

=head2 binding_queues

The missions waiting for a busy binding (ADR 0003: one writer per session,
new input is queued), as a map from binding key to a FIFO list of spawn
arguments; kept in F<.raider-hall/state/binding_queues.json>. A mission
whose binding already has a running raider waits here and starts when
that run ends, in the binding's session -- two quick Telegram messages to
one chat run one after the other. A hall start runs what a previous hall
left waiting. Missions without a binding never wait here.

=head2 keep_events

How many F<SLOT-TIME.events.jsonl> files the hall keeps per slot; older ones
are removed when a run of that slot ends. From C<logs: { keep_events: N }>
in F<.raider-hall.yml>, default 20; 0 keeps all of them. Slot logs
(F<SLOT.log>) are not pruned; see L</max_log_size>.

=head2 max_log_size

Size in bytes above which a slot log F<SLOT.log> is moved to F<SLOT.log.1>
(replacing an older one) when the next run of that slot starts -- never
while any raider of the slot is still writing it. From
C<logs: { max_log_size: N }> in F<.raider-hall.yml>, default 1048576
(1 MiB); 0 never rotates.

=head2 lib_target

The local::lib the hall's raiders install into with C<perl_cpanm>:
C<preferred_lib_target> of the config, relative to the hall root, default
F<.raider/lib>. Each raider gets it as C<-o preferred_lib_target=...>, which
beats that key in a F<.raider.yml>, and its F<lib/perl5> on C<PERL5LIB>.

=head2 cancel_raider

    my $res = $hall->cancel_raider($id);   # { cancelled => 1, id => $id } or { error => ... }

Cancels the run of the running raider C<$id> with C<SIGINT>: F<raider>
ends the run as C<cancelled> (its C<run.finished>, the session journal)
and then dies of the signal. C<kill_raider> sends C<SIGTERM> instead, a
stop that ends the run as C<interrupted>.

A raider still running L</cancel_grace> seconds later -- stuck in a call
that holds off the signal -- gets C<SIGTERM>, and C<SIGKILL> when it is
still there after another L</cancel_grace>.

=head2 cancel_grace

Seconds L</cancel_raider> gives a raider to end on C<SIGINT> before it
sends C<SIGTERM>, and again before C<SIGKILL>. From C<cancel_grace: N> in
F<.raider-hall.yml>, default 5; 0 never escalates. The default leaves
F<raider> time for its own cancel -- ending the tool subprocesses takes it
up to two seconds (L<Langertha::Raider::CLI::Runner/terminate_children>)
-- and matches the grace the hall gives its raiders on shutdown.

=head2 logs

    my $res = $hall->logs(id => $id);   # { log => $text } or { error => ... }

The run's part of its slot log: from its C<[hall] raider ID started> line
to its result line, or to the end of the log while it runs. Runs of a plain
name in parallel share the slot log, so their lines can interleave. A log
without that start line (written before the hall marked starts, or
rotated away) is answered with the whole slot log.

For an ended run the slot comes from the ID (C<SLOT-TIME> or
C<SLOT-TIME.N>); the run counts as known while its events file or its
lines in the slot log are there. When the log does not carry its result
line (rotated or removed), the result line built from the events file is
appended.

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

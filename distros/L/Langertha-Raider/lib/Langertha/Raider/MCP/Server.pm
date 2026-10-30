package Langertha::Raider::MCP::Server;
# ABSTRACT: Internal client of one configured MCP server, mounted as an engine MCP server
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Path::Tiny;
use Scalar::Util qw( weaken );
use Langertha::Raider::MCP::HTTP;
use Langertha::Raider::MCP::Stdio;


has spec => ( is => 'ro', isa => 'HashRef', required => 1 );
has loop => ( is => 'ro', required => 1 );

has max_output_tokens => ( is => 'ro', isa => 'Int', default => 25000 );
has on_tools_changed  => ( is => 'ro', isa => 'Maybe[CodeRef]' );

has startup_timeout_ms => ( is => 'ro', isa => 'Num', default => 30000 );
has base_env           => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
has kill_grace         => ( is => 'ro', isa => 'Num', default => 2 );
has on_status          => ( is => 'ro', isa => 'Maybe[CodeRef]' );

sub _build_base_env { return { %ENV } }


has status           => ( is => 'ro', isa => 'Str', default => 'configured', writer => '_set_status_value' );
has reason           => ( is => 'ro', isa => 'Maybe[Str]', writer => '_set_reason' );
has protocol_version => ( is => 'ro', isa => 'Maybe[Str]', writer => '_set_protocol_version' );
has server_info      => ( is => 'ro', isa => 'HashRef', default => sub { {} }, writer => '_set_server_info' );
has instructions     => ( is => 'ro', isa => 'Maybe[Str]', writer => '_set_instructions' );
has warnings         => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

has _transport => ( is => 'rw', init_arg => undef );
has _start_f   => ( is => 'rw', init_arg => undef );
has _tools     => ( is => 'ro', init_arg => undef, default => sub { [] } );
has _original  => ( is => 'ro', init_arg => undef, default => sub { {} } );
has _caps      => ( is => 'rw', isa => 'HashRef', init_arg => undef, default => sub { {} } );
has _prompts   => ( is => 'rw', init_arg => undef, clearer => '_clear_prompts' );
has _resources => ( is => 'rw', init_arg => undef, clearer => '_clear_resources' );
has _refresh_f => ( is => 'rw', init_arg => undef, clearer => '_clear_refresh_f' );
has _refresh_again => ( is => 'rw', init_arg => undef, default => 0 );


sub name      { $_[0]->spec->{name} }
sub key       { $_[0]->spec->{key} }
sub transport { $_[0]->spec->{transport} }


sub client_protocol_version { '2025-11-25' }
sub known_protocol_versions { qw( 2025-11-25 2025-06-18 2025-03-26 2024-11-05 ) }

sub _set_status {
  my ( $self, $status, $reason ) = @_;
  $self->_set_status_value($status);
  $self->_set_reason($reason);
  $self->on_status->($self) if $self->on_status;
  return;
}


sub fingerprint {
  my ( $self ) = @_;
  my $spec = $self->spec;
  my %what = map { $_ => $spec->{$_} } qw( transport command args cwd project_dir url headers tool_prefix timeout_ms );
  $what{env} = $self->child_env if ( $spec->{transport} // '' ) eq 'stdio';
  return JSON::MaybeXS->new( canonical => 1 )->encode(\%what);
}

sub pid {
  my ( $self ) = @_;
  my $t = $self->_transport or return;
  return unless $t->can('is_running') && $t->is_running;
  return $t->pid;
}


sub stderr_tail {
  my ( $self ) = @_;
  my $t = $self->_transport or return;
  return $t->stderr_tail;
}


sub child_env {
  my ( $self ) = @_;
  my $spec = $self->spec;
  my %env = %{ $self->base_env };
  delete @env{qw( CLAUDE_PLUGIN_ROOT CLAUDE_PLUGIN_DATA )};
  %env = ( %env, %{ $spec->{env} // {} } );
  $env{CLAUDE_PROJECT_DIR} = $spec->{project_dir} if defined $spec->{project_dir};
  if (my $plugin = $spec->{plugin}) {
    $env{CLAUDE_PLUGIN_ROOT} = $plugin->{root};
    $env{CLAUDE_PLUGIN_DATA} = $plugin->{data_dir} if defined $plugin->{data_dir};
  }
  return \%env;
}

sub _build_transport {
  my ( $self ) = @_;
  my $spec = $self->spec;
  weaken( my $weak = $self );
  my $on_notification = sub { $weak->_notified(@_) if $weak };
  if ($spec->{transport} eq 'http') {
    return Langertha::Raider::MCP::HTTP->new(
      loop            => $self->loop,
      url             => $spec->{url},
      headers         => $spec->{headers} // {},
      on_notification => $on_notification,
    );
  }
  croak __PACKAGE__.': cannot connect a '.( $spec->{transport} // 'missing' ).' transport'
    unless ( $spec->{transport} // '' ) eq 'stdio';
  # Claude Code creates the plugin's data directory when its config names it.
  if (my $plugin = $spec->{plugin}) {
    my $raw = JSON::MaybeXS->new( canonical => 1 )->encode($spec->{entry});
    eval { path($plugin->{data_dir})->mkpath } if defined $plugin->{data_dir} && $raw =~ /\$\{CLAUDE_PLUGIN_DATA/;
  }
  return Langertha::Raider::MCP::Stdio->new(
    loop       => $self->loop,
    command    => $spec->{command},
    args       => $spec->{args} // [],
    env        => $self->child_env,
    cwd        => $spec->{cwd},
    kill_grace => $self->kill_grace,
    on_notification => $on_notification,
  );
}


sub initialize { $_[0]->start_f }

sub start_f {
  my ( $self ) = @_;
  return $self->_start_f if $self->_start_f;
  my $spec = $self->spec;
  unless (( $spec->{status} // '' ) eq 'configured') {
    $self->_set_status(failed => 'not startable: '.( $spec->{status} // '?' ));
    return $self->_start_f(Future->done);
  }
  $self->_set_status('starting');
  my $loop = $self->loop;
  my $seconds = $self->startup_timeout_ms / 1000;
  my $connect = $self->_connect_f;
  my $timer = $loop->delay_future( after => $seconds )
    ->then(sub { Future->fail('did not start within '.$self->_seconds_text($seconds).' (MCP_TIMEOUT)') });
  my $f = Future->wait_any($connect, $timer)->then(
    sub {
      $self->_set_status('connected');
      return Future->done;
    },
    sub {
      my ( $error ) = @_;
      $self->_set_status(failed => $self->_failure_text($error));
      # Stopped in the background (the transport holds its timers): the
      # start is over now, not after the kill grace.
      my $t = $self->_transport;
      $t->stop_f->retain if $t;
      return Future->done;
    },
  );
  return $self->_start_f($f);
}

sub _seconds_text {
  my ( $self, $s ) = @_;
  return ( $s == int $s ? $s : sprintf('%.1f', $s) ).' s';
}

# A failure as one line, with how a stdio process ended and its last
# stderr line.
sub _failure_text {
  my ( $self, $error ) = @_;
  my ( $text ) = split /\n/, ''.( $error // 'unknown error' );
  $text =~ s/ at \S+ line \d+\.?\z//;
  my $t = $self->_transport;
  if ($t && $t->can('exited') && $t->exited && $text =~ /\AMCP server process /) {
    $text = $t->exit_text;
  }
  my ( $last ) = reverse $self->stderr_tail;
  $text .= ' (stderr: '.$last.')' if defined $last && index($text, $last) < 0;
  return $text;
}

async sub _connect_f {
  my ( $self ) = @_;
  my $t = $self->_build_transport;
  $self->_transport($t);
  $t->start;
  my $init = await $t->request_f( initialize => {
    protocolVersion => $self->client_protocol_version,
    capabilities    => {},
    clientInfo      => { name => 'raider', version => $VERSION },
  } )->else(sub {
    my ( $error, $category, $detail ) = @_;
    return Future->fail('the server does not answer initialize: it speaks only an MCP revision raider does not '
      .'(2026-07-28 and later need server/discover)')
      if ( $category // '' ) eq 'mcp' && ref $detail eq 'HASH' && ( $detail->{code} // 0 ) == -32601;
    return Future->fail(@_);
  });
  await Future->fail('the initialize answer is not an object') unless ref $init eq 'HASH';
  my $version = $init->{protocolVersion} // '';
  await Future->fail('the server answered with MCP revision '.( length $version ? $version : '(none)' )
    .'; raider speaks '.join(', ', $self->known_protocol_versions))
    unless grep { $_ eq $version } $self->known_protocol_versions;
  $self->_set_protocol_version($version);
  $t->protocol_version($version) if $t->can('protocol_version');
  $self->_set_server_info(ref $init->{serverInfo} eq 'HASH' ? $init->{serverInfo} : {});
  $self->_set_instructions($init->{instructions}) if defined $init->{instructions} && !ref $init->{instructions};
  if ($t->can('notify_f')) { await $t->notify_f('notifications/initialized') }
  else                     { $t->notify('notifications/initialized') }

  my $caps = ref $init->{capabilities} eq 'HASH' ? $init->{capabilities} : {};
  $self->_caps($caps);
  return unless $caps->{tools};
  my @tools = await $self->_paged_f( $t, 'tools/list', 'tools' );
  $self->_add_tools(grep { defined $_->{name} && !ref $_->{name} } @tools);
  return;
}

# All pages of a list method: the hash refs under $key.
async sub _paged_f {
  my ( $self, $t, $method, $key ) = @_;
  my ( @items, %seen_cursor, $cursor );
  for my $page (1 .. 100) {
    my $res = await $t->request_f($method, defined $cursor ? { cursor => $cursor } : {});
    push @items, grep { ref $_ eq 'HASH' } @{ ref $res eq 'HASH' && ref $res->{$key} eq 'ARRAY' ? $res->{$key} : [] };
    $cursor = ref $res eq 'HASH' ? $res->{nextCursor} : undef;
    last unless defined $cursor && !ref $cursor;
    await Future->fail($method.' repeats the cursor '.$cursor) if $seen_cursor{$cursor}++;
  }
  return @items;
}

# A notification from the server.
sub _notified {
  my ( $self, $method ) = @_;
  if ($method eq 'notifications/tools/list_changed') {
    $self->_refresh_tools;
    $self->on_tools_changed->($self) if $self->on_tools_changed;
  }
  elsif ($method eq 'notifications/prompts/list_changed') { $self->_clear_prompts }
  elsif ($method eq 'notifications/resources/list_changed') { $self->_clear_resources }
  return;
}

# List the tools again after tools/list_changed. A failed refresh keeps the
# tools known so far (as Claude Code does); a change that arrives while one
# refresh runs causes one more.
sub _refresh_tools {
  my ( $self ) = @_;
  return unless $self->status eq 'connected';
  return $self->_refresh_again(1) if $self->_refresh_f;
  weaken( my $weak = $self );
  my $f = $self->_paged_f( $self->_transport, 'tools/list', 'tools' )->then(sub {
    return unless $weak;
    my @tools = grep { defined $_->{name} && !ref $_->{name} } @_;
    @{ $weak->_tools } = ();
    %{ $weak->_original } = ();
    @{ $weak->warnings } = grep { !/\Atool .* dropped: / } @{ $weak->warnings };
    $weak->_add_tools(@tools);
    return Future->done;
  })->else(sub {
    push @{ $weak->warnings }, 'tools/list after list_changed failed: '.( split /\n/, ''.( $_[0] // 'error' ) )[0] if $weak;
    return Future->done;
  })->on_ready(sub {
    return unless $weak;
    $weak->_clear_refresh_f;
    if ($weak->_refresh_again) { $weak->_refresh_again(0); $weak->_refresh_tools }
  });
  $self->_refresh_f($f) unless $f->is_ready;
  return;
}

sub _add_tools {
  my ( $self, @tools ) = @_;
  my $prefix = $self->spec->{tool_prefix};
  for my $tool (@tools) {
    ( my $part = $tool->{name} ) =~ s/[^A-Za-z0-9_-]/_/g;
    my $name = $prefix.$part;
    if (exists $self->_original->{$name}) {
      push @{ $self->warnings }, 'tool '.$tool->{name}.' dropped: its name '.$name.' is taken by '.$self->_original->{$name};
      next;
    }
    $self->_original->{$name} = $tool->{name};
    push @{ $self->_tools }, {
      %$tool,
      name        => $name,
      inputSchema => ref $tool->{inputSchema} eq 'HASH' ? $tool->{inputSchema} : { type => 'object', properties => {} },
    };
  }
  return;
}


sub tool_names    { map { $_->{name} } @{ $_[0]->_tools } }
sub original_name { $_[0]->_original->{ $_[1] } }


async sub list_tools {
  my ( $self ) = @_;
  await $self->start_f;
  while (my $refresh = $self->_refresh_f) { await $refresh }   # the answer to tools/list_changed
  return [] unless $self->status eq 'connected';
  return [ map { { %$_ } } @{ $self->_tools } ];
}


sub call_tool {
  my ( $self, $name, $args ) = @_;
  return $self->start_f->then(sub {
    return Future->fail('MCP server '.$self->name.' is not connected ('.$self->status
      .( defined $self->reason ? ': '.$self->reason : '' ).')')
      unless $self->status eq 'connected';
    my $original = $self->original_name($name);
    return Future->fail('MCP server '.$self->name.' has no tool '.$name) unless defined $original;
    my $call = $self->_transport->request_f('tools/call', { name => $original, arguments => $args // {} });
    if (defined( my $ms = $self->spec->{timeout_ms} )) {
      my $seconds = $ms / 1000;
      my $timer = $self->loop->delay_future( after => $seconds )
        ->then(sub { Future->fail('MCP tool call timed out after '.$self->_seconds_text($seconds)) });
      $call = Future->wait_any($call, $timer);
    }
    return $call->then(sub { Future->done($self->_clean_result($_[0])) });
  });
}


sub limit_content {
  my ( $self, $content, $is_error ) = @_;
  my @text = grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'text' && defined $_->{text} && !ref $_->{text} } @$content;
  if ($is_error) {
    return [ map {
      my $b = $_;
      ( ref $b eq 'HASH' && ( $b->{type} // '' ) eq 'text' && defined $b->{text} && !ref $b->{text} && length $b->{text} > 11000 )
        ? { %$b, text => substr($b->{text}, 0, 5000)
              ."\n[... ".( length($b->{text}) - 10000 )." characters removed ...]\n"
              .substr($b->{text}, -5000) }
        : $b
    } @$content ];
  }
  return $content if grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'image' } @$content;
  my $limit = $self->max_output_tokens * 4;
  my $total = 0;
  $total += length $_->{text} for @text;
  return $content if $total <= $limit;
  my $left = $limit;
  my @out;
  for my $b (@$content) {
    unless (ref $b eq 'HASH' && ( $b->{type} // '' ) eq 'text' && defined $b->{text} && !ref $b->{text}) {
      push @out, $b;
      next;
    }
    next if $left <= 0;
    if (length $b->{text} > $left) {
      push @out, { %$b, text => substr($b->{text}, 0, $left) };
      $left = 0;
    }
    else {
      push @out, $b;
      $left -= length $b->{text};
    }
  }
  push @out, { type => 'text', text => '[MCP tool output truncated: about '.int(($total + 3) / 4)
    .' tokens, the limit is '.$self->max_output_tokens.' tokens (MAX_MCP_OUTPUT_TOKENS). '
    .'Ask the tool for less (filter, paginate), or raise MAX_MCP_OUTPUT_TOKENS.]' };
  return \@out;
}


sub has_prompts   { $_[0]->status eq 'connected' && $_[0]->_caps->{prompts}   ? 1 : 0 }
sub has_resources { $_[0]->status eq 'connected' && $_[0]->_caps->{resources} ? 1 : 0 }

async sub list_prompts_f {
  my ( $self ) = @_;
  await $self->start_f;
  return [] unless $self->has_prompts;
  unless ($self->_prompts) {
    my @items;
    return [] unless eval { @items = await $self->_paged_f( $self->_transport, 'prompts/list', 'prompts' ); 1 };
    $self->_prompts([ grep { defined $_->{name} && !ref $_->{name} } @items ]);
  }
  return [ map { { %$_ } } @{ $self->_prompts } ];
}

async sub list_resources_f {
  my ( $self ) = @_;
  await $self->start_f;
  return [] unless $self->has_resources;
  unless ($self->_resources) {
    my @items;
    return [] unless eval { @items = await $self->_paged_f( $self->_transport, 'resources/list', 'resources' ); 1 };
    $self->_resources([ grep {
      defined $_->{uri} && !ref $_->{uri} && $_->{uri} !~ m{\Aui://}i
        && ( $_->{mimeType} // '' ) !~ m{\Atext/html;\s*profile=mcp-app}i
    } @items ]);
  }
  return [ map { { %$_ } } @{ $self->_resources } ];
}

sub _bounded_f {
  my ( $self, $call ) = @_;
  if (defined( my $ms = $self->spec->{timeout_ms} )) {
    my $seconds = $ms / 1000;
    my $timer = $self->loop->delay_future( after => $seconds )
      ->then(sub { Future->fail('MCP call timed out after '.$self->_seconds_text($seconds)) });
    return Future->wait_any($call, $timer);
  }
  return $call;
}

async sub get_prompt_f {
  my ( $self, $name, $args ) = @_;
  await $self->start_f;
  await Future->fail('MCP server '.$self->name.' is not connected') unless $self->has_prompts;
  my $res = await $self->_bounded_f($self->_transport->request_f('prompts/get',
    { name => $name, arguments => { map { $_ => ''.$args->{$_} } keys %{ $args // {} } } }));
  return ref $res eq 'HASH' ? $res : { messages => [] };
}

async sub read_resource_f {
  my ( $self, $uri ) = @_;
  await $self->start_f;
  await Future->fail('MCP server '.$self->name.' is not connected') unless $self->has_resources;
  my $res = await $self->_bounded_f($self->_transport->request_f('resources/read', { uri => $uri }));
  return [ grep { ref $_ eq 'HASH' } @{ ref $res eq 'HASH' && ref $res->{contents} eq 'ARRAY' ? $res->{contents} : [] } ];
}

# The result without _meta keys of raider's own namespace, its text cut to
# the output limit.
sub _clean_result {
  my ( $self, $result ) = @_;
  return { content => [] } unless ref $result eq 'HASH';
  my %r = %$result;
  $r{content} = [] unless ref $r{content} eq 'ARRAY';
  $r{content} = $self->limit_content( $r{content}, $r{isError} ? 1 : 0 );
  if (ref $r{_meta} eq 'HASH') {
    my %meta = map { $_ => $r{_meta}{$_} } grep { !m{\Araider/} } keys %{ $r{_meta} };
    if (%meta) { $r{_meta} = \%meta } else { delete $r{_meta} }
  }
  return \%r;
}


sub stop_f {
  my ( $self ) = @_;
  my $t = $self->_transport;
  my $was = $self->status;
  $self->_start_f->cancel if $self->_start_f && !$self->_start_f->is_ready;
  $self->_set_status(stopped => $was eq 'failed' ? $self->reason : undef) unless $was eq 'stopped';
  return $t ? $t->stop_f->else_done : Future->done;
}


sub kill_now {
  my ( $self ) = @_;
  my $t = $self->_transport or return;
  $t->kill_now if $t->can('kill_now');
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::MCP::Server - Internal client of one configured MCP server, mounted as an engine MCP server

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $server = Langertha::Raider::MCP::Server->new(
      spec => $mcp_config->server('github'),   # an entry of Langertha::Raider::MCP::Config
      loop => $loop,
    );
    await $server->initialize;                 # never fails: status connected or failed
    say $server->status.': '.( $server->reason // '' );
    my $tools  = await $server->list_tools;    # names mcp__github__*
    my $result = await $server->call_tool( 'mcp__github__create_issue', \%args );
    await $server->stop_f;

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

One configured MCP server (ADR 0029 E<sect>10) as raider mounts it: an
object that answers C<initialize>, C<list_tools> and C<call_tool> like
L<Net::Async::MCP>, so it is one more entry of the engine's C<mcp_servers>
and L<Langertha::Raider> calls it as it calls every other.

=over

=item * B<Start.> L</start_f> (and L</initialize>) connects once: the
transport (L<Langertha::Raider::MCP::Stdio> or
L<Langertha::Raider::MCP::HTTP>), the C<initialize> handshake, the
C<notifications/initialized> notification and the tool list, all within
L</startup_timeout_ms>. It never fails: L</status> becomes C<connected>, or
C<failed> with L</reason>; a stdio process of a failed start is stopped.

=item * B<Protocol.> Raider speaks the established handshake of the MCP
revisions 2024-11-05 to 2025-11-25: it asks for L</client_protocol_version>
and accepts any revision of L</known_protocol_versions> the server answers
with. The stateless 2026-07-28 revision (C<server/discover>) is not spoken;
a server that knows only that one fails with a reason that says so. The
installed L<Net::Async::MCP> speaks only that revision, which is why raider
has its own client here (ADR 0029).

=item * B<Tools.> The server's tools are listed once, at the start, under
the names the model sees: C<mcp__KEY__TOOL> with the tool part normalised
(L<Langertha::Raider::MCP::Config/tool_name>). Two tools that normalise to
the same name: the first is kept. L</call_tool> sends the original name.

=item * B<Calls> are bounded by the server's C<timeout_ms> (its C<timeout>,
else C<MCP_TOOL_TIMEOUT>); a call that runs out is cancelled
(C<notifications/cancelled>) and fails. A result keeps what the server sent,
except C<_meta> keys under C<raider/>: a foreign server cannot hand the
raider instructions through them (L<Langertha::Raider> takes user messages
from C<_meta.raider/messages> of its own sources).

=back

=head2 spec

The server's entry of L<Langertha::Raider::MCP::Config/servers>. Required.

=head2 loop

The L<IO::Async::Loop>. Required.

=head2 startup_timeout_ms

How long the start may take, in milliseconds. Default 30000.

=head2 base_env

The environment a stdio server inherits (before its own C<env>). Default a
copy of C<%ENV>.

=head2 kill_grace

Seconds between closing a stdio server's stdin, C<TERM> and C<KILL>.
Default 2.

=head2 on_status

C<< sub { my ( $server ) = @_; ... } >>, called whenever L</status>
changes. Optional.

=head2 max_output_tokens

How many tokens (about four characters each) of a tool result's text raider
passes on; more is cut with a note (ADR 0029 Addendum 1). Default 25000
(C<MAX_MCP_OUTPUT_TOKENS>).

=head2 on_tools_changed

C<< sub { my ( $server ) = @_; ... } >>, called when the server announced
C<notifications/tools/list_changed>, at once: the tools are listed again
in the background, and L</list_tools> waits for that. Optional.

=head2 status

C<configured> before the start, C<starting>, then C<connected> or
C<failed>; C<stopped> after L</stop_f>.

=head2 reason

Why it failed (or stopped), with the last stderr line of a stdio server.

=head2 protocol_version

The revision the server answered with.

=head2 server_info

The server's C<serverInfo> (C<name>, C<version>), or C<{}>.

=head2 instructions

The server's C<instructions>, or C<undef>.

=head2 warnings

What went wrong without stopping the server: a tool dropped because its
name collides, ...

=head2 name

=head2 key

=head2 transport

The server's C<name>, C<key> and C<transport> from L</spec>.

=head2 client_protocol_version

The revision raider asks for in C<initialize>: C<2025-11-25>.

=head2 known_protocol_versions

The revisions raider accepts in the answer: C<2025-11-25>, C<2025-06-18>,
C<2025-03-26>, C<2024-11-05>. They differ in features raider does not use;
the handshake, C<tools/list> and C<tools/call> are the same in all of them.

=head2 fingerprint

What the server is started with, as one string: the transport, the
command, arguments, working and project directory and the whole
environment of a stdio server, the URL and headers of an HTTP one, the tool
prefix and the call timeout. Two clients with the same fingerprint talk to
the same thing (C</reload> keeps such a client).

=head2 pid

The process id of a running stdio server, else C<undef>.

=head2 stderr_tail

The last lines a stdio server wrote to stderr.

=head2 child_env

The environment a stdio server is started with: L</base_env> without
inherited C<CLAUDE_PLUGIN_ROOT> / C<CLAUDE_PLUGIN_DATA>, then the entry's
C<env>, then C<CLAUDE_PROJECT_DIR> (the project dir, as Claude Code sets
it) and, for a plugin's server, its C<CLAUDE_PLUGIN_ROOT> and
C<CLAUDE_PLUGIN_DATA>.

=head2 start_f

    await $server->start_f;

Connects once (see L</DESCRIPTION>); every later call returns the same
future. Never fails.

=head2 initialize

The same as L</start_f>, under the name L<Langertha::Raider::Application>
calls on every engine MCP server before a raid.

=head2 tool_names

The names the model sees (C<mcp__KEY__TOOL>), in the server's order.

=head2 original_name

    my $name = $server->original_name('mcp__github__create_issue');   # create_issue

The tool's name on the server, or C<undef> for a name it does not offer.

=head2 list_tools

    my $tools = await $server->list_tools;

The tools under their prefixed names (after the start; empty unless
C<connected>), each a copy of the server's definition. While the server's
answer to a C<notifications/tools/list_changed> is being fetched, it waits
for it.

=head2 call_tool

    my $result = await $server->call_tool( 'mcp__github__create_issue', \%args );

Calls the tool by its original name, bounded by C<timeout_ms> of the
L</spec>. Fails when the server is not connected, the name is unknown, the
server answers with a JSON-RPC error, the process is gone or the time is up
(C<MCP tool call timed out after N s>).

=head2 limit_content

    my $content = $server->limit_content( $result->{content}, $is_error );

The content blocks of a tool result with their text held to
L</max_output_tokens> (four characters count as a token, as a rough
estimate): text over the limit is cut and a note block says how much there
was and how to raise the limit. A result with an image block is passed on
as it is, as Claude Code does not cut it either. An error result whose
text is over about 11000 characters keeps its first and last 5000, with a
marker between them that says how many characters were removed (Claude
Code's rule). Claude Code saves the whole text to a file and names the
path; raider keeps no such file and cuts.

=head2 has_prompts

=head2 has_resources

True when the connected server announced the C<prompts> / C<resources>
capability.

=head2 list_prompts_f

    my $prompts = await $server->list_prompts_f;   # [ { name, description, arguments => [ { name, required } ] } ]

The server's prompts, listed on first use and again after
C<notifications/prompts/list_changed>. Empty unless connected; a failing
C<prompts/list> is an empty list.

=head2 get_prompt_f

    my $prompt = await $server->get_prompt_f( 'pr_review', { number => '456' } );
    # { description => ..., messages => [ { role => 'user', content => { type => 'text', text => ... } } ] }

C<prompts/get>, with the same call timeout as a tool. Fails when the
server is not connected or answers with an error.

=head2 list_resources_f

    my $resources = await $server->list_resources_f;   # [ { uri, name, mimeType, description } ]

The server's resources (C<resources/list>), cached like the prompts;
C<ui://> resources and those of media type C<text/html;profile=mcp-app>
are left out (Claude Code does the same).

=head2 read_resource_f

    my $contents = await $server->read_resource_f('file:///a');   # [ { uri, mimeType, text | blob } ]

C<resources/read>.

=head2 stop_f

    await $server->stop_f;

Stops the server: a stdio process as L<Langertha::Raider::MCP::Stdio/stop_f>,
an HTTP session with C<DELETE>. Status C<stopped>.

=head2 kill_now

Kills a stdio process at once.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::MCP>

=item * L<Langertha::Raider::MCP::Config>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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

L<https://raudssus.de/>

=cut

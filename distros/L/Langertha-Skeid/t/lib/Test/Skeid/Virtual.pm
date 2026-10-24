package Test::Skeid::Virtual;
# ABSTRACT: A real Skeid proxy whose nodes are Langertha::Virtual::Server processes
use strict;
use warnings;
use Carp ();
use Exporter 'import';
use JSON::MaybeXS ();
use Mojo::UserAgent;
use Path::Tiny;
use Test::Mojo;
use YAML::PP;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

our @EXPORT_OK = qw( virtual_available skeid_virtual );

=head1 SYNOPSIS

    use Test::Skeid::Virtual qw( skeid_virtual );

    my $sv = skeid_virtual(
      nodes => [ { id => 'gpu1', model => 'qwen', upstream => { fallback => { answer => 'Hi!' } } } ],
    );
    my $res = $sv->chat( openai => model => 'qwen', prompt => 'x' );
    $res->{text};                      # Hi!
    $sv->upstream_requests('gpu1');    # what the node's Virtual engine saw

=head1 DESCRIPTION

Every entry of C<nodes> becomes a L<Langertha::Virtual::Server> in its own
process (C<spawn>, C<debug> on), answering by the rules of the entry's
C<upstream> (the rules-file format of L<Langertha::Engine::Virtual>: C<rules>,
C<after>, C<fallback>, C<script>; a reaction C<< { error: { status, message } } >>
makes the node fail like a server). The Skeid proxy runs in this process, served
by C<Test::Mojo>; the upstreams are other processes, so the blocking client and
the event loop of the proxy never wait on each other. No network beyond
loopback, no key.

=cut

sub virtual_available { eval { require Langertha::Engine::Virtual; require Langertha::Virtual::Server; 1 } ? 1 : 0 }

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

=func skeid_virtual

    my $sv = skeid_virtual(
      nodes     => [ { id, model, tags, max_conns, weight, upstream => \%rules, ... } ],
      config    => \%skeid_config,   # aliases, policies, keys, routing, registry, ...
      clients   => { alice => 'sk-alice' },   # name => key; "@alice" in config.keys is its key id
      admin_key => $key,
    );

Node entries are passed to the Skeid config as they are, minus C<upstream>,
C<stream_chunk_size> and C<default_usage> (both go to the node's Virtual engine), with
C<url> and C<engine: openai> filled in. In C<config>, a key of C<keys> written
C<@name> is replaced by the customer key id of C<clients>' C<name>.

=cut

sub skeid_virtual {
  my ( %opt ) = @_;
  virtual_available() or Carp::croak("Test::Skeid::Virtual needs Langertha::Virtual::Server");
  my ( %pid, %url, @keep );
  my @nodes;
  for my $n ( @{ $opt{nodes} // [] } ) {
    my %node = %$n;
    my $spec = delete $node{upstream} // { fallback => { answer => 'ok' } };
    my %engine_opt = map { exists $node{$_} ? ( $_ => delete $node{$_} ) : () } qw( stream_chunk_size default_usage );
    my $file = Path::Tiny->tempfile( SUFFIX => '.yml' );
    $file->spew_utf8( YAML::PP->new->dump_string($spec) );
    push @keep, $file;
    my $engine = Langertha::Engine::Virtual->new( rules_file => "$file", langfuse_enabled => 0, %engine_opt );
    my ( $pid, $url ) = Langertha::Virtual::Server->spawn( engine => $engine, debug => 1 );
    $pid{ $node{id} } = $pid;
    $url{ $node{id} } = $url;
    push @nodes, { engine => 'openai', %node, url => $url };
  }

  my %ids = map { $_ => Langertha::Skeid->key_id_for_key( $opt{clients}{$_} ) } keys %{ $opt{clients} // {} };
  my $config = { %{ $opt{config} // {} }, nodes => \@nodes };
  if ( my $keys = $config->{keys} ) {
    $config->{keys} = { map { my $k = $_; ( $k =~ /\A@(.+)\z/ ? ( $ids{$1} // Carp::croak("no client '$1'") ) : $k ) => $keys->{$_} } keys %$keys };
  }
  $config->{routing} = { wait_timeout_ms => 50, wait_poll_ms => 5, %{ $config->{routing} // {} } };
  $config->{admin} = { api_key => $opt{admin_key} } if defined $opt{admin_key};

  my @events;
  my $skeid = Langertha::Skeid->new(
    config_loader          => sub { $config },
    config_reload_interval => 0,
    store_usage_event      => sub { push @events, $_[1]; return { ok => 1 } },
  );
  my $app = Langertha::Skeid::Proxy->build_app( skeid => $skeid );
  $app->log->level('fatal');
  $app->mode('production');

  return bless {
    t => Test::Mojo->new($app), skeid => $skeid, events => \@events, pid => \%pid, url => \%url,
    ua => Mojo::UserAgent->new, keep => \@keep, owner => $$,
  }, __PACKAGE__;
}

sub skeid  { $_[0]{skeid} }
sub events { @{ $_[0]{events} } }

=method upstream_requests

    $sv->upstream_requests($node_id)   # [ { model, last_user_text, tools, body, ... } ] as the node's engine saw them

=cut

sub upstream_requests {
  my ( $self, $id ) = @_;
  my $url = $self->{url}{$id} or Carp::croak("no node '$id'");
  ( my $base = $url ) =~ s{/v1\z}{};
  my $res = $self->{ua}->get("$base/_virtual/requests")->result;
  return $res->json->{requests} // [];
}

=method http

    my $res = $sv->http( METHOD => $path, bearer => $k, headers => {...}, body => \%or_string );

Returns C<< { status, headers, raw, body (decoded JSON or undef) } >>.

=cut

sub http {
  my ( $self, $method, $path, %o ) = @_;
  my %h = %{ $o{headers} // {} };
  $h{Authorization} = 'Bearer ' . $o{bearer} if defined $o{bearer};
  my $tx = $self->{t}->ua->build_tx( $method => $path => \%h =>
    ( defined $o{body} ? ( ref $o{body} ? ( json => $o{body} ) : ( $o{body} ) ) : () ) );
  $tx = $self->{t}->ua->start($tx);
  my $res = $tx->res;
  my $raw = $res->body // '';
  return {
    status  => $res->code // 0,
    headers => { map { lc $_ => $res->headers->header($_) } @{ $res->headers->names } },
    raw     => $raw,
    body    => scalar( eval { $json->decode($raw) } ),
  };
}

my %PROTOCOL = (
  openai => {
    path => '/v1/chat/completions',
    body => sub { +{ model => $_[0]{model}, messages => [ { role => 'user', content => $_[0]{prompt} } ],
      ( $_[0]{stream} ? ( stream => JSON::MaybeXS::true(),
        ( $_[0]{include_usage} ? ( stream_options => { include_usage => JSON::MaybeXS::true() } ) : () ) ) : () ) } },
    read => sub { my $b = shift; +{ text => $b->{choices}[0]{message}{content}, model => $b->{model},
      finish_reason => $b->{choices}[0]{finish_reason} } },
    stream => sub {
      my $r = {};
      for my $c (@_) {
        $r->{model} //= $c->{model};
        $r->{usage} = $c->{usage} if $c->{usage};
        my $ch = $c->{choices}[0] or next;
        if ( defined $ch->{delta}{content} && length $ch->{delta}{content} ) { $r->{text} .= $ch->{delta}{content}; $r->{events}++ }
        $r->{finish_reason} = $ch->{finish_reason} if $ch->{finish_reason};
      }
      return $r;
    },
  },
  anthropic => {
    path => '/v1/messages',
    body => sub { +{ model => $_[0]{model}, max_tokens => 64, messages => [ { role => 'user', content => $_[0]{prompt} } ],
      ( $_[0]{stream} ? ( stream => JSON::MaybeXS::true() ) : () ) } },
    read => sub { my $b = shift; +{ text => join( '', map { $_->{text} } grep { $_->{type} eq 'text' } @{ $b->{content} // [] } ),
      model => $b->{model}, finish_reason => $b->{stop_reason} } },
    stream => sub {
      my $r = {};
      for my $c (@_) {
        next unless ref $c;
        if ( $c->{type} eq 'message_start' ) { $r->{model} = $c->{message}{model}; $r->{usage}{$_} = $c->{message}{usage}{$_} for keys %{ $c->{message}{usage} // {} } }
        elsif ( $c->{type} eq 'content_block_delta' && length( $c->{delta}{text} // '' ) ) { $r->{text} .= $c->{delta}{text}; $r->{events}++ }
        elsif ( $c->{type} eq 'message_delta' ) {
          $r->{finish_reason} = $c->{delta}{stop_reason};
          $r->{usage}{$_} = $c->{usage}{$_} for keys %{ $c->{usage} // {} };
        }
        elsif ( $c->{type} eq 'message_stop' ) { $r->{stopped} = 1 }
      }
      return $r;
    },
  },
  ollama => {
    path => '/api/chat',
    body => sub { +{ model => $_[0]{model}, stream => ( $_[0]{stream} ? JSON::MaybeXS::true() : JSON::MaybeXS::false() ),
      messages => [ { role => 'user', content => $_[0]{prompt} } ] } },
    read => sub { my $b = shift; +{ text => $b->{message}{content}, model => $b->{model}, finish_reason => $b->{done_reason} } },
    stream => sub {
      my $r = {};
      for my $c (@_) {
        $r->{model} //= $c->{model};
        if ( length( $c->{message}{content} // '' ) ) { $r->{text} .= $c->{message}{content}; $r->{events}++ }
        next unless $c->{done};
        $r->{stopped} = 1;
        $r->{finish_reason} = $c->{done_reason};
        $r->{usage} = { map { $_ => $c->{$_} } grep { defined $c->{$_} } qw( prompt_eval_count eval_count ) };
      }
      return $r;
    },
  },
);

=method chat

    my $res = $sv->chat( openai|anthropic|ollama => model => ..., prompt => ..., bearer => ..., headers => ... );

C<http> extended with C<text>, C<model>, C<finish_reason> read from a 200 answer.

With C<< stream => 1 >> the request asks for a stream (OpenAI's also C<< include_usage => 1 >>
for C<stream_options.include_usage>) and the answer is read event by event: the same keys,
plus C<body>, replaced by C<< { events => the content events, usage => what the stream
reported (OpenAI's usage chunk, Anthropic's message_start/message_delta usage, Ollama's
prompt_eval_count/eval_count), stopped => 1 when the stream ended properly } >> so the
runner's C<json:> paths reach it.

=cut

sub chat {
  my ( $self, $proto, %o ) = @_;
  my $p = $PROTOCOL{$proto} or Carp::croak("unknown protocol '$proto'");
  my $res = $self->http( POST => $p->{path}, ( map { $_ => $o{$_} } grep { defined $o{$_} } qw( bearer headers ) ),
    body => $p->{body}->( \%o ) );
  if ( $o{stream} && $res->{status} == 200 ) {
    my ( @chunks, $done );
    for my $line ( split /\r?\n/, $res->{raw} ) {
      $line =~ s/\Adata:\s?// or $line =~ /\A\s*\{/ or next;
      if ( $line eq '[DONE]' ) { $done = 1; next }
      my $c = eval { $json->decode($line) };
      push @chunks, $c if ref $c;
    }
    my $r = $p->{stream}->(@chunks);
    $r->{stopped} = 1 if $done;
    $res->{body} = { map { $_ => $r->{$_} } grep { defined $r->{$_} } qw( events usage stopped ) };
    $res->{body}{events} //= 0;
    $res->{$_} = $r->{$_} for qw( text model finish_reason );
  }
  elsif ( $res->{status} == 200 && ref $res->{body} ) { %$res = ( %$res, %{ $p->{read}->( $res->{body} ) } ) }
  return $res;
}

sub DESTROY {
  my ( $self ) = @_;
  return unless ( $self->{owner} // 0 ) == $$;
  Langertha::Virtual::Server->reap($_) for values %{ $self->{pid} // {} };
}

1;

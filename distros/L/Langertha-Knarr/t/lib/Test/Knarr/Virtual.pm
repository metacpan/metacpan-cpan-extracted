package Test::Knarr::Virtual;
# ABSTRACT: A real Knarr over loopback with Langertha::Engine::Virtual as its backend
use strict;
use warnings;
use Carp ();
use Exporter 'import';
use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;
use Path::Tiny;
use YAML::PP;

use Langertha::Knarr;
use Langertha::Knarr::Admin;
use Langertha::Knarr::Config;
use Langertha::Knarr::Stack;
use Langertha::Knarr::RequestLog;

our @EXPORT_OK = qw( virtual_available knarr_virtual );

=head1 SYNOPSIS

    use Test::Knarr::Virtual qw( knarr_virtual );

    my $kv = knarr_virtual(
      config   => { models => { fast => { engine => 'KnarrVirtual', model => 'v1' } } },
      backends => { v1 => { rules => { Hello => { answer => 'Hi!' } } } },
    );
    my $res = $kv->chat( openai => model => 'fast', prompt => 'Hello' );
    $res->{text};                    # Hi!
    $kv->backend('v1')->requests;    # what the backend engine saw

=head1 DESCRIPTION

Builds what C<knarr start> builds -- Config, Stack, Admin, Knarr -- and
serves it on an ephemeral loopback port. The backend of every model is a
C<LangerthaX::Engine::KnarrVirtual>, a L<Langertha::Engine::Virtual> that
takes its rules from the C<backends> map by the model it was built for (the
model the config names under C<model:>, else the name the client asked for;
C<*> is the fallback entry). A backend entry is the rules-file format of the
Virtual engine: C<rules>, C<after>, C<fallback> or C<script>, plus
C<engine_args>, constructor arguments of the engine itself
(C<stream_chunk_size>, C<default_usage>, C<no_streaming> for an engine that
cannot stream). No network, no
key. The C<engine:> of a model in the config is written C<KnarrVirtual>.

=cut

sub virtual_available { eval { require Langertha::Engine::Virtual; 1 } ? 1 : 0 }

our ( %BACKENDS, %ENGINES );

if (virtual_available()) {
  package LangerthaX::Engine::KnarrVirtual;
  use Moose;
  extends 'Langertha::Engine::Virtual';

  around BUILDARGS => sub {
    my ( $orig, $class, @args ) = @_;
    my $args  = @args == 1 ? { %{ $args[0] } } : { @args };
    my $model = $args->{model} // '*';
    my $spec  = $BACKENDS{$model} // $BACKENDS{'*'}
      or Carp::croak("Test::Knarr::Virtual: no backend for model '$model'");
    $spec = { %$spec };
    my $engine_args = delete $spec->{engine_args} // {};
    my $file = Path::Tiny->tempfile( SUFFIX => '.yml' );
    $file->spew_utf8( YAML::PP->new->dump_string($spec) );
    $Test::Knarr::Virtual::KEEP{ $file->stringify } = $file;
    return $class->$orig( %$engine_args, %$args, langfuse_enabled => 0, rules_file => $file->stringify );
  };
  # engine_args: { no_streaming: 1 } = an engine that cannot stream (supports('streaming') is false)
  has no_streaming => ( is => 'ro', isa => 'Bool', default => 0 );
  around supports => sub {
    my ( $orig, $self, $cap, @rest ) = @_;
    return 0 if $self->no_streaming && $cap eq 'streaming';
    return $self->$orig( $cap, @rest );
  };
  after BUILD => sub { my ( $self, $args ) = @_; push @{ $ENGINES{ $args->{model} // '*' } }, $self };
  __PACKAGE__->meta->make_immutable;
  $INC{'LangerthaX/Engine/KnarrVirtual.pm'} = __FILE__;
}

our %KEEP;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new;
$loop->add($http);

=func knarr_virtual

    my $kv = knarr_virtual(
      config        => \%knarr_config,   # models, default, proxy_api_key, ...
      backends      => \%by_model,
      admin_key     => $key,             # admin routes on
      remote_config => 1,                # start without a setup (503 until PUT)
      request_log   => 1,                # a JSONL request log (see log_entries)
    );

=cut

sub knarr_virtual {
  my ( %opt ) = @_;
  %BACKENDS = %{ $opt{backends} // {} };
  %ENGINES  = ();
  my $data = { %{ $opt{config} // {} } };
  my $log;
  if ( $opt{request_log} ) {
    $log = Path::Tiny->tempfile( SUFFIX => '.jsonl' );
    $data->{logging} = { file => "$log" };
  }
  my $config = Langertha::Knarr::Config->new( data => $data );
  my $rlog   = $log ? Langertha::Knarr::RequestLog->new( config => $config ) : undef;
  my $stack  = Langertha::Knarr::Stack->new(
    config => $config, loop => $loop, ( $rlog ? ( request_log => $rlog ) : () ) );
  my $admin = defined $opt{admin_key} ? Langertha::Knarr::Admin->new(
    key => $opt{admin_key}, stack => $stack, remote_config => $opt{remote_config} // 0 ) : undef;
  my $knarr = Langertha::Knarr->new(
    loop    => $loop,
    port    => 0,
    handler => $stack->handler,
    router  => $stack->router,
    ( defined $stack->auth_token ? ( auth_token => $stack->auth_token ) : () ),
    ( $admin ? ( admin => $admin ) : () ),
  );
  $knarr->start;
  return bless {
    knarr => $knarr,
    port  => $knarr->_server->read_handle->sockport,
    log   => $log,
  }, __PACKAGE__;
}

sub port { $_[0]{port} }

=method backend

    $kv->backend($model)   # the Virtual engine built for that model (last one)

=cut

sub backend { my ( $self, $model ) = @_; return ( $ENGINES{$model} // [] )->[-1] }

sub log_entries {
  my ( $self ) = @_;
  return () unless $self->{log} && $self->{log}->exists;
  return map { $json->decode($_) } grep { length } $self->{log}->lines_utf8( { chomp => 1 } );
}

=method http

    my $res = $kv->http( METHOD => $path, bearer => $k, xkey => $k, body => \%or_string );

Returns C<< { status, headers, body (decoded JSON or undef), raw } >>.

=cut

sub http {
  my ( $self, $method, $path, %o ) = @_;
  my $req = HTTP::Request->new( $method => 'http://127.0.0.1:'.$self->port.$path );
  $req->header( Authorization => 'Bearer '.$o{bearer} ) if defined $o{bearer};
  $req->header( 'x-api-key' => $o{xkey} ) if defined $o{xkey};
  if ( defined $o{body} ) {
    my $body = ref $o{body} ? $json->encode( $o{body} ) : $o{body};
    $req->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $req->content($body);
  }
  my $resp = $http->do_request( request => $req )->get;
  my $raw  = $resp->decoded_content // '';
  return {
    status  => $resp->code,
    headers => { map { lc $_ => scalar $resp->header($_) } $resp->header_field_names },
    raw     => $raw,
    body    => scalar( eval { $json->decode($raw) } ),
  };
}

# --- the protocols: request shape and the reading of the answer ---

sub _tools_for {
  my ( $proto, $tools ) = @_;
  return () unless $tools && @$tools;
  return ( tools => [ map { {
    type     => 'function',
    function => { name => $_->{name}, description => $_->{description} // $_->{name},
                  parameters => $_->{parameters} // { type => 'object', properties => {} } },
  } } @$tools ] ) if $proto eq 'openai' || $proto eq 'ollama';
  return ( tools => [ map { {
    name => $_->{name}, description => $_->{description} // $_->{name},
    input_schema => $_->{parameters} // { type => 'object', properties => {} },
  } } @$tools ] );
}

# The token counts of an answer as { input, output }; undef when it has none.
sub _usage {
  my ( $u, $in, $out ) = @_;
  return undef unless ref $u eq 'HASH' && ( defined $u->{$in} || defined $u->{$out} );
  return { input => $u->{$in} // 0, output => $u->{$out} // 0 };
}

# A streamed answer read frame by frame: the text, the number of content
# frames, the finish reason, the token usage if a frame carries one, and
# whether the stream ends with the protocol's exact end marker.
sub _sse_frames {
  my ( $raw ) = @_;
  return map {
    my %f;
    for my $line ( split /\n/ ) {
      $f{event} = $1 if $line =~ /\Aevent: (.*)/;
      $f{data} = ( $f{data} // '' ).$1 if $line =~ /\Adata: (.*)/;
    }
    \%f;
  } grep { length } split /\n\n/, $raw;
}

my %STREAM_READ = (
  openai => sub { my ( $raw ) = @_;
    my @f = _sse_frames($raw);
    my @calls;
    my %r = ( text => '', chunks => 0, ended => ( @f && ( $f[-1]{data} // '' ) eq '[DONE]' && $raw =~ /data: \[DONE\]\n\n\z/ ? 1 : 0 ) );
    for my $f ( grep { ( $_->{data} // '[DONE]' ) ne '[DONE]' } @f ) {
      my $d = $json->decode( $f->{data} );
      my $c = $d->{choices}[0] // {};
      if ( length( $c->{delta}{content} // '' ) ) { $r{text} .= $c->{delta}{content}; $r{chunks}++ }
      $r{finish_reason} = $c->{finish_reason} if defined $c->{finish_reason};
      $r{usage} = _usage( $d->{usage}, qw( prompt_tokens completion_tokens ) ) if $d->{usage};
      for my $t ( @{ $c->{delta}{tool_calls} // [] } ) {
        my $call = $calls[ $t->{index} // 0 ] //= { name => '', json => '' };
        $call->{name} .= $t->{function}{name} // '';
        $call->{json} .= $t->{function}{arguments} // '';
      }
    }
    $r{tool_calls} = [ map { { name => $_->{name}, args => $json->decode( $_->{json} ) } } @calls ];
    return \%r },
  anthropic => sub { my ( $raw ) = @_;
    my @f = _sse_frames($raw);
    my @calls;
    my %r = ( text => '', chunks => 0, ended => ( @f && ( $f[-1]{event} // '' ) eq 'message_stop' && $raw =~ /event: message_stop\ndata: [^\n]*\n\n\z/ ? 1 : 0 ) );
    for my $f (@f) {
      my $d = $json->decode( $f->{data} // '{}' );
      if ( ( $f->{event} // '' ) eq 'content_block_delta' && length( $d->{delta}{text} // '' ) ) {
        $r{text} .= $d->{delta}{text}; $r{chunks}++;
      }
 push @calls, { name => $d->{content_block}{name}, json => '' }
        if ( $f->{event} // '' ) eq 'content_block_start' && ( $d->{content_block}{type} // '' ) eq 'tool_use';
      $calls[-1]{json} .= $d->{delta}{partial_json}
        if ( $f->{event} // '' ) eq 'content_block_delta' && defined $d->{delta}{partial_json};
      $r{finish_reason} = $d->{delta}{stop_reason} if ( $f->{event} // '' ) eq 'message_delta' && defined $d->{delta}{stop_reason};
      if ( ( $f->{event} // '' ) =~ /\Amessage_(?:start|delta)\z/ ) {
        my $u = $d->{usage} // $d->{message}{usage};
        my $n = _usage( $u, qw( input_tokens output_tokens ) );
        $r{usage} = $n if $n && ( $n->{input} || $n->{output} );
      }
    }
    $r{tool_calls} = [ map { { name => $_->{name}, args => $json->decode( $_->{json} || '{}' ) } } @calls ];
    return \%r },
  ollama => sub { my ( $raw ) = @_;
    my @l = map { $json->decode($_) } grep { length } split /\n/, $raw;
    my %r = ( text => '', chunks => 0, ended => ( @l && $l[-1]{done} && $raw =~ /\n\z/ && !( grep { $_->{done} } @l[ 0 .. $#l - 1 ] ) ? 1 : 0 ) );
    $r{tool_calls} = [];
    for my $d (@l) {
      if ( length( $d->{message}{content} // '' ) ) { $r{text} .= $d->{message}{content}; $r{chunks}++ }
      push @{ $r{tool_calls} }, map { { name => $_->{function}{name}, args => $_->{function}{arguments} } }
        @{ $d->{message}{tool_calls} // [] };
      if ( $d->{done} ) {
        $r{finish_reason} = $d->{done_reason};
        $r{usage} = _usage( $d, qw( prompt_eval_count eval_count ) );
      }
    }
    return \%r },
);

my %PROTOCOL = (
  openai => {
    path => '/v1/chat/completions',
    body => sub { my ( $o ) = @_; +{
      model => $o->{model}, messages => $o->{messages} // [ { role => 'user', content => $o->{prompt} } ],
      _tools_for( openai => $o->{tools} ),
    } },
    read => sub { my ( $b ) = @_;
      my $m = $b->{choices}[0]{message} // {};
      return {
        text => $m->{content}, finish_reason => $b->{choices}[0]{finish_reason}, model => $b->{model},
        usage => _usage( $b->{usage}, qw( prompt_tokens completion_tokens ) ),
        tool_calls => [ map { { name => $_->{function}{name}, args => $json->decode( $_->{function}{arguments} ) } }
          @{ $m->{tool_calls} // [] } ],
      } },
  },
  anthropic => {
    path => '/v1/messages',
    body => sub { my ( $o ) = @_; +{
      model => $o->{model}, max_tokens => 256,
      messages => $o->{messages} // [ { role => 'user', content => $o->{prompt} } ],
      _tools_for( anthropic => $o->{tools} ),
    } },
    read => sub { my ( $b ) = @_;
      my @c = @{ $b->{content} // [] };
      return {
        text => join( '', map { $_->{text} } grep { $_->{type} eq 'text' } @c ),
        finish_reason => $b->{stop_reason}, model => $b->{model},
        usage => _usage( $b->{usage}, qw( input_tokens output_tokens ) ),
        tool_calls => [ map { { name => $_->{name}, args => $_->{input} } } grep { $_->{type} eq 'tool_use' } @c ],
      } },
  },
  ollama => {
    path => '/api/chat',
    body => sub { my ( $o ) = @_; +{
      model => $o->{model}, stream => JSON::MaybeXS::false(),
      messages => $o->{messages} // [ { role => 'user', content => $o->{prompt} } ],
      _tools_for( ollama => $o->{tools} ),
    } },
    read => sub { my ( $b ) = @_;
      my $m = $b->{message} // {};
      return {
        text => $m->{content}, finish_reason => $b->{done_reason}, model => $b->{model},
        usage => _usage( $b, qw( prompt_eval_count eval_count ) ),
        tool_calls => [ map { { name => $_->{function}{name}, args => $_->{function}{arguments} } }
          @{ $m->{tool_calls} // [] } ],
      } },
  },
  a2a => {
    path => '/',
    body => sub { my ( $o ) = @_; +{
      jsonrpc => '2.0', id => 1, method => 'tasks/send',
      params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => $o->{prompt} } ] } },
    } },
    read => sub { my ( $b ) = @_;
      my $r = $b->{result} // {};
      my @parts = map { @{ $_->{parts} // [] } } @{ $r->{artifacts} // [] };
      return { text => join( '', map { $_->{text} // '' } @parts ), state => $r->{status}{state}, tool_calls => [] } },
  },
  acp => {
    path => '/runs',
    body => sub { my ( $o ) = @_; +{
      agent_name => $o->{model}, mode => 'sync',
      input => [ { parts => [ { content_type => 'text/plain', content => $o->{prompt} } ] } ],
    } },
    read => sub { my ( $b ) = @_;
      my @parts = map { @{ $_->{parts} // [] } } @{ $b->{output} // [] };
      return { text => join( '', map { $_->{content} // '' } @parts ), state => $b->{status}, tool_calls => [] } },
  },
);

=method chat

    my $res = $kv->chat( $protocol, model => ..., prompt => ..., tools => [...],
                         messages => [...], bearer => ..., xkey => ...,
                         stream => 1, extra => \%more_body_fields );

Sends one non-streaming chat in the protocol's own wire format and returns
C<http> extended with C<text>, C<finish_reason>, C<model>, C<tool_calls>
(C<< { name, args } >>) read from the answer when the status is 200, and
C<usage> (C<< { input, output } >>, undef when the answer has none). A
streamed answer (C<stream =E<gt> 1>; OpenAI, Anthropic, Ollama) is read frame
by frame into C<text>, C<chunks> (content frames), C<tool_calls>, C<finish_reason>, C<usage>
and C<ended> (1 when the stream ends with the protocol's exact end marker:
C<data: [DONE]>, C<event: message_stop>, the C<done: true> line).

=cut

sub chat {
  my ( $self, $proto, %o ) = @_;
  my $p = $PROTOCOL{$proto} or die "unknown protocol '$proto'";
  my $body = $p->{body}->( \%o );
  $body->{stream} = $o{stream} ? JSON::MaybeXS::true() : JSON::MaybeXS::false() if exists $o{stream};
  $body = { %$body, %{ $o{extra} } } if $o{extra};
  my $res = $self->http( POST => $p->{path}, ( map { $_ => $o{$_} } grep { defined $o{$_} } qw( bearer xkey ) ),
    body => $body );
  %$res = ( %$res, %{ $p->{read}->( $res->{body} ) } ) if $res->{status} == 200 && ref $res->{body} && !$o{stream};
  %$res = ( %$res, %{ $STREAM_READ{$proto}->( $res->{raw} ) } ) if $res->{status} == 200 && $o{stream} && $STREAM_READ{$proto};
  return $res;
}

sub protocols { sort keys %PROTOCOL }

1;

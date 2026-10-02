use strict;
use warnings;
use Test2::V0;
use Future;
use File::Temp qw( tempdir );
use HTTP::Request ();
use HTTP::Response ();
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use Path::Tiny;

use Langertha::Content::Image;
use Langertha::Knarr::Config;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Image;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::RequestLog;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;

# k33: a client sends images in its face's shape (OpenAI image_url parts,
# Anthropic image blocks, Ollama's images array), but the routed engine may
# speak any content format. Each face parses its images into
# Langertha::Content::Image objects so core writes them in the engine's own
# shape -- without that, an OpenAI image reaches Claude as an unreadable part
# and an Ollama image reaches every non-Ollama engine not at all. The matrix
# below builds the real engine request body for every face x engine content
# format and checks the image sits there in the engine's native shape.
# A core whose Content::Image cannot write every format (Langertha 0.503)
# gets the messages untouched, exactly as before k33.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $PNG = encode_base64( "\x89PNG\r\n\x1a\n" . ( "\0" x 16 ), '' );
my $JPG = encode_base64( "\xFF\xD8\xFF\xE0" . ( "\0" x 16 ), '' );
my $URL = 'https://img.example/cat.jpg';

my %proto = (
  openai    => Langertha::Knarr::Protocol::OpenAI->new,
  anthropic => Langertha::Knarr::Protocol::Anthropic->new,
  ollama    => Langertha::Knarr::Protocol::Ollama->new,
);

sub parse {
  my ( $face, $data ) = @_;
  my $body = $json->encode($data);
  return $proto{$face}->parse_chat_request( HTTP::Request->new( POST => '/' ), \$body );
}

# One user message with the text 'look' and one base64 image per face.
my %b64_request = (
  openai => { model => 'm', messages => [ { role => 'user', content => [
    { type => 'text', text => 'look' },
    { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } },
  ] } ] },
  anthropic => { model => 'm', messages => [ { role => 'user', content => [
    { type => 'text', text => 'look' },
    { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
  ] } ] },
  # Ollama sends no media type: the JPEG magic bytes must be recognized.
  ollama => { model => 'm', stream => JSON::MaybeXS::false(), messages => [
    { role => 'user', content => 'look', images => [$JPG] },
  ] },
);
# /api/generate: one prompt, the images on the request itself (k34).
my %generate_request = ( model => 'm', stream => JSON::MaybeXS::false(),
  prompt => 'look', images => [$JPG] );

my %b64_expect = ( openai => [ $PNG, 'image/png' ], anthropic => [ $PNG, 'image/png' ],
  ollama => [ $JPG, 'image/jpeg' ] );

# A URL image (OpenAI and Anthropic faces only; Ollama has no URL form).
my %url_request = (
  openai => { model => 'm', messages => [ { role => 'user', content => [
    { type => 'text', text => 'look' },
    { type => 'image_url', image_url => { url => $URL, detail => 'high' } },
  ] } ] },
  anthropic => { model => 'm', messages => [ { role => 'user', content => [
    { type => 'text', text => 'look' },
    { type => 'image', source => { type => 'url', url => $URL } },
  ] } ] },
);

# Engine content format => [ engine class, constructor args, extractor of
# the last message's native content from the request body, expected shape
# for base64 ($b64, $media_type), expected shape for a URL (undef: the
# format inlines, so core would fetch -- not exercised offline) ].
my %engine = (
  openai => [ 'OpenAI', { api_key => 'k' },
    sub { $_[0]{messages}[-1]{content} },
    sub { [ { type => 'text', text => 'look' },
            { type => 'image_url', image_url => { url => "data:$_[1];base64,$_[0]" } } ] },
    [ { type => 'text', text => 'look' }, { type => 'image_url', image_url => { url => $URL } } ] ],
  anthropic => [ 'Anthropic', { api_key => 'k' },
    sub { $_[0]{messages}[-1]{content} },
    sub { [ { type => 'text', text => 'look' },
            { type => 'image', source => { type => 'base64', media_type => $_[1], data => $_[0] } } ] },
    [ { type => 'text', text => 'look' }, { type => 'image', source => { type => 'url', url => $URL } } ] ],
  gemini => [ 'Gemini', { api_key => 'k' },
    sub { $_[0]{contents}[-1]{parts} },
    sub { [ { text => 'look' }, { inline_data => { mime_type => $_[1], data => $_[0] } } ] },
    undef ],
  ollama => [ 'Ollama', { url => 'http://127.0.0.1:1', model => 'm' },
    sub { my $m = $_[0]{messages}[-1]; +{ content => $m->{content}, images => $m->{images} } },
    sub { +{ content => 'look', images => [ $_[0] ] } },
    undef ],
  responses => [ 'OpenAIResponses', { api_key => 'k' },
    sub { $_[0]{input}[-1]{content} },
    sub { [ { type => 'input_text', text => 'look' },
            { type => 'input_image', image_url => "data:$_[1];base64,$_[0]" } ] },
    [ { type => 'input_text', text => 'look' }, { type => 'input_image', image_url => $URL } ] ],
);

sub engine_for {
  my ($fmt) = @_;
  my ( $name, $args ) = @{ $engine{$fmt} };
  my $class = "Langertha::Engine::$name";
  eval "require $class; 1" or die $@;
  my $e = $class->new(%$args);
  is $e->content_format, $fmt, "$name writes the $fmt content format";
  return $e;
}

sub body_of {
  my ( $e, $req ) = @_;
  return $json->decode( $e->chat( @{ $req->messages } )->content );
}

if ( Langertha::Knarr::Image::translates() ) {
  for my $fmt ( sort keys %engine ) {
    my ( undef, undef, $extract, $b64_shape, $url_shape ) = @{ $engine{$fmt} };
    my $e = engine_for($fmt);
    for my $face ( sort keys %b64_request ) {
      my $got = $extract->( body_of( $e, parse( $face, $b64_request{$face} ) ) );
      is $got, $b64_shape->( @{ $b64_expect{$face} } ),
        "$face face, base64 image -> $fmt engine: native $fmt image";
    }
    next unless $url_shape;
    for my $face ( sort keys %url_request ) {
      my $got = $extract->( body_of( $e, parse( $face, $url_request{$face} ) ) );
      is $got, $url_shape, "$face face, URL image -> $fmt engine: URL passed on, not fetched";
    }
  }

  # k34: /api/generate images were dropped -- a vision prompt reached the
  # engine as text alone. They now join the synthesized user message.
  for my $fmt (qw( anthropic ollama openai )) {
    my ( undef, undef, $extract, $b64_shape ) = @{ $engine{$fmt} };
    my $e = engine_for($fmt);
    my $got = $extract->( body_of( $e, parse( ollama => \%generate_request ) ) );
    is $got, $b64_shape->( $JPG, 'image/jpeg' ),
      "ollama /api/generate, request images -> $fmt engine: native $fmt image";
  }

  subtest 'what the faces parse' => sub {
    my $data = $b64_request{ollama};
    my $req  = parse( ollama => $data );
    my $msg  = $req->messages->[0];
    ok !exists $msg->{images}, 'Ollama images array moved into content';
    is $msg->{content}[0], 'look', 'the text stays a plain string';
    isa_ok $msg->{content}[1], 'Langertha::Content::Image';
    is $req->raw->{messages}[0]{images}, [$JPG], 'raw body untouched (passthrough reads it)';

    my $oreq = parse( openai => $url_request{openai} );
    my $img  = $oreq->messages->[0]{content}[1];
    isa_ok $img, 'Langertha::Content::Image';
    is $img->url, $URL, 'URL kept';
    ok !$img->has_base64, 'nothing fetched while parsing';
    is $oreq->raw->{messages}[0]{content}[1]{type}, 'image_url', 'raw OpenAI part untouched';

    my $areq = parse( anthropic => { model => 'm', system => 'be brief', messages => [
      { role => 'user', content => 'hello' },
      { role => 'user', content => [
        { type => 'text', text => 'cached', cache_control => { type => 'ephemeral' } },
        { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $PNG } },
      ] },
    ] } );
    is $areq->messages->[0], { role => 'system', content => 'be brief' }, 'system prompt first';
    is $areq->messages->[1], { role => 'user', content => 'hello' }, 'text-only message unchanged';
    is $areq->messages->[2]{content}[0],
      { type => 'text', text => 'cached', cache_control => { type => 'ephemeral' } },
      'a text block with cache_control is kept as sent';

    my $gif = encode_base64( "GIF89a" . ( "\0" x 10 ), '' );
    my $webp = encode_base64( "RIFF\0\0\0\0WEBPVP8 ", '' );
    my %sniff = ( $gif => 'image/gif', $webp => 'image/webp', $PNG => 'image/png',
      encode_base64( 'no magic here', '' ) => 'image/png' );
    for my $b64 ( sort keys %sniff ) {
      my $r = parse( ollama => { model => 'm', messages => [ { role => 'user', content => '', images => [$b64] } ] } );
      is $r->messages->[0]{content}[0]->media_type, $sniff{$b64}, "Ollama image sniffed as $sniff{$b64}";
    }
    my $du = parse( ollama => { model => 'm', messages => [
      { role => 'user', content => 'x', images => ["data:image/webp;base64,$PNG"] } ] } );
    is $du->messages->[0]{content}[1]->media_type, 'image/webp', 'a data: URL in images keeps its media type';
  };

  for my $face ( sort keys %proto ) {
    is $proto{$face}->manifest_endpoint->{image_content_formats},
      [qw( openai anthropic gemini ollama responses lmstudio )],
      "$face endpoint: images reach every engine content format";
  }
}
else {
  for my $face ( sort keys %b64_request ) {
    my $data = $b64_request{$face};
    my $req  = parse( $face => $data );
    my @msgs = @{ $req->messages };
    shift @msgs if $face eq 'anthropic' && defined $data->{system};
    is \@msgs, $data->{messages}, "$face face: messages untouched on a core without full image translation";
  }
  is parse( ollama => \%generate_request )->messages,
    [ { role => 'user', content => 'look', images => [$JPG] } ],
    'ollama /api/generate: request images ride on the user message unchanged';
  is $proto{openai}->manifest_endpoint->{image_content_formats}, [qw( openai gemini )], 'openai formats as before';
  is $proto{anthropic}->manifest_endpoint->{image_content_formats}, [qw( anthropic )], 'anthropic formats as before';
  is $proto{ollama}->manifest_endpoint->{image_content_formats}, [qw( ollama )], 'ollama formats as before';
}

# The trace and the JSONL log encode the request's messages; an image object
# has no TO_JSON, so both sinks write it as a plain image_url part. Both go
# through their real encoder: Tracing's flush builds the Langfuse POST body,
# RequestLog's writer swallows encode errors (a broken entry is a lost line).
{
  package CapturingHTTP;
  sub new { bless { requests => [] }, shift }
  sub requests { $_[0]{requests} }
  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{requests} }, $args{request};
    return Future->done( HTTP::Response->new(200) );
  }
}

my $session = Langertha::Knarr::Session->new( id => 's' );
sub image_request {
  Langertha::Knarr::Request->new( protocol => 'openai', model => 'm', messages => [ { role => 'user', content => [
    'look',
    Langertha::Content::Image->from_base64( $PNG, media_type => 'image/png' ),
    Langertha::Content::Image->from_url($URL),
  ] } ] );
}
my $plain = [ 'look',
  { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } },
  { type => 'image_url', image_url => { url => $URL } } ];

subtest 'the Langfuse trace encodes image objects' => sub {
  my $http = CapturingHTTP->new;
  my $tracing = Langertha::Knarr::Tracing->new(
    config => Langertha::Knarr::Config->new( data => { models => {}, langfuse => {
      public_key => 'pk-lf-test', secret_key => 'sk-lf-test', url => 'http://127.0.0.1:1' } } ),
    _http => $http,
  );
  Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub { 'ok' } ),
    tracing => $tracing,
  )->handle_chat_f( $session, image_request() )->get;
  is scalar @{ $http->requests }, 1, 'the batch was posted' or return;
  my $batch = $json->decode( $http->requests->[0]->content )->{batch};
  my ($trace) = grep { $_->{type} eq 'trace-create' } @$batch;
  is $trace->{body}{input}[0]{content}, $plain, 'images traced as image_url parts';
};

subtest 'the JSONL request log encodes image objects' => sub {
  my $log_file = tempdir( CLEANUP => 1 ) . '/requests.jsonl';
  my $rlog = Langertha::Knarr::RequestLog->new(
    config => Langertha::Knarr::Config->new( data => { models => {}, logging => { file => $log_file } } ),
  );
  Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => Langertha::Knarr::Handler::Code->new( code => sub { 'ok' } ),
    request_log => $rlog,
  )->handle_chat_f( $session, image_request() )->get;
  my @lines = grep { length } split /\n/, ( -e $log_file ? path($log_file)->slurp_utf8 : '' );
  is scalar @lines, 1, 'the line was written, not lost in the encode' or return;
  is $json->decode( $lines[0] )->{messages}[0]{content}, $plain, 'images logged as image_url parts';
};

done_testing;

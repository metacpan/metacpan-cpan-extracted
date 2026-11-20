package Langertha::Holmgang::Target;
# ABSTRACT: A Langertha engine as a benchmark target: variant settings, one model turn, failed turns classified

use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Compress::Zlib ();
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Langertha::Content::Image;
use Langertha::Holmgang::Error;
use Langertha::Role::HTTP ();
use Scalar::Util qw( blessed );

our $VERSION = '0.002';


has engine => (
  is       => 'ro',
  required => 1,
);


has variant => (
  is      => 'ro',
  default => sub { {} },
);


has deadline => (
  is        => 'ro',
  predicate => 'has_deadline',
);


sub BUILD {
  my ( $self ) = @_;
  croak __PACKAGE__.'->new: engine must be a Langertha engine with chat_f'
    unless blessed $self->engine && $self->engine->can('chat_f');
  croak __PACKAGE__.'->new: variant must be a HashRef'
    unless ref $self->variant eq 'HASH';
  croak __PACKAGE__.'->new: deadline must be a number of seconds above 0'
    if $self->has_deadline && !( defined $self->deadline && $self->deadline =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $self->deadline > 0 );
  return;
}

#### Variants

# The settings a variant may name, in the order a message lists them.
my @VARIANT_KEYS = qw( enable_thinking reasoning_effort max_tokens temperature deadline );
my %VARIANT_KEY  = map { $_ => 1 } @VARIANT_KEYS;

# Langertha's reasoning_effort values (Langertha::Role::Chat)
my %EFFORT = map { $_ => 1 } qw( none minimal low medium high xhigh max );

sub variant_keys { @VARIANT_KEYS }


sub check_variant {
  my ( $self, $settings, $engine ) = @_;
  my $no = sub { Langertha::Holmgang::Error->throw(@_) };
  $no->( variant => 'not a hash of settings' ) unless ref $settings eq 'HASH';
  my %v;
  for my $k ( sort keys %$settings ) {
    my $x = $settings->{$k};
    $no->( 'variant.'.$k => 'unknown setting (known: '.join( ', ', @VARIANT_KEYS ).')' ) unless $VARIANT_KEY{$k};
    # an empty value names nothing (cai-platform check_variant)
    next if !defined $x || ( !ref $x && !length $x );
    if ( $k eq 'enable_thinking' ) {
      my $on = JSON::MaybeXS::is_bool($x) ? ( $x ? 1 : 0 )
             : ref $x                     ? undef
             : $x =~ /\A(?:on|true|1)\z/  ? 1
             : $x =~ /\A(?:off|false|0)\z/ ? 0
             :                              undef;
      $no->( 'variant.enable_thinking' => 'on or off (true/false, 1/0)' ) unless defined $on;
      $v{$k} = $on ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
    }
    elsif ( $k eq 'reasoning_effort' ) {
      $no->( 'variant.reasoning_effort' => 'one of '.join( ', ', qw( none minimal low medium high xhigh max ) ) )
        unless !ref $x && $EFFORT{$x};
      $v{$k} = ''.$x;
    }
    elsif ( $k eq 'max_tokens' ) {
      $no->( 'variant.max_tokens' => 'a whole number from 1 to 9999999' ) unless !ref $x && $x =~ /\A[1-9][0-9]{0,6}\z/;
      $v{$k} = 0 + $x;
    }
    elsif ( $k eq 'temperature' ) {
      $no->( 'variant.temperature' => 'a number from 0 to 2' )
        unless !ref $x && $x =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $x <= 2;
      $v{$k} = 0 + $x;
    }
    else {   # deadline
      $no->( 'variant.deadline' => 'seconds, a number above 0 and at most 86400' )
        unless !ref $x && $x =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $x > 0 && $x <= 86400;
      $v{$k} = 0 + $x;
    }
  }
  return \%v unless defined $engine;
  my $name  = ref $engine;
  my $model = $engine->can('chat_model') ? eval { $engine->chat_model } : undef;
  my $of    = 'the engine '.$name.( defined $model ? ' (model '.$model.')' : '' );
  my $takes = sub { !$engine->can('supports') || $engine->supports( $_[0] ) };
  $no->( 'variant.temperature' => $of.' takes no temperature; Langertha would drop it' )
    if exists $v{temperature} && !$takes->('temperature');
  $no->( 'variant.reasoning_effort' => $of.' takes no reasoning_effort; Langertha would drop it' )
    if exists $v{reasoning_effort} && !$takes->('reasoning_effort');
  $no->( 'variant.enable_thinking' => $of.' speaks no OpenAI-compatible wire, so chat_template_kwargs has no place' )
    if exists $v{enable_thinking} && !( $engine->can('does') && $engine->does('Langertha::Role::OpenAICompatible') );
  $no->( 'variant.deadline' => $of.' runs on no event loop (IO::Async and Net::Async::HTTP), so a deadline cannot cut a request' )
    if exists $v{deadline} && !( $engine->can('async_loop') && $engine->async_loop );
  return \%v;
}


sub for_variant {
  my ( $self, %arg ) = @_;
  my $engine = $arg{engine};
  croak __PACKAGE__.'->for_variant: engine must be a Langertha engine with chat_f'
    unless blessed $engine && $engine->can('chat_f');
  my $s = $self->check_variant( $arg{settings} // {}, $engine );
  my %opts = map { exists $s->{$_} ? ( $_ => $s->{$_} ) : () } qw( reasoning_effort max_tokens temperature );
  $opts{chat_template_kwargs} = { enable_thinking => $s->{enable_thinking} } if exists $s->{enable_thinking};
  return ( ref $self || $self )->new(
    engine  => $engine,
    variant => \%opts,
    ( exists $s->{deadline} ? ( deadline => $s->{deadline} ) : () ),
  );
}


# How much of an error body Langertha keeps in its croak while a turn runs.
# Its default ($Langertha::Role::HTTP::error_body_max_length, 500 characters)
# can cut a signature off a long body (a provider error with a long preamble).
sub error_body_max_length { 65536 }


#### Signatures

# A target that cannot take an image (k27): llama.cpp without an mmproj
# ("image input is not supported - hint: ... provide the mmproj"), vLLM
# ("... is not a multimodal model").
my $NO_VISION_RE = qr{
    image \s+ input \s+ is \s+ not \s+ supported
  | not \s+ a \s+ multimodal \s+ model
}xi;

# The request exceeds the context window -- cai-platform's $CONTEXT_RE
# (Eval::Runner, af7561a5), unchanged: OpenAI, vLLM, llama.cpp, SGLang, TGI,
# LiteLLM, Ollama, Anthropic, and the generic "context window" phrasing.
my $CONTEXT_RE = qr{
    context_length_exceeded | exceed_context_size | ContextWindowExceeded
  | maximum \s+ context \s+ length | maximum \s+ model \s+ length | max_model_len
  | exceeds? \s+ the \s+ (?:available \s+)? context \s+ (?:size|length|window)
  | longer \s+ than \s+ the \s+ model'?s? \s+ context \s+ length
  | tokens \s* \+ \s* `?max_new_tokens`? \s+ must \s+ be \s+ <=
  | context \s+ window \s+ (?:exceeded|is \s+ too \s+ small)
  | prompt \s+ is \s+ too \s+ long
}xi;

sub classify_error {
  my ( $self, $text ) = @_;
  return 'error' unless defined $text && length $text;
  return $text =~ $NO_VISION_RE ? 'no_vision'
       : $text =~ $CONTEXT_RE   ? 'context_exceeded'
       :                          'error';
}


#### Scrubbing

# Query parameters and header/JSON fields whose value is a credential.
my $SECRET_PARAM = qr{ (?: api[_-]?key | key | access[_-]?token | token | auth | secret | password | passwd | sig | signature ) }xi;
my $AUTH_SCHEME  = qr{ (?: Bearer | Basic | Token | Digest ) \s+ }xi;
# What ends a value in a header, a query or a JSON string.
my $VALUE = qr{ [^\s"',;&#]+ }x;
# A path segment: anything but whitespace, a slash and the usual delimiters.
my $SEG = qr{ [^\s/\\"'<>:,;()\[\]{}]+ }x;

# A die or warn location: " at FILE line N", with the line of the last read
# handle (", <FH> line N" or "chunk N") when Perl adds one; FILE is $1. The one
# rule of the dist (k42): World builds its Perl-error line from it, World cuts a
# trailing one with it (k44), the CLI
# cuts relayed errors and warnings with _strip_location (k41).
our $LOCATION = qr/ at (\S+) line \d+(?:, <[^>]*> (?:line|chunk) \d+)?/;

# die and Carp locations anywhere, the closing dot optional ("called at" lines have none)
sub _strip_location { my ( $class, $text ) = @_; return $text =~ s/$LOCATION\.?//gr }

sub scrub {
  my ( $self, $text ) = @_;
  return $text unless defined $text;
  # the engine's own key, of whatever shape (cai-platform ModelTester::scrub)
  if ( ref $self ) {
    my $engine = $self->engine;
    my $key = $engine->can('api_key') ? eval { $engine->api_key } : undef;
    $text =~ s/\Q$key\E/***/g if defined $key && !ref $key && length $key >= 4;
  }
  $text = $self->_strip_location($text);
  # credentials in URLs: userinfo and secret query parameters
  $text =~ s{ ( \b [a-z][a-z0-9+.-]* :// ) [^/\s\@"']+ \@ }{$1***\@}gxi;
  $text =~ s{ ( [?&;] $SECRET_PARAM = ) $VALUE }{$1***}gx;
  # credentials in headers and JSON fields
  $text =~ s{ \b ( Authorization ["']? \s* [:=] \s* ["']? $AUTH_SCHEME? ) $VALUE }{$1***}gxi;
  $text =~ s{ \b ( Bearer \s+ ) (?!\*\*\*) $VALUE }{$1***}gxi;
  $text =~ s{ \b ( (?: x- (?: goog- )? )? api[_-]?key ["']? \s* [:=] \s* ["']? ) $VALUE }{$1***}gxi;
  # key shapes of the common providers
  $text =~ s{ \b (?: sk | pplx | gsk | xai | hf ) [-_] [A-Za-z0-9_-]{16,} }{***}gx;
  $text =~ s{ \b AIza [0-9A-Za-z_-]{30,} }{***}gx;
  # absolute host paths: Unix (two segments at least, not inside a URL), home, Windows
  $text =~ s{ (?<! [\w.:/~\\\@-] ) (?: ~ | [A-Za-z]: )? [/\\] (?: $SEG [/\\] )+ $SEG }{<path>}gx;
  return $text;
}


#### Vision (k27)

# The input tokens an image must add at least before the sight test counts it
# as seen (k27: "Mindestkosten des Bildes, ~200").
sub sight_test_min_tokens { 200 }


my $SIGHT_PNG;

sub sight_test_image {
  return $SIGHT_PNG //= do {
    my ( $w, $h ) = ( 512, 512 );
    # 8-bit grey, a checkerboard of 64-pixel squares; filter byte 0 per row
    my $raw = join '', map {
      my $y = $_;
      "\0".join '', map { ( int( $_ / 64 ) + int( $y / 64 ) ) % 2 ? "\xFF" : "\x40" } 0 .. $w - 1;
    } 0 .. $h - 1;
    my $chunk = sub {
      my ( $type, $data ) = @_;
      return pack( 'N', length $data ).$type.$data.pack( 'N', Compress::Zlib::crc32( $type.$data ) );
    };
    "\x89PNG\r\n\x1a\n"
      .$chunk->( 'IHDR', pack( 'NNCCCCC', $w, $h, 8, 0, 0, 0, 0 ) )
      .$chunk->( 'IDAT', Compress::Zlib::compress( $raw, 9 ) )
      .$chunk->( 'IEND', '' );
  };
}


my $SIGHT_TEXT = 'This is a connection check. Reply with the single word OK.';

async sub vision_check_f {
  my ( $self ) = @_;
  my $engine = $self->engine;
  my $name   = ref $engine;
  # 1. the wire: an engine without the role has no image part Langertha vouches for
  return { no_vision => 'the engine '.$name.' takes no image (no Langertha::Role::ImageInput)', check => 'wire' }
    unless $engine->can('does') && $engine->does('Langertha::Role::ImageInput');

  # 2. what the server says about its model, where Langertha can ask (llama.cpp
  # /props, Ollama, LM Studio, OpenRouter ...); elsewhere this asks nothing
  my $learned = $engine->can('probe_model_capabilities_f')
    ? await( $engine->probe_model_capabilities_f->else( sub { Future->done( {} ) } ) )
    : {};
  my $model = $engine->can('chat_model') ? eval { $engine->chat_model } : undef;
  my $fact  = defined $model && ref $learned eq 'HASH' && ref $learned->{$model} eq 'HASH'
    ? $learned->{$model}{image_input} : undef;
  return { no_vision => 'the server\'s model metadata says the model '.$model.' takes no image', check => 'probe' }
    if defined $fact && !$fact;

  # 3. the sight test: the same short request without and with an image; a
  # template that drops the image leaves the input tokens where they were
  my %controls = ( max_tokens => 16 );
  my $plain = await $self->chat_turn_f( messages => [ { role => 'user', content => $SIGHT_TEXT } ], %controls );
  my $image = Langertha::Content::Image->from_data( $self->sight_test_image, media_type => 'image/png' );
  my $seen  = await $self->chat_turn_f( messages => [ { role => 'user', content => [ { type => 'text', text => $SIGHT_TEXT }, $image ] } ], %controls );
  if ( defined $seen->{error_class} && $seen->{error_class} eq 'no_vision' ) {
    return { no_vision => 'the target refused the image: '.$seen->{error}, check => 'sight_test' };
  }
  for my $t ( $plain, $seen ) {
    return { no_vision => undef, check => 'sight_test', note => 'sight test failed: '.$t->{error} }
      if defined $t->{error_class};
  }
  my ( $without, $with ) = map {
    my $r = $_->{response};
    $r && $r->has_usage ? $r->usage->input_tokens : undef;
  } $plain, $seen;
  return { no_vision => undef, check => 'sight_test', note => 'sight test unmeasured: the target reports no input tokens' }
    unless defined $without && defined $with;
  my $added = $with - $without;
  my $min   = $self->sight_test_min_tokens;
  return { no_vision => 'sight test: the image added '.$added.' input tokens, at least '.$min
      .' expected -- the target drops the image', check => 'sight_test', added_tokens => $added }
    if $added < $min;
  return { no_vision => undef, check => 'sight_test', added_tokens => $added };
}


#### The turn

sub chat_turn_f {
  my ( $self, %opts ) = @_;
  my $f;
  {
    my $max = $self->error_body_max_length;
    local $Langertha::Role::HTTP::error_body_max_length =
      $Langertha::Role::HTTP::error_body_max_length > $max ? $Langertha::Role::HTTP::error_body_max_length : $max;
    $f = eval { $self->engine->chat_f( %opts, %{ $self->variant } ) };
    $f = Future->fail( $@ || ref( $self->engine ).'->chat_f returned no Future' )
      unless blessed $f && $f->isa('Future');
  }
  # the variant's deadline: the request races a timer on the engine's loop
  if ( $self->has_deadline && !$f->is_ready ) {
    my $loop = $self->engine->can('async_loop') ? $self->engine->async_loop : undef;
    if ( $loop ) {
      my $d = $self->deadline;
      $f = Future->wait_any( $f, $loop->delay_future( after => $d )->then_fail( 'timeout: deadline ('.$d.' s)' ) );
    }
  }
  return $f->then(
    sub {
      my ( $response ) = @_;
      return Future->done( { response => $response, error => undef, error_class => undef } );
    },
    sub {
      my ( $failure ) = @_;
      my $text = defined $failure ? "$failure" : '';
      $text =~ s/\s+\z//;
      # classified on the raw text, scrubbed before it leaves (k38)
      my $class = $self->classify_error($text);
      return Future->done( { response => undef, error => $self->scrub($text), error_class => $class } );
    },
  );
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Target - A Langertha engine as a benchmark target: variant settings, one model turn, failed turns classified

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Target;
  use Langertha::Engine::Virtual;
  use Langertha::Virtual::Rules qw( answer error );

  my $target = Langertha::Holmgang::Target->new(
    engine  => Langertha::Engine::Virtual->new( rules => [ qr/./ => answer('done') ] ),
    variant => { max_tokens => 4000 },     # chat_f options, passed through unchecked
  );

  my $turn = $target->chat_turn_f(
    messages    => [ { role => 'user', content => 'Fix the route on gw-a.' } ],
    tools       => \@tool_schemas,
    temperature => 0,
  )->get;

  if ( defined $turn->{error_class} ) {
    # 'no_vision', 'context_exceeded' or 'error' -- the case ends with that status
    warn $turn->{error};
  }
  else {
    my $response = $turn->{response};      # Langertha::Response
  }

=head1 DESCRIPTION

A target is what a run measures (C<CONTEXT.md>): one Langertha engine -- any
engine, L<Langertha::Engine::Virtual> in tests -- plus the settings of the
variant under which it runs. The runner asks it for one model turn at a
time and gets a normalised result back: either the engine's
L<Langertha::Response>, or the error text and its class.

The class decides the case status of ADR 0006 when the target did not answer:
C<no_vision> (the target cannot see an image of the case), C<context_exceeded>
(the request does not fit its context window) or C<error> (any other failure).
Langertha has no structured request failure yet, only the text of the croak
(C<< <class> request failed: <status line> - <body> >>), so the class is read
off that text with the signatures of the common servers; see
L</classify_error>.

=head2 engine

Required. The Langertha engine the turns go to -- any object with C<chat_f>
(L<Langertha::Role::Chat>). Its own attributes (model, url, system prompt,
engine-level controls) stay as they are; the target never changes it.

=head2 variant

Optional, default C<{}>. The variant's settings as C<chat_f> options
(C<max_tokens>, C<temperature>, C<reasoning_effort>, C<chat_template_kwargs>
...). They are added to every turn and win over the turn's own options of the
same name, as cai-platform's variant C<max_tokens> beats the case's. A plain
HashRef, passed through unchecked: this is the wire-level form. The named
and checked settings of a variant go through L</for_variant>, which builds
this HashRef from them.

=head2 deadline

Optional. Seconds one turn may take, a number above 0. When the engine runs
on an event loop (C<async_loop>), L</chat_turn_f> races the request against a
timer on that loop; a turn that runs out fails with C<timeout: deadline (N s)>
(class C<error>) and the request is cancelled. On an engine without a loop
the request has already finished when C<chat_f> returns, so there is nothing
to race; L</check_variant> refuses a deadline for such an engine.

=head2 variant_keys

  my @keys = Langertha::Holmgang::Target->variant_keys;

The settings a variant may name: C<enable_thinking>, C<reasoning_effort>,
C<max_tokens>, C<temperature>, C<deadline>.

=head2 check_variant

  my $settings = Langertha::Holmgang::Target->check_variant( \%settings );
  my $settings = Langertha::Holmgang::Target->check_variant( \%settings, $engine );

Checks the settings of a variant and returns them normalised. A variant names
only these, each checked (cai-platform C<ModelTester::check_variant>):

=over

=item * C<enable_thinking> -- C<on>/C<off>, C<true>/C<false>, C<1>/C<0> or a
JSON boolean; normalised to a JSON boolean. Goes out as
C<< chat_template_kwargs => { enable_thinking => ... } >> (Qwen, Nemotron,
Gemma under llama.cpp, vLLM, SGLang).

=item * C<reasoning_effort> -- one of Langertha's values C<none minimal low
medium high xhigh max>.

=item * C<max_tokens> -- a whole number from 1 to 9999999; beats the case's.

=item * C<temperature> -- a number from 0 to 2; beats the case's.

=item * C<deadline> -- seconds per turn, above 0 and at most 86400
(L</deadline>).

=back

An empty value names nothing and is left out. With an C<$engine> the settings
are also checked against it: C<temperature> and C<reasoning_effort> only where
it C<supports> them (Langertha would drop them with a warning, and the report
would name a setting that never went out), C<enable_thinking> only on an
engine with L<Langertha::Role::OpenAICompatible>, C<deadline> only on an
engine with an event loop. Throws a L<Langertha::Holmgang::Error> on the field
C<variant.E<lt>keyE<gt>>.

=head2 for_variant

  my $target = Langertha::Holmgang::Target->for_variant(
    engine   => $engine,
    settings => { enable_thinking => 'off', max_tokens => 4000, deadline => 1800 },
  );

A target for one variant: the settings checked against the engine
(L</check_variant>) and turned into L</variant> (the C<chat_f> options) and
L</deadline>.

=head2 error_body_max_length

  Langertha::Holmgang::Target->error_body_max_length;   # 65536

How many characters of a failed response's body the error text keeps, at
least. Langertha cuts the body in its croak at
C<$Langertha::Role::HTTP::error_body_max_length> (500); L</chat_turn_f>
raises that to this value with C<local> for the duration of the call (a
higher value already set stays). B<Limit:> the C<local> covers the
synchronous transports -- L<Langertha::Engine::Virtual> and the LWP fallback
without C<Net::Async::HTTP>, where the request and its croak happen inside
the call. With a real event loop the croak happens later, outside the
C<local>, and the body is cut at Langertha's limit again; signatures in the
first 500 characters are still found. An uncut body is a Langertha gap.

=head2 classify_error

  $target->classify_error($error_text);   # 'no_vision' | 'context_exceeded' | 'error'

The class of a failed turn from its error text (also callable on the class).
Only ever asked for a turn that failed: a response that merely mentions one
of the phrases is a response, never one of these classes.

The first that matches wins, in the order of ADR 0006:

=over

=item * C<no_vision> -- llama.cpp without a projector ("image input is not
supported ... mmproj"), vLLM ("is not a multimodal model").

=item * C<context_exceeded> -- OpenAI (C<context_length_exceeded>), vLLM
("maximum context length", "longer than the maximum model length",
C<max_model_len>), llama.cpp (C<exceed_context_size_error>, "exceeds the
available context size"), SGLang ("longer than the model's context length"),
TGI ("C<inputs> tokens + C<max_new_tokens> must be <= N"), LiteLLM
(C<ContextWindowExceededError>), Ollama ("input length exceeds the context
length"), Anthropic ("prompt is too long"), and "context window exceeded" /
"is too small". The expression is cai-platform's C<$CONTEXT_RE> unchanged.

=item * C<error> -- everything else, an empty text included: a 500 without a
hint, a timeout, a refused connection, a croak before the request.

=back

=head2 scrub

  my $clean = $target->scrub($text);    # also callable on the class, without the key

The text of a failed turn with what must not leave the run removed (ADR
0006: "error texts pass the engine's scrubbing first" -- Langertha has no
scrubber of its own, so the target does it). L</chat_turn_f> scrubs its C<error>; the
class of the failure is read off the raw text before. What goes:

=over

=item * the engine's own C<api_key> (4 characters and up), wherever it stands
-- C<***>; only on an object, the class knows no key;

=item * die and Carp locations (C<at FILE line N.>, C<called at ...>, with
C<< , <FH> line N >> when Perl adds it), dropped;

=item * URL credentials: the userinfo (C<https://***@host/...>) and the value
of a query parameter named C<key>, C<api_key>, C<access_token>, C<token>,
C<auth>, C<secret>, C<password>, C<sig>, C<signature> -- C<***>, the rest of
the URL stays;

=item * header and JSON field values: C<Authorization> (after its scheme),
C<Bearer> tokens, C<x-api-key>, C<x-goog-api-key>, C<api_key>/C<api-key> --
C<***>;

=item * key shapes of the common providers (C<sk->, C<pplx->, C<gsk_>,
C<xai->, C<hf_> with 16 characters and up, C<AIza...>) -- C<***>;

=item * absolute host paths (C</a/b>, C<~/a>, C<C:\a\b>; not the path of a
URL, not a single segment) -- C<< <path> >>.

=back

The status line, the provider's reason and the URL's host and path stay
readable. This is a net for what Langertha's error text can carry, not a
proof: a credential the engine does not hold and that has none of these
shapes passes.

=head2 sight_test_min_tokens

  Langertha::Holmgang::Target->sight_test_min_tokens;   # 200

How many input tokens the sight test image (L</sight_test_image>) must add to
a request before L</vision_check_f> counts it as seen. Common vision models
spend 256 (Gemma 3, InternVL) to over 1000 (Pixtral) on a 512 by 512 image;
a template that drops the image adds next to nothing.

=head2 sight_test_image

  my $png = Langertha::Holmgang::Target->sight_test_image;   # bytes

The image of the sight test: a 512 by 512 grey PNG with a checkerboard,
built in memory, the same bytes on every call.

=head2 vision_check_f

  my $check = await $target->vision_check_f;
  # { no_vision => undef | $reason, check => 'wire' | 'probe' | 'sight_test',
  #   added_tokens => n, note => $text }

The pre-check of a target for a suite whose cases carry images (k27, ADR
0006): can the target see an image? A pre-check, never a graded case. In
this order, the first that decides wins:

=over

=item 1. B<The wire.> An engine that does not compose
L<Langertha::Role::ImageInput> has no image part Langertha vouches for:
C<no_vision>. (L<Langertha::Engine::Virtual> is one; the runner's
L<Langertha::Holmgang::Runner/mock_engine> claims it for a case with images.)

=item 2. B<The server's model metadata.>
L<Langertha::Role::Capabilities/probe_model_capabilities_f> asks the
providers Langertha can ask (llama.cpp C</props>, Ollama, LM Studio,
OpenRouter, Mistral, TSystems; on every other engine it asks nothing). When it
learned C<< image_input => 0 >> for the engine's C<chat_model>: C<no_vision>. A failing probe decides nothing. A static "no claim" (vLLM,
llama.cpp before the probe, gateways) decides nothing either -- the model
behind them is unknown to the client.

=item 3. B<The sight test.> Two short requests through L</chat_turn_f> (the
variant applies): a text, then the same text with
L</sight_test_image>. If the second fails with a C<no_vision> signature
(L</classify_error>): C<no_vision>. If the image added fewer input tokens than
L</sight_test_min_tokens>, the chat template dropped it without a word:
C<no_vision>. A failed request or a target without token usage decides
nothing (C<note> says why); the cases then run and show what they get.

=back

The Future is always done. C<no_vision> is C<undef> when the target may see
the image, else the reason, which the runner gives every case with images of
the suite as its error (L<Langertha::Holmgang::Runner/run_case_f>, option
C<no_vision>).

=head2 chat_turn_f

  my $turn = await $target->chat_turn_f(
    messages => \@messages,      # system prompt included as the runner builds it
    tools    => \@tools,         # the suite's tool schemas
    %controls,                   # temperature, max_tokens, seed, ...
  );

One model turn: the options go to the engine's C<chat_f> unchanged, with the
L</variant> settings added on top. Returns a L<Future> that is always
B<done> -- a failed request is a result, not a failed Future -- with a
HashRef:

=over

=item * C<response> -- the L<Langertha::Response> of a turn that succeeded,
C<undef> otherwise. Usage, finish reason, tool calls and timing are read from
it.

=item * C<error> -- the error text of a failed turn (Langertha's croak,
without the trailing whitespace, through L</scrub>), C<undef> otherwise.

=item * C<error_class> -- C<undef> for a turn that succeeded, else
C<no_vision>, C<context_exceeded> or C<error> (L</classify_error>); the
runner ends the case with that status.

=back

With a L</deadline>, a request still running after that many seconds is
cancelled and the turn fails with C<timeout: deadline (N s)> (class
C<error>).

Anything C<chat_f> throws or fails with counts as a failed turn, including
a croak before the request (a capability exclusion, a malformed tool). What
the model may see is the caller's business: the target strips nothing, so
the runner hands it messages and tools without state, rules or C<untrusted>
marks. The error body is kept up to L</error_body_max_length> characters (see
there for the limit under a real event loop).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Langertha::ToolResult;
# ABSTRACT: Immutable canonical result of executing one tool, with cross-provider conversion
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS;
use MIME::Base64 ();
use Encode ();
use URI ();
use URI::Escape ();


has name => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);


has id => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);


has content => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);


has is_error => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);


has structured_content => (
  is        => 'ro',
  predicate => 'has_structured_content',
);


# Shared encoder for result payloads that ride as a JSON *string* inside the
# request body (or inside hermes text): characters, not bytes. The transport
# (Role::JSON) encodes the whole body to UTF-8 once; a byte string here would be
# encoded twice ("Köln" -> "KÃ¶ln"). Same key order as Role::JSON. -- karr k252
my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1 );

# --- MCP content normalizer, shared by every format (karr k326, k336) ---
#
# One pass over the MCP content array yields neutral items; each format renders
# them. Kinds:
#   text      a text block (keeps cache_control, for Anthropic)
#   document  text from an embedded resource (whatever its MIME type), or a
#             text/* blob decoded as UTF-8
#   blob      a base64 payload (image, audio, binary resource) with its MIME
#   native    an Anthropic-native block a caller built for that wire
#   note      a ready text placeholder (resource_link, non-hash blocks)
# A blob the wire cannot carry becomes a placeholder naming type, MIME, URI and
# decoded size -- never the base64 payload.

sub _b64_size {
  my ($data) = @_;
  return undef unless defined $data && !ref $data;
  ( my $b64 = $data ) =~ s/\s+//g;
  my $pad = () = $b64 =~ /=/g;
  return int( length($b64) * 3 / 4 ) - $pad;
}

sub _placeholder {
  my ( $type, $mime, $uri, $data ) = @_;
  my $size = _b64_size($data);
  return join( ' ', "[$type]", grep { defined && length } $mime,
    ( defined $uri ? "<$uri>" : () ), ( defined $size ? "($size bytes)" : () ) );
}

sub _mcp_resource {
  my ($res) = @_;
  $res = {} unless ref $res eq 'HASH';
  my $mime = $res->{mimeType};
  return { kind => 'document', text => $res->{text} } if defined $res->{text};
  if ( defined $res->{blob} && defined $mime && $mime =~ m{\Atext/} ) {
    my $bytes = MIME::Base64::decode_base64( $res->{blob} );
    return { kind => 'document',
      text => Encode::decode( 'UTF-8', $bytes, Encode::FB_DEFAULT() ) };
  }
  return { kind => 'blob', type => 'resource', mime => $mime, uri => $res->{uri},
    data => $res->{blob} };
}

sub _mcp_item {
  my ($block) = @_;
  return { kind => 'note', text => _placeholder('unsupported') } unless ref $block eq 'HASH';
  my $type = $block->{type} // '';
  if ( $type eq 'text' ) {
    return { kind => 'text', text => ( $block->{text} // '' ),
      ( exists $block->{cache_control} ? ( cache_control => $block->{cache_control} ) : () ) };
  }
  return { kind => 'native', block => $block }
    if ( ( $type eq 'image' || $type eq 'document' ) && ref $block->{source} eq 'HASH' )
    || $type eq 'search_result';
  return _mcp_resource( $block->{resource} ) if $type eq 'resource';
  if ( $type eq 'resource_link' ) {
    return { kind => 'note', text => join( ' ', '[resource_link]',
      grep { defined && length } $block->{name},
      ( defined $block->{uri} ? "<$block->{uri}>" : () ) ) };
  }
  return { kind => 'blob', type => ( length $type ? $type : 'unsupported' ),
    mime => $block->{mimeType}, uri => $block->{uri}, data => $block->{data} };
}

sub _mcp_items {
  my ($self) = @_;
  return map { _mcp_item($_) } @{ $self->content };
}

# One item as text for the string wires.
sub _string_item {
  my ($item) = @_;
  my $kind = $item->{kind};
  return _placeholder( @{$item}{qw( type mime uri data )} ) if $kind eq 'blob';
  return $item->{text} unless $kind eq 'native';
  return _native_string( $item->{block} );
}

# An Anthropic-native block as text, for a wire that cannot carry it: a text
# document gives its text, a content document its inner parts (karr k367), a
# search_result a "[search_result] title <source>" line and its text parts
# (karr k366), anything else a placeholder. Inner parts render the same way.
sub _native_string {
  my ($native) = @_;
  return _placeholder('unsupported') unless ref $native eq 'HASH';
  my $type = $native->{type} // '';
  return $native->{text} // '' if $type eq 'text';
  if ( $type eq 'search_result' ) {
    my $source = $native->{source};
    my $head   = join ' ', '[search_result]', grep { defined && length } $native->{title},
      ( defined $source && !ref $source && length $source ? "<$source>" : () );
    return join "\n", $head, _native_parts( $native->{content} );
  }
  my $src = ref $native->{source} eq 'HASH' ? $native->{source} : {};
  my $src_type = $src->{type} // '';
  return $src->{data} if $src_type eq 'text' && defined $src->{data};
  if ( $src_type eq 'content' ) {
    my @parts = _native_parts( $src->{content} );
    return join "\n", @parts if @parts;
  }
  return _placeholder( $type, $src->{media_type}, $src->{url} );
}

sub _native_parts {
  my ($parts) = @_;
  return () unless defined $parts;
  return ($parts) unless ref $parts;
  return () unless ref $parts eq 'ARRAY';
  return map { _native_string($_) } @$parts;
}

# The whole result as one string: parts joined with "\n"; empty content falls
# back to the JSON-encoded structured_content, else ''. _string_of renders a
# subset, for a wire that carries the other items natively (karr k344).
sub _string_content {
  my ($self) = @_;
  return $self->_string_of( $self->_mcp_items );
}

sub _string_of {
  my ( $self, @items ) = @_;
  my @parts = map { _string_item($_) } @items;
  return join( "\n", @parts ) if @parts;
  return $JSON->encode( $self->structured_content ) if $self->has_structured_content;
  return '';
}

# --- Native tool-result images (karr k344) ---
#
# Two wires take an image inside a tool result: the Open Responses
# function_call_output (output = string | array of input_text / input_image
# parts; OpenAI /v1/responses and Perplexity /v1/agent) and Gemini 3's
# functionResponse.parts[].inlineData (v1beta). Docs-derived, not
# live-verified (2026-09-29). The caller (Role::Tools) passes image_input => 1
# only when the model sees images; without it, and on every other wire but
# Anthropic (same gate, karr k359, below), the image stays the k336
# placeholder.

my %RESPONSES_IMAGE_MIME = map { $_ => 1 } qw( image/jpeg image/png image/gif image/webp );
my %GEMINI_IMAGE_MIME    = map { $_ => 1 } qw( image/jpeg image/png image/webp );

# The base64 payload of an item the wire takes as an image, else undef.
sub _native_image_data {
  my ( $item, $mimes ) = @_;
  return undef unless $item->{kind} eq 'blob' && defined $item->{data} && !ref $item->{data};
  return undef unless $item->{type} eq 'image' || $item->{type} eq 'resource';
  return undef unless $mimes->{ $item->{mime} // '' };
  ( my $b64 = $item->{data} ) =~ s/\s+//g;
  return $b64;
}

# --- Native tool-result PDFs (karr k361) ---
#
# The same two wires take a PDF inside a tool result: OpenAI /v1/responses as
# an input_file part of function_call_output.output (API reference,
# FunctionCallOutput: string | [input_text | input_image | input_file]; the
# PDF-files guide sends file_data as a data:application/pdf;base64,... URL
# with a filename), Gemini 3 as functionResponse.parts[].inlineData
# (generate-content function-calling guide: "Documents: application/pdf,
# text/plain"). Perplexity's /v1/agent lists only input_text / input_image.
# Docs-derived, not live-verified (developers.openai.com, ai.google.dev,
# docs.perplexity.ai, 2026-09-30). The caller (Role::Tools) passes
# native_pdf => 1 only where the wire takes it and the model claims
# image_input; otherwise the PDF stays the k336 placeholder. A PDF is an MCP
# embedded resource blob, the one MCP shape that carries a document (as on the
# anthropic wire, k326).

# The base64 payload of an item that is a PDF, else undef.
sub _native_pdf_data {
  my ($item) = @_;
  return undef unless $item->{kind} eq 'blob' && $item->{type} eq 'resource';
  return undef unless ( $item->{mime} // '' ) eq 'application/pdf';
  return undef unless defined $item->{data} && !ref $item->{data};
  ( my $b64 = $item->{data} ) =~ s/\s+//g;
  return $b64;
}

# input_file's filename: the reference marks it optional, but the server
# rejects file_data without one (community reports, 2025-2026). The last
# segment of the resource URI's hierarchical path, percent-decoded (as UTF-8
# characters, like every string here -- k252), with .pdf appended when it has
# no such extension (the name is what the model sees the attachment as). An
# opaque URI (urn:, data:, a rootless scheme:path) or an empty path gives a
# generic name.
sub _pdf_filename {
  my ($uri) = @_;
  my $name = '';
  if ( defined $uri && !ref $uri && length $uri ) {
    my $parsed = URI->new($uri);
    if ( $parsed->isa('URI::_generic')
      && ( !defined $parsed->scheme || $parsed->path =~ m{\A/} ) ) {
      my ($segment) = $parsed->path =~ m{([^/]*)\z};
      $name = Encode::decode( 'UTF-8', URI::Escape::uri_unescape($segment),
        Encode::FB_DEFAULT() );
    }
  }
  return 'document.pdf' unless length $name;
  return $name =~ /\.pdf\z/i ? $name : "$name.pdf";
}

# --- Serializers to per-provider result blocks ---

sub to_openai {
  my ($self) = @_;
  # The chat tool message takes a string (or text parts only) -- karr k336.
  return {
    role         => 'tool',
    tool_call_id => $self->id,
    content      => $self->_string_content,
  };
}

sub to_ollama {
  my ($self) = @_;
  # Ollama's Message carries tool_name and tool_call_id (both omitempty); with
  # same-name parallel calls they are what correlates a result (karr k328).
  return {
    role      => 'tool',
    tool_name => $self->name,
    ( length( $self->id ) ? ( tool_call_id => $self->id ) : () ),
    content   => $self->_string_content,
  };
}

sub to_responses {
  my ( $self, %opts ) = @_;
  # A Responses API input item, not a chat message: the wire discriminates on
  # `type`, carries the payload in `output`, and has no `role` at all.
  return {
    type    => 'function_call_output',
    call_id => $self->id,
    output  => $self->_responses_output(%opts),
  };
}

# One item as a native Responses part (input_image with image_input, karr
# k344; input_file with native_pdf, karr k361), else undef.
sub _responses_native_part {
  my ( $item, %opts ) = @_;
  if ( $opts{image_input} ) {
    my $b64 = _native_image_data( $item, \%RESPONSES_IMAGE_MIME );
    return { type => 'input_image', image_url => "data:$item->{mime};base64,$b64" }
      if defined $b64;
  }
  if ( $opts{native_pdf} ) {
    my $b64 = _native_pdf_data($item);
    return { type => 'input_file', filename => _pdf_filename( $item->{uri} ),
      file_data => "data:application/pdf;base64,$b64" } if defined $b64;
  }
  return undef;
}

# With an item the wire takes natively, `output` becomes a part array in
# content order (one input_text per other item, as the string form renders
# it); without one it stays the string (karr k344, k361).
sub _responses_output {
  my ( $self, %opts ) = @_;
  my @items = $self->_mcp_items;
  my @native = map { _responses_native_part( $_, %opts ) } @items;
  return $self->_string_of(@items) unless grep { defined } @native;
  return [ map {
    $native[$_] // { type => 'input_text', text => _string_item( $items[$_] ) }
  } 0 .. $#items ];
}

# --- Anthropic tool_result content (karr k326) ---
#
# Anthropic's tool_result takes text | image | document | search_result blocks
# and rejects unknown fields, so MCP blocks are mapped, not embedded. The mapping
# follows anthropic-sdk-python lib/tools/mcp.py, except that nothing dies inside
# the tool loop: what Anthropic cannot carry (audio, resource_link, unsupported
# MIME types) becomes a text placeholder.
#
# Two options, both decided by the caller (Role::Tools) per engine and model:
#   image_input  an MCP image becomes an image block only with it (karr k359),
#                as on the responses / gemini wires: the /anthropic shims
#                answer 200 whether or not the model sees it. An
#                Anthropic-native image block the caller built passes through.
#   source_blocks  0 on a wire that rejects Anthropic's source blocks
#                (document, search_result) in a tool_result (karr k364, k366:
#                AKI's shim answers 529 "Unsupported content type: document" /
#                "... search_result"): a text document goes inline as a text
#                block, as on the string wires, a PDF as the placeholder. That
#                is wire truth, not a model question, so a native document or
#                search_result is degraded the same way (Role::Tools carps
#                when it does). Default 1.

my %ANTHROPIC_IMAGE_MIME = map { $_ => 1 } qw( image/jpeg image/png image/gif image/webp );

# The Anthropic-native block types source_blocks => 0 degrades.
my %ANTHROPIC_SOURCE_BLOCK = map { $_ => 1 } qw( document search_result );

sub _anthropic_block {
  my ( $item, %opts ) = @_;
  my $kind          = $item->{kind};
  my $source_blocks = $opts{source_blocks} // 1;
  if ( $kind eq 'native' ) {
    return $item->{block} if $source_blocks || !$ANTHROPIC_SOURCE_BLOCK{ $item->{block}{type} };
    return { type => 'text', text => _string_item($item) };
  }
  if ( $kind eq 'text' ) {
    return { type => 'text', text => $item->{text},
      ( exists $item->{cache_control} ? ( cache_control => $item->{cache_control} ) : () ) };
  }
  return { type => 'text', text => $item->{text} } if $kind eq 'note';
  if ( $kind eq 'document' ) {
    return { type => 'text', text => $item->{text} } unless $source_blocks;
    return { type => 'document',
      source => { type => 'text', media_type => 'text/plain', data => $item->{text} } };
  }
  my ( $type, $mime, $data ) = ( $item->{type}, $item->{mime} // '', $item->{data} );
  if ( defined $data && ( $type eq 'image' || $type eq 'resource' ) ) {
    return { type => 'image', source => { type => 'base64', media_type => $mime, data => $data } }
      if $opts{image_input} && $ANTHROPIC_IMAGE_MIME{$mime};
    return { type => 'document',
      source => { type => 'base64', media_type => 'application/pdf', data => $data } }
      if $source_blocks && $type eq 'resource' && $mime eq 'application/pdf';
  }
  return { type => 'text', text => _placeholder( @{$item}{qw( type mime uri data )} ) };
}

sub _anthropic_content {
  my ( $self, %opts ) = @_;
  my @blocks = map { _anthropic_block( $_, %opts ) } $self->_mcp_items;
  return \@blocks if @blocks;
  return $JSON->encode( $self->structured_content ) if $self->has_structured_content;
  return '';
}

# The types of the Anthropic-native source blocks a caller put into the
# content, each once: what source_blocks => 0 degrades. Role::Tools warns about
# them (karr k366); an MCP resource is the normal path and not among them.
sub _native_source_block_types {
  my ($self) = @_;
  my %seen;
  return grep { $ANTHROPIC_SOURCE_BLOCK{$_} && !$seen{$_}++ }
    map { $_->{block}{type} } grep { $_->{kind} eq 'native' } $self->_mcp_items;
}

sub to_anthropic {
  my ( $self, %opts ) = @_;
  return {
    type        => 'tool_result',
    tool_use_id => $self->id,
    content     => $self->_anthropic_content(%opts),
    ( $self->is_error ? ( is_error => JSON::MaybeXS::true() ) : () ),
  };
}

sub to_gemini {
  my ( $self, %opts ) = @_;
  # With image_input, an image Gemini 3 takes moves out of the result string
  # into functionResponse.parts[].inlineData (karr k344), with native_pdf a
  # PDF likewise (karr k361). No displayName: it is only needed to $ref a
  # part from `response`, and the v1beta discovery schema of
  # FunctionResponseBlob does not list it.
  my ( @rest, @parts );
  for my $item ( $self->_mcp_items ) {
    my ( $b64, $mime );
    $b64 = _native_image_data( $item, \%GEMINI_IMAGE_MIME ) if $opts{image_input};
    $mime = $item->{mime} if defined $b64;
    if ( !defined $b64 && $opts{native_pdf} ) {
      $b64  = _native_pdf_data($item);
      $mime = 'application/pdf';
    }
    if ( defined $b64 ) {
      push @parts, { inlineData => { mimeType => $mime, data => $b64 } };
    }
    else {
      push @rest, $item;
    }
  }
  # functionResponse.response is a JSON object: the MCP structuredContent when
  # the tool gave one, else the result string under `result` (karr k336).
  # It is required, so an image-only result still sends a `result` string
  # ('' unless a non-hash structuredContent fills it).
  my $structured = $self->structured_content;
  return {
    functionResponse => {
      name     => $self->name,
      # Gemini 3 requires the functionCall's id back; 2.5 may send none, and
      # an invented one would match nothing (karr k328).
      ( length( $self->id ) ? ( id => $self->id ) : () ),
      response => ( ref $structured eq 'HASH'
        ? $structured : { result => $self->_string_of(@rest) } ),
      ( @parts ? ( parts => \@parts ) : () ),
    },
  };
}

sub to_hermes {
  my ( $self, %opts ) = @_;
  my $tag = $opts{response_tag} // 'tool_response';
  return "<${tag}>\n"
    . $JSON->encode( { name => $self->name, content => $self->_string_content } )
    . "\n</${tag}>";
}

# --- Tag-driven dispatch ---

my %TO_METHOD = (
  openai    => 'to_openai',
  anthropic => 'to_anthropic',
  gemini    => 'to_gemini',
  ollama    => 'to_ollama',
  responses => 'to_responses',
  hermes    => 'to_hermes',
);


sub to {
  my ( $self, $fmt, %opts ) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::ToolResult: unknown wire format '" . ( $fmt // '' ) . "'";
  return $self->$method(%opts);
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::ToolResult - Immutable canonical result of executing one tool, with cross-provider conversion

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::ToolResult;

    my $result = Langertha::ToolResult->new(
        name     => 'get_weather',
        id       => 'call_abc',
        content  => [ { type => 'text', text => 'Sunny, 22C' } ],
        is_error => 0,
    );

    my $block = $result->to('anthropic');
    # { type => 'tool_result', tool_use_id => 'call_abc', content => [...] }

=head1 DESCRIPTION

Canonical, provider-neutral result of a single tool execution. Serializes to
the per-provider result I<block> via C<to($fmt)> — one block per result. The
surrounding message envelope (arity, the assistant echo of the prior turn) is
assembled by L<Langertha::Role::Tools>, not here: a ToolResult knows only its
own block shape.

The C<content> is the MCP-style content array (C<[ { type => 'text', text =>
... } ]>). OpenAI, OpenAI Responses, Ollama and Hermes send it as one string:
text parts joined with C<"\n">, an embedded text resource as its text, a
C<text/*> blob decoded as UTF-8, a C<resource_link> as
C<[resource_link] name E<lt>uriE<gt>>, and an image, audio or binary blob as a
placeholder such as C<[image] image/png (12345 bytes)> -- never the base64
payload. Gemini sends that string as C<< { result => ... } >>, or the
L</structured_content> object itself when there is one.

Anthropic takes structured blocks, so each MCP block is mapped onto one: text
keeps only C<text> (and C<cache_control>); an image, or an embedded resource
whose blob is an image, becomes a base64 C<image> (JPEG, PNG, GIF, WebP) when
C<to> is called with C<< image_input => 1 >> (see below), else the text
placeholder; a PDF blob becomes a base64 C<document>; a text resource (whatever
its MIME type) or a C<text/*> blob becomes a text C<document>. Anthropic-native
C<image> / C<document> blocks (with a C<source>) and C<search_result> pass
through. Everything else -- C<resource_link>, audio, other MIME types -- becomes
the same text placeholder, naming type, MIME type, URI and size.

With C<< source_blocks => 0 >> the Anthropic form sends no C<document> or
C<search_result> block, for a server that rejects them inside a
C<tool_result>: a text resource or C<text/*> blob becomes a C<text> block
holding the text (as on the string wires), a PDF blob the placeholder, and an
Anthropic-native C<document> or C<search_result> a C<text> block with the text
it has in the string form (below). L<Langertha::Role::Tools/format_tool_results>
passes it on the C</anthropic> shims of AKI.IO, Moonshot and
(conservatively, not live-verified) LM Studio.

An Anthropic-native block on a string wire (or with C<< source_blocks => 0 >>)
keeps its text: a C<document> with a C<text> source gives that text, one with a
C<content> source its inner parts joined with C<"\n"> (an image among them as a
placeholder), a C<search_result> a line C<[search_result] title E<lt>sourceE<gt>>
followed by its text parts. Anything else becomes a placeholder.

On every string wire and on Anthropic, empty content goes out as the
JSON-encoded L</structured_content>, or as C<''>.

Three wires carry an image natively, and do so only when C<to> is called with
C<< image_input => 1 >> (L<Langertha::Role::Tools/format_tool_results> passes
it when the model claims C<image_input>):

=over

=item * C<anthropic> -- the base64 C<image> block above. Documented for
first-party Anthropic; on the C</anthropic> shims it is not live-verified:
Kimi's schema lists C<image> inside a C<tool_result> (docs only), MiniMax
documents nothing about it, and the only live evidence is negative (AKI.IO's
shim accepts it but its models do not see it, so that engine never sends it).

=item * C<responses> -- C<output> becomes an array of parts in content order:
an image (C<image> block or image resource; JPEG, PNG, GIF, WebP) is an
C<input_image> with a C<data:> URL in C<image_url>, every other item an
C<input_text> with the text it has in the string form. Without such an image
C<output> stays the string. OpenAI C</v1/responses> and Perplexity
C</v1/agent> document the same shape.

=item * C<gemini> -- an image (JPEG, PNG, WebP) moves out of the C<result>
string into C<< functionResponse.parts[].inlineData >> (C<mimeType>,
C<data>). Documented for the Gemini 3 series (v1beta) only.

=back

The C<responses> and C<gemini> forms are B<documentation-derived, not
live-verified>. C<openai>, C<ollama> and C<hermes> have no image form in a
tool result and ignore the option: the image stays a placeholder there.

A PDF (an embedded resource whose blob is C<application/pdf>) rides natively
on two more of those wires when C<to> is called with C<< native_pdf => 1 >>
(L<Langertha::Role::Tools/format_tool_results> passes it on OpenAI Responses
and Gemini 3, for a model that claims C<image_input>):

=over

=item * C<responses> -- C<output> becomes the part array as above, the PDF an
C<input_file> with C<file_data> (a C<data:application/pdf;base64,...> URL) and
a C<filename>: the percent-decoded last segment of the resource URI's
hierarchical path, with C<.pdf> appended when missing; an opaque URI
(C<urn:>, C<data:>) or an empty path gives C<document.pdf>. Documented for OpenAI
C</v1/responses>; Perplexity's C</v1/agent> takes no C<input_file>, so the
PDF stays the placeholder there.

=item * C<gemini> -- the PDF moves out of the C<result> string into
C<< functionResponse.parts[].inlineData >> with C<mimeType>
C<application/pdf>. Documented for the Gemini 3 series.

=back

Both are B<documentation-derived, not live-verified>. The other wires ignore
C<native_pdf>: C<openai>, C<ollama> and C<hermes> keep the placeholder, and
C<anthropic> sends its C<document> block whenever C<source_blocks> allows it.

Not every block is a chat message: the OpenAI Responses block is an C<input>
I<item> discriminated by C<type> (C<function_call_output>), carrying its payload
in C<output> and no C<role> at all.

=head2 name

The tool's name. Used by formats that key results by name (Gemini, Hermes,
Ollama's C<tool_name>).

=head2 id

The provider call id this result answers (C<tool_call_id> / C<tool_use_id> /
C<call_id>; Gemini's C<functionResponse.id>, Ollama's C<tool_call_id>). May be
empty; Gemini and Ollama then send no id at all.

=head2 content

The MCP-style content array of the tool's output, e.g.
C<[ { type => 'text', text => '...' } ]>.

=head2 is_error

Boolean. True when the tool execution failed; surfaced on formats that carry an
error flag (Anthropic C<is_error>).

=head2 structured_content

The MCP C<structuredContent> of the tool's output, if any. Sent JSON-encoded as
the result string when C<content> is empty; Gemini sends the object as its
C<functionResponse.response> whenever it is present.

=head2 to

    my $block = $result->to($fmt);
    my $block = $result->to('hermes', response_tag => 'fn_response');
    my $block = $result->to('responses', image_input => 1);
    my $block = $result->to('gemini', image_input => 1, native_pdf => 1);

Serializes to the result block for the given C<tool_wire_format>. Extra options
are passed through to the per-format serializer (Hermes accepts
C<response_tag>; C<responses>, C<gemini> and C<anthropic> accept
C<image_input>, C<responses> and C<gemini> also C<native_pdf>, C<anthropic>
also C<source_blocks>, see L</DESCRIPTION>; the other formats ignore them).

=head1 SEE ALSO

=over

=item * L<Langertha::ToolCall> - The invocation a ToolResult answers

=item * L<Langertha::Tool> - The tool definition

=item * L<Langertha::Role::Tools> - Assembles result blocks into the message envelope

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

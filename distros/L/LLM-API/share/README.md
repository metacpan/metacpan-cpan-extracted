# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [CONFIGURATION](#configuration)
* [CONSTANTS](#constants)
* [METHODS AND SUBROUTINES](#methods-and-subroutines)
  * [new](#new)
  * [count\_input\_tokens](#count\input\tokens)
  * [send\_prompt](#send\prompt)
  * [prompt](#prompt)
  * [text](#text)
  * [document](#document)
  * [models](#models)
  * [api\_keys](#api\keys)
  * [usage\_report](#usage\report)
  * [cost\_report](#cost\report)
  * [headers](#headers)
  * [pricing](#pricing)
  * [rfc\_3339](#rfc\3339)
  * [query\_string](#query\string)
  * [now](#now)
* [ACCESSORS](#accessors)
* [ENVIRONMENT](#environment)
* [CAVEATS](#caveats)
* [DEPENDENCIES](#dependencies)
* [SEE ALSO](#see-also)
* [VERSION](#version)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

LLM::API - Anthropic API client for Claude language models

# SYNOPSIS

    use LLM::API;
    use CLI::Simple::Utils qw(slurp);

    my $llm = LLM::API->new(
      api_key => 'sk-ant-...',
    );

    # Send a simple text prompt
    my $response = $llm->prompt('Summarize the Perl documentation.');

    if ( $response->is_success ) {
      print $response->content;
    }

    # Send a document with a prompt
    my $file = 'My/Module.pm';
    my $doc  = $llm->document( media_type => 'text', data => slurp($file), title => 'My::Module' );
    my $text = $llm->text('Review this perl module');
    my $rsp  = $llm->send_prompt( [ $doc, $text ] );

    # Retrieve usage and cost data
    my $usage = $llm->usage_report( from => '2025-01-01', to => '2025-01-31' );
    my $cost  = $llm->cost_report( from => '2025-01-01' );

# DESCRIPTION

LLM::API is a client for the Anthropic Claude REST API. It supports sending
text and document prompts to Claude models, retrieving model lists, API key
information, and querying organizational usage and cost reports.

Authentication is handled by passing an API key at construction time or by
setting the LLM\_API\_KEY environment variable. The environment variable is
deleted from the process environment immediately after it is read, as a
security measure to prevent accidental exposure to child processes.

# CONFIGURATION

The following options may be passed to new():

    api_key

      Required. Your Anthropic API key. If not provided as an argument, the
      constructor reads it from the LLM_API_KEY environment variable and then
      deletes that variable from the environment.

    model

      Optional. The Claude model identifier to use. Defaults to claude-sonnet-4-6.

    max_tokens

      Optional. Maximum number of tokens in the model response. Defaults to 4096.

    timeout

      Optional. HTTP request timeout in seconds. Defaults to 300.

    version

      Optional. Anthropic API version string sent in the anthropic-version header.
      Defaults to 2023-06-01.

    role

      Optional. The message role sent with each request. Defaults to 'user'.

# CONSTANTS

The following Readonly constants are exported into the package namespace and
may be referenced as LLM::API::CONSTANT\_NAME.

    $DEFAULT_LLM_MODEL

      The default model: claude-sonnet-4-6.

    $LLM_URL_BASE

      Base URL for the Anthropic API: https://api.anthropic.com/v1/

    $LLM_COUNT_TOKENS_EP

      Endpoint for the determing the number of tokens in a message.

    $LLM_MESSAGES_EP

      Endpoint path for sending messages: 'messages'

    $LLM_MODELS_EP

      Endpoint path for listing models: 'models'

    $LLM_USAGE_EP

      Endpoint path for usage reports: 'organizations/usage_report/messages'

    $LLM_COST_EP

      Endpoint path for cost reports: 'organizations/cost_report'

    $LLM_KEYS_EP

      Endpoint path for API key listings: 'organizations/api_keys'

    $LLM_MAX_TOKENS

      Default maximum token count for responses: 4096

    $LLM_VERSION

      Default Anthropic API version header value: '2023-06-01'

    $LLM_ROLE

      Default message role: 'user'

    $LLM_TIMEOUT

      Default HTTP timeout in seconds: 300

    $LLM_PRICING

      A hash reference mapping model names to two-element array
      references containing the per-token input cost and per-token
      output cost in US dollars.

    %LLM_MEDIA_TYPES

      A hash mapping short type names to MIME type strings.
      Supported keys are 'text' (maps to 'text/plain') and 'pdf'
      (maps to 'application/pdf').

# METHODS AND SUBROUTINES

## new

    my $llm = LLM::API->new( api_key => $key );
    my $llm = LLM::API->new( \%options );

Constructs and returns a new LLM::API instance. Accepts either a hash of
named arguments or a reference to a hash.

The `api_key` argument is required and may alternatively be supplied via the
LLM\_API\_KEY environment variable. The environment variable is deleted from
%ENV immediately after being read.

Dies with an error message if `api_key` is not provided.

## count\_input\_tokens

    my ( $tokens, $cost ) = $llm->count_input_tokens( $content );

Counts the input tokens in the supplied content by querying the
Anthropic API token counting endpoint without generating a message
response. The argument must be an array reference of content
block structures such as those produced by `text()` and
`document()`.

Returns a two-element list: the number of input tokens and the
estimated cost in US dollars at the current pricing for the configured
model. The cost is calculated by multiplying the token count by the
per-token input cost from the pricing table.

Throws an exception if the argument is not an array reference.

## send\_prompt

    my $response = $llm->send_prompt( $content );

Sends a messages request to the Anthropic API. The argument must be an
array reference of content block structures such as those produced by
`text()` and `document()` (see [document](https://metacpan.org/pod/document), [text](https://metacpan.org/pod/text)). Returns an
[LLM::API::Response](https://metacpan.org/pod/LLM%3A%3AAPI%3A%3AResponse) object. Throws an exception if argument is not
an array reference.

Use the `is_success` method of the response to test for success before accessing response data.

    die $response->error
      if !$response->is_success;

`send_prompt` does not throw exceptions on HTTP failure; instead
failure information is contained in the response object.

See [LLM::API::Response](https://metacpan.org/pod/LLM%3A%3AAPI%3A%3AResponse) for detail on response object methods.

## prompt

    my $response = $llm->prompt( $text_string );

Convenience wrapper around send\_prompt(). Wraps the supplied plain text string
in a text content block and submits it to the API. Returns an
LLM::API::Response object.

## text

    my $block = $llm->text( $text );

Constructs and returns a text content block hash reference suitable for
inclusion in the content array passed to send\_prompt().

## document

    my $block = $llm->document(
      media_type => 'text',   # 'text' or 'pdf'
      data       => $string,  # plain text, or a scalar reference for binary data
      title      => $title,   # optional
    );

Constructs and returns a document content block hash reference suitable for
inclusion in the content array passed to send\_prompt().

When data is a plain scalar string the source type is set to 'text'
and the data is used as-is.

When data is a scalar reference the referenced value is base64-encoded
using MIME::Base64::encode\_base64(), which by default includes
newlines every 76.  This is the mechanism for submitting PDF files.

The media\_type argument accepts the short keys defined in
%LLM\_MEDIA\_TYPES: 'text' or 'pdf'. It defaults to 'text'. Any other
value will throw an exception. The corresponding MIME type is resolved
internally before the block is constructed.

## models

    my $data = $llm->models;

Retrieves the list of available models from the Anthropic API. Returns
the decoded JSON response as a Perl data structure on success, or
throws an exception containing the HTTP response code and HTTP body.

See [https://platform.claude.com/docs/en/api/beta/models/list](https://platform.claude.com/docs/en/api/beta/models/list) for more details.

## api\_keys

    my $data = $llm->api_keys;

Retrieves the list of API keys for the organization from the Anthropic
API.  Returns the decoded JSON response as a Perl data structure on
success, or throws an exception containing the HTTP response code and
HTTP body.

_Note: This endpoint requires the use of an admin API key._

See [https://platform.claude.com/docs/en/api/admin/api\_keys/list](https://platform.claude.com/docs/en/api/admin/api_keys/list) for more details.

## usage\_report

    my $data = $llm->usage_report(
      from         => '2025-01-01',          # defaults to today
      to           => '2025-01-31',          # optional end date
      api_key_ids  => [$api_key_id],         # optional array of API key filters
      bucket_width => '1h',                  # optional, defaults to '1h'
    );

Queries the Anthropic organizational usage report endpoint for message usage
data. The from and to values are date strings accepted in either 'YYYY-MM-DD'
or 'YYYY-MM-DD HH:MM' format and are converted to RFC 3339 timestamps
internally. from defaults to today's local date if not supplied.

Returns the decoded JSON response as a Perl data structure on success,
or throws an exception containing the HTTP response code and HTTP body.

See
[https://platform.claude.com/docs/en/api/admin/usage\_report/retrieve\_messages](https://platform.claude.com/docs/en/api/admin/usage_report/retrieve_messages)
for more details.

## cost\_report

    my $data = $llm->cost_report(
      from         => '2025-01-01',          # defaults to today
      to           => '2025-01-31',          # optional end date
      bucket_width => '1d',                  # optional, defaults to '1d'
    );

Queries the Anthropic organizational cost report endpoint. Date arguments
follow the same rules as usage\_report(). The default bucket\_width for cost
reports is '1d' rather than '1h'.

Returns the decoded JSON response as a Perl data structure on success,
or throws an exception containing the HTTP response code and HTTP body.

See [https://platform.claude.com/docs/en/api/admin/cost\_report/retrieve](https://platform.claude.com/docs/en/api/admin/cost_report/retrieve) for more detail.

## headers

    my $headers = $llm->headers;
    my $headers = $llm->headers( 'content-type' => 'application/json' );

Builds and returns a hash reference of HTTP request headers. Always includes
the x-api-key and anthropic-version headers. Additional header key-value pairs
may be supplied as a flat list and are merged into the returned hash.

## pricing

    my ( $input_cost, $output_cost ) = $llm->pricing;
    my ( $input_cost, $output_cost ) = $llm->pricing( $model_name );

Returns the per-token input and output costs in US dollars for the
specified model. Throws an exception of no pricing is available for
the model.

_Note: Costs are expressed as fractional dollar amounts per single
token (for example, 0.000003 for $3 per million)._

## rfc\_3339

    my $timestamp = $llm->rfc_3339( '2025-01-15' );
    my $timestamp = $llm->rfc_3339( '2025-01-15 14:30' );

Interprets the input date string as local time and converts it to an
RFC 3339 formatted UTC timestamp string of the form
YYYY-MM-DDTHH:MM:SSZ.

Accepts exactly two input formats:

    YYYY-MM-DD
    YYYY-MM-DD HH:MM

Throws an exception if an unsupported format is passed.

Returns a formatted timestamp conforming to RFC 3339 if a valid date
and format are passed. Throws an exception if passed invalid
dates. (see [Time::Piece](https://metacpan.org/pod/Time%3A%3APiece))

## query\_string

    my $qs = $llm->query_string( key => 'value', other => 'data' );

Builds a URL query string from a flat hash of key-value pairs. Values
are URI-encoded using `URI::Encode`. Returns a string of the form
'key=value&other=data'.  The order of parameters in the returned
string is not guaranteed.

Values can be scalars, arrays or hashes. Arrays and hashes will be
expanded in the query string as describe in the examples below.

- Array Behavior

    When an array reference is passed as a value, each element is added to
    the query string as a separate parameter with the same key.

        $llm->query_string( id => [1, 2] );
        

    Produces: `id=1&id=2`

- Hashes Behavior

    When a hash reference is passed as a value, each nested key-value pair
    becomes an individual query parameter using the nested key as the
    parameter name, and the outer key is discarded.

        $llm->query_string(filters => {status => "active", type => "user"});

    Produces: `status=active&type=user`

## now

    my $date = $llm->now;

Returns the current local date as a string in 'YYYY-MM-DD' format. Used
internally as the default starting date for usage and cost reports.

# ACCESSORS

The following read/write accessors are generated by Class::Accessor::Fast
using the follow\_best\_practice naming convention. Use get\_NAME to read a
value and set\_NAME to write it.

    get_api_key_getter / set_api_key_getter

      Holds a code reference that returns the API key when called. The API key
      is stored only inside this closure and is not exposed directly as an
      attribute value.

    get_max_tokens / set_max_tokens

      Maximum number of tokens the model may return in a single response.

    get_model / set_model

      The model identifier string used for API requests.

    get_version / set_version

      The Anthropic API version string sent in the anthropic-version request header.

    get_role / set_role

      The message role string included in each messages API request.

    get_timeout / set_timeout

      The HTTP request timeout in seconds sent to L<HTTP::Tiny> by all API calls.

# ENVIRONMENT

- LLM\_API\_KEY

    If set, the constructor reads this variable as the API key. The
    variable is immediately deleted from %ENV after being read to reduce
    the risk of exposing the key to child processes. Setting both this
    variable and the api\_key constructor argument is allowed; the
    constructor argument takes precedence

    _Note: `LLM_API_KEY` is deleted from the environment as a security
    measure regardless of whether it is used._

- DEBUG

    If set to a true value at program startup, Data::Dumper is loaded and
    its Dumper function is imported into the current namespace. This is
    intended for development use only and has no effect on API behavior.

# CAVEATS

- The rfc\_3339() method recognizes exactly two date string formats
(see ["rfc\_3339"](#rfc_3339)). Supplying an invalid date string or one that does
not conform to two supported formats will raise an exception from
`Time::Piece::strptime`.
- The query\_string() method does not guarantee parameter ordering. When the
Anthropic API requires parameters in a specific order this should not be
a concern because HTTP query strings are order-independent, but callers
relying on a stable string representation should not depend on the output order.
- Pricing constants are hardcoded for claude-sonnet-4-6 and reflect the rates
at the time this module was written. Anthropic may change pricing at any time.
Verify current rates at [https://www.anthropic.com/pricing](https://www.anthropic.com/pricing) before relying
on these values for billing calculations.

# DEPENDENCIES

    Class::Accessor::Fast
    CLI::Simple::Constants
    CLI::Simple::Utils
    English
    HTTP::Tiny
    JSON::PP
    LLM::API::Response (provided by this distribution)
    MIME::Base64
    Readonly
    Time::Piece
    URI::Encode

# SEE ALSO

[LLM::API::Response](https://metacpan.org/pod/LLM%3A%3AAPI%3A%3AResponse)

[HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny)

[Class::Accessor::Fast](https://metacpan.org/pod/Class%3A%3AAccessor%3A%3AFast)

[JSON::PP](https://metacpan.org/pod/JSON%3A%3APP)

[MIME::Base64](https://metacpan.org/pod/MIME%3A%3ABase64)

[Time::Piece](https://metacpan.org/pod/Time%3A%3APiece)

[URI::Encode](https://metacpan.org/pod/URI%3A%3AEncode)

[Readonly](https://metacpan.org/pod/Readonly)

Anthropic API documentation: [https://docs.anthropic.com/en/api/](https://docs.anthropic.com/en/api/)

Anthropic pricing: [https://www.anthropic.com/pricing](https://www.anthropic.com/pricing)

# VERSION

This documentation refers to version 1.0.1.

# AUTHOR

See the distribution metadata for author information.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

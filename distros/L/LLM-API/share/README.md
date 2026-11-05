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
  * [send\_messages](#send\messages)
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
* [PROVIDER CATALOG](#provider-catalog)
* [CAVEATS](#caveats)
* [DEPENDENCIES](#dependencies)
* [SEE ALSO](#see-also)
* [VERSION](#version)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

LLM::API - Provider-independent LLM client

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

    # Send a multi-turn conversation
    my $conversation = $llm->send_messages( [
      { role => 'user',      content => [ $llm->text('What is a Perl role?') ] },
      { role => 'assistant', content => [ $llm->text('A reusable unit of behavior.') ] },
      { role => 'user',      content => [ $llm->text('Give an example.') ] },
    ] );

    # Use Amazon Bedrock with AWS credentials instead of an Anthropic API key
    my $bedrock = LLM::API->new(
      provider => 'bedrock',
      model    => 'us.anthropic.claude-haiku-4-5-20251001-v1:0',
      region   => 'us-east-1',
    );

    # Anthropic-only administrative reporting
    my $usage = $llm->usage_report( from => '2025-01-01', to => '2025-01-31' );
    my $cost  = $llm->cost_report( from => '2025-01-01' );

# DESCRIPTION

LLM::API supports Anthropic's direct API and Amazon Bedrock. The provider is
selected at construction time, and text and document content blocks and
[LLM::API::Response](https://metacpan.org/pod/LLM%3A%3AAPI%3A%3AResponse) objects provide a common interface. The client supports
single-turn prompts and explicit multi-turn conversations. Bedrock can invoke
supported Amazon Nova and Anthropic Claude models; Anthropic's direct API
supports Claude models.

For Anthropic, authentication uses an API key supplied to the constructor or
in the `LLM_API_KEY` environment variable. For Bedrock, the underlying AWS
client resolves AWS credentials; no Anthropic API key is required. The
constructor deletes `LLM_API_KEY` from the process environment after reading
it, including when a constructor argument takes precedence.

Model listing, API-key administration, organizational usage reports, and
organizational cost reports in this module are supported only for Anthropic's
direct API. There is no Bedrock model-discovery interface.

Provider classes and model pricing are curated in `providers.yml`, shipped
in the distribution's share directory. This catalog is not a list of models
currently accessible to the caller's credentials.

# CONFIGURATION

The following options may be passed to new():

    provider

      Optional. Defaults to anthropic. Use bedrock for AWS Bedrock Converse.

    api_key

      Required for Anthropic, not used for Bedrock. Your Anthropic API key. If not provided as an argument, the
      constructor reads it from the LLM_API_KEY environment variable and then
      deletes that variable from the environment.

    model

      Optional. Defaults to claude-sonnet-4-6 for Anthropic, or amazon.nova-micro-v1:0 for Bedrock.

    max_tokens

      Optional. Maximum number of tokens in the model response. Defaults to 8192.

    region

      Optional for Bedrock. Uses AWS_REGION, then AWS_DEFAULT_REGION, then
      us-east-1. This is the AWS request Region; cross-Region inference routing
      is selected by the model/inference profile identifier.

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

      Default maximum token count for responses: 8192

    $LLM_VERSION

      Default Anthropic API version header value: '2023-06-01'

    $LLM_ROLE

      Default message role: 'user'

    $LLM_TIMEOUT

      Default HTTP timeout in seconds: 300

    %LLM_MEDIA_TYPES

      A hash mapping short type names to MIME type strings.
      Supported keys are 'text' (maps to 'text/plain') and 'pdf'
      (maps to 'application/pdf').

# METHODS AND SUBROUTINES

## new

    my $llm = LLM::API->new( api_key => $key );
    my $llm = LLM::API->new( \%options );
    my $llm = LLM::API->new( provider => 'anthropic', api_key => $key );
    my $llm = LLM::API->new( provider => 'bedrock', region => 'us-east-1' );

Constructs and returns a new LLM::API instance. Accepts either a hash of
named arguments or a reference to a hash.

For `provider => 'anthropic'` (the default), `api_key` is required
and may alternatively be supplied via `LLM_API_KEY`. The variable is deleted
from `%ENV` after being read. For `provider => 'bedrock'`, no Anthropic
API key is required; AWS credential resolution is handled by the underlying
AWS client. The constructor rejects unsupported providers.

The default models are `claude-sonnet-4-6` for Anthropic and
`amazon.nova-micro-v1:0` for Bedrock. Model IDs are passed to the selected
provider; inclusion in `providers.yml` is required for pricing lookup, not
for model invocation.

## count\_input\_tokens

    my ( $tokens, $cost ) = $llm->count_input_tokens( $content );

Counts the input tokens in the supplied content by querying the
selected provider's token counting endpoint without generating a message
response. For Bedrock this uses `CountTokens` with Converse-formatted
messages, where supported by the selected model. The argument must be an
array reference of content blocks, such as those produced by `text()` and
`document()`.

Returns a two-element list: the number of input tokens and the estimated
input cost in US dollars, calculated using the selected provider and model's
input rate from `providers.yml`. An unpriced model raises an error rather
than silently reporting zero cost. Model-specific token counting availability
is determined by the provider.

Throws an exception if the argument is not an array reference.

## send\_prompt

    my $response = $llm->send_prompt( $content );

Sends a messages request to the selected provider. The argument must be an
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

## send\_messages

    my $response = $llm->send_messages( [
      { role => 'user',      content => [ $llm->text('Hello') ] },
      { role => 'assistant', content => [ $llm->text('Hello!') ] },
      { role => 'user',      content => [ $llm->text('Explain closures.') ] },
    ] );

Sends an explicit multi-turn conversation to the selected provider. The
argument must be a nonempty array reference of message hash references.
Each message requires a `role` of `user` or `assistant` and a nonempty
`content` array reference containing text or document blocks produced by
`text()` or `document()`.

Text blocks must contain a defined `text` value. Document blocks must
appear in user messages and contain a source hash reference. This method
validates the message shape before delegating to the provider; additional
provider and model restrictions may apply. It returns an
[LLM::API::Response](https://metacpan.org/pod/LLM%3A%3AAPI%3A%3AResponse) object. The caller supplies the complete conversation
on each invocation; this method does not maintain conversation history.

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

For Bedrock, text documents are sent as text content. PDF sources are
translated into Converse document blocks with a safe document name. The
adapter decodes the document helper's base64 source into raw bytes and passes
those bytes to the AWS transport, which performs base64 encoding for the
JSON request. A PDF must be accompanied by a nonempty text prompt in the
same user message, and the selected model must support PDF documents.
Nova Micro is text-only; use a document-capable model for PDF requests.
The `document()` return structure remains unchanged for Anthropic callers.

## models

This method is available only with `provider => 'anthropic'`; it
throws an exception for other providers.

    my $data = $llm->models;

Retrieves the list of available models from the Anthropic API. Returns
the decoded JSON response as a Perl data structure on success, or
throws an exception containing the HTTP response code and HTTP body.

See [https://platform.claude.com/docs/en/api/beta/models/list](https://platform.claude.com/docs/en/api/beta/models/list) for more details.

## api\_keys

This method is available only with `provider => 'anthropic'`; it
throws an exception for other providers.

    my $data = $llm->api_keys;

Retrieves the list of API keys for the organization from the Anthropic
API.  Returns the decoded JSON response as a Perl data structure on
success, or throws an exception containing the HTTP response code and
HTTP body.

_Note: This endpoint requires the use of an admin API key._

See [https://platform.claude.com/docs/en/api/admin/api\_keys/list](https://platform.claude.com/docs/en/api/admin/api_keys/list) for more details.

## usage\_report

This method is available only with `provider => 'anthropic'`; it
throws an exception for other providers.

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

This method is available only with `provider => 'anthropic'`; it
throws an exception for other providers.

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

Delegates HTTP header construction to the selected provider. For Anthropic,
the returned hash reference includes `x-api-key` and `anthropic-version`;
additional header key-value pairs may be supplied as a flat list. Bedrock
uses AWS authentication rather than Anthropic API-key headers.

## pricing

    my ( $input_cost, $output_cost ) = $llm->pricing;
    my ( $input_cost, $output_cost ) = $llm->pricing( $model_name );

Returns the per-token input and output costs in US dollars for the
specified model and selected provider. Prices are loaded from the
installed `providers.yml` catalog. The optional model argument defaults
to `get_model`. Bedrock pricing is keyed by the complete model or inference
profile identifier, so global and geographic profiles may have different
rates. Throws an exception if pricing is not available for the
provider/model combination; an unpriced model may still be invoked.

_Note: Costs are expressed as fractional dollar amounts per single
token (for example, 0.000003 for $3 per million)._

## rfc\_3339

    my $timestamp = $llm->rfc_3339( '2025-01-15' );
    my $timestamp = $llm->rfc_3339( '2025-01-15 14:30' );

Parses the input date string using `Time::Piece::strptime` and formats
it as `YYYY-MM-DDTHH:MM:SSZ`. The method appends a literal `Z`; it does
not explicitly convert a local-time value to UTC. Callers should not rely
on it to perform timezone conversion.

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

    get_provider / set_provider

      The selected provider identifier, such as 'anthropic' or 'bedrock'.

    get_region / set_region

      The AWS request Region for Bedrock. Not used for Anthropic requests.

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

- AWS\_REGION / AWS\_DEFAULT\_REGION

    For Bedrock, `AWS_REGION` takes precedence over `AWS_DEFAULT_REGION`.
    When neither is set and no `region` is provided, `us-east-1` is used.

- DEBUG

    If set to a true value at program startup, Data::Dumper is loaded and
    its Dumper function is imported into the current namespace. This is
    intended for development use only and has no effect on API behavior.

# PROVIDER CATALOG

`providers.yml` is installed as a distribution share file. Its top-level
`providers` mapping identifies each provider's implementation class and
curated model pricing. For development from a source checkout, the module
can load `providers.yml` from the project root when the installed share
file is unavailable.

Each model entry contains `input_tokens` and `output_tokens` as
`[price_in_usd, token_count]` pairs. `pricing()` divides the quoted
price by the token count to return rates per single token. The catalog is
loaded once per process. It does not perform live model discovery or test
whether the configured credentials can invoke a model.

# CAVEATS

- The rfc\_3339() method recognizes exactly two date string formats
(see ["rfc\_3339"](#rfc_3339)). Supplying an invalid date string or one that does
not conform to two supported formats will raise an exception from
`Time::Piece::strptime`.
- The query\_string() method does not guarantee parameter ordering. When the
Anthropic API requires parameters in a specific order this should not be
a concern because HTTP query strings are order-independent, but callers
relying on a stable string representation should not depend on the output order.
- Pricing is curated in `providers.yml` in the distribution share
    directory. The rates are estimates for standard, uncached,
    on-demand token usage. Providers may change rates; verify current
    pricing before using the estimates for billing calculations.

# DEPENDENCIES

    Class::Accessor::Fast
    File::Basename
    File::ShareDir
    File::Spec
    YAML::Tiny
    CLI::Simple::Constants
    CLI::Simple::Utils
    English
    HTTP::Tiny (Anthropic transport)
    JSON::PP
    Scalar::Util
    LLM::API::Anthropic (provided by this distribution)
    LLM::API::Bedrock (provided by this distribution)
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

This documentation refers to version 2.0.0.

# AUTHOR

See the distribution metadata for author information.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

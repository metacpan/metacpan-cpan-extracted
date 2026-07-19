package LLM::API;
# Anthropic specific API client

use strict;
use warnings;

BEGIN {
  if ( $ENV{DEBUG} ) {
    require Data::Dumper;
    Data::Dumper->import('Dumper');
  }
}

use English qw(-no_match_vars);
use CLI::Simple::Utils qw(slurp choose);
use CLI::Simple::Constants qw(:booleans);
use JSON::PP qw(encode_json decode_json);
use HTTP::Tiny;
use LLM::API::Response;
use MIME::Base64;
use Scalar::Util qw(reftype);
use Time::Piece;
use URI::Encode qw(uri_encode);

use Readonly;

Readonly::Scalar our $DEFAULT_LLM_MODEL => 'claude-sonnet-4-6';  # default model

# endpoints
Readonly::Scalar our $LLM_URL_BASE        => 'https://api.anthropic.com/v1/';
Readonly::Scalar our $LLM_MESSAGES_EP     => 'messages';
Readonly::Scalar our $LLM_MODELS_EP       => 'models';
Readonly::Scalar our $LLM_USAGE_EP        => 'organizations/usage_report/messages';
Readonly::Scalar our $LLM_COUNT_TOKENS_EP => 'messages/count_tokens';
Readonly::Scalar our $LLM_COST_EP         => 'organizations/cost_report';
Readonly::Scalar our $LLM_KEYS_EP         => 'organizations/api_keys';

Readonly::Scalar our $LLM_MAX_TOKENS => 8192;
Readonly::Scalar our $LLM_VERSION    => '2023-06-01';
Readonly::Scalar our $LLM_ROLE       => 'user';
Readonly::Scalar our $LLM_TIMEOUT    => 300;

Readonly::Scalar our $LLM_PRICING => {
  'claude-sonnet-4-6'         => [ 3 / 1_000_000,  15 / 1_000_000 ],
  'claude-haiku-4-5-20251001' => [ 1 / 1_000_000,  5 / 1_000_000 ],
  'claude-sonnet-5'           => [ 3 / 1_000_000,  15 / 1_000_000 ],  # see note below
  'claude-opus-4-8'           => [ 5 / 1_000_000,  25 / 1_000_000 ],
  'claude-fable-5'            => [ 10 / 1_000_000, 50 / 1_000_000 ],
  'claude-mythos-5'           => [ 10 / 1_000_000, 50 / 1_000_000 ],
};

Readonly::Hash our %LLM_MEDIA_TYPES => (
  text => 'text/plain',
  pdf  => 'application/pdf',
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    api_key_getter
    max_tokens
    model
    version
    role
    timeout
  )
);

our $VERSION = '1.0.1';

use parent qw(Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  # API key from the option list takes precedence
  my $api_key = $options->{api_key};
  delete $options->{api_key};

  $api_key //= $ENV{LLM_API_KEY};
  delete $ENV{LLM_API_KEY};

  die "ERROR: api_key is a required argument\n"
    if !$api_key;

  $options->{model} //= $DEFAULT_LLM_MODEL;

  $options->{timeout} //= $LLM_TIMEOUT;

  my $self = $class->SUPER::new($options);

  $self->set_api_key_getter( sub {$api_key} );

  $self->_init;

  return $self;
}

########################################################################
sub count_input_tokens {
########################################################################
  my ( $self, $content ) = @_;

  die "ERROR: usage: send_prompt(array-ref)\n"
    if !ref $content || reftype($content) ne 'ARRAY';

  my $req = {
    headers => $self->headers( 'content-type' => 'application/json' ),
    content => encode_json(
      { model    => $self->get_model,
        messages => [
          { role    => $self->get_role,
            content => $content,
          }
        ]
      }
    )
  };

  my $rsp = HTTP::Tiny->new( timeout => $self->get_timeout )->post( $LLM_URL_BASE . $LLM_COUNT_TOKENS_EP, $req );

  die sprintf "ERROR %s:%s\n", @{$rsp}{qw(code content)}
    if !$rsp->{success};

  my ($input_token_cost) = $self->pricing( $self->get_model // $DEFAULT_LLM_MODEL );

  my $decoded = decode_json( $rsp->{content} );

  my $input_tokens = $decoded->{input_tokens};

  return ( $input_tokens, $input_tokens * $input_token_cost );
}

########################################################################
sub send_prompt {
########################################################################
  my ( $self, $content ) = @_;

  die "ERROR: usage: send_prompt(array-ref)\n"
    if !ref $content || reftype($content) ne 'ARRAY';

  my $req = {
    headers => $self->headers( 'content-type' => 'application/json' ),
    content => encode_json(
      { model      => $self->get_model,
        max_tokens => $self->get_max_tokens,
        messages   => [
          { role    => $self->get_role,
            content => $content,
          }
        ]
      }
    )
  };

  my $rsp = HTTP::Tiny->new( timeout => $self->get_timeout )->post( $LLM_URL_BASE . $LLM_MESSAGES_EP, $req );

  return LLM::API::Response->new($rsp);
}

########################################################################
sub document {
########################################################################
  my ( $self, %args ) = @_;

  my ( $media_type, $data, $title ) = @args{qw(media_type data title)};

  $media_type //= 'text';

  die "ERROR: unknown media type: $media_type. Only pdf and text are currently supported.\n"
    if !$LLM_MEDIA_TYPES{$media_type};

  my ( $type, $document_data ) = choose {
    return ( 'base64', encode_base64( ${$data} ) )
      if ref $data && reftype($data) eq 'SCALAR';

    return ( 'text', $data )
      if !ref $data;

    die "ERROR: only scalars and scalar references supported.\n"
  };

  my $document = {
    type   => 'document',
    source => {
      type       => $type,
      media_type => $LLM_MEDIA_TYPES{$media_type},
      data       => $document_data,
    },
    $title ? ( title => $title ) : (),
  };

  return $document;
}

########################################################################
sub models {
########################################################################
  my ($self) = @_;

  my @model_list;

  while ($TRUE) {
    my $rsp = $self->_do_api( $LLM_URL_BASE . $LLM_MODELS_EP );
    push @model_list, @{ $rsp->{data} };
    last if !$rsp->{has_more};
  }

  my %models = map { $_->{id} => $_ } @model_list;

  return \%models;
}

########################################################################
sub api_keys {
########################################################################
  my ($self) = @_;

  return $self->_do_api( $LLM_URL_BASE . $LLM_KEYS_EP );
}

########################################################################
sub rfc_3339 {
########################################################################
  my ( $self, $date ) = @_;

  my $fmt = choose {
    return '%Y-%m-%d'
      if $date =~ /\A\d{4}-\d{2}-\d{2}\z/xsm;

    return '%Y-%m-%d %H:%M'
      if $date =~ /\A\d{4}-\d{2}-\d{2}[ ]\d{2}:\d{2}\z/xsm;

    die "ERROR: invalid date format (use YYYY-MM-DD or YYYY-MM-DD hh:mm)\n"
  };

  my $t = Time::Piece->strptime( $date, $fmt );

  # Format to RFC 3339 standard
  return $t->strftime('%Y-%m-%dT%H:%M:%SZ');
}

########################################################################
sub query_string {
########################################################################
  my ( $self, %params ) = @_;

  my @vars;

  foreach my $k ( keys %params ) {

    if ( !ref $params{$k} ) {
      push @vars, sprintf '%s=%s', $k, uri_encode( $params{$k} );
      next;
    }
    elsif ( reftype( $params{$k} ) eq 'ARRAY' ) {
      push @vars, map { sprintf '%s=%s', $k, uri_encode($_) } @{ $params{$k} };
      next;
    }
    elsif ( reftype( $params{$k} ) eq 'HASH' ) {
      push @vars, map { sprintf '%s=%s', $_, uri_encode( $params{$k}->{$_} ) } keys %{ $params{$k} };
      next;
    }

    die "ERROR: unsupport ref type\n";
  }

  return join q{&}, @vars;
}

########################################################################
sub now {
########################################################################
  my ($self) = @_;

  my @t = localtime;
  $t[5] += 1900;
  $t[4]++;

  return sprintf '%04d-%02d-%02d', @t[ ( 5, 4, 3 ) ];
}

########################################################################
sub usage_report {
########################################################################
  my ( $self, %args ) = @_;

  my ( $from, $to, $api_key_ids, $bucket_width ) = @args{qw(from to api_key_ids bucket_width)};
  $from //= $self->now();

  my $starting_at = $self->rfc_3339($from);

  my %params = (
    bucket_width    => $bucket_width // '1h',
    starting_at     => $starting_at,
    'api_key_ids[]' => $api_key_ids,
    $to ? ( ending_at => $self->rfc_3339($to) ) : (),
  );

  my $url = sprintf '%s?%s', $LLM_URL_BASE . $LLM_USAGE_EP, $self->query_string(%params);

  return $self->_do_admin_api($url);
}

########################################################################
sub cost_report {
########################################################################
  my ( $self, %args ) = @_;

  my ( $from, $to, $bucket_width ) = @args{qw(from to bucket_width)};
  $from //= $self->now();

  my $starting_at = $self->rfc_3339($from);

  my %params = (
    bucket_width => $bucket_width // '1d',
    starting_at  => $starting_at,
    $to ? ( ending_at => $self->rfc_3339($to) ) : (),
  );

  my $url = sprintf '%s?%s', $LLM_URL_BASE . $LLM_COST_EP, $self->query_string(%params);

  return $self->_do_admin_api($url);
}

########################################################################
sub headers {
########################################################################
  my ( $self, @headers ) = @_;

  return {
    @headers,
    'x-api-key'         => $self->get_api_key_getter->(),
    'anthropic-version' => $self->get_version,
  };
}

########################################################################
sub text {
########################################################################
  my ( $self, $text ) = @_;

  return {
    type => 'text',
    text => $text,
  };
}

########################################################################
sub prompt {
########################################################################
  my ( $self, $prompt ) = @_;

  my $llm_rsp = $self->send_prompt( [ $self->text($prompt) ] );

  return $llm_rsp;
}

########################################################################
sub pricing {
########################################################################
  my ( $self, $model ) = @_;

  $model //= $self->get_model;

  die "ERROR: no pricing for specified model.\n"
    if !$LLM_PRICING->{$model};

  return @{ $LLM_PRICING->{$model} };
}

########################################################################
# Private Methods
########################################################################

########################################################################
sub _init {
########################################################################
  my ($self) = @_;

  no strict 'refs'; ## no critic
  foreach my $key (qw(max_tokens version role)) {
    my $val = ${ 'LLM::API::LLM_' . uc $key };

    next if defined $self->get($key);

    $self->set( $key, $val );
  }

  return;
}

########################################################################
sub _do_api { goto &_do_admin_api; }
########################################################################

########################################################################
sub _do_admin_api {
########################################################################
  my ( $self, $url ) = @_;

  my $rsp = HTTP::Tiny->new( timeout => $self->get_timeout )->get( $url, { headers => $self->headers } );

  die sprintf "%s:%s\n", @{$rsp}{qw(code content)}
    if !$rsp->{success};

  return decode_json( $rsp->{content} );
}

1;

__END__

=pod

=head1 NAME

LLM::API - Anthropic API client for Claude language models

=encoding utf8

=head1 SYNOPSIS

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

=head1 DESCRIPTION

LLM::API is a client for the Anthropic Claude REST API. It supports sending
text and document prompts to Claude models, retrieving model lists, API key
information, and querying organizational usage and cost reports.

Authentication is handled by passing an API key at construction time or by
setting the LLM_API_KEY environment variable. The environment variable is
deleted from the process environment immediately after it is read, as a
security measure to prevent accidental exposure to child processes.

=head1 CONFIGURATION

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

=head1 CONSTANTS

The following Readonly constants are exported into the package namespace and
may be referenced as LLM::API::CONSTANT_NAME.

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

=head1 METHODS AND SUBROUTINES

=head2 new

  my $llm = LLM::API->new( api_key => $key );
  my $llm = LLM::API->new( \%options );

Constructs and returns a new LLM::API instance. Accepts either a hash of
named arguments or a reference to a hash.

The C<api_key> argument is required and may alternatively be supplied via the
LLM_API_KEY environment variable. The environment variable is deleted from
%ENV immediately after being read.

Dies with an error message if C<api_key> is not provided.

=head2 count_input_tokens

  my ( $tokens, $cost ) = $llm->count_input_tokens( $content );

Counts the input tokens in the supplied content by querying the
Anthropic API token counting endpoint without generating a message
response. The argument must be an array reference of content
block structures such as those produced by C<text()> and
C<document()>.

Returns a two-element list: the number of input tokens and the
estimated cost in US dollars at the current pricing for the configured
model. The cost is calculated by multiplying the token count by the
per-token input cost from the pricing table.

Throws an exception if the argument is not an array reference.

=head2 send_prompt

    my $response = $llm->send_prompt( $content );

Sends a messages request to the Anthropic API. The argument must be an
array reference of content block structures such as those produced by
C<text()> and C<document()> (see L<document>, L<text>). Returns an
L<LLM::API::Response> object. Throws an exception if argument is not
an array reference.

Use the C<is_success> method of the response to test for success before accessing response data.

    die $response->error
      if !$response->is_success;

C<send_prompt> does not throw exceptions on HTTP failure; instead
failure information is contained in the response object.

See L<LLM::API::Response> for detail on response object methods.

=head2 prompt

  my $response = $llm->prompt( $text_string );

Convenience wrapper around send_prompt(). Wraps the supplied plain text string
in a text content block and submits it to the API. Returns an
LLM::API::Response object.

=head2 text

    my $block = $llm->text( $text );

Constructs and returns a text content block hash reference suitable for
inclusion in the content array passed to send_prompt().

=head2 document

    my $block = $llm->document(
      media_type => 'text',   # 'text' or 'pdf'
      data       => $string,  # plain text, or a scalar reference for binary data
      title      => $title,   # optional
    );

Constructs and returns a document content block hash reference suitable for
inclusion in the content array passed to send_prompt().

When data is a plain scalar string the source type is set to 'text'
and the data is used as-is.

When data is a scalar reference the referenced value is base64-encoded
using MIME::Base64::encode_base64(), which by default includes
newlines every 76.  This is the mechanism for submitting PDF files.

The media_type argument accepts the short keys defined in
%LLM_MEDIA_TYPES: 'text' or 'pdf'. It defaults to 'text'. Any other
value will throw an exception. The corresponding MIME type is resolved
internally before the block is constructed.

=head2 models

    my $data = $llm->models;

Retrieves the list of available models from the Anthropic API. Returns
the decoded JSON response as a Perl data structure on success, or
throws an exception containing the HTTP response code and HTTP body.

See L<https://platform.claude.com/docs/en/api/beta/models/list> for more details.

=head2 api_keys

    my $data = $llm->api_keys;

Retrieves the list of API keys for the organization from the Anthropic
API.  Returns the decoded JSON response as a Perl data structure on
success, or throws an exception containing the HTTP response code and
HTTP body.

I<Note: This endpoint requires the use of an admin API key.>

See L<https://platform.claude.com/docs/en/api/admin/api_keys/list> for more details.

=head2 usage_report

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
L<https://platform.claude.com/docs/en/api/admin/usage_report/retrieve_messages>
for more details.

=head2 cost_report

    my $data = $llm->cost_report(
      from         => '2025-01-01',          # defaults to today
      to           => '2025-01-31',          # optional end date
      bucket_width => '1d',                  # optional, defaults to '1d'
    );

Queries the Anthropic organizational cost report endpoint. Date arguments
follow the same rules as usage_report(). The default bucket_width for cost
reports is '1d' rather than '1h'.

Returns the decoded JSON response as a Perl data structure on success,
or throws an exception containing the HTTP response code and HTTP body.

See L<https://platform.claude.com/docs/en/api/admin/cost_report/retrieve> for more detail.

=head2 headers

    my $headers = $llm->headers;
    my $headers = $llm->headers( 'content-type' => 'application/json' );

Builds and returns a hash reference of HTTP request headers. Always includes
the x-api-key and anthropic-version headers. Additional header key-value pairs
may be supplied as a flat list and are merged into the returned hash.

=head2 pricing

    my ( $input_cost, $output_cost ) = $llm->pricing;
    my ( $input_cost, $output_cost ) = $llm->pricing( $model_name );

Returns the per-token input and output costs in US dollars for the
specified model. Throws an exception of no pricing is available for
the model.

I<Note: Costs are expressed as fractional dollar amounts per single
token (for example, 0.000003 for $3 per million).>

=head2 rfc_3339

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
dates. (see L<Time::Piece>)

=head2 query_string

    my $qs = $llm->query_string( key => 'value', other => 'data' );

Builds a URL query string from a flat hash of key-value pairs. Values
are URI-encoded using C<URI::Encode>. Returns a string of the form
'key=value&other=data'.  The order of parameters in the returned
string is not guaranteed.

Values can be scalars, arrays or hashes. Arrays and hashes will be
expanded in the query string as describe in the examples below.

=over 4 

=item Array Behavior

When an array reference is passed as a value, each element is added to
the query string as a separate parameter with the same key.

  $llm->query_string( id => [1, 2] );
  
Produces: C<id=1&id=2>

=item Hashes Behavior

When a hash reference is passed as a value, each nested key-value pair
becomes an individual query parameter using the nested key as the
parameter name, and the outer key is discarded.

  $llm->query_string(filters => {status => "active", type => "user"});

Produces: C<status=active&type=user>

=back

=head2 now

    my $date = $llm->now;

Returns the current local date as a string in 'YYYY-MM-DD' format. Used
internally as the default starting date for usage and cost reports.

=head1 ACCESSORS

The following read/write accessors are generated by Class::Accessor::Fast
using the follow_best_practice naming convention. Use get_NAME to read a
value and set_NAME to write it.

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

=head1 ENVIRONMENT

=over 4

=item  LLM_API_KEY

If set, the constructor reads this variable as the API key. The
variable is immediately deleted from %ENV after being read to reduce
the risk of exposing the key to child processes. Setting both this
variable and the api_key constructor argument is allowed; the
constructor argument takes precedence

I<Note: C<LLM_API_KEY> is deleted from the environment as a security
measure regardless of whether it is used.>

=item DEBUG

If set to a true value at program startup, Data::Dumper is loaded and
its Dumper function is imported into the current namespace. This is
intended for development use only and has no effect on API behavior.

=back

=head1 CAVEATS

=over 4

=item The rfc_3339() method recognizes exactly two date string formats
(see L</rfc_3339>). Supplying an invalid date string or one that does
not conform to two supported formats will raise an exception from
C<Time::Piece::strptime>.

=item The query_string() method does not guarantee parameter ordering. When the
Anthropic API requires parameters in a specific order this should not be
a concern because HTTP query strings are order-independent, but callers
relying on a stable string representation should not depend on the output order.

=item Pricing constants are hardcoded for claude-sonnet-4-6 and reflect the rates
at the time this module was written. Anthropic may change pricing at any time.
Verify current rates at L<https://www.anthropic.com/pricing> before relying
on these values for billing calculations.

=back

=head1 DEPENDENCIES

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

=head1 SEE ALSO

L<LLM::API::Response>

L<HTTP::Tiny>

L<Class::Accessor::Fast>

L<JSON::PP>

L<MIME::Base64>

L<Time::Piece>

L<URI::Encode>

L<Readonly>

Anthropic API documentation: L<https://docs.anthropic.com/en/api/>

Anthropic pricing: L<https://www.anthropic.com/pricing>

=head1 VERSION

This documentation refers to version 1.0.1.

=head1 AUTHOR

See the distribution metadata for author information.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

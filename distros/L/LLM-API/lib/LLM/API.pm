package LLM::API;
# Provider-independent LLM client

use strict;
use warnings;

BEGIN {
  if ( $ENV{DEBUG} ) {
    require Data::Dumper;
    Data::Dumper->import('Dumper');
  }
}

use English qw(-no_match_vars);
use File::Basename qw(dirname);
use File::ShareDir qw(dist_file);
use File::Spec;
use CLI::Simple::Utils qw(slurp choose);
use CLI::Simple::Constants qw(:booleans);
use JSON::PP qw(encode_json decode_json);
use MIME::Base64;
use Scalar::Util qw(reftype);
use Time::Piece;
use URI::Encode qw(uri_encode);
use YAML::Tiny;

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

# Curated provider metadata is installed with the distribution share files.
my $PROVIDERS;

Readonly::Hash our %LLM_MEDIA_TYPES => (
  text => 'text/plain',
  pdf  => 'application/pdf',
);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    api_key_getter
    provider
    region
    max_tokens
    model
    version
    role
    timeout
  )
);

our $VERSION = '2.0.0';

use parent qw(Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  # Anthropic remains the default for existing callers.
  $options->{provider} //= q{anthropic};
  die sprintf "ERROR: unsupported LLM provider: %s\n", $options->{provider}
    if !exists _providers()->{ $options->{provider} };

  # API key from the option list takes precedence
  my $api_key = $options->{api_key};
  delete $options->{api_key};

  $api_key //= $ENV{LLM_API_KEY};
  delete $ENV{LLM_API_KEY};

  die "ERROR: api_key is a required argument\n"
    if $options->{provider} eq q{anthropic} && !$api_key;

  $options->{model} //= $options->{provider} eq q{bedrock} ? q{amazon.nova-micro-v1:0} : $DEFAULT_LLM_MODEL;

  $options->{region} //= $ENV{AWS_REGION} // $ENV{AWS_DEFAULT_REGION} // q{us-east-1}
    if $options->{provider} eq q{bedrock};

  $options->{timeout} //= $LLM_TIMEOUT;

  my $self = $class->SUPER::new($options);

  $self->set_api_key_getter( sub {$api_key} )
    if $options->{provider} eq q{anthropic};

  $self->_init;

  return $self;
}

########################################################################
sub count_input_tokens {
########################################################################
  my ( $self, @args ) = @_;

  return $self->_provider_class->count_input_tokens( $self, @args );
}

########################################################################
sub send_prompt {
########################################################################
  my ( $self, @args ) = @_;

  return $self->_provider_class->send_prompt( $self, @args );
}

########################################################################
sub send_messages {
########################################################################
  my ( $self, $messages ) = @_;

  die "ERROR: usage: send_messages(array-ref)\n"
    if !ref $messages || reftype($messages) ne q{ARRAY} || !@{$messages};

  for my $message ( @{$messages} ) {
    die "ERROR: each message must contain a user or assistant role and text content\n"
      if !ref $message
      || reftype($message) ne q{HASH}
      || ( $message->{role} // q{} ) !~ m{\A(?:user|assistant)\z}
      || !ref $message->{content}
      || reftype( $message->{content} ) ne q{ARRAY}
      || !@{ $message->{content} };

    for my $block ( @{ $message->{content} } ) {
      die "ERROR: send_messages requires text or document blocks\n"
        if !ref $block
        || reftype($block) ne q{HASH}
        || ( $block->{type} // q{} ) ne q{text} && ( $block->{type} // q{} ) ne q{document};

      if ( $block->{type} eq q{text} ) {
        die "ERROR: text content is missing\n"
          if !defined $block->{text};
      }
      else {
        die "ERROR: document content must be a user message with a source\n"
          if $message->{role} ne q{user} || ref $block->{source} ne q{HASH};
      }
    }
  }

  return $self->_provider_class->send_messages( $self, $messages );
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

  die "ERROR: models is not supported by this provider\n"
    if $self->get_provider ne q{anthropic};

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

  die "ERROR: api_keys is not supported by this provider\n"
    if $self->get_provider ne q{anthropic};

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

  die "ERROR: usage_report is not supported by this provider\n"
    if $self->get_provider ne q{anthropic};

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

  die "ERROR: cost_report is not supported by this provider\n"
    if $self->get_provider ne q{anthropic};

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
  my ( $self, @args ) = @_;

  return $self->_provider_class->headers( $self, @args );
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
  my $provider = $self->get_provider;
  my $details  = _providers()->{$provider}->{models}->{$model};

  die sprintf "ERROR: no pricing for provider %s, model %s\n", $provider, $model
    if !$details;

  my @rates;
  for my $name (qw(input_tokens output_tokens)) {
    my $amount = $details->{$name};
    die sprintf "ERROR: invalid %s pricing for provider %s, model %s\n", $name, $provider, $model
      if ref $amount ne q{ARRAY}
      || @{$amount} != 2
      || !defined $amount->[0]
      || !defined $amount->[1]
      || $amount->[0] !~ m{\A\d+(?:\.\d+)?\z}
      || $amount->[1] !~ m{\A\d+(?:\.\d+)?\z}
      || $amount->[1] == 0;
    push @rates, $amount->[0] / $amount->[1];
  }

  return @rates;
}

########################################################################
# Private Methods
########################################################################

########################################################################
sub _providers {
########################################################################
  return $PROVIDERS if defined $PROVIDERS;

  # Installed distributions use their share directory. Source checkouts
  # use the same catalog from the project root for pre-install tests.
  my $path = eval { dist_file( q{LLM-API}, q{providers.yml} ) };
  if ( !$path ) {
    my $source = File::Spec->catfile( dirname(__FILE__), qw(.. .. providers.yml) );
    $path = $source if -f $source;
  }
  die "ERROR: cannot locate LLM provider catalog providers.yml\n"
    if !$path;

  my $yaml = YAML::Tiny->read($path);
  die sprintf "ERROR: cannot read LLM provider catalog %s: %s\n", $path, YAML::Tiny->errstr // q{unknown error}
    if !$yaml;

  my $providers = $yaml->[0]->{providers};
  die sprintf "ERROR: invalid LLM provider catalog %s\n", $path
    if ref $providers ne q{HASH};

  $PROVIDERS = $providers;
  return $PROVIDERS;
}

########################################################################
sub _provider_class {
########################################################################
  my ($self) = @_;

  my $class = _providers()->{ $self->get_provider }->{class};
  die sprintf "ERROR: missing class for LLM provider %s\n", $self->get_provider
    if !$class;

  eval "require $class"; ## no critic
  die sprintf "ERROR: cannot load LLM provider %s: %s\n", $self->get_provider, $@
    if $@;
  return $class;
}

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
  my ( $self, @args ) = @_;

  return $self->_provider_class->_do_admin_api( $self, @args );
}

1;

__END__

=pod

=head1 NAME

LLM::API - Provider-independent LLM client

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

=head1 DESCRIPTION

LLM::API supports Anthropic's direct API and Amazon Bedrock. The provider is
selected at construction time, and text and document content blocks and
L<LLM::API::Response> objects provide a common interface. The client supports
single-turn prompts and explicit multi-turn conversations. Bedrock can invoke
supported Amazon Nova and Anthropic Claude models; Anthropic's direct API
supports Claude models.

For Anthropic, authentication uses an API key supplied to the constructor or
in the C<LLM_API_KEY> environment variable. For Bedrock, the underlying AWS
client resolves AWS credentials; no Anthropic API key is required. The
constructor deletes C<LLM_API_KEY> from the process environment after reading
it, including when a constructor argument takes precedence.

Model listing, API-key administration, organizational usage reports, and
organizational cost reports in this module are supported only for Anthropic's
direct API. There is no Bedrock model-discovery interface.

Provider classes and model pricing are curated in F<providers.yml>, shipped
in the distribution's share directory. This catalog is not a list of models
currently accessible to the caller's credentials.

=head1 CONFIGURATION

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

=head1 METHODS AND SUBROUTINES

=head2 new

  my $llm = LLM::API->new( api_key => $key );
  my $llm = LLM::API->new( \%options );
  my $llm = LLM::API->new( provider => 'anthropic', api_key => $key );
  my $llm = LLM::API->new( provider => 'bedrock', region => 'us-east-1' );

Constructs and returns a new LLM::API instance. Accepts either a hash of
named arguments or a reference to a hash.

For C<provider =E<gt> 'anthropic'> (the default), C<api_key> is required
and may alternatively be supplied via C<LLM_API_KEY>. The variable is deleted
from C<%ENV> after being read. For C<provider =E<gt> 'bedrock'>, no Anthropic
API key is required; AWS credential resolution is handled by the underlying
AWS client. The constructor rejects unsupported providers.

The default models are C<claude-sonnet-4-6> for Anthropic and
C<amazon.nova-micro-v1:0> for Bedrock. Model IDs are passed to the selected
provider; inclusion in F<providers.yml> is required for pricing lookup, not
for model invocation.

=head2 count_input_tokens

  my ( $tokens, $cost ) = $llm->count_input_tokens( $content );

Counts the input tokens in the supplied content by querying the
selected provider's token counting endpoint without generating a message
response. For Bedrock this uses C<CountTokens> with Converse-formatted
messages, where supported by the selected model. The argument must be an
array reference of content blocks, such as those produced by C<text()> and
C<document()>.

Returns a two-element list: the number of input tokens and the estimated
input cost in US dollars, calculated using the selected provider and model's
input rate from F<providers.yml>. An unpriced model raises an error rather
than silently reporting zero cost. Model-specific token counting availability
is determined by the provider.

Throws an exception if the argument is not an array reference.

=head2 send_prompt

    my $response = $llm->send_prompt( $content );

Sends a messages request to the selected provider. The argument must be an
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

=head2 send_messages

  my $response = $llm->send_messages( [
    { role => 'user',      content => [ $llm->text('Hello') ] },
    { role => 'assistant', content => [ $llm->text('Hello!') ] },
    { role => 'user',      content => [ $llm->text('Explain closures.') ] },
  ] );

Sends an explicit multi-turn conversation to the selected provider. The
argument must be a nonempty array reference of message hash references.
Each message requires a C<role> of C<user> or C<assistant> and a nonempty
C<content> array reference containing text or document blocks produced by
C<text()> or C<document()>.

Text blocks must contain a defined C<text> value. Document blocks must
appear in user messages and contain a source hash reference. This method
validates the message shape before delegating to the provider; additional
provider and model restrictions may apply. It returns an
L<LLM::API::Response> object. The caller supplies the complete conversation
on each invocation; this method does not maintain conversation history.

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

For Bedrock, text documents are sent as text content. PDF sources are
translated into Converse document blocks with a safe document name. The
adapter decodes the document helper's base64 source into raw bytes and passes
those bytes to the AWS transport, which performs base64 encoding for the
JSON request. A PDF must be accompanied by a nonempty text prompt in the
same user message, and the selected model must support PDF documents.
Nova Micro is text-only; use a document-capable model for PDF requests.
The C<document()> return structure remains unchanged for Anthropic callers.

=head2 models

This method is available only with C<provider =E<gt> 'anthropic'>; it
throws an exception for other providers.

    my $data = $llm->models;

Retrieves the list of available models from the Anthropic API. Returns
the decoded JSON response as a Perl data structure on success, or
throws an exception containing the HTTP response code and HTTP body.

See L<https://platform.claude.com/docs/en/api/beta/models/list> for more details.

=head2 api_keys

This method is available only with C<provider =E<gt> 'anthropic'>; it
throws an exception for other providers.

    my $data = $llm->api_keys;

Retrieves the list of API keys for the organization from the Anthropic
API.  Returns the decoded JSON response as a Perl data structure on
success, or throws an exception containing the HTTP response code and
HTTP body.

I<Note: This endpoint requires the use of an admin API key.>

See L<https://platform.claude.com/docs/en/api/admin/api_keys/list> for more details.

=head2 usage_report

This method is available only with C<provider =E<gt> 'anthropic'>; it
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
L<https://platform.claude.com/docs/en/api/admin/usage_report/retrieve_messages>
for more details.

=head2 cost_report

This method is available only with C<provider =E<gt> 'anthropic'>; it
throws an exception for other providers.

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

Delegates HTTP header construction to the selected provider. For Anthropic,
the returned hash reference includes C<x-api-key> and C<anthropic-version>;
additional header key-value pairs may be supplied as a flat list. Bedrock
uses AWS authentication rather than Anthropic API-key headers.

=head2 pricing

    my ( $input_cost, $output_cost ) = $llm->pricing;
    my ( $input_cost, $output_cost ) = $llm->pricing( $model_name );

Returns the per-token input and output costs in US dollars for the
specified model and selected provider. Prices are loaded from the
installed F<providers.yml> catalog. The optional model argument defaults
to C<get_model>. Bedrock pricing is keyed by the complete model or inference
profile identifier, so global and geographic profiles may have different
rates. Throws an exception if pricing is not available for the
provider/model combination; an unpriced model may still be invoked.

I<Note: Costs are expressed as fractional dollar amounts per single
token (for example, 0.000003 for $3 per million).>

=head2 rfc_3339

    my $timestamp = $llm->rfc_3339( '2025-01-15' );
    my $timestamp = $llm->rfc_3339( '2025-01-15 14:30' );

Parses the input date string using C<Time::Piece::strptime> and formats
it as C<YYYY-MM-DDTHH:MM:SSZ>. The method appends a literal C<Z>; it does
not explicitly convert a local-time value to UTC. Callers should not rely
on it to perform timezone conversion.

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

=item AWS_REGION / AWS_DEFAULT_REGION

For Bedrock, C<AWS_REGION> takes precedence over C<AWS_DEFAULT_REGION>.
When neither is set and no C<region> is provided, C<us-east-1> is used.

=item DEBUG

If set to a true value at program startup, Data::Dumper is loaded and
its Dumper function is imported into the current namespace. This is
intended for development use only and has no effect on API behavior.

=back

=head1 PROVIDER CATALOG

F<providers.yml> is installed as a distribution share file. Its top-level
C<providers> mapping identifies each provider's implementation class and
curated model pricing. For development from a source checkout, the module
can load F<providers.yml> from the project root when the installed share
file is unavailable.

Each model entry contains C<input_tokens> and C<output_tokens> as
C<[price_in_usd, token_count]> pairs. C<pricing()> divides the quoted
price by the token count to return rates per single token. The catalog is
loaded once per process. It does not perform live model discovery or test
whether the configured credentials can invoke a model.

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

=item Pricing is curated in F<providers.yml> in the distribution share
    directory. The rates are estimates for standard, uncached,
    on-demand token usage. Providers may change rates; verify current
    pricing before using the estimates for billing calculations.

=back

=head1 DEPENDENCIES

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

This documentation refers to version 2.0.0.

=head1 AUTHOR

See the distribution metadata for author information.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

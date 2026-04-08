package LLM::SimpleClient;

use strict;
use warnings;
use 5.028;
no warnings 'experimental';
use feature qw{signatures};
use utf8;
use Module::Load qw( load );
use Log::Log4perl;
use Mojo::UserAgent;
use Time::HiRes qw( gettimeofday tv_interval );

our $VERSION = '0.01';

# Wrapper registration for Log4perl
Log::Log4perl->wrapper_register(__PACKAGE__);

# Allowed provider names
our %VALID_PROVIDERS = (
    mistral     => 'LLM::SimpleClient::Mistral',
    huggingface => 'LLM::SimpleClient::HuggingFace',
    openrouter  => 'LLM::SimpleClient::OpenRouter',
);

# Constructor
sub new ( $class, %params ) {
    my $self = bless {}, ref($class) || $class;

    # Required parameters
    $self->{api_key}  = $params{api_key}  or die "API key is required";
    $self->{model}    = $params{model}    or die "Model name is required";
    $self->{provider} = $params{provider} or die "Provider is required";

    # Validate provider
    die "Invalid provider: $self->{provider}"
      unless exists $VALID_PROVIDERS{ $self->{provider} };

    # Optional parameters - set defaults first, then override if provided
    $self->{temperature} = 0.7;
    $self->{max_tokens}  = 4096;
    $self->{top_p}       = 1.0;
    $self->{timeout}     = 60;
    $self->{temperature} = $params{temperature} if exists $params{temperature};
    $self->{max_tokens}  = $params{max_tokens}  if exists $params{max_tokens};
    $self->{top_p}       = $params{top_p}       if exists $params{top_p};
    $self->{role}        = $params{role}        if exists $params{role};
    $self->{timeout}     = $params{timeout}     if exists $params{timeout};

    # Fallback providers - normalize to internal format
    $self->{fallback} = $self->_normalize_fallback( $params{fallback} );

    $self->{ua}     = Mojo::UserAgent->new;
    $self->{logger} = Log::Log4perl->get_logger(__PACKAGE__);

    $self->{logger}
      ->debug("LLM client initialized: provider=$self->{provider}, model=$self->{model}");

    return $self;
}

# Normalize fallback to internal format
# Accepts: hashref or arrayref of hashrefs
# Each hash must have: provider, api_key, model
sub _normalize_fallback ( $self, $providers ) {
    return [] unless defined $providers;

    # Handle single hashref (one provider)
    $providers = [$providers] if ref $providers eq 'HASH';

    die "fallback must be a hashref or arrayref"
      unless ref $providers eq 'ARRAY';

    my @normalized;
    for my $item (@$providers) {
        die "fallback must be a hashref or arrayref of hashrefs"
          unless ref $item eq 'HASH';

        # Required: provider, api_key, model
        my $provider_name = $item->{provider}
          or die "Fallback provider hash must have 'provider' key";
        my $api_key = $item->{api_key}
          or die "Fallback provider '$provider_name' must have 'api_key'";

        my %fallback_item = (
            provider => $provider_name,
            api_key  => $api_key,
            model    => $item->{model} // $self->{model},
            timeout  => $item->{timeout},
        );

        $fallback_item{temperature} = $item->{temperature} if exists $item->{temperature};
        $fallback_item{max_tokens}  = $item->{max_tokens}  if exists $item->{max_tokens};
        $fallback_item{top_p}       = $item->{top_p}       if exists $item->{top_p};

        push @normalized, \%fallback_item;
    }

    return \@normalized;
}

# Send a single text query to LLM and get response
# No conversation history is stored - each request is independent
sub ask ( $self, $text ) {
    $self->{logger}->info("Sending single query to LLM");

    # Build request with system role (if set) and single user message
    my @messages;

    # Only add system message if role was explicitly provided
    if ( exists $self->{role} ) {
        push @messages, { role => 'system', content => $self->{role} };
    }

    push @messages, { role => 'user', content => $text };

    # Build providers list with their configs
    # Primary provider first, then fallback providers
    my @providers_to_try = (
        {
            provider => $self->{provider},
            api_key  => $self->{api_key},
            model    => $self->{model},
        },
        @{ $self->{fallback} }
    );

    my $last_error;
    my $used_provider;

    for my $provider_config (@providers_to_try) {
        my $provider_name = $provider_config->{provider};
        $used_provider = $provider_name;
        $self->{logger}->debug("Trying provider: $provider_name");

        # Create provider-specific handler with specific config
        my $handler = $self->_create_provider_handler( $provider_name, $provider_config );

        unless ($handler) {
            $self->{logger}->warn("Unknown provider: $provider_name, skipping");
            next;
        }

        my $t0     = [gettimeofday];
        my $result = $handler->send_request( \@messages );
        my $after  = sprintf "%.2f", tv_interval( $t0, [gettimeofday] );

        # Check if request was successful
        if ( $result->{success} ) {
            $result->{provider} = $provider_name;
            $self->{logger}->info("Request successful with provider: $provider_name, after $after s");
            return $result;
        }

        $last_error = $result->{error};
        $self->{logger}->warn("Provider $provider_name failed: $last_error, after $after s");

        # Check if we should fallback
        # Fallback on: 401 (unauthorized/too many requests), 429 (rate limit), 5xx (server error)
        my $should_fallback = 0;

        if ( $result->{status_code} ) {
            my $status = $result->{status_code};
            if ( $status == 401 || $status == 429 || ( $status >= 500 && $status < 600 ) ) {
                $should_fallback = 1;
                $self->{logger}->warn("Falling back from $provider_name due to status $status");
            }
        }

        # Also fallback on connection errors
        if ( $result->{is_connection_error} ) {
            $should_fallback = 1;
            $self->{logger}->warn("Falling back from $provider_name due to connection error");
        }

        unless ($should_fallback) {

            # Not a fallback situation, return the error
            return {
                success     => 0,
                error       => $last_error,
                status_code => $result->{status_code},
                provider    => $provider_name,
            };
        }
    }

    # All providers failed
    $self->{logger}->error("All providers failed. Last error: $last_error");

    return {
        success  => 0,
        error    => $last_error // "All providers failed",
        provider => $used_provider,
    };
}

# Create provider-specific handler
# $provider_name - name of the provider
# $provider_config - hashref with provider-specific config (api_key, model, etc.)
sub _create_provider_handler ( $self, $name, $config = {} ) {

    my $handler_class = $VALID_PROVIDERS{$name};
    return undef unless $handler_class;

    # Require the module dynamically
    eval { load $handler_class };

    if ($@) {
        $self->{logger}->error("Failed to load provider $handler_class: $@");
        return undef;
    }

    # Use provider-specific config - each provider must have its own api_key
    my $api_key = $config->{api_key} or die "Provider '$name' must have 'api_key'";
    my $model   = $config->{model} // $self->{model};

    # Build params for provider handler
    my %handler_params = (
        api_key => $api_key,
        model   => $model,
        logger  => $self->{logger},
        timeout => $self->{timeout},
    );

    # Add optional parameters only if they are set
    $handler_params{temperature} = $config->{temperature} // $self->{temperature}
      if exists $config->{temperature} || exists $self->{temperature};

    $handler_params{top_p} = $config->{top_p} // $self->{top_p}
      if exists $config->{top_p} || exists $self->{top_p};

    $handler_params{max_tokens} = $config->{max_tokens} // $self->{max_tokens}
      if exists $config->{max_tokens} || exists $self->{max_tokens};

    return $handler_class->new(%handler_params);
}

1;

__END__

=head1 NAME

LLM::SimpleClient - Perl module for making single API requests to LLM providers

=head1 SYNOPSIS

    use LLM::SimpleClient;
    use Log::Log4perl;

    # Initialize logging
    Log::Log4perl->init("log4perl.conf");

    # Create LLM client
    my $llm = LLM::SimpleClient->new(
        api_key    => 'your-api-key',
        model      => 'mistral-small-latest',
        provider   => 'mistral',
        role       => 'You are a helpful assistant.',
    );

    # Send single query and get response (no history stored)
    my $result = $llm->ask("What is Perl?");

    if ($result->{success}) {
        print "Response: $result->{content}\n";
    } else {
        print "Error: $result->{error}\n";
    }

=head1 DESCRIPTION

LLM::SimpleClient provides a simple interface for sending single queries to LLM
(Language Model) providers through their REST APIs. Each call to ask() is independent
and does not maintain conversation history.

Supported providers:
- Mistral AI (api.mistral.ai)
- HuggingFace Router (router.huggingface.co)
- OpenRouter (openrouter.ai)

The module handles API authentication, request formatting, response parsing,
and automatic failover to backup providers when errors occur.

=head1 METHODS

=head2 new(%params)

Creates a new LLM client instance.

Required parameters:
- api_key: API key for authentication
- model: Model identifier (e.g., 'mistral-small-latest')
- provider: Provider name ('mistral', 'huggingface', or 'openrouter')

Optional parameters:
- temperature: Sampling temperature (0.0-2.0, default: 0.7)
- max_tokens: Maximum tokens to generate (default: 2048)
- role: System prompt/role (default: 'You are a helpful assistant.')
- top_p: Nucleus sampling parameter (default: 1.0)
- timeout: Request timeout in seconds (default: 60)
- fallback: Arrayref of fallback provider configurations.
  Each element must be a hashref with required keys: provider, api_key, model.
  Optional keys: temperature, top_p, timeout.

  Example:
    fallback => [
        { provider => 'huggingface', api_key => '...', model => '...' },
        { provider => 'openrouter', api_key => '...', model => '...', temperature => 0.5 },
    ]

=head2 ask($text)

Sends a single text query to the LLM and returns the response.
This is the only public method - each call is independent with no conversation history.

Returns a hashref with keys:
- success: Boolean indicating success
- content: Generated text response (on success)
- error: Error message if failed
- provider: Provider that handled the request

=head1 AUTHOR

Konstantin Pristine <kpristine@cpan.org>


=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package MFab::Plugins::Datadog 1.0;

=encoding utf8

=head1 NAME

MFab::Plugins::Datadog - Mojolicious plugin for Datadog APM integration

=head1 SYNOPSIS

    # In your Mojolicious application
    push(@{ $self->plugins->namespaces }, 'MFab::Plugins');

    $app->plugin('Datadog', {
        enabled => "true",
        service => "MyApp",
        serviceEnv => "production"
    });

=head1 DESCRIPTION

This module provides seamless integration between Mojolicious web applications and Datadog's Application Performance Monitoring (APM) system. It automatically instruments your Mojolicious application to send distributed traces and metrics to Datadog, giving you visibility into:

=over 4

=item * HTTP request/response cycles

=item * Route matching and dispatch timing

=item * Controller action execution

=item * Custom application spans

=back

The plugin automatically propagates trace context across service boundaries using Datadog's trace headers, enabling distributed tracing across your microservices architecture.

=head1 CUSTOM SPANS

When you want to measure a specific function, you can use the startSpan/endSpan functions to mark the start and end points:

    sub customHandler {
        my($c) = @_;
        my $span = startSpan($c->tx, "TestCode::customHandler", "customHandler");
        # do work here
        sleep(10);
        endSpan($span);
    }

=head1 NOTES

=over 4

=item * If the worker is killed through a heartbeat failure, the spans for that worker won't be sent

=item * Websockets only generate a mojolicious-transaction span

=back

=head1 FUNCTIONS

=cut

use Mojo::Base qw(Mojolicious::Plugin -signatures);

use Time::HiRes qw(gettimeofday tv_interval);
use Crypt::Random;
use Math::Pari;

use Exporter 'import';
our @EXPORT_OK = qw(startSpan endSpan);

# Keep track of all outstanding transactions
my(%transactions);

=head2 register()

Register Mojolicious plugin and hook into the application - called by the Mojolicious framework

It accepts the following config items

=over 4

=item * "datadogHost" - the datadog agent host, also looks in the ENV for "DD_AGENT_HOST", defaults to "localhost"

=item * "enabled" - if "true", traces are sent to datadog, also looks in the ENV for "DD_TRACE_ENABLED", defaults to "false"

=item * "service" - the value to send to datadog for the service name, defaults to "MFab::Plugins::Datadog"

=item * "serviceEnv" - the value to send to datadog for the service environment, defaults to "test"

=back

=cut

sub register ($self, $app, $args) {
	if(not $args->{service}) {
		$args->{service} = "MFab::Plugins::Datadog";
	}
	$args->{datadogHost} = configItem($args->{datadogHost}, "DD_AGENT_HOST", "localhost");
	$args->{enabled} = configItem($args->{enabled}, "DD_TRACE_ENABLED", "false") eq "true";
	$args->{datadogURL} = "http://".$args->{datadogHost}.":8126/v0.3/traces";
	$args->{serviceEnv} = $args->{serviceEnv} || "test";

	if($args->{enabled}) {
		$app->hook(around_action => \&aroundActionHook);
		$app->hook(after_dispatch => \&afterDispatchHook);
		$app->hook(after_build_tx => sub ($tx, $app) { afterBuildTxHook($tx, $app, $args) });
	}
}

=head2 datadogId()

Generate a 64 bit integer that JSON::XS will serialize as an integer

=cut

sub datadogId () {
	my $id = Crypt::Random::makerandom(Size => 64, Strength => 0);
	return Math::Pari::pari2iv($id);
}

=head2 configItem($config_host)

Get the config item from: the app setting, the environment variable, or use the default

=cut

sub configItem ($appSetting, $envName, $default) {
	if(not $appSetting) {
		$appSetting = $ENV{$envName} || $default;
	}
	return $appSetting;
}

=head2 setTraceId($c, $connection_data)

Set the traceid in the connection data

=cut

sub setTraceId ($tx, $connection_data) {
	if(defined $connection_data->{traceid}) {
		return;
	}

	$connection_data->{traceid} = $tx->req->headers->header("x-datadog-trace-id");
	if($connection_data->{traceid}) {
		$connection_data->{traceid} = int($connection_data->{traceid});
	} else {
		$connection_data->{traceid} = datadogId();
		$tx->req->headers->header("x-datadog-trace-id" => $connection_data->{traceid});
	}
}

=head2 aroundActionHook()

The around_action hook - wrapped around the action

=cut

sub aroundActionHook ($next, $c, $action, $last) {
	my $connection_data = $transactions{$c->tx} || {};

	$connection_data->{action_start} = [gettimeofday()];
	$connection_data->{action_spanid} = datadogId();
	$connection_data->{current_spanid} = $connection_data->{dispatch_spanid};
	$connection_data->{after_dispatch} = 0;

	setTraceId($c->tx, $connection_data);

	$connection_data->{parentid} = $c->tx->req->headers->header("x-datadog-parent-id");
	if($connection_data->{parentid}) {
		$connection_data->{parentid} = int($connection_data->{parentid});
	}
	$c->tx->req->headers->header("x-datadog-parent-id" => $connection_data->{action_spanid});

	my $retval = $next->();

	$connection_data->{action_duration} = tv_interval($connection_data->{action_start});
	$connection_data->{is_sync} = $connection_data->{after_dispatch};

	my $route = $c->match->endpoint;
	# "/" doesn't have a pattern
	$connection_data->{pattern} = $route->pattern->unparsed || $c->req->url;

	return $retval;
}

=head2 afterDispatchHook()

The after_dispatch hook - called after the request is finished the sync stage of processing, more async processing can happen after this

=cut

sub afterDispatchHook ($c) {
	my $connection_data = $transactions{$c->tx} || {};

	if(not defined($connection_data->{action_start})) {
		$connection_data->{action_start} = [gettimeofday()];
	}

	setTraceId($c->tx, $connection_data);

	$connection_data->{after_dispatch} = 1;
	$connection_data->{current_spanid} = $connection_data->{dispatch_spanid};
	$connection_data->{dispatch_duration} = tv_interval($connection_data->{action_start});
}

=head2 afterBuildTxHook()

The after_build_tx hook - called after the transaction is built but before it is parsed

=cut

sub afterBuildTxHook ($tx, $app, $args) {
	my $connection_data = {
		spans => [],
	};
	$transactions{$tx} = $connection_data;
	$connection_data->{tx_spanid} = datadogId();
	$connection_data->{dispatch_spanid} = datadogId();
	$connection_data->{current_spanid} = $connection_data->{tx_spanid};
	$connection_data->{build_tx_start} = [gettimeofday()];

	$tx->on(finish => sub ($tx) {
		# websockets skip dispatch & action hooks
		setTraceId($tx, $connection_data);
		$connection_data->{url} = $tx->req->url->path;
		$connection_data->{method} = $tx->req->method;
		$connection_data->{code} = $tx->res->code;
		$connection_data->{tx_duration} = tv_interval($connection_data->{build_tx_start});
		submitDatadog($app, $connection_data, $args);
		$transactions{$tx} = undef;
	});
}

=head2 startSpan($tx, $name, $resource, [$parent_id])

Start a new span, associates it to the transaction via $tx

=cut

sub startSpan ($tx, $name, $resource, $parent_id = undef) {
	# we don't have a transaction, so we can't send this span
	if(not defined($tx)) {
		return {
			"no_tx" => 1,
		};
	}
	my $connection_data = $transactions{$tx} || {};
	my $span = {
		"name" => $name,
		"resource" => $resource,
		"start" => [gettimeofday()],
		"span_id" => datadogId(),
		"parent_id" => $parent_id || $connection_data->{current_spanid},
		"type" => "web",
		"meta" => {},
	};
	push(@{$connection_data->{spans}}, $span);
	return $span;
}

=head2 endSpan($span, [$error_message])

End a span, optional error message

=cut

sub endSpan ($span, $error_message = undef) {
	if($span->{no_tx}) {
		return;
	}
	# we've already submitted this span, likely due to a timeout
	if($span->{meta}{"mojolicious.unclosed"} or ref($span->{start}) ne "ARRAY") {
		return;
	}
	$span->{duration} = durationToDatadog(tv_interval($span->{start}));
	$span->{start} = timestampToDatadog($span->{start});
	if($error_message) {
		$span->{error} = 1;
		$span->{meta} = { "error.message" => "$error_message" };
	}
}

=head2 timestampToDatadog($timestamp)

Datadog wants number of nanoseconds since the epoch

=cut

sub timestampToDatadog ($timestamp) {
	if (not defined($timestamp)) {
		return undef;
	}
	return $timestamp->[0] * 1000000000 + $timestamp->[1] * 1000;
}

=head2 durationToDatadog($duration)

Datadog wants duration in nanoseconds

=cut

sub durationToDatadog ($duration) {
	if (not defined($duration)) {
		return undef;
	}
	return int($duration * 1000000000);
}

=head2 submitDatadog($app, $connection_data, $args)

Submit spans to datadog agent

=cut

sub submitDatadog ($app, $connection_data, $args) {
	my $pattern = $connection_data->{pattern} || $connection_data->{url};
	my $is_sync = $connection_data->{is_sync} || 0;
	my %meta = (
		"env" => $args->{serviceEnv},
		"api.endpoint.route" => $pattern,
		"http.path_group" => $connection_data->{pattern},
		"http.method" => $connection_data->{method},
		"http.url_details.path" => $connection_data->{url},
		"process_id" => "$$",
		"language" => "perl",
		"mojolicious.sync" => "$is_sync",
	);
	if(defined($connection_data->{code})) {
		$meta{"http.status_code"} = "".$connection_data->{code};
	}

	my @spans = @{$connection_data->{spans}};

	for my $span (@spans) {
		$span->{meta}{env} = $meta{env};
		$span->{meta}{process_id} = "$$";
		$span->{meta}{language} = "perl";
		$span->{trace_id} = $connection_data->{traceid};
		if(not defined($span->{duration})) {
			$span->{duration} = durationToDatadog(tv_interval($span->{start}));
			$span->{start} = timestampToDatadog($span->{start});
			$span->{meta}{"mojolicious.unclosed"} = "true";
			$span->{error} = 1;
			$span->{meta} = { "error.message" => "Span was not finished when it was sent to the platform" };
		}

		$span->{service} = $args->{service};
	}

	if(defined($connection_data->{action_duration})) {
		push(@spans, 
			{
				"duration" => durationToDatadog($connection_data->{action_duration}),
				"meta" => \%meta,
				"name" => "mojolicious-action",
				"resource" => $pattern,
				"service" => $args->{service},
				"span_id" => $connection_data->{action_spanid},
				"start" => timestampToDatadog($connection_data->{action_start}),
				"trace_id" => $connection_data->{traceid},
				"parent_id" => $connection_data->{tx_spanid},
				"type" => "web",
			});
	}

	if($connection_data->{after_dispatch}) {
		push(@spans,
			{
				"duration" => durationToDatadog($connection_data->{dispatch_duration}),
				"meta" => \%meta,
				"name" => "mojolicious-dispatch",
				"resource" => $pattern,
				"service" => $args->{service},
				"span_id" => $connection_data->{dispatch_spanid},
				"start" => timestampToDatadog($connection_data->{action_start}),
				"trace_id" => $connection_data->{traceid},
				"parent_id" => $connection_data->{tx_spanid},
				"type" => "web",
			}
		);
	}

	my $tx_span = {
		"duration" => durationToDatadog($connection_data->{tx_duration}),
		"meta" => \%meta,
		"name" => "mojolicious-transaction",
		"resource" => $pattern,
		"service" => $args->{service},
		"span_id" => $connection_data->{tx_spanid},
		"start" => timestampToDatadog($connection_data->{build_tx_start}),
		"trace_id" => $connection_data->{traceid},
		"type" => "web",
	};
	if($connection_data->{parentid}) {
		$tx_span->{"parent_id"} = $connection_data->{parentid};
	}
	push(@spans, $tx_span);

	$app->ua->put($args->{datadogURL}, json => [ \@spans ], sub ($ua, $tx) {
		if($tx->res->is_error) {
			$app->log->error("HTTP Error sending to datadog: ".$tx->res->code." ".$tx->res->body);
			return;
		}
		# Errors without a HTTP status code like connection refused & timeout
		if($tx->res->error) {
			$app->log->error("Error sending to datadog: ".$tx->res->error->{message});
			return;
		}
	});
}

1;

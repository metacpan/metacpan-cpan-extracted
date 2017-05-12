# $Id: /mirror/gungho/lib/Gungho/Component/Core.pm 31304 2007-11-29T11:56:44.884140Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Core;
use strict;
use warnings;
use base qw(Gungho::Component);
use Carp ();
use Config::Any;
use Class::Inspector;
use Event::Notify;
use UNIVERSAL::isa;
use UNIVERSAL::require;
use HTTP::Status qw(status_message);

use Gungho::Exception;
use Gungho::Request;
use Gungho::Response;
use Gungho::Util;

__PACKAGE__->mk_classdata('notify_hub');

sub setup
{
    my $c = shift;

    $c->notify_hub( Event::Notify->new );
    $c->setup_log();
    $c->setup_provider();
    $c->setup_handler();
    $c->setup_engine();
    $c->setup_plugins();

    $c;
}

sub setup_log
{
    my $c = shift;

    my $log_config = { %{$c->config->{log} || { logs => [] }} };
    my $module     = delete $log_config->{module} || 'Simple';
    my $pkg        = $c->load_gungho_module($module, 'Log');
    my $log        = $pkg->new(config => $log_config->{config} || $log_config);

    $log->setup($c);
    $c->log($log);
}

sub setup_provider
{
    my $c = shift;

    my $config = $c->config->{provider};

    my $ref = ref $config;
    if (! $config || ! defined $ref) {
        Carp::croak("Gungho requires a provider");
    }

    if ($ref eq 'CODE') {
        # Smells like an inlined provider
        my $code = $config;
        $config = {
            module => "Inline",
            config => {
                callback => $code
            }
        }
    } elsif ( $ref ne 'HASH') {
        Carp::croak("Gungho requires a provider");
    }

    my $pkg = $c->load_gungho_module($config->{module}, 'Provider');
    $pkg->isa('Gungho::Provider') or die "$pkg is not a Gungho::Provider subclass";
    my $obj = $pkg->new(config => $config->{config} || {} );
    $obj->setup( $c );
    $c->provider( $obj );
}

sub setup_engine
{
    my $c = shift;

    my $config = $c->config->{engine} || {
        module => 'POE',
    };
    if (! $config || ref $config ne 'HASH') {
        Carp::croak("Gungho requires a engine");
    }

    my $pkg = $c->load_gungho_module($config->{module}, 'Engine');
    $pkg->isa('Gungho::Engine') or die "$pkg is not a Gungho::Engine subclass";
    my $obj = $pkg->new( config => $config->{config} || {} );
    $obj->setup( $c );
    $c->engine( $obj );
}

sub setup_handler
{
    my $c = shift;

    my $config = $c->config->{handler} || {
        module => 'Null',
        config => {}
    };
    my $ref = ref $config;
    if (! $config || ! defined $ref) {
        Carp::croak("Gungho requires a handler");
    }

    if ($ref eq 'CODE') {
        # Smells like an inlined handler
        my $code = $config;
        $config = {
            module => "Inline",
            config => {
                callback => $code
            }
        }
    } elsif ( $ref ne 'HASH') {
        Carp::croak("Gungho requires a handler");
    }

    my $pkg = $c->load_gungho_module($config->{module}, 'Handler');
    $pkg->isa('Gungho::Handler') or die "$pkg is not a Gungho::Handler subclass";
    my $obj = $pkg->new( config => $config->{config} || {});
    $obj->setup( $c );
    $c->handler( $obj );
}

sub setup_plugins
{
    my $c = shift;

    my $plugins = $c->config->{plugins} || [];
    foreach my $plugin (@$plugins) {
        my $pkg = $c->load_gungho_module($plugin->{module}, 'Plugin');
        my $obj = $pkg->new( config => $plugin->{config} || {});
        $obj->setup($c);
    }
}

sub has_feature
{
    my ($c, $name) = @_;
    return exists $c->features()->{$name};
}

sub load_gungho_module
{
    my ($c, $pkg, $prefix) = @_;
    return Gungho::Util::load_module( 
        $pkg,
        $prefix ? "Gungho::${prefix}" : "Gunho"
    );
    Class::Inspector->loaded($pkg) or $pkg->require or die;
    return $pkg;
}

sub dispatch_requests
{
    my $c = shift;
    if ($c->is_running) {
        $c->provider->dispatch($c, @_);
        $c->notify('dispatch.dispatch_requests');
    }
}

sub prepare_request
{
    my $c = shift;
    my $req  = shift;
    $c->notify('dispatch.prepare_request', $req);
    return $req;
}

sub prepare_response
{
    my ($c, $res) = @_;

    {
        my $old = $res;
        $res = Gungho::Response->new(
            $res->code,
            $res->message,
            $res->headers,
            $res->content
        );
        $res->request( $old->request );
    }
    return $res;
}

sub send_request
{
    my $c = shift;
    my $request = shift;
    $request = $c->prepare_request($request);
    return $c->engine->send_request($c, $request);
}

sub pushback_request
{
    my ($c, $request) = @_;
    $c->provider->pushback_request( $c, $request );
}

sub request_is_allowed { 1 }

sub handle_response
{
    my $c = shift;
    my ($req, $res) = @_;

    my $e;
    eval {
        $c->maybe::next::method($req, $res);
    };
    if ($e = Gungho::Exception->caught('Gungho::Exception::HandleResponse::Handled')) {
        return;
    } elsif ($e = Gungho::Exception->caught()) {
        die $e;
    }
    $c->handler->handle_response($c, $req, $res);
}

sub handle_dns_response
{
    my ($c, $request, $answer, $dns_response) = @_;

    my $host = $request->uri->host;
    my $addr = $answer->address;
    $request->header(Host => $host);
    $request->notes(original_host => $host);
    $request->notes(resolved_ip   => $addr);
    eval {
        $c->send_request($request);
    };
    if (my $e = $@) {
        if ($e->isa('Gungho::Exception::RequestThrottled')) {
            # This request was throttled. Attempt to do it later
            $c->provider->pushback_request($c, $request);
        } else {
            die $e;
        }
    }

    return 1;
}

# Utility method to create an error HTTP response.
# Stolen from PoCo::Client::HTTP::Request
sub _http_error
{
    my ($self, $code, $message, $request) = @_;

    my $nl = "\n";
    my $r = Gungho::Response->new($code);
    my $http_msg = status_message($code);
    my $m = (
      "<html>$nl"
      . "<HEAD><TITLE>Error: $http_msg</TITLE></HEAD>$nl"
      . "<BODY>$nl"
      . "<H1>Error: $http_msg</H1>$nl"
      . "$message$nl"
      . "</BODY>$nl"
      . "</HTML>$nl"
    );

    $r->content($m);
    $r->request($request);
    return $r;
}

sub register_event
{
    my $c = shift;
    $c->notify_hub->register_event(@_);
}
*register_hook = \&register_event;

sub unregister_event
{
    my $c = shift;
    $c->notify_hub->unregister_event(@_);
}

sub notify
{
    my ($c, $event, @args) = @_;
    $c->notify_hub->notify($event, $c, @args);
}
*run_hook = \&notify;

sub shutdown
{
    my ($c, $reason) = @_;

    $reason ||= 'unknown reason';
    $c->log->notice("Gungho received a shutdown request!: '$reason'");
    $c->is_running(0);

    # Tell everybody to shutdown
    $c->provider->stop($reason);
    $c->handler->stop($reason);
    $c->engine->stop($reason);
}

1;

__END__

=head1 NAME

Gungho::Component::Core - Gungho Core Methods

=head1 METHODS

=head2 new($config)

This method has been deprecated. Use run() instead.

=head2 run

Starts the Gungho process.  It requires either the name of a config filename
or a hashref.

=head2 has_feature($name)

Returns true if Gungho supports some feature $name

=head2 setup()

Sets up the Gungho environment, including calling the various setup_*
methods to configure the provider, engine, handler, etc.

=head2 setup_components()

=head2 setup_engine()

=head2 setup_handler()

=head2 setup_log()

=head2 setup_provider()

=head2 setup_plugins()

Sets up the various components.

=head2 register_hook($hook_name => $coderef[, $hook_name => $coderef])

Is deprecated. Use register_event instead.

=head2 register_event($event, $observer)

Registers an observer that gets notified when $event happens. The $observer
argument can be either an object implementing notify(), or a subroutine
reference.

=head2 unregister_event($event, $observer)

Unregisters an observer from the specified event

=head2 run_hook($hook_name, @args)

Is deprecated. Use notify() instead.

=head2 notify($event, @args)

Notifies observers of an event.

=head2 has_requests

Delegates to provider's has_requests

=head2 get_requests

Delegates to provider's get_requests

=head2 handle_response

Delegates to handler's handle_response

=head2 handle_dns_response

Delegates to engine's send_request upon successful DNS response

=head2 dispatch_requests

Calls provider->dispatch

=head2 prepare_request($req)

Given a request, preps it before sending it to the engine

=head2 prepare_response($req)

Given a response, preps it before sending it to handle_response()

=head2 send_request

Delegates to engine's send_request

=head2 pushback_request

Push back a request

=head2 load_config($config)

Loads the config from $config via Config::Any.

=head2 load_gungho_module($name, $prefix)

Loads a Gungho component. Compliments the module name with 'Gungho::$prefix::',
unless the name is prefixed with a '+'. In that case, no transformation is
performed, and the module name is used as-is.

=head2 request_is_allowed($req)

Returns true if the given request is allowed to be fetched (this has nothing
to do with authentication and such, and is purely internal)

=head2 shutdown($reason)

Shuts down Gungho. Call this if you want to tell the entire system to stop.
This method in turn calls stop methods on the Engine, Provider, and Handler
objects

=cut

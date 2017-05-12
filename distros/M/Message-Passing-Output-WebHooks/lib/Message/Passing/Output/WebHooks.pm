package Message::Passing::Output::WebHooks;
use Moo;
use Message::Passing::DSL;
use AnyEvent::HTTP;
use Message::Passing::DSL::Factory ();
use Try::Tiny;
use aliased 'Message::Passing::WebHooks::Event::Call::Success';
use aliased 'Message::Passing::WebHooks::Event::Call::Timeout';
use aliased 'Message::Passing::WebHooks::Event::Call::Failure';
use aliased 'Message::Passing::WebHooks::Event::Bad';
use MooX::Types::MooseLike::Base qw/ Int /;
use JSON qw/ encode_json /;
use MooX::Options flavour => [qw( pass_through )], protect_argv => 0;
use Message::Passing::Role::CLIComponent;
#use namespace::clean -except => [qw/ meta new_with_options parse_options _options_data _options_config/];

our $VERSION = '0.008';
$VERSION = eval $VERSION;

with 'Message::Passing::Role::Output',
    CLIComponent( name => 'log', default => 'Null' );

sub BUILD {
    my $self = shift;
    $self->log_chain;
}

has log_chain => (
    is => 'ro',
    does => 'Message::Passing::Role::Output',
    handles => {
        log_result => 'consume',
    },
    lazy => 1,
    default => sub {
        my $self = shift;
        my $class = Message::Passing::DSL::Factory->expand_class_name('Output', $self->log);
        Class::MOP::load_class($class);
        $class->new($self->log_options)
    },
);

has timeout => (
    isa => Int,
    is => 'ro',
    default => sub { 300 },
);

sub consume {
    my ($self, $data) = @_;
    if (!exists($data->{data}) || !exists($data->{url})) {
        try {
            $self->log_result(Bad->new(
                bad_event => $data,
            ));
        };
        return;
    }
    my $body = encode_json($data->{data});
    # XXX FIXME http://wiki.shopify.com/Verifying_Webhooks
    # HMAC goes here.
    #warn "MAKE POST to " . $data->{url};
    my $headers = { 'Content-Type' => 'application/json' };
    my $timeout = $self->timeout;
    my ($timer, $guard);
    $timer = AnyEvent->timer(
        after => $timeout,
        cb => sub {
            undef $guard;
            undef $timer;
            $self->log_result(Timeout->new(
                url => $data->{url},
            ));
        },
    );
    $guard = http_post
        $data->{url},
        $body,
        headers => $headers,
        timeout => $timeout + 5,
        sub {
            undef $guard;
            undef $timer;
            my ($body, $headers) = @_;
            if ($headers->{Status} =~ /2\d\d/) {
                $self->log_result(Success->new(
                    url => $data->{url},
                ));
            }
            else {
                $self->log_result(Failure->new(
                    url => $data->{url} || 'No url!',
                    code => $headers->{Status},
                ));
            }
            #use Data::Dumper; warn Dumper(\@_);
        };
}

1;

=head1 NAME

Message::Passing::Output::WebHooks - call 'WebHooks' with messages.

=head1 SYNOPSIS

    message-pass_webhooks --input STDIN

    You type:
    {"url": "http://localhost:5000/test","@type":"WebHooks","data":{"foo":"bar"}}

    Causes:

    POST /test HTTP/1.1
    Host: localhost:5000
    Content-Length: 13
    Content-Type: application/json

    {"foo":"bar"}

    # Consume messages from ZeroMQ, and publish results to
    # ZeroMQ:
    message-pass_webhooks --input ZeroMQ --input_options \
        '{"socket_bind":"tcp://*:5558"}' --log ZeroMQ \
        --log_options '{"connect":"tcp://192.168.0.1:5559"}'

=head1 WHAT IS A WEBHOOK

A web-hook is an a notification method used by APIs.

The idea is that you (as a client) define a URI on your website which is called when a certain action
happens at your API provider. Some data relevant to the event is serialized out to you, allowing you
to take action.

The canonical example is PayPal's IPN system, in which PayPal make a call to your online payment system to
verify that a payment has been made.

=head1 DESCRIPTION

This class expects to have it's consume method called with a has of parameters, including:

=over

=item url

The URL to make the request to.

=item data

The data to serialize out to the HTTP post request

=back

=head1 USAGE

As a L<Message::Passing> component, input is easy - if you're writing asynchronous perl code already,
you can use the L<Message::Passing::Output::WebHooks> class directly in your perl code, or
you can use L<Log::Dispatch::Message::Passing> to divert your application logs into it via the
L<Log::Dispatch> framework. 

If you're not already an L<AnyEvent> perl app (most people!), then you can use
L<Message::Passing::Input::STDIN>, L<Message::Passing::Input::ZeroMQ>
or any other input class, and the command line message-pass utility supplied to run a worker
process, then send messages to it.

To send messages, you can either use Java or Ruby logstash L<http://logstash.net/>, or
if you're in perl, then it's entirely possible to use the L<ZeroMQ> output component,
L<Message::Passing::Output::ZeroMQ> from within a normal perl application (via L<Log::Dispatch::Message::Passing>
or directly).

=head1 LOGGING

This output publishes one message for each message received, logging
the status of the HTTP call after it completes.

The log output can be setup on command line as documented in the SYNOPSIS,
or if you're building classes manually, you can supply the C<log_chain>
attribute yourself.

Events that can be logged are:

=head2 L<Message::Passing::WebHooks::Event::Bad>.

The message received was missing either a C< url > or a C< data >
field, meaning it could not be used for a HTTP request.

=head2 L<Message::Passing::WebHooks::Event::Call::Success>.

The call succeeded, and a 2XX status was received from the remote
server

=head2 L<Message::Passing::WebHooks::Event::Call::Failure>.

The call failed, due to a bad server or the server returning an error
status.

=head2 L<Message::Passing::WebHooks::Event::Call::Timeout>.

The remote server failed to respond within the timeout configured
so the request was aborted.

=head1 ATTRIBUTES

=head2 log_chain

Holds a chain of L<Message::Passing> filters and outputs.

Defaults to L<Message::Passing::Output::Null>, causing all status reports
to be discarded.

=head2 timeout

Integer number of seconds, after which HTTP connections are timed out.

=head1 METHODS

=head2 consume

Generates and sends the post request from the message passed.

=head1 SEE ALSO

=over

=item L<Message::Passing>

=item L<http://logstash.net>

=item L<http://wiki.shopify.com/WebHook>

=back

=head1 AUTHOR

Tomas (t0m) Doran <bobtfish@bobtfish.net>

=head1 SPONSORSHIP

This module exists due to the wonderful people at Suretec Systems Ltd.
<http://www.suretecsystems.com/> who sponsored its development for its
VoIP division called SureVoIP <http://www.surevoip.co.uk/> for use with
the SureVoIP API - 
<http://www.surevoip.co.uk/support/wiki/api_documentation>

=head1 COPYRIGHT

Copyright Suretec Systems 2012.

=head1 LICENSE

GNU Affero General Public License, Version 3

If you feel this is too restrictive to be able to use this software,
please talk to us as we'd be willing to consider re-licensing under
less restrictive terms.

=cut

1;


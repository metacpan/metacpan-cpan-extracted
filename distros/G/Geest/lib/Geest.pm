package Geest;
use Moo;
use AnyEvent;
use AnyEvent::HTTP ();
use AnyEvent::Socket ();
use HTTP::Message::PSGI ();
use HTTP::Request;
use HTTP::Response;
use Log::Minimal;
use Plack::Request;
use Geest::Backend;
use constant DEBUG => !!$ENV{GEEST_DEBUG};
our $VERSION = '0.02';
BEGIN {
    $Log::Minimal::ENV_DEBUG = "GEEST_DEBUG";
    $Log::Minimal::PRINT = sub {
        my ($time, $type, $message) = @_;
        print STDERR "$time [$type] $message\n";
    };
}

has master => (
    is => 'rw'
);

has callbacks => (
    is => 'lazy',
    default => sub { +{} }
);

has backends => (
    is => 'lazy',
    default => sub { +{} }
);

sub on {
    my ($self, $name, $cb) = @_;
    my $list = $self->callbacks->{$name} ||= [];
    push @$list, $cb;
}

sub fire {
    my ($self, $name, @args) = @_;

    my $list = $self->callbacks->{$name} || [];
    my @ret;
    foreach my $cb (@$list) {
        if (DEBUG) {
            debugf("Firing callback %s for hook '%s'", $cb, $name);
        }
        @ret = $cb->(@args);
    }
    return @ret;
}

sub add_master {
    my ($self, $name, %args) = @_;
    $self->master($name);
    $self->add_backend($name, %args);
}

sub add_backend {
    my ($self, $name, %args) = @_;
    $self->backends->{$name} = Geest::Backend->new(name => $name, %args);
}

sub psgi_app {
    my $self = shift;

    # Do some sanity checks...
    # Make sure that we have backends registered
    {
        my $backends = $self->backends;
        if (keys %$backends < 1) {
            Carp::croak("No backends registered! Can't proceed");
        }

        my $master = $self->master;
        if (! $master) {
            Carp::croak("No master backend registered! Can't proceed");
        }
    }

    return sub {
        my $env = shift;

        # Do away with stuff you don't really need to postpone.
        my $preq = Plack::Request->new($env);
        my $hreq = HTTP::Request->new($preq->method, $preq->uri);
        $preq->headers->scan(sub {
            my ($k, $v) = @_;
            $hreq->headers->push_header($k, $v);
        });
        $hreq->content($preq->content);

        return sub {
            my $responder = shift;

            my $backends = $self->backends;
            my ($backend_names) = $self->fire('select_backend', $hreq);
            if (! $backend_names) {
                # You didn't specify any backends for me? hmmm...
                # Well, then let's just get all the backends...
                $backend_names = [ keys %$backends ];
            }

            if (DEBUG) {
                local $Log::Minimal::AUTODUMP = 1;
                debugf("Backend names: %s", $backend_names);
            }

            # Keep track of this request
            my %state = (
                sent_reply => 0,
                reply_on_master =>
                    !!(grep { $_ eq $self->master } @$backend_names),
            );

            # Check at which point we should reply to the client.
            # If the list of backends contains the master backend,
            # we honor that. Otherwise, just reply when the earliest
            # reply comes in
            # This is where we hold the responses
            my %responses;

            # When all sub-requests are done, fire the backend_finished
            # hook. Note that this will most likely fire AFTER the
            # client has received a response. See $respond_cv below
            my $main_cv = AE::cv {
                if (DEBUG) {
                    debugf("Received all responses");
                }
                $self->fire(backend_finished => \%responses);

                # Explicitly free the response so we don't possibly
                # hog all the memory 
                undef %responses;
                undef %state;
            };

            # When the master server responds, we reply to the client.
            # Waiting for all the backends would be silly.
            my $respond_cv = AE::cv {
                $responder->($_[0]->recv);
            };

            foreach my $backend (map { $backends->{$_} } @$backend_names ) {
                my %response = (
                    backend => $backend,
                    request => $hreq,
                    response => undef
                );
                $responses{$backend->name} = \%response;

                $main_cv->begin;
                my $cv = $self->send_backend($backend, $hreq->clone);
                $cv->cb(sub {
                    $response{response} = HTTP::Message::PSGI::res_from_psgi($cv->recv);
                    $main_cv->end;
                    if ($state{sent_reply}) {
                        # We hav ealready sent a reply. short-circuit.
                        return;
                    }

                    if ($state{reply_on_master}) {
                        # check if this is master
                        if ($backend->name eq $self->master) {
                            if (DEBUG) {
                                debugf("Received response from '%s' (master), replying to client", $backend->name);
                            }
                            $respond_cv->send($cv->recv);
                            $state{sent_reply}++;
                        }
                    } else {
                        # Nothing specified, just reply 
                        if (DEBUG) {
                            debugf("Received response from '%s', replying to client", $backend->name);
                        }
                        $respond_cv->send($cv->recv);
                        $state{sent_reply}++;
                    }
                });
            }
        };
    }
}

sub send_backend {
    my ($self, $backend, $req) = @_;

    if (DEBUG) {
        debugf("Sending %s '%s %s'", $backend->name, $req->method, $req->uri);
    }

    $self->fire(munge_request => ($backend, $req));

    my %headers;
    $req->headers->scan(sub {
        my ($key, $value) = @_;
        $headers{$key} = $value;
    });

    my $cv = AE::cv;
    my $guard; $guard = AnyEvent::HTTP::http_request(
        $req->method,
        $req->uri,
        headers => \%headers,
        recurse => 0,
        persistent => 0,
        tcp_connect => sub {
            # Override tcp_connect so we connect to the specified
            # backend instead of the request url
            my ($host, $port, $connect_cb, $prepare_cb) = @_;
            if (DEBUG) {
                debugf("Connecting to %s => %s:%s", $backend->name, $backend->host, $backend->port);
            }
            return AnyEvent::Socket::tcp_connect(
                $backend->host,
                $backend->port,
                sub {
                    if (DEBUG) {
                        debugf("Connected to %s => %s:%s", $backend->name, $backend->host, $backend->port);
                    }
                    $connect_cb->(@_),
                },
                $prepare_cb
            );
        },
        sub {
            # Free me, baby.
            undef $guard;

            if (DEBUG) {
                debugf("Received response from %s => code = %s, message = %s", $backend->name, $_[1]->{Status}, $_[1]->{Reason});
            }
            # Remove these pseudo-headers from AE::HTTP
            delete $_[1]->{URL};
            delete $_[1]->{HTTPVersion};
            delete $_[1]->{Reason};

            # Notify the condvar with a PSGI response.
            $cv->send([
                delete $_[1]->{Status},
                [ %{$_[1]} ],
                [ $_[0] ]
            ]);
        }
    );
    return $cv;
}


no Moo;

1;

__END__

=head1 NAME

Geest - Perl Port of Kage

=head1 SYNOPSIS

    # app.psgi
    use strict;
    use Geest;

    my $server = Geest->new;
    $server->add_master(production => (
        host => "myapp.production.example.com",
        port => 80
    ));
    $server->add_backend(staging => (
        host => "myapp.staging.example.com",
        port => 8000
    ));
    $server->on(select_backend => sub {
        return [ "staging", "production" ]
    });
    $server->on(backend_finished => sub {
        my $responses = shift;
        my $data_production = $responses->{production}->{response}->decoded_content;
        my $data_staging    = $responses->{staging}->{response}->decoded_content;
        ...
    });

    $server->psgi_app;

    # run it
    twiggy -a app.psgi

=head1 DESCRIPTION

This is a port of kage (https://github.com/cookpad/kage) to perl. 
Why does this exist? Because I felt like writing it, duh.

In its essence, this module is just an HTTP proxy server. It receives requests
from the client, and broadcasts the requests to multiple backends.

Why would you want this? For example, you can put this in front of your
staging app server while you're refactoring your code. Geest can be configured
to access your production server AND your refactored server, and to show
any differences in the content received. This way you can avoid breaking
your existing code.

=head1 HOW GEEST PROCESSES REQUESTS

Backends consist of one "master", and one or more others. The client only
receives response from the master. This comes in handy depending on where you
put the kage proxy. See example later.

Backends can be registered through the C<add_backend()> method (or 
C<add_master()>, if you are adding a master backend)

    $server->add_backend(name_of_backend => (
        host => ...,
        port => ...
    ));

By default all backends are used, but you may change this by setting the
C<select_backend> hook:

    $server->on(select_backend => sub {
        my ($request) = @_; # HTTP::Request object
        ...
    });

The callback receives the HTTP::Request object representing the original
client request. You can, for example, choose to send all GET requests to
servers A and B, and everything else to only B

    $server->on(select_backend => sub {
        my ($request) = @_;
        if ($request->method eq 'GET') {
            return [ 'A', 'B' ];
        } else {
            return [ 'A' ];
        }
    });

The proxy asynchronously connects to the hosts specified by the method
above, and then send them the same request. If you want to change the
requests being sent to each backend, you can do so in the C<munge_request>
hook:

    $server->on(munge_request => sub {
        my ($backend, $request) = @_;
        # Do what you will to $request
    });

When the backend responds, the response is accumulated in memory. If
the list of backends contains the "master" backend, then the client will
receive the response when the proxy receives a response from the master.
Otherwise, the first response is used to reply to the client.

When all the backends are finished, the C<backend_finished> hook is called.
You can do any verification you need to do in this hook. For example,
the most simple check would be to check the difference between the
responses:

    use Text::Diff;

    $server->on(backend_finished => sub {
        my ($responses) = @_;
        # $responses = {
        #    name_of_backend => {
        #       backend  => ...,  # Geest::Backend object
        #       response => ...,  # HTTP::Response object
        #       request  => ...,  # HTTP::Request object
        #    },
        #    ...
        # };
        if (! $responses->{prod} && $responses->{dev}) {
            return;
        }

        my $data_prod = $responses->{prod}->{response}->decoded_content;
        my $data_dev  = $responses->{dev}->{response}->decoded_content;
        if ($data_prod ne $data_dev) {
            # You probably want to check that both responses are
            # content_type -> text/* before running diff()
            print STDERR diff(\$data_prod, $data_dev);
        }
    });

And voila, you get to check if you have any differences between your current
development version and the production server.

=head1 DEBUG

When you set C<GEEST_DEBUG> to a non-zero value, debug output will be available.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=cut


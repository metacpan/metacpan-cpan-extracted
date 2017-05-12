###########################################
package LWP::UserAgent::POE;
###########################################

use strict;
use warnings;

our $VERSION = "0.05";
use LWP::UserAgent;
use base "LWP::UserAgent";

use warnings;
use strict;
use POE;
use POE::Component::Client::HTTP;
use HTTP::Request;
use Log::Log4perl qw(:easy);

#use Scalar::Defer;

###########################################
sub new {
###########################################
    my ($class, %options) = @_;

    my $default_options = LWP::UserAgent->new( %options );
    delete $default_options->{proxy};

    my $self = bless {
        await_id => 0,
        poco_alias => "lwp_useragent_poe_http_client_poco",
        %$default_options,
        %options,
    }, $class;

    DEBUG "Creating $self->{poco_alias} session";

    POE::Session->create(
        object_states => [
            $self => {
                on_response => '_poe_handle_response',
                on_request  => '_poe_handle_request',
                on_shutdown => '_poe_handle_shutdown',
                _start => '_poe_handle_startup',
            }
        ],
    );

    $self->spawn();

    return $self;
}

###########################################
sub spawn {
###########################################
    my($self) = @_;

    if( $poe_kernel->alias_resolve( $self->{poco_alias} ) ){
        DEBUG "Not spawning $self->{poco_alias}",
              " session (there's one already)";
        return 1;
    }

    DEBUG "Spawning $self->{poco_alias} POE HTTP client component";

    POE::Component::Client::HTTP->spawn(
        Alias           =>  $self->{poco_alias},
        $self->poco_options(),
    );
}

###########################################
sub poco_options {
###########################################
    my($self) = @_;

    # agent                   "libwww-perl/#.##"
    # from                    undef
    # conn_cache              undef
    # cookie_jar              undef
    # default_headers         HTTP::Headers->new
    # max_size                undef
    # max_redirect            7
    # parse_head              1
    # protocols_allowed       undef
    # protocols_forbidden     undef
    # requests_redirectable   [’GET’, ’HEAD’]
    # timeout                 180

    my %lwp2poco = (
        agent      => "Agent",
        from       => "From",
        timeout    => "Timeout",
        max_size   => "MaxSize",
        cookie_jar => "CookieJar",
        proxy      => "Proxy",
        noproxy    => "NoProxy",
        redirects  => "FollowRedirects",
    );
    
    my %poco_options = ();

    for my $lwp_opt (keys %lwp2poco) {
        if(exists $lwp2poco{ $lwp_opt } ) {
            $poco_options{ $lwp2poco{ $lwp_opt } } =
                $self->{ $lwp_opt };
        }
    }

    return %poco_options;
}

###########################################
sub _poe_handle_startup {
###########################################
    $_[KERNEL]->alias_set("$_[OBJECT]");
}

###########################################
sub _poe_handle_shutdown {
###########################################
    $_[KERNEL]->alias_remove("$_[OBJECT]");
}

###########################################
sub simple_request {
###########################################
    my ($self, $request) = @_;

    INFO "Received request ", $request->url();

    $self->prepare_request( $request );

    my $promise = \my $scalar;
    $poe_kernel->post("$self", on_request => $request, $promise);
    $self->await( $promise, $request );
    return $$promise;

    # maybe we'll add that later to stack up requests before
    # processing them. 
    # lazy { $$promise or $self->await($promise); $$promise };
}

###########################################
sub _poe_handle_request {
###########################################
    my ($self, $kernel, $request, $promise) = @_[OBJECT, KERNEL, ARG0, ARG1];
    
    DEBUG "Handling request ", $request->url();

    $kernel->post($self->{poco_alias} =>
                  request => on_response => $request, $promise);
}

###########################################
sub _poe_handle_response {
###########################################
    my ($self, $request_info, $response_info) = @_[OBJECT, ARG0, ARG1];

    DEBUG "Handling response ", $request_info->[0]->url();

    my $promise = $request_info->[1];
    my $response = $response_info->[0];

    my $promise_number = $promise + 0;
    $$promise = $response;

    my $await_id = delete $self->{awaiting}{$promise_number};
    delete $self->{promises}{$await_id}{$promise_number};
}

###########################################
sub await {
###########################################
    my ($self, $promise, $request) = @_;

    DEBUG "Awaiting ", $request->url();

    my $await_id = $self->{await_id}++;

    my $promise_number = $promise+0;
    $self->{promises}{$await_id}{$promise_number} = $promise;
    $self->{awaiting}{$promise_number} = $await_id;

    while (keys %{$self->{promises}{$await_id}}) {
        $poe_kernel->run_one_timeslice();
    }

    INFO "Response from ", $request->url(), " arrived (", 
         $$promise->code(), ")";

    delete $self->{promises}{$await_id};
}

1;

__END__

=head1 NAME

LWP::UserAgent::POE - Drop-in LWP::UserAgent replacement in POE environments

=head1 SYNOPSIS

    use LWP::UserAgent::POE;

    my $ua = LWP::UserAgent::POE->new();

      # The following command looks (and behaves) like it's blocking, 
      # but it actually keeps the POE kernel ticking and processing 
      # other tasks. post() and request() work as well.
    my $resp = $ua->get( "http://www.yahoo.com" );

    if($resp->is_success()) {
        print $resp->content();
    } else {
        print "Error: ", $resp->message(), "\n";
    }

    POE::Kernel->run();

=head1 DESCRIPTION

LWP::UserAgent::POE is a subclass of LWP::UserAgent and works 
well in a POE environment. It is a drop-in replacement for LWP::UserAgent
in systems that are already using LWP::UserAgent synchronously and want 
to play nicely with POE.

The problem: LWP::UserAgent by itself is synchronous and blocks on
requests until the response from the network trickles in. This is 
unacceptable in POE, as the POE kernel needs to
continue processing other tasks until the HTTP response arrives.

LWP::UserAgent::POE to the rescue. Its request() method and all related
methods like get(), post() etc. work just like in the original.
But if you peek under the hood, they're sending a request to a 
running POE::Component::Client::HTTP component and return a valid $response
object when a response from the network is available. 
Although the program flow seems to be blocked, it's not. 
LWP::UserAgent::POE works the magic behind the scenes to keep the POE
kernel ticking and process other tasks.

The net effect is that you can use LWP::UserAgent::POE just like 
LWP::UserAgent in a seemingly synchronous way.

Note that this module is B<not> a POE component. Instead, it is a 
subclass of LWP::UserAgent. It is self-contained, it even spawns the
POE::Component::Client::HTTP component in its constructor unless there's 
one already running that has been started by another instance.

=head2 Cookies and other features

Just like LWP::UserAgent, LWP::UserAgent::POE supports cookies if you 
define a cookie jar:

   my $ua = LWP::UserAgent::POE->new(
       cookie_jar => HTTP::Cookies->new(),
   );

Just make sure to pass these parameters to the constructor, see the
'Bugs' section below on what hasn't been implemented yet.

=head2 Bugs

Currently, you can't call LWP::UserAgent's parameter methods, like

    $ua->timeout();

as this won't be propagated to the POE component running the HTTP
requests. It might be added later. Currently, you have to add it
to the constructor, like

    my $ua = LWP::UserAgent->new( timeout => 10 );

to take effect. LWP::UserAgent::POE translates the LWP::UserAgent parameter 
names to POE::Component::Client::HTTP's parameters, which are 
slightly different.

=head1 LEGALESE

Copyright 2008 by Mike Schilli and Rocco Caputo, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

The code of this module is based on Rocco Caputo's "pua-defer" code, which
has been included with his permission.

2008, Mike Schilli <cpan@perlmeister.com>

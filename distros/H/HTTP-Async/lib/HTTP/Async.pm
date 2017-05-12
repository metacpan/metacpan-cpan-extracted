use strict;
use warnings;

package HTTP::Async;

our $VERSION = '0.33';

use Carp;
use Data::Dumper;
use HTTP::Response;
use IO::Select;
use Net::HTTP::NB;
use Net::HTTP;
use URI;
use Time::HiRes qw( time sleep );

=head1 NAME

HTTP::Async - process multiple HTTP requests in parallel without blocking.

=head1 SYNOPSIS

Create an object and add some requests to it:

    use HTTP::Async;
    my $async = HTTP::Async->new;
    
    # create some requests and add them to the queue.
    $async->add( HTTP::Request->new( GET => 'http://www.perl.org/'         ) );
    $async->add( HTTP::Request->new( GET => 'http://www.ecclestoad.co.uk/' ) );

and then EITHER process the responses as they come back:

    while ( my $response = $async->wait_for_next_response ) {
        # Do some processing with $response
    }
    
OR do something else if there is no response ready:
    
    while ( $async->not_empty ) {
        if ( my $response = $async->next_response ) {
            # deal with $response
        } else {
            # do something else
        }
    }

OR just use the async object to fetch stuff in the background and deal with
the responses at the end.

    # Do some long code...
    for ( 1 .. 100 ) {
      some_function();
      $async->poke;            # lets it check for incoming data.
    }

    while ( my $response = $async->wait_for_next_response ) {
        # Do some processing with $response
    }    

=head1 DESCRIPTION

Although using the conventional C<LWP::UserAgent> is fast and easy it does
have some drawbacks - the code execution blocks until the request has been
completed and it is only possible to process one request at a time.
C<HTTP::Async> attempts to address these limitations.

It gives you a 'Async' object that you can add requests to, and then get the
requests off as they finish. The actual sending and receiving of the requests
is abstracted. As soon as you add a request it is transmitted, if there are
too many requests in progress at the moment they are queued. There is no
concept of starting or stopping - it runs continuously.

Whilst it is waiting to receive data it returns control to the code that
called it meaning that you can carry out processing whilst fetching data from
the network. All without forking or threading - it is actually done using
C<select> lists.

=head1 Default settings:

There are a number of default settings that should be suitable for most uses.
However in some circumstances you might wish to change these.

            slots:  20
          timeout:  180 (seconds)
 max_request_time:  300 (seconds)
    max_redirect:   7
    poll_interval:  0.05 (seconds)
       proxy_host:  ''
       proxy_port:  ''
       local_addr:  ''
       local_port:  ''
       ssl_options: {}
       cookie_jar:  undef
       peer_addr:   ''

If defined, is expected to be similar to C<HTTP::Cookies>, with extract_cookies and add_cookie_header methods.

The option max_redirects has been renamed to max_redirect to be consistent with LWP::UserAgent, although max_redirects still works.

       
=head1 METHODS

=head2 new

    my $async = HTTP::Async->new( %args );

Creates a new HTTP::Async object and sets it up. Variations from the default
can be set by passing them in as C<%args>.

=cut

sub new {
    my $class = shift;
    my $self  = bless {

        opts => {
            slots            => 20,
            max_redirect     => 7,
            timeout          => 180,
            max_request_time => 300,
            poll_interval    => 0.05,
            cookie_jar       => undef,
        },

        id_opts => {},

        to_send     => [],
        in_progress => {},
        to_return   => [],

        current_id   => 0,
        fileno_to_id => {},
    }, $class;

    $self->_init(@_);

    return $self;
}

sub _init {
    my $self = shift;
    my %args = @_;
    $self->_set_opt( $_ => $args{$_} ) for sort keys %args;
    return $self;
}

sub _next_id { return ++$_[0]->{current_id} }

=head2 slots, timeout, max_request_time, poll_interval, max_redirect, proxy_host, proxy_port, local_addr, local_port, ssl_options, cookie_jar, peer_addr

    $old_value = $async->slots;
    $new_value = $async->slots( $new_value );

Get/setters for the C<$async> objects config settings. Timeout is for
inactivity and is in seconds.

Slots is the maximum number of parallel requests to make.

=cut

my %GET_SET_KEYS = map { $_ => 1 } qw( slots poll_interval
  timeout max_request_time max_redirect
  proxy_host proxy_port local_addr local_port ssl_options cookie_jar peer_addr);

sub _add_get_set_key {
    my $class = shift;
    my $key   = shift;
    $GET_SET_KEYS{$key} = 1;
}

my %KEY_ALIASES = ( max_redirects => 'max_redirect' );

sub _get_opt {
    my $self = shift;
    my $key  = shift;
    my $id   = shift;

    $key = $KEY_ALIASES{$key} if exists $KEY_ALIASES{$key};

    die "$key not valid for _get_opt" unless $GET_SET_KEYS{$key};

    # If there is an option set for this id then use that, otherwise fall back
    # to the defaults.
    return $self->{id_opts}{$id}{$key}
      if $id && defined $self->{id_opts}{$id}{$key};

    return $self->{opts}{$key};

}

sub _set_opt {
    my $self = shift;
    my $key  = shift;

    $key = $KEY_ALIASES{$key} if exists $KEY_ALIASES{$key};

    die "$key not valid for _set_opt" unless $GET_SET_KEYS{$key};
    $self->{opts}{$key} = shift if @_;
    return $self->{opts}{$key};
}

foreach my $key ( keys %GET_SET_KEYS ) {
    eval "
    sub $key {
        my \$self = shift;
        return scalar \@_
          ? \$self->_set_opt( '$key', \@_ )
          : \$self->_get_opt( '$key' );
    }
    ";
}

=head2 add

    my @ids      = $async->add(@requests);
    my $first_id = $async->add(@requests);

Adds requests to the queues. Each request is given an unique integer id (for
this C<$async>) that can be used to track the requests if needed. If called in
list context an array of ids is returned, in scalar context the id of the
first request added is returned.

=cut

sub add {
    my $self    = shift;
    my @returns = ();

    foreach my $req (@_) {
        push @returns, $self->add_with_opts( $req, {} );
    }

    return wantarray ? @returns : $returns[0];
}

=head2 add_with_opts

    my $id = $async->add_with_opts( $request, \%opts );

This method lets you add a single request to the queue with options that
differ from the defaults. For example you might wish to set a longer timeout
or to use a specific proxy. Returns the id of the request.

The method croaks when passed an invalid option.

=cut

sub add_with_opts {
    my $self = shift;
    my $req  = shift;
    my $opts = shift;

    for my $key (keys %{$opts}) {
        croak "$key not valid for add_with_opts" unless $GET_SET_KEYS{$key};
    }

    my $id = $self->_next_id;

    push @{ $$self{to_send} }, [ $req, $id ];
    $self->{id_opts}{$id} = $opts;
    $self->poke;

    return $id;
}

=head2 poke

    $async->poke;

At fairly frequent intervals some housekeeping needs to performed - such as
reading received data and starting new requests. Calling C<poke> lets the
object do this and then return quickly. Usually you will not need to use this
as most other methods do it for you.

You should use C<poke> if your code is spending time elsewhere (ie not using
the async object) to allow it to keep the data flowing over the network. If it
is not used then the buffers may fill up and completed responses will not be
replaced with new requests.

=cut

sub poke {
    my $self = shift;

    $self->_process_in_progress;
    $self->_process_to_send;

    return 1;
}

=head2 next_response

    my $response          = $async->next_response;
    my ( $response, $id ) = $async->next_response;

Returns the next response (as a L<HTTP::Response> object) that is waiting, or
returns undef if there is none. In list context it returns a (response, id)
pair, or an empty list if none. Does not wait for a response so returns very
quickly.

=cut

sub next_response {
    my $self = shift;
    return $self->_next_response(0);
}

=head2 wait_for_next_response

    my $response          = $async->wait_for_next_response( 3.5 );
    my ( $response, $id ) = $async->wait_for_next_response( 3.5 );

As C<next_response> but only returns if there is a next response or the time
in seconds passed in has elapsed. If no time is given then it blocks. Whilst
waiting it checks the queues every c<poll_interval> seconds. The times can be
fractional seconds.

=cut

sub wait_for_next_response {
    my $self     = shift;
    my $wait_for = shift;

    $wait_for = $self->max_request_time
      if !defined $wait_for;

    return $self->_next_response($wait_for);
}

sub _next_response {
    my $self        = shift;
    my $wait_for    = shift || 0;
    my $end_time    = time + $wait_for;
    my $resp_and_id = undef;

    while ( !$self->empty ) {
        $resp_and_id = shift @{ $$self{to_return} };

        # last if we have a response or we have run out of time.
        last
          if $resp_and_id
          || time > $end_time;

        # sleep for the default sleep time.
        # warn "sleeping for " . $self->poll_interval;
        sleep $self->poll_interval;
    }

    # If there is no result return false.
    return unless $resp_and_id;

    # We have a response - delete the options for it from the store.
    delete $self->{id_opts}{ $resp_and_id->[1] };

    # If we have a result return list or response depending on
    # context.
    return wantarray
      ? @$resp_and_id
      : $resp_and_id->[0];
}

=head2 to_send_count

    my $pending = $async->to_send_count;

Returns the number of items which have been added but have not yet started being processed.

=cut

sub to_send_count {
    my $self = shift;
    $self->poke;
    return scalar @{ $self->{to_send} };
}

=head2 to_return_count

    my $completed = $async->to_return_count;

Returns the number of items which have completed transferring, and are waiting to be returned by next_response().

=cut

sub to_return_count {
    my $self = shift;
    $self->poke;
    return scalar @{ $self->{to_return} };
}

=head2 in_progress_count

    my $running = $async->in_progress_count;

Returns the number of items which are currently being processed asynchronously.

=cut

sub in_progress_count {
    my $self = shift;
    $self->poke;
    return scalar keys %{ $self->{in_progress} };
}

=head2 total_count

    my $total = $async->total_count;

Returns the sum of the to_send_count, in_progress_count and to_return_count.

This should be the total number of items which have been added that have not yet been returned by next_response().

=cut

sub total_count {
    my $self = shift;

    my $count = 0                   #
      + $self->to_send_count        #
      + $self->in_progress_count    #
      + $self->to_return_count;

    return $count;
}

=head2 info

    print $async->info;

Prints a line describing what the current state is.

=cut

sub info {
    my $self = shift;

    return sprintf(
        "HTTP::Async status: %4u,%4u,%4u (send, progress, return)\n",
        $self->to_send_count,        #
        $self->in_progress_count,    #
        $self->to_return_count
    );
}

=head2 remove

    $async->remove($id);
    my $success = $async->remove($id);

Removes the item with the given id no matter which state it is currently in. Returns true if an item is removed, and false otherwise.

=cut

sub remove {
    my $self = shift;
    my $id = shift;

    my $hashref = delete $self->{in_progress}{$id};
    if (!$hashref) {
        for my $list ('to_send', 'to_return') {
            my ($r_and_id) = grep { $_->[1] eq $id } @{ $self->{$list} };
            $hashref = $r_and_id->[0];
            if ($hashref) {
                @{ $self->{$list} }
                    = grep { $_->[1] ne $id } @{ $self->{$list} };
            }
        }
    }
    return if !$hashref;

    my $s = $hashref->{handle};
    $self->_io_select->remove($s);
    delete $self->{id_opts}{$id};

    return 1;
}

=head2 remove_all

    $async->remove_all;
    my $success = $async->remove_all;

Removes all items no matter what states they are currently in. Returns true if any items are removed, and false otherwise.

=cut

sub remove_all {
    my $self = shift;
    return if $self->empty;

    my @ids = (
        (map { $_->[1] } @{ $self->{to_send} }),
        (keys %{ $self->{in_progress} }),
        (map { $_->[1] } @{ $self->{to_return} }),
    );

    for my $id (@ids) {
        $self->remove($id);
    }

    return 1;
}

=head2 empty, not_empty

    while ( $async->not_empty ) { ...; }
    while (1) { ...; last if $async->empty; }

Returns true or false depending on whether there are request or responses
still on the object.

=cut

sub empty {
    my $self = shift;
    return $self->total_count ? 0 : 1;
}

sub not_empty {
    my $self = shift;
    return !$self->empty;
}

=head2 DESTROY

The destroy method croaks if an object is destroyed but is not empty. This is
to help with debugging.

=cut

sub DESTROY {
    my $self  = shift;
    my $class = ref $self;

    carp "$class object destroyed but still in use"
      if $self->total_count;

    carp "$class INTERNAL ERROR: 'id_opts' not empty"
      if scalar keys %{ $self->{id_opts} };

    return;
}

# Go through all the values on the select list and check to see if
# they have been fully received yet.

sub _process_in_progress {
    my $self     = shift;
    my %seen_ids = ();

  HANDLE:
    foreach my $s ( $self->_io_select->can_read(0) ) {

        # Get the id and add it to the hash of seen ids so we don't check it
        # later for errors.
        my $id = $self->{fileno_to_id}{ $s->fileno }
          || die "INTERNAL ERROR: could not got id for fileno";
        $seen_ids{$id}++;

        my $hashref = $$self{in_progress}{$id};
        my $tmp = $hashref->{tmp} ||= {};

        # warn Dumper $hashref;

        # Check that we have not timed-out.
        if (   time > $hashref->{timeout_at}
            || time > $hashref->{finish_by} )
        {

            # warn sprintf "Timeout: %.3f > %.3f",    #
            #   time, $hashref->{timeout_at};

            $self->_add_error_response_to_return(
                id       => $id,
                code     => 504,
                request  => $hashref->{request},
                previous => $hashref->{previous},
                content  => 'Timed out',
            );

            $self->_io_select->remove($s);
            delete $$self{fileno_to_id}{ $s->fileno };
            next HANDLE;
        }

        # If there is a code then read the body.
        if ( $$tmp{code} ) {
            my $buf;
            my $n = $s->read_entity_body( $buf, 1024 * 16 );    # 16kB
            $$tmp{is_complete} = 1 unless $n;
            $$tmp{content} .= $buf;

            # warn "Received " . length( $buf ) ;

            # warn $buf;
        }

        # If no code try to read the headers.
        else {
            $s->flush;

            my ( $code, $message, %headers );

            eval {
                ( $code, $message, %headers ) =
                  $s->read_response_headers( laxed => 1, junk_out => [] );
            };

            if ($@) {
                $self->_add_error_response_to_return(
                    'code'     => 504,
                    'content'  => $@,
                    'id'       => $id,
                    'request'  => $hashref->{request},
                    'previous' => $hashref->{previous}
                );
                $self->_io_select->remove($s);
                delete $$self{fileno_to_id}{ $s->fileno };
                next HANDLE;
            }

            if ($code) {

                # warn "Got headers: $code $message " . time;

                $$tmp{code}    = $code;
                $$tmp{message} = $message;
                my @headers_array = map { $_, $headers{$_} } keys %headers;
                $$tmp{headers} = \@headers_array;

            }
        }

        # Reset the timeout.
        $hashref->{timeout_at} = time + $self->_get_opt( 'timeout', $id );
        # warn "recieved - timeout set to '$hashref->{timeout_at}'";

        # If the message is complete then create a request and add it
        # to 'to_return';
        if ( $$tmp{is_complete} ) {
            delete $$self{fileno_to_id}{ $s->fileno };
            $self->_io_select->remove($s);

            # warn Dumper $$hashref{content};

            my $response = HTTP::Response->new(
                @$tmp{ 'code', 'message', 'headers', 'content' } );

            $response->request( $hashref->{request} );
            $response->previous( $hashref->{previous} ) if $hashref->{previous};

            # Deal with cookies
            my $jar = $self->_get_opt('cookie_jar', $id);
            if ($jar) {
                $jar->extract_cookies($response);
            }

            # If it was a redirect and there are still redirects left
            # create a new request and unshift it onto the 'to_send'
            # array.
            # Only redirect GET and HEAD as per RFC  2616.
            # http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
            my $code = $response->code;
            my $get_or_head = $response->request->method =~ m{^(?:GET|HEAD)$};

            if (
                $response->is_redirect                     # is a redirect
                && $hashref->{redirects_left} > 0          # and we still want to follow
                && ($get_or_head || $code !~ m{^30[127]$}) # must be GET or HEAD if it's 301, 302 or 307
                && $code != 304                            # not a 'not modified' reponse
                && $code != 305                            # not a 'use proxy' response
              )
            {

                $hashref->{redirects_left}--;

                my $loc = $response->header('Location');
                my $uri = $response->request->uri;

                warn "Problem: " . Dumper( { loc => $loc, uri => $uri } )
                  unless $uri && ref $uri && $loc && !ref $loc;

                my $url = _make_url_absolute( url => $loc, ref => $uri );

                my $request = $response->request->clone;
                $request->uri($url);

                # These headers should never be forwarded
                $request->remove_header('Host', 'Cookie');

                # Don't leak private information.
                # http://www.w3.org/Protocols/rfc2616/rfc2616-sec15.html#sec15.1.3
                if ($request->header('Referer') &&
                    $hashref->{request}->uri->scheme eq 'https' &&
                    $request->uri->scheme eq 'http') {

                    $request->remove_header('Referer');
                }

                # See Other should use GET
                if ($code == 303 && !$get_or_head) {
                    $request->method('GET');
                    $request->content('');
                    $request->remove_content_headers;
                }

                $self->_send_request( [ $request, $id ] );
                $hashref->{previous} = $response;
            }
            else {
                $self->_add_to_return_queue( [ $response, $id ] );
                delete $$self{in_progress}{$id};
            }

            delete $hashref->{tmp};
        }
    }

    # warn Dumper(
    #     {
    #         in_progress => $self->{in_progress},
    #         seen_ids    => \%seen_ids,
    #     }
    # );

    foreach my $id ( keys %{ $self->{in_progress} } ) {

        # skip this one if it was processed above.
        next if $seen_ids{$id};

        my $hashref = $self->{in_progress}{$id};

        if (   time > $hashref->{timeout_at}
            || time > $hashref->{finish_by} )
        {

            # warn Dumper( { hashref => $hashref, now => time } );

            # we have a request that has timed out - handle it
            $self->_add_error_response_to_return(
                id       => $id,
                code     => 504,
                request  => $hashref->{request},
                previous => $hashref->{previous},
                content  => 'Timed out',
            );

            my $s = $hashref->{handle};
            $self->_io_select->remove($s);
            delete $$self{fileno_to_id}{ $s->fileno };
        }
    }

    return 1;
}

sub _add_to_return_queue {
    my $self       = shift;
    my $req_and_id = shift;
    push @{ $$self{to_return} }, $req_and_id;
    return 1;
}

# Add all the items waiting to be sent to 'to_send' up to the 'slots'
# limit.

sub _process_to_send {
    my $self = shift;

    while ( scalar @{ $$self{to_send} }
        && $self->slots > scalar keys %{ $$self{in_progress} } )
    {
        $self->_send_request( shift @{ $$self{to_send} } );
    }

    return 1;
}

sub _send_request {
    my $self     = shift;
    my $r_and_id = shift;
    my ( $request, $id ) = @$r_and_id;

    my $uri = URI->new( $request->uri );

    my %args = ();

    # Get cookies from jar if one exists
    my $jar = $self->_get_opt('cookie_jar', $id);
    if ($jar) {
        $jar->add_cookie_header($request);
    }

    # We need to use a different request_uri for proxied requests. Decide to use
    # this if a proxy port or host is set.
    #
    #   http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1.2
    $args{Host}     = $uri->host;
    $args{PeerAddr} = $self->_get_opt( 'proxy_host', $id );
    $args{PeerPort} = $self->_get_opt( 'proxy_port', $id );
    $args{LocalAddr} = $self->_get_opt('local_addr', $id );
    $args{LocalPort} = $self->_get_opt('local_port', $id );

    # https://rt.cpan.org/Public/Bug/Display.html?id=33071
    $args{Timeout} = $self->_get_opt( 'timeout', $id);

    # ACF - Pass ssl_options through
    $args{ssl_opts} = $self->_get_opt( 'ssl_options', $id);

    my $request_is_to_proxy =
      ( $args{PeerAddr} || $args{PeerPort} )    # if either are set...
      ? 1                                       # ...then we are a proxy request
      : 0;                                      # ...otherwise not

    # If we did not get a setting from the proxy then use the uri values.

    $args{PeerAddr} ||= $uri->host;
    my $peer_address = $self->_get_opt('peer_addr', $id );
    if($peer_address) {
        $args{PeerAddr} = $peer_address;
    }

    $args{PeerPort} ||= $uri->port;

    my $net_http_class = 'Net::HTTP::NB';
    if ($uri->scheme and $uri->scheme eq 'https' and not $request_is_to_proxy) {
        $net_http_class = 'Net::HTTPS::NB';
        eval {
            require Net::HTTPS::NB;
            Net::HTTPS::NB->import();
        };
        die "$net_http_class must be installed for https support" if $@;

        # Add SSL options, if any, to args
        my $ssl_options = $self->_get_opt('ssl_options');
        @args{ keys %$ssl_options } = values %$ssl_options if $ssl_options;
    }
    elsif($uri->scheme and $uri->scheme eq 'https' and $request_is_to_proxy) {
        # We are making an HTTPS request through an HTTP proxy such as squid.
        # The proxy will handle the HTTPS, we need to connect to it via HTTP
        # and then make a request where the https is clear from the scheme...
        $args{Host} = sprintf(
            '%s:%s',
            delete @args{'PeerAddr', 'PeerPort'}
        );
    }
    my $s = eval { $net_http_class->new(%args) };

    # We could not create a request - fake up a 503 response with
    # error as content.
    if ( !$s ) {

        $self->_add_error_response_to_return(
            id       => $id,
            code     => 503,
            request  => $request,
            previous => $$self{in_progress}{$id}{previous},
            content  => $@,
        );

        return 1;
    }

    my %headers;
    for my $key ($request->{_headers}->header_field_names) {
        $headers{$key} = $request->header($key);
    }

    # Decide what to use as the request_uri
    my $request_uri = $request_is_to_proxy    # is this a proxy request....
      ? $uri->as_string                       # ... if so use full url
      : _strip_host_from_uri($uri);    # ...else strip off scheme, host and port

    croak "Could not write request to $uri '$!'"
      unless $s->write_request( $request->method, $request_uri, %headers,
        $request->content );

    $self->_io_select->add($s);

    my $time = time;
    my $entry = $$self{in_progress}{$id} ||= {};

    $$self{fileno_to_id}{ $s->fileno } = $id;

    $entry->{request}    = $request;
    $entry->{started_at} = $time;

    
    $entry->{timeout_at} = $time + $self->_get_opt( 'timeout', $id );
    # warn "sent - timeout set to '$entry->{timeout_at}'";

    $entry->{finish_by}  = $time + $self->_get_opt( 'max_request_time', $id );
    $entry->{handle}     = $s;

    $entry->{redirects_left} = $self->_get_opt( 'max_redirect', $id )
      unless exists $entry->{redirects_left};

    return 1;
}

sub _strip_host_from_uri {
    my $uri = shift;

    my $scheme_and_auth = quotemeta( $uri->scheme . '://' . $uri->authority );
    my $url             = $uri->as_string;

    $url =~ s/^$scheme_and_auth//;
    $url = "/$url" unless $url =~ m{^/};

    return $url;
}

sub _io_select {
    my $self = shift;
    return $$self{io_select} ||= IO::Select->new();
}

sub _make_url_absolute {
    my %args = @_;

    my $in  = $args{url};
    my $ref = $args{ref};

    return URI->new_abs($in, $ref)->as_string;
}

sub _add_error_response_to_return {
    my $self = shift;
    my %args = @_;

    use HTTP::Status;

    my $response =
      HTTP::Response->new( $args{code}, status_message( $args{code} ),
        undef, $args{content} );

    $response->request( $args{request} );
    $response->previous( $args{previous} ) if $args{previous};

    $self->_add_to_return_queue( [ $response, $args{id} ] );
    delete $$self{in_progress}{ $args{id} };

    return $response;

}

=head1 SEE ALSO

L<HTTP::Async::Polite> - a polite form of this module. Slows the scraping down
by domain so that the remote server is not overloaded.

=head1 GOTCHAS

The responses may not come back in the same order as the requests were made.
For https requests to work, you must have L<Net::HTTPS::NB> installed.

=head1 THANKS

Egor Egorov contributed patches for proxies, catching connections that die
before headers sent and more.

Tomohiro Ikebe from livedoor.jp submitted patches (and a test) to properly
handle 304 responses.

Naveed Massjouni for adding the https handling code.

Alex Balhatchet for adding the https + proxy handling code, and for making the
tests run ok in parallel.

Josef Toman for fixing two bugs, one related to header handling and another
related to producing an absolute URL correctly.

Github user 'c00ler-' for adding LocalAddr and LocalPort support.

rt.cpan.org user 'Florian (fschlich)' for typo in documentation.

Heikki Vatiainen for the ssl_options support patch.

Daniel Lintott of the Debian Perl Group for pointing out a test failure when
using a very recent version of HTTP::Server::Simple to implement
t/TestServer.pm

=head1 BUGS AND REPO

Please submit all bugs, patches etc on github

L<https://github.com/evdb/HTTP-Async>

=head1 AUTHOR

Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>. 

L<http://www.ecclestoad.co.uk/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1;


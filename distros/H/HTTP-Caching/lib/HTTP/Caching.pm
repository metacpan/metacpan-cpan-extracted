package HTTP::Caching;

=head1 NAME

HTTP::Caching - The RFC 7234 compliant brains to do caching right

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.15';

use strict;
use warnings;

use Carp;
use Digest::MD5;
use HTTP::Method;
use HTTP::Status ':constants';
use List::MoreUtils qw{ any };
use Time::HiRes;
use URI;

use Moo;
use MooX::Types::MooseLike::Base ':all';

our $DEBUG = 0;

use Readonly;

Readonly my $REUSE_NO_MATCH             => 0; # mismatch of headers etc
Readonly my $REUSE_IS_OK                => 1;
Readonly my $REUSE_IS_STALE             => 2;
Readonly my $REUSE_REVALIDATE           => 4;
Readonly my $REUSE_IS_STALE_OK          => $REUSE_IS_STALE | $REUSE_IS_OK;
Readonly my $REUSE_IS_STALE_REVALIDATE  => $REUSE_IS_STALE | $REUSE_REVALIDATE;

=head1 SYNOPSIS

    my $chi_cache = CHI->new(
        driver          => 'File',
        root_dir        => '/tmp/HTTP_Caching',
        file_extension  => '.cache',
        l1_cache        => {
            driver          => 'Memory',
            global          => 1,
            max_size        => 1024*1024
        }
    );
    
    my $ua = LWP::UserAgent->new();
    
    my $http_caching = HTTP::Caching->new(
        cache         => $chi_cache,
        cache_type    => 'private',
        forwarder     => sub { return $ua->request(shift) }
    );
    
    my $rqst = HTTP::Request->new( GET => 'http://example.com' );
    
    my $resp = $http_caching->make_request( $rqst );
    
=cut

has cache => (
    is          => 'ro',
    required    => 0,
    isa         => Maybe[ HasMethods['set', 'get'] ],
    builder     => sub {
        warn __PACKAGE__ . " without cache, forwards requests and responses\n";
        return undef
    },
);

has cache_meta => (
    is          => 'ro',
    required    => 0,
    isa         => Maybe[ HasMethods['set', 'get'] ],
    lazy        => 1,
    builder     => sub {
        return shift->cache
    },
);

has cache_type => (
    is          => 'ro',
    required    => 1,
    isa         => Maybe[ Enum['private', 'public'] ],
);

has cache_control_request => (
    is          => 'ro',
    required    => 0,
    isa         => Maybe[ Str ],
);

has cache_control_response => (
    is          => 'ro',
    required    => 0,
    isa         => Maybe[ Str ],
);

has forwarder => (
    is          => 'ro',
    required    => 1,
    isa         => CodeRef,
);

sub is_shared {
    my $self = shift;
    
    return unless $self->cache_type;
    return $self->cache_type eq 'public'
}

=head1 DEPRECATION WARNING !!!

This module is going to be completely redesigned!!!

As it was planned, these are the brains, but unfortunately, it has become an
implementation.

The future version will answer two questions:

=over

=item may_store

=item may_reuse

=back

Those are currently implemented as private methods.

Please contact the author if you rely on this module directly to prevent
breakage

Sorry for any inconvenience

=head1 ADVICE

Please use L<LPW::UserAgent::Caching> or <LWP::UserAgent::Caching::Simple>.

=head1 NOTE

You can surpress the message by setting the environment varibale
C<HTTP_CACHING_DEPRECATION_WARNING_HIDE>

=cut

use HTTP::Caching::DeprecationWarning;

=head1 DESCRIPTION

This module tries to provide caching for HTTP responses based on
L<RFC 7234 Hypertext Transfer Protocol (HTTPE<sol>1.1): Caching|
    http://tools.ietf.org/html/rfc7234>.

Basicly it looks like the following steps below:

=over

=item

For a presented request, it will check with the cache if there is a suitable
response available AND if it can be served or that it needs to be revalidated
with an upstream server.

=item

If there was no response available at all, or non were suitable, the (modified)
request will simply be forwarded.

=item

Depending on the response it gets back, it will do one of the following
dependingon the response status code:

=over

=item 200 OK

it will update the cache and serve the response as is

=item 304 Not Modified

the cached version is valid, update the cache with new header info and serve the
cached response

=item 500 Server Error

in general, this is an error, and pass that onto the caller, however, in some
cases it could be fine to serve a (stale) cached response

=back

=back

The above is a over-simplified version of the RFC

=cut

=head1 CONSTRUCTORS

=head2 new

    my $http_caching = HTTP::Caching->new(
        cache           => $chi_cache,
        cache_type      => 'private',
        cache_request   => 'max-age=86400, min-fresh=60',
        forwarder       => sub { return $ua->request(shift) }
    );

Constructs a new C<HTTP::Caching> object that knows how to find cached responses
and will forward if needed.

=head1 ATRRIBUTES

=head2 cache

Cache must be an object that MUST implement two methods

=over

=item sub set ($key, $data)

to store data in the cache

=item sub get ($key)

to retrieve the data stored under the key

=back

This can be as simple as a hash, like we use in the tests:

    use Test::MockObject;
    
    my %cache;
    my $mocked_cache = Test::MockObject->new;
    $mocked_cache->mock( set => sub { $cache{$_[1]} = $_[2] } );
    $mocked_cache->mock( get => sub { return $cache{$_[1]} } );

But very convenient is to use L<CHI>, which implements both required methods and
also has the option to use a L1 cache to speed things up even more. See the
SYNOPSIS for an example

=head2 cache_type

This must either be C<'private'> or C<'public'>. For most L<LWP::UserAgents>, it
can be C<'private'> as it will probably not be shared with other processes on
the same macine. If this module is being used at the serverside in a
L<Plack::Middleware> then the cache will be used by all other clients connecting
to the server, and thus should be set to C<'public'>.

Responses to Authenticated request should not be held in public caches and also
those responses that specifacally have their cache-control headerfield set to
C<'private'>.

=head2 cache_control_request

A string that contains the Cache-control header-field settings that will be sent
as default with the request. So you do not have to set those each time. See
RFC 7234 Section 5.2.1 for the list of available cache-control directives.

=head2 cache_control_response

Like the above, but those will be set for each response. This is useful for
server side caching. See RFC 7234 Section 5.2.2.

=head2 forwarder

This CodeRef must be a callback function that accepts a L<HTTP::Request> and
returns a L<HTTP::Response>. Since this module does not know how to do a request
it will use the C<forwarder>. It will be used to sent of validation requests
with C<If-None-Match> and/or C<If-Modified-Since> header-fields. Or if it does
not have a stored response it will send the original full request (with the
extra directives from C<cache_request>).

Failing to return a C<HTTP::Response> might cause the module to die or generate
a response itself with status code C<502 Bad Gateway>. 

=head1 METHODS

=head2 make_request

This is the only public provided method and will take a L<HTTP::Request>. Like
described above, it might have to forward the (modified) request throug the
CodeRef in the C<forwarder> attribute.

It will return a L<HTTP::Response> from cache or a new retrieved one. This might
be a HTTP respons with a C<500 Error> message.

In other cases it might die and let the caller know what was wrong, or send
another 5XX Error.

=cut

sub make_request {
    
    HTTP::Caching::DeprecationWarning->show_once();

    my $self = shift;
    
    croak __PACKAGE__
        . " missing request"
        unless defined $_[0];
    croak __PACKAGE__
        . " request is not a HTTP::Request [$_[0]]"
        unless UNIVERSAL::isa($_[0],'HTTP::Request');
    
    my $presented_request = shift->clone;
    
    my @params = @_;

    # add the default Cache-Control request header-field
    $presented_request->headers->push_header(
        cache_control => $self->cache_control_request,
    ) if $self->cache_control_request();
    
    my $response;
    
    unless ($self->cache) {
        $response = $self->_forward($presented_request, @params);
    } elsif ( $self->_non_safe($presented_request) ) {
        
        # always forwad requests with unsafe methods
        $response = $self->_forward($presented_request, @params);
        
        # when returned with a non-err, invalidate the cache
        if ( $response->is_success or $response->is_redirect ) {
            $self->_invalidate($presented_request)
        }
    } else {
        if (my $cache_resp =
            $self->_retrieve($presented_request)
        ) {
            $response = $cache_resp;
        } else {
            $response = $self->_forward($presented_request, @params);
            $self->_store($presented_request, $response);
        }
    }
    
     # add the default Cache-Control response header-field
    $response->headers->push_header(
        cache_control => $self->cache_control_response,
    ) if $self->cache_control_response;
   
    return $response;
    
}

sub _forward {
    my $self = shift;
    
    my $forwarded_rqst = shift;
    
    my $forwarded_resp = $self->forwarder->($forwarded_rqst, @_);
    
    unless ( UNIVERSAL::isa($forwarded_resp,'HTTP::Response') ) {
        carp __PACKAGE__
            . " response is not a HTTP::Response [$forwarded_resp]";
        # rescue from a failed forwarding, HTTP::Caching should not break
        $forwarded_resp = HTTP::Response->new(502); # Bad Gateway
    }
    
    return $forwarded_resp;
}


=head1 ABOUT CACHING

If one would read the RFC7234 Section 2. Overview of Cache Operation, it becomes
clear that a cache can hold multiple responses for the same URI. Caches that
conform to CHI and many others, typically use a key / value storage. But this
will become a problem as that it can not use the URI as a key to the various
responses.

The way it is solved is to create an intermediate meta-dictionary. This can be
stored by URI as key. Each response will simply be stored with a unique key and
these keys will be used as the entries in the dictionary.

The meta-dictionary entries will hold (relevant) request and response headers so
that it willbe more quick to figure wich entrie can be used. Otherwise we would
had to read the entire responses to analyze them.

=cut

# _store may or may not store the response into the cache
#
# depending on the response it _may_store_in_cache()
#
sub _store {
    my $self        = shift;
    my $rqst        = shift;
    my $resp        = shift;
    
    return unless $self->_may_store_in_cache($rqst, $resp);
    
    if ( my $resp_key = $self->_store_response($resp) ) {
        my $rqst_key = Digest::MD5::md5_hex($rqst->uri()->as_string);
        my $rsqt_stripped = $rqst->clone; $rsqt_stripped->content(undef);
        my $resp_stripped = $resp->clone; $resp_stripped->content(undef);
        $self->_insert_meta_dict(
            $rqst_key,
            $resp_key,
            {
                resp_stripped   => $resp_stripped,
                rqst_stripped   => $rsqt_stripped,
            },
        );
        return $resp_key;
    }
    
    return
}

sub _store_response {
    my $self        = shift;
    my $resp        = shift;
    
    my $resp_key = Digest::MD5::md5_hex(Time::HiRes::time());
    
    eval { $self->cache->set( $resp_key => $resp ) };
    return $resp_key unless $@;
    
    croak __PACKAGE__
        . " could not store response in cache with key [$resp_key], $@";
    
    return
}

sub _insert_meta_dict {
    my $self        = shift;
    my $rqst_key    = shift;
    my $resp_key    = shift;
    my $meta_data   = shift;
    
    my $meta_dict  = $self->cache_meta->get($rqst_key) || {};
    $meta_dict->{$resp_key} = $meta_data;
    $self->cache_meta->set( $rqst_key => $meta_dict );
    
    return $meta_dict;
}

sub _retrieve {
    my $self            = shift;
    my $rqst_presented  = shift;
    
    my $rqst_key = Digest::MD5::md5_hex($rqst_presented->uri()->as_string);
    my $meta_dict = $self->_retrieve_meta_dict($rqst_key);
    
    return unless $meta_dict;
    
    my @meta_keys = keys %$meta_dict;
    
    foreach my $meta_key (@meta_keys) {
        my $reuse_status = $self->_may_reuse_from_cache(
            $rqst_presented,
            $meta_dict->{$meta_key}{resp_stripped},
            $meta_dict->{$meta_key}{rqst_stripped}
        );
        $meta_dict->{$meta_key}{reuse_status} = $reuse_status
    }
    
    my @okay_keys =
        grep { $meta_dict->{$_}{reuse_status} & $REUSE_IS_OK} @meta_keys;
    
    if (scalar @okay_keys) {
        #
        # TODO: do content negotiation if possible
        #
        # TODO: Sort to select lates response
        #
        my ($resp_key) = @okay_keys;
        my $resp = $self->_retrieve_response($resp_key);
        return $resp
    }
    
    my @vldt_keys =
        grep { $meta_dict->{$_}{reuse_status} & $REUSE_REVALIDATE} @meta_keys;
    
    if (scalar @vldt_keys) {
        #
        #                                           RFC 7234 Section 4.3.1
        #
        # Sending a Validation Request
        #
        my ($resp_key) = @vldt_keys;
        my $resp_stripped = $meta_dict->{$resp_key}{resp_stripped};
        
        # Assume we have validation headers, otherwise we'll need a HEAD request
        #
        my $etag = $resp_stripped->header('ETag');
        my $last = $resp_stripped->header('Last-Modified');
        
        my $rqst_forwarded = $rqst_presented->clone;
        $rqst_forwarded->header('If-None-Match' => $etag) if $etag;
        $rqst_forwarded->header('If-Modified-Since' => $last) if $last;
        
        my $resp_forwarded = $self->_forward($rqst_forwarded);
        
        #                                           RFC 7234 Section 4.3.3.
        #
        # Handling a Validation Response
        #
        # Cache handling of a response to a conditional request is dependent
        # upon its status code:
        
        
        # A 304 (Not Modified) response status code indicates that the
        # stored response can be updated and reused; see Section 4.3.4.
        #
        if ($resp_forwarded->code == HTTP_NOT_MODIFIED) {
            my $resp = $self->_retrieve_response($resp_key);
            return $resp
            #
            # TODO: make it all compliant with Section 4.3.4 on how to select
            #       which stored responses need update
            # TODO: ade 'Age' header
        }
        
        
        # A full response (i.e., one with a payload body) indicates that
        # none of the stored responses nominated in the conditional request
        # is suitable.  Instead, the cache MUST use the full response to
        # satisfy the request and MAY replace the stored response(s).
        #
        if ( not HTTP::Status::is_server_error($resp_forwarded->code) ) {
            $self->_store($rqst_presented, $resp_forwarded);
            return $resp_forwarded;
        }
        
        
        # However, if a cache receives a 5xx (Server Error) response while
        # attempting to validate a response, it can either forward this
        # response to the requesting client, or act as if the server failed
        # to respond.  In the latter case, the cache MAY send a previously
        # stored response (see Section 4.2.4).
        #
        if ( HTTP::Status::is_server_error($resp_forwarded->code) ) {
            return $resp_forwarded;
        }
        #
        # TODO: check if we can use a cached stale version
        
        
        return undef;
    }
    
    return undef;
}

sub _retrieve_meta_dict {
    my $self        = shift;
    my $rqst_key    = shift;
    
    my $meta_dict  = $self->cache_meta->get($rqst_key);
    
    return $meta_dict;
}

sub _retrieve_response {
    my $self        = shift;
    my $resp_key    = shift;
    
    if (my $resp = eval { $self->cache->get( $resp_key ) } ) {
        return $resp
    }
    
    carp __PACKAGE__
        . " could not retrieve response from cache with key [$resp_key], $@";
    
    return
}

sub _invalidate {
    my $self            = shift;
    my $rqst_presented  = shift;
    
    my $rqst_key = Digest::MD5::md5_hex($rqst_presented->uri()->as_string);
    my $meta_dict = $self->_retrieve_meta_dict($rqst_key);
    
    return unless $meta_dict;
    
    my @meta_keys = keys %$meta_dict;
    
    foreach my $meta_key (@meta_keys) {
        $self->_invalidate_response($meta_key);
    }
    
    $self->_invalidate_meta_dict($rqst_key);
    
    return;
}

sub _invalidate_meta_dict {
    my $self        = shift;
    my $rqst_key    = shift;
    
    $self->cache_meta->remove($rqst_key);
    
    return
}

sub _invalidate_response {
    my $self        = shift;
    my $resp_key    = shift;
    
    $self->cache->remove($resp_key);
    
    return
}

sub _non_safe {
    my $self        = shift;
    my $rqst        = shift;
    
    my $method = eval { HTTP::Method->new( uc $rqst->method ) };
    return 1 unless $method; #safety can not be guaranteed
    
    return not $method->is_method_safe
}

# _may_store_in_cache()
#
# based on some headers in the request, but mostly on those in the new response
# the cache can hold a copy of it or not.
#
# see RFC 7234 Section 3: Storing Responses in Caches
#
sub _may_store_in_cache {
    my $self = shift;
    my $rqst = shift;
    my $resp = shift;
    
    # $msg->header('cache-control) is supposed to return a list, but only works
    # if it has been generated as a list, not as string with 'comma'
    # $msg->header in scalar context gives a ', ' joined string
    # which we now split and trim whitespace
    my @rqst_directives =
        map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
        split ',', scalar $rqst->header('cache-control') || '';
    my @resp_directives =
        map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
        split ',', scalar $resp->header('cache-control') || '';
    
    
    #                                               RFC 7234 Section 3
    #
    # A cache MUST NOT store a response to any request, unless:
    
    #                                               RFC 7234 Section 3 #1
    #
    # the request method is understood by the cache and defined as being
    # cacheable
    #
    do {
        my $string = $rqst->method;
        my $method = eval { HTTP::Method->new($string) };
        
        unless ($method) {
            carp "NO CACHE: method is not understood: '$string'\n"
                if $DEBUG;
            return 0
        }
        unless ($method->is_method_cachable) { # XXX Fix cacheable
            carp "NO CACHE: method is not cacheable: '$string'\n"
                if $DEBUG;
            return 0
        }
    };
    
    #                                               RFC 7234 Section 3 #2
    #
    # the response status code is understood by the cache
    #
    do {
        my $code = $resp->code; 
        my $message = eval { HTTP::Status::status_message($code) };
        
        unless ($message) {
            carp "NO CACHE: response status code is not understood: '$code'\n"
                if $DEBUG;
            return 0
        }
    };
    
    
    #                                               RFC 7234 Section 3 #3
    #
    # the "no-store" cache directive (see Section 5.2) does not appear
    # in request or response header fields
    #
    do {
        if (any { lc $_ eq 'no-store' } @rqst_directives) {
            carp "NO CACHE: 'no-store' appears in request cache directives\n"
                if $DEBUG;
            return 0
        }
        if (any { lc $_ eq 'no-store' } @resp_directives) {
            carp "NO CACHE: 'no-store' appears in response cache directives\n"
                if $DEBUG;
            return 0
        }
    };
    
    #                                               RFC 7234 Section 3 #4
    #
    # the "private" response directive (see Section 5.2.2.6) does not
    # appear in the response, if the cache is shared
    #
    if ($self->is_shared) {
        if (any { lc $_ eq 'private' } @resp_directives) {
            carp "NO CACHE: 'private' appears in cache directives when shared\n"
                if $DEBUG;
            return 0
        }
    };
    
    #                                               RFC 7234 Section 3 #5
    #
    # the Authorization header field (see Section 4.2 of [RFC7235]) does
    # not appear in the request, if the cache is shared, unless the
    # response explicitly allows it (see Section 3.2)
    #
    if ($self->is_shared) {
        if ($rqst->header('Authorization')) {
            if (any { lc $_ eq 'must-revalidate' } @resp_directives) {
                carp "DO CACHE: 'Authorization' appears: must-revalidate\n"
                    if $DEBUG;
                return 1
            }
            if (any { lc $_ eq 'public' } @resp_directives) {
                carp "DO CACHE: 'Authorization' appears: public\n"
                    if $DEBUG;
                return 1
            }
            if (any { lc $_ =~ m/^s-maxage=\d+$/ } @resp_directives) {
                carp "DO CACHE: 'Authorization' appears: s-maxage\n"
                    if $DEBUG;
                return 1
            }
            carp "NO CACHE: 'Authorization' appears in request when shared\n"
                if $DEBUG;
            return 0
        }
    };
    
    
    #                                               RFC 7234 Section 3 #6
    #
    # the response either:
    #
    # - contains an Expires header field (see Section 5.3)
    #
    do {
        my $expires_at = $resp->header('Expires');
        
        if ($expires_at) {
            carp "OK CACHE: 'Expires' at: $expires_at\n"
                if $DEBUG;
            return 1
        }
    };
    
    # - contains a max-age response directive (see Section 5.2.2.8)
    #
    do {
        if (any { lc $_ =~ m/^max-age=\d+$/ } @resp_directives) {
            carp "DO CACHE: 'max-age' appears in response cache directives\n"
                if $DEBUG;
            return 1
        }
    };
    
    # - contains a s-maxage response directive (see Section 5.2.2.9)
    #   and the cache is shared
    #
    if ($self->is_shared) {
        if (any { lc $_ =~ m/^s-maxage=\d+$/ } @resp_directives) {
            carp "DO CACHE: 's-maxage' appears in response cache directives\n"
                if $DEBUG;
            return 1
        }
    };
    
    
    # - contains a Cache Control Extension (see Section 5.2.3) that
    #   allows it to be cache
    #
    # TODO  it looks like this is only used for special defined cache-control
    #       directives. As such, those need special treatment.
    #       It does not seem a good idea to hardcode those here, a config would
    #       be a better solution.
    
    
    # - has a status code that is defined as cacheable by default (see
    #   Section 4.2.2)
    #
    do {
        my $code = $resp->code; 
        
        if (HTTP::Status::is_cacheable_by_default($code)) {
            carp "DO CACHE: status code is cacheable by default: '$code'\n"
                if $DEBUG;
            return 1
        }
    };
    
    # - contains a public response directive (see Section 5.2.2.5)
    #
    do {
        if (any { lc $_ eq 'public' } @resp_directives) {
            carp "DO CACHE: 'public' appears in response cache directives\n"
                if $DEBUG;
            return 1
        }
    };
    
    # Falls trough ... SHOULD NOT store in cache
    #
    carp "NO CACHE: Does not match the six criteria above\n"
        if $DEBUG;
    
    return undef;
}


# _may_reuse_from_cache
#
# my $status = _may_reuse_from_cache (
#     $presented_request,
#     $stored_response,
#     $associated_request,
# )
#
# will return false if the stored response can not be used for this request at
# all. In all other cases, it either
#   - can be used, because it matches all the criteria and os fresh
#   - is stale and can be used if needed
#   - needs revalidation
#
# see RFC 7234 Section 4: Constructing Responses from Caches
#
sub _may_reuse_from_cache {
    my $self            = shift;
    my $rqst_presented  = shift;
    my $resp_stored     = shift;
    my $rqst_associated = shift;
    
    #                                               RFC 7234 Section 4
    #
    # When presented with a request, a cache MUST NOT reuse a stored
    # response, unless:
    
    
    #                                               RFC 7234 Section 4 #1
    #
    # The presented effective request URI (Section 5.5 of [RFC7230]) and
    # that of the stored response match
    #
    do {
        unless ( URI::eq($rqst_presented->uri, $rqst_associated->uri) ) {
            carp "NO REUSE: URI's do not match\n"
                if $DEBUG;
            return $REUSE_NO_MATCH
        }
    };
    
    
    #                                               RFC 7234 Section 4 #2
    #
    # the request method associated with the stored response allows it
    # to be used for the presented request
    #
    do {
        unless ( $rqst_presented->method eq $rqst_associated->method ) {
            carp "NO REUSE: Methods do not match\n"
                if $DEBUG;
            return $REUSE_NO_MATCH
        }
    };
    #
    # NOTE: We did not make the test case insensitive, according to RFC 7231.
    #
    # NOTE: We might want to extend it so that we can serve a chopped response
    #       where the presented request is a HEAD request
    
    
    #                                               RFC 7234 Section 4 #3
    #
    # selecting header fields nominated by the stored response (if any)
    # match those presented (see Section 4.1)
    if ( $resp_stored->header('Vary') ) {
        
        if ( scalar $resp_stored->header('Vary') eq '*' ) {
            carp "NO REUSE: 'Vary' equals '*'\n"
                if $DEBUG;
            return $REUSE_NO_MATCH
        }
        
        #create an array with nominated headers
        my @vary_headers =
            map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
            split ',', scalar $resp_stored->header('Vary') || '';
        
        foreach my $header ( @vary_headers ) {
            my $header_presented = $rqst_presented->header($header) || '';
            my $header_associated = $rqst_associated->header($header) || '';
            unless ( $header_presented eq $header_associated ) {
                carp "NO REUSE: Nominated headers in 'Vary' do not match\n"
                    if $DEBUG;
                return $REUSE_NO_MATCH
            }
        }
    };
    #
    # TODO: According to Section 4.1, we could do normalization and reordering
    #       This requires further investigation and is worth doing to increase
    #       the hit chance
    
    
    #                                               RFC 7234 Section 4 #4
    #
    # the presented request does not contain the no-cache pragma
    # (Section 5.4), nor the no-cache cache directive (Section 5.2.1),
    # unless the stored response is successfully validated
    # (Section 4.3)
    #
    do {
        # generate an array with cache-control directives
        my @rqst_directives =
            map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
            split ',', scalar $rqst_presented->header('cache-control') || '';
        
        if (any { lc $_ eq 'no-cache' } @rqst_directives) {
            carp "NO REUSE: 'no-cache' appears in request cache directives\n"
                if $DEBUG;
            return $REUSE_REVALIDATE
        }
        
        if (
            $rqst_presented->header('Pragma')
            and
            scalar $rqst_presented->header('Pragma') =~ /no-cache/
        ) {
            carp "NO REUSE: Pragma: 'no-cache' appears in request\n"
                if $DEBUG;
            return $REUSE_REVALIDATE
        }
    };
    
    
    #                                               RFC 7234 Section 4 #5
    #
    # the stored response does not contain the no-cache cache directive
    # (Section 5.2.2.2), unless it is successfully validated
    # (Section 4.3)
    #
    do {
        # generate an array with cache-control directives
        my @resp_directives =
            map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
            split ',', scalar $resp_stored->header('cache-control') || '';
        
        if (any { lc $_ eq 'no-cache' } @resp_directives) {
            carp "NO REUSE: 'no-cache' appears in response cache directives\n"
                if $DEBUG;
            return $REUSE_REVALIDATE
        }
    };
    
    #                                               RFC 7234 Section 4 #6
    #
    # the stored response is either:
    #
    # - fresh (see Section 4.2), or
    #
    do {
        if ($resp_stored->is_fresh(heuristic_expiry => undef)) {
            carp "DO REUSE: Response is fresh\n"
                if $DEBUG;
            return $REUSE_IS_OK
        }
    };
    #
    # TODO: heuristic_expiry => undef should be a option, not hardcoded
    
    # - allowed to be served stale (see Section 4.2.4), or
    #
    do {
        # generate an array with cache-control directives
        my @resp_directives =
            map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
            split ',', scalar $resp_stored->header('cache-control') || '';
        
        #                                           RFC 7234 Section 5.2.2.1
        #
        # must-revalidate
        #
        if (any { lc $_ eq 'must-revalidate' } @resp_directives) {
            carp "NO REUSE: Stale but 'must-revalidate'\n"
                if $DEBUG;
            return $REUSE_IS_STALE_REVALIDATE
        }
        
        #                                           RFC 7234 Section 5.2.2.7
        #
        # proxy-revalidate
        #
        if (
            any { lc $_ eq 'proxy-revalidate' } @resp_directives
            and
            $self->is_shared
        ) {
            carp "NO REUSE: Stale but 'proxy-revalidate'\n"
                if $DEBUG;
            return $REUSE_IS_STALE_REVALIDATE
        }
        
        
        #                                           RFC 7234 Section 5.2.1.2
        #
        # max-stale = ...
        #
        my @rqst_directives =
            map { my $str = $_; $str =~ s/^\s+//; $str =~ s/\s+$//; $str }
            split ',', scalar $rqst_presented->header('cache-control') || '';
        
        my ($directive) =
            grep { $_ =~ /^max-stale\s*=?\s*\d*$/ } @rqst_directives;
        
        if ($directive) {
            my ($max_stale) = $directive =~ /=(\d+)$/;
            unless (defined $max_stale) {
                carp "DO REUSE: 'max-stale' for unlimited time\n"
                    if $DEBUG;
                return $REUSE_IS_STALE_OK
            }
            my $freshness = # not fresh!!! so, this is a negative number
                $resp_stored->freshness_lifetime(heuristic_expiry => undef);
            if ( abs($freshness) < $max_stale ) {
                carp "DO REUSE: 'max-stale' not exceeded\n"
                    if $DEBUG;
                return $REUSE_IS_STALE_OK
            }
        }
        
    };
    
    # - successfully validated (see Section 4.3).
    #
    do {
        carp "NO REUSE: must successfully validated"
            if $DEBUG;
        return $REUSE_IS_STALE_REVALIDATE
    };
    
}

1;

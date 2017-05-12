package Hypothesis::API;

use 5.006;
use strict;
use warnings;

use namespace::autoclean;
use Moose;
use Storable qw( dclone );
use Try::Tiny;

use CGI::Cookie;
use HTTP::Cookies;
use HTTP::Request;
use JSON;
use LWP::UserAgent;
use URI;
use URI::Encode;

# For better performance, also install:
# JSON::XS

# DEBUG
# use Data::Dumper;
#
# 0 = None, 5 = Max:
my $VERB = 0; 

=pod

=head1 NAME

Hypothesis::API - Wrapper for the hypothes.is web (HTTP) API.

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

A Perl wrapper and utility functions for the hypothes.is web (HTTP) API.

Create a hypothes.is object.

    use Hypothesis::API;

    my $H = Hypothesis::API->new();

    # or if user-specific actions without login are needed (no known uses yet):
    my $H = Hypothesis::API->new($username);

    # or if login is needed (usually for annotator-store alterations)
    my $H = Hypothesis::API->new($username, $password);


Login-required functionality:

    $H->login; 

    my $payload = {
        "uri"  => 'http://my.favorite.edu/doc.html',
        "text" => "testing create in hypothes.is API"
    };
    my $id = $H->create($payload);
    $H->delete_id($id);

Search functionality (no login needed):

    my $annotation = $H->read_id($id);
    die if ($annotation->{'id'} ne $id);

    my $page_size = 20;
    my $iter = $H->search({limit => 100}, $page_size);
    my @annotations;
    while ( my $item = $iter->() ) {
        push @annotations, $item;
    }

    my $total = $H->search_total({limit => 100}, $page_size);
    print "Reported $total total items.\n";

=head1 EXPORT

Currently nothing.

=cut

my $json = JSON->new->allow_nonref;
$json->pretty(1);
$json->canonical(1); 


#
# TODO: add getter/setter?
#
my $page_size_default = 20;

has 'api_url' => (
    is        => 'ro',
    default   => 'https://hypothes.is/api',
    predicate => 'has_api_url',
);

has 'app_url' => (
    is        => 'ro',
    default   => 'https://hypothes.is/app',
    predicate => 'has_app_url',
);

has 'username' => (
    is         => 'ro',
    predicate  => 'has_username',
);

has 'password' => (
    is         => 'ro',
    predicate  => 'has_password',
);

has 'token' => (
    is         => 'ro',
    predicate  => 'has_token',
    writer     => '_set_token',
    init_arg => undef,
);

has 'csrf_token' => (
    is           => 'ro',
    predicate    => 'has_csrf_token',
    writer       => '_set_csrf_token',
    init_arg => undef,
);

has 'ua' => (
    is        => 'ro',
    default   =>  sub { LWP::UserAgent->new; },
    predicate => 'has_ua',
);

has 'uri_encoder' => (
    is        => 'ro',
    default   =>  sub {  
        URI::Encode->new( { 
            encode_reserved => 0, 
            double_encode => 0, 
        } );
    },
    predicate => 'has_uri_encoder',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ >= 2 ) {
        if ( @_ > 2) {
            warn "At most two arguments expected in constructor.\n";
        }
        return $class->$orig( username => $_[0], password => $_[1] );
    } elsif ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( username => $_[0], password => undef );
    } else {
        return $class->$orig( username => undef, password => undef );
    }
};

=head1 SUBROUTINES/METHODS

=head2 create(\%payload)

Generalized interface to POST /api/annotations

In the simplest form, creates an annotation
$payload->{'text'} at $payload->{'uri'}.
For more sophisticated usage please see the
hypothes.is API documentation.

Returns annotation id if created or HTTP status 
code otherwise.

=cut

sub create {
    my ($self, $payload) = @_;

    if (ref($payload) ne "HASH") {
        warn 'Payload is not a hashref.\n';
        return -1;
    }
    if (not exists $payload->{'uri'}) {
        warn "Payload does not contain a 'uri' key to be annotated.\n";
        return -1;
    }
    my $payload_out = dclone $payload;
    my $user = $self->username;
    my $user_acct = "acct:$user\@hypothes.is";
    $payload_out->{'user'} = $user_acct;
    if (not exists $payload->{'permissions'}) {
        $payload_out->{'permissions'} = { 
            "read"   => ["group:__world__"],
            "update" => [$user_acct],
            "delete" => [$user_acct],
            "admin"  => [$user_acct]
        };
    }
    if (not exists $payload->{'document'}) {
        $payload_out->{'document'} = {};
    }
    if (not exists $payload->{'text'}) {
        $payload_out->{'text'} = undef;
    }
    if (not exists $payload->{'tags'}) {
        $payload_out->{'tags'} = undef;
    }
    if (not exists $payload->{'target'}) {
        $payload_out->{'target'} = undef;
    }
    
    my $data = $json->encode($payload_out);
    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
        'X-Annotator-Auth-Token' => $self->token, 
    );
    $self->ua->default_headers( $h );
    my $url = URI->new( "${\$self->api_url}/annotations" );
    my $response = $self->ua->post( $url, Content => $data );
    if ($response->code == 200) {
        my $json_content = try_json_decode($response);
        if (not $json_content) {
            die "Was unable to decode JSON content for id from 'create' call.";
        }
        if (exists $json_content->{'id'}) {
            return $json_content->{'id'};
        } else {
            return -1;
        }
    } else {
        return $response->code;
    }
}


=head2 delete_id($id)

Interface to DELETE /api/annotations/<id>

Given an annotation id, returns a boolean value indicating whether or
not the annotation for that id has been successfully delete (1 = yes,
0 = no).

=cut

sub delete_id {
    my ($self, $id) = @_;
    if (not defined $id) {
        warn "No id given to delete.\n";
        return 0;
    }
    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
        'X-Annotator-Auth-Token' => $self->token, 
    );
    $self->ua->default_headers( $h );
    my $url = URI->new( "${\$self->api_url}/annotations/$id" );
    my $response = $self->ua->delete( $url );
    my $json_content = 0;
    if ($response->code != 500) {
        $json_content = try_json_decode($response);
        if (not $json_content) {
            die "Was unable to decode JSON content for delete_id, id: $id";
        }
    } else {
        die "Received status code ${\$response->code} from Hypothes.is in delete_id.";
    }
    my $content_type = ref($json_content);
    if ($content_type eq "HASH") {
        if (defined $json_content->{'deleted'}) {
            if ($json_content->{'deleted'}) {
                return 1;
            } elsif (not $json_content->{'deleted'}) {
                return 0;
            } else { # Never reached in current implementation
                warn "unexpected deletion status: ${\$json_content->{'deleted'}}";
                return 0;
            }
        } else {
            warn "Received unexpected object: no 'deleted' entry present.";
            return 0;
        }
    } else {
        die "Got $content_type; expected an ARRAY or HASH.";
    }
}


=head2 login

Proceeds to login; on success retrieves and stores 
CSRF and bearer tokens.

=cut

sub login {
    my ($self) = @_;

    # Grab cookie_jar for csrf_token, etc.
    my $request  = HTTP::Request->new(GET => $self->app_url);  
    my $cookie_jar  = HTTP::Cookies->new();
    $self->ua->cookie_jar($cookie_jar);
    my $response = $self->ua->request($request);
    $cookie_jar->extract_cookies( $response );
    my %cookies = CGI::Cookie->parse($cookie_jar->as_string);
    if (exists $cookies{'Set-Cookie3: XSRF-TOKEN'}) {
        $self->_set_csrf_token($cookies{'Set-Cookie3: XSRF-TOKEN'}->value); 
    } else {
        warn "Login failed: couldn't obtain CSRF token.";
        return -1;
    }

    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
    );
    $self->ua->default_headers( $h );
    my $payload = {
        username => $self->username,
        password => $self->password
    };
    my $data = $json->encode($payload);
    $response = $self->ua->post(
        $self->app_url . '?__formid__=login', 
        Content => $data
    );
    my $url = URI->new( "${\$self->api_url}/token" );
    $url->query_form(assertion => $self->csrf_token);
    $response = $self->ua->get( $url );
    $self->_set_token($response->content);

    return 0;
}


=head2 read_id($id)

Interface to GET /api/annotations/<id>

Returns the annotation for a given annotation id if id is defined or
nonempty. Otherwise (in an effort to remain well-typed) returns the
first annotation on the list returned from hypothes.is. At the time of
this writing, this functionality of empty 'search' and 'read' requests
are identical in the HTTP API, but in this Perl API, 'read'
returns a scalar value and 'search' returns an array.

=cut

sub read_id {
    my ($self, $id) = @_;
    if (not defined $id) {
        $id = q();
    }
    my $url = URI->new( "${\$self->api_url}/annotations/$id" );
    my $response = $self->ua->get( $url );
    my $json_content = 0;
    if ($response->code != 500) {
        $json_content = try_json_decode($response);
        if (not $json_content) {
            die "Was unable to decode JSON content for read_id, id: $id"
        }
    } else {
        die "Received status code ${\$response->code} from Hypothes.is in read_id.";
    }
    my $content_type = ref($json_content);
    if ($content_type eq "HASH") {
        if (defined $json_content->{'id'}) {
            return $json_content;
        } elsif (defined $json_content->{'rows'}) {
            return $json_content->{'rows'}->[0];
        } else {
            die "Don't know how to find the annotation.";
        }
    } else {
        die "Got $content_type; expected a HASH.";
    }
}



=head2 search(\%query, $page_size)

Generalized interface to GET /api/search

Generalized query function.

query is a hash ref with the following optional keys 
as defined in the hypothes.is HTTP API:
 * limit
 * offset
 * uri
 * uri.parts
 * text
 * quote
 * user

page_size is an additional parameter related to $query->limit
and $query->offset, which specifies the number of annotations
to fetch at a time, but does not override the spirit of either
of the $query parameters.

Tries not to return annotations created after initiation
of the search.

Note that while this function has been made robust to addition of
new annotations being created during a query, it is not yet
robust to deletion of annotations.

=cut

# FIXME: improve handling of deletions

sub search {
    my ($self, $query, $page_size) = @_;

    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
    );
    if (not defined $query) {
        $query = {};
    }
    if ( defined $query->{ 'uri' } ) {
        $query->{ 'uri' } = $self->uri_encoder->encode(
           $query->{ 'uri' }
        );
    }
    if (not defined $page_size) {
        #Default at the time, but need to make explicit here:
        $page_size = $page_size_default;
    }
    if ( not defined $query->{ 'limit' } ) {
        #Default at the time, but need to make explicit here:
        $query->{ 'limit' } = $page_size;
    }

    my $done = 0;
    my $last_id = undef;
    my $num_returned = 0;
    my $limit_orig = $query->{ 'limit' };
    $query->{ 'limit' } = $page_size + 1;

    my @annotation_buff = ();
    return sub {
        $done = 1 if (defined $limit_orig and $num_returned >= $limit_orig);
        QUERY: if (@annotation_buff == 0 && not $done) {
            warn "fetching annotations from server.\n" if $VERB > 0;
            #Need to refill response buffer
            my $url = URI->new( "${\$self->api_url}/search" );
            $url->query_form($query);
            warn $url, "\n" if $VERB > 1;
            my $response = $self->ua->get( $url );
            my $json_content = 0;
            if ($response->code != 500) {
                $json_content = try_json_decode($response);
                if (not $json_content) {
                    die "Was unable to decode JSON content in search.";
                }
            } else {
                die "Received status code ${\$response->code} from Hypothes.is in search.";
            }
            @annotation_buff = @{$json_content->{ 'rows' }};
            if (defined $limit_orig and $limit_orig eq 'Infinity') {
                # OK, we get the point, but let's get finite.
                $limit_orig = $json_content->{ 'total' };
                $query->{ 'limit' } = $json_content->{ 'total' };
            }
            if (not defined $limit_orig or $json_content->{ 'total' } < $limit_orig) {
                # No limit set or more than total. Set it to the total
                # so we don't have to try an extra request past the 
                # total number of results
                $limit_orig = $json_content->{ 'total' };
                warn "setting limit_orig=$limit_orig based on total\n" if $VERB > 1;
            }
            if (defined $last_id) {
                # This assumes that the feed is like a stack: LIFO.
                # Annotations created after the search call
                # shouldn't be returned.
                # 
                # This is not the first query because $last_id is set and the
                # offset arranges so that, without the addition of new 
                # annotations, the first result from the new query will be
                # the same as the last result of the old query. If it isn't
                # then we assume that new items have been added to the beginning
                # and scan forward to find the id. The may be more than one
                # page of scanning.
                while (@annotation_buff and $last_id ne $annotation_buff[0]->{'id'}) {
                    warn "mismatch: scanning for last seen id\n" if $VERB > 0;
                    shift @annotation_buff;
                    if (@annotation_buff == 0) {
                        $query->{ 'offset' } += $page_size;
                        goto QUERY;
                    }
                }
                if (@annotation_buff) {
                    shift @annotation_buff;
                }
            }
            $query->{ 'offset' } += $page_size;
            warn $response->content if $VERB > 5;
        }
        return undef if ($done or @annotation_buff == 0);
        my $anno = shift @annotation_buff;
        $last_id = $anno->{'id'};
        $num_returned++;
        return $anno;
    }

}

=head2 search_total(\%query, $page_size)

Specific interface to GET /api/search that simply 
returns the total number of query results. See 
the search subroutine for more details on parameters.

=cut

sub search_total {

    # Note: try to keep the logic here the same as in the search
    # function, or possibly remove code duplication.
    #
    # Start of code duplication:
    #
    my ($self, $query, $page_size) = @_;

    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
    );
    if (not defined $query) {
        $query = {};
    }
    if ( defined $query->{ 'uri' } ) {
        $query->{ 'uri' } = $self->uri_encoder->encode(
           $query->{ 'uri' }
        );
    }
    if (not defined $page_size) {
        #Default at the time, but need to make explicit here:
        $page_size = 20;
    }
    if ( not defined $query->{ 'limit' } ) {
        #Default at the time, but need to make explicit here:
        $query->{ 'limit' } = $page_size;
    }

    my $done = 0;
    my $last_id = undef;
    my $num_returned = 0;
    my $limit_orig = $query->{ 'limit' };
    $query->{ 'limit' } = $page_size + 1;
    #
    # End of code duplication:
    #

    my $url = URI->new( "${\$self->api_url}/search" );
    $url->query_form($query);
    warn $url, "\n" if $VERB > 1;
    my $response = $self->ua->get( $url );
    my $json_content = 0;
    if ($response->code != 500) {
        $json_content = try_json_decode($response);
        if (not $json_content) {
            die "Was unable to decode JSON content in search_total.";
        }
    } else {
        die "Received status code ${\$response->code} from Hypothes.is in search_total.";
    }
    return $json_content->{ 'total' };
}


=head2 update_id($id, \%payload)

Interface to PUT /api/annotations/<id>

Updates the annotation for a given annotation id if id is defined and
the user is authenticated and has update permissions. Takes a payload
as described for 'search'. Only fields specified in the new payload
are altered; other existing fields should remain unchanged.

Returns a boolean value indicating whether or not the annotation for
that id has been successfully updated (1 = yes, 0 = no).

=cut

sub update_id {
    my ($self, $id, $payload) = @_;
    if (not defined $id) {
        die "Can only call update if given an id.";
    }
    my $data = $json->encode($payload);
    my $h = HTTP::Headers->new;
    $h->header(
        'content-type' => 'application/json;charset=UTF-8', 
        'x-csrf-token' => $self->csrf_token,
        'X-Annotator-Auth-Token' => $self->token, 
    );
    $self->ua->default_headers( $h );
    my $url = URI->new( "${\$self->api_url}/annotations/$id" );
    my $response = $self->ua->put( $url, Content => $data );
    my $json_content = 0;
    if ($response->code != 500) {
        $json_content = try_json_decode($response);
        if (not $json_content) {
            die "Was unable to decode JSON content for update_id, id: $id";
        }
    } else {
        die "Received status code ${\$response->code} from Hypothes.is in update_id.";
    }
    my $content_type = ref($json_content);
    if ($content_type eq "HASH") {
        if (defined $json_content->{'updated'}) {
            if ($json_content->{'updated'}) {
                return 1;
            } elsif (not $json_content->{'updated'}) {
                return 0;
            } else { # Never reached in current implementation
                warn "unexpected update status: ${\$json_content->{'updated'}}";
                return 0;
            }
        } else {
            die "Received unexpected object: no 'updated' entry present.";
        }
    } else {
        die "Got $content_type; expected an ARRAY or HASH.";
    }
}


=head1 EXTERNAL ACCESSORS

=head2 get_ua_timeout($timeout)

Gets the timeout (in seconds) of the internal LWP::UserAgent object used to
make requests to the Hypothes.is service.

=cut

sub get_ua_timeout {
    my ($self) = @_;
    return $self->ua->timeout;
}

=head2 set_ua_timeout($timeout)

Under certain circumstances, particularly for testing, it is helpful to set
the timeout (in seconds) used by LWP::UserAgent to make requests to the
Hypothes.is service.

=cut

sub set_ua_timeout {
    my ($self, $timeout) = @_;
    $self->ua->timeout( $timeout );
    return;
}


sub try_json_decode {
    my ($response) = @_;
    my $json_content = 0;
    try{
        $json_content = $json->decode($response->content);
    } catch {
        warn "Trouble decoding JSON: $_\n";
        warn $response->content;
    };
    return $json_content;
}



=head1 AUTHOR

Brandon E. Barker, C<< <brandon.barker at cornell.edu> >>

Created  06/2015

Licensed under the Apache License, Version 2.0 (the "Apache License");
also licensed under the Artistic License 2.0 (the "Artistic License").
you may not use this file except in compliance with one of
these two licenses. You may obtain a copy of the Apache License at

    http://www.apache.org/licenses/LICENSE-2.0

Alternatively a copy of the Apache License should be available in the
LICENSE-2.0.txt file found in this source code repository.

You may obtain a copy of the Artistic License at

    http://www.perlfoundation.org/artistic_license_2_0

Alternatively a copy of the Artistic License should be available in the
artistic-2_0.txt file found in this source code repository.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the Apache License or Artistic License for the specific language 
governing permissions and limitations under the licenses.

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/bbarker/Hypothesis-API/issues>.
Alternatively, you may send them to C<bug-hypothesis-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hypothesis-API>, but this
is not preferred.  In either case, I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 REPOSITORY

L<https://github.com/bbarker/Hypothesis-API>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hypothesis::API

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hypothesis-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hypothesis-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hypothesis-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Hypothesis-API/>

=back


=head1 ACKNOWLEDGEMENTS

We are thankful for support from the Alfred P. Sloan Foundation.

=cut

1; # End of Hypothesis::API

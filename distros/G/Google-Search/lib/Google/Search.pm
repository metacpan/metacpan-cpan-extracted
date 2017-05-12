package Google::Search;
{
  $Google::Search::VERSION = '0.028';
}
# ABSTRACT: Interface to the Google AJAX Search API and suggestion API (DEPRECATED)

use warnings;
use strict;


use Any::Moose;
use Google::Search::Carp;

use Google::Search::Response;
use Google::Search::Page;
use Google::Search::Result;
use Google::Search::Error;
use LWP::UserAgent;
require HTTP::Request::Common;
use JSON;

my $json = JSON->new;

BEGIN {
    use vars qw/ $Base %Service2URI /;
    $Base = 'http://ajax.googleapis.com/ajax/services/search';
    %Service2URI = (
        videos => "$Base/video",
        blog => "$Base/blogs",
        book => "$Base/books",
        image => "$Base/images",
        patents => "$Base/patent",
        map { $_ => "$Base/$_" } qw/ web local video blogs news books images patent /,
    );
}


sub _inflate_query (@) {
    my @query;
    for (@_) {
        if      ( ref eq 'HASH' )   { push @query, %$_ }
        elsif   ( ref eq 'ARRAY' )  { push @query, @$_ }
        elsif   ( ! ref )           { push @query, q => $_ } 
        else                        { croak "Invalid query ($_)" }
    }
    return \@query;
}

{
    my $agent_;
    sub suggest {
        my $self = shift; # Could be class or object

        my $agent = blessed $self ? $self->agent : ( $agent_ ||= LWP::UserAgent->new );
        my ( $term, $query, $uri ) = ( undef, [], {} );

        for( @_ ) {
            next unless defined $_;
            if      ( ! ref )          { $term = $_ }
            elsif   ( ref eq 'ARRAY' ) { $query = $_ }
            elsif   ( ref eq 'HASH' )  { $uri = $_ }
            else                       { croak "Invalid parameter ($_)" }
        }

        croak "Missing term" unless defined $term;
        my @query = @$query;
        croak "Uneven query ($#query): ", @query if @query % 2;

        my %query = @query;
        unshift @query, q => $term unless exists $query{q};

        my @uri = ( map { $_ => $uri->{$_} } grep { exists $uri->{$_} }
            qw/ host port host_port scheme path userinfo authority agent / );
        unshift @uri, qw{ scheme http host clients1.google.com path complete/search };
        my %uri = @uri;
        my $user_agent = delete $uri{agent};

        $uri = URI->new;
        while ( my ($k, $v) = each %uri ) { $uri->$k( $v ) }
        $uri->query_form( @query );

        my @header;
        @header = ( 'User-Agent' => $user_agent ) if defined $user_agent;

        my $response = $agent->get( $uri, @header );
        croak "Failed response: ", $response->status_line unless $response->is_success;
        my $content = $response->decoded_content;
        croak "Malformed content: $content" unless $content =~ s/^.*?\(\[(.*)\]\)$/[$1]/g;
        my $data = $json->decode( $content );
        croak "Malformed content: $content" unless ref $data eq 'ARRAY' && $data->[1];
        return $data->[1];
    }
}

sub service2uri {
    my $class = shift;
    my $service = shift;
    croak "Missing service" unless $service;
    $service = lc $service;
    return unless my $uri = $Service2URI{$service};
    return $uri;
}

sub BUILDARGS {
    my $class = shift;
    
    my $given;
    if ( 1 == @_ && ref $_[0] eq 'HASH' ) {
        $given = $_[0];
    }
    elsif ( 3 == @_ && $_[0] eq 'service' && ! ref $_[2] && defined $_[2] ) {
        my $query = pop;
        $given = { @_, query => $query };
    }
    elsif ( 0 == @_ % 2 ) {
        $given = { @_ };
    }
    elsif ( @_ > 3 && $_[0] eq 'service' ) {
        my @given = splice @_, 0, 2;
        push @given, query => shift @_;
        $given = { @given, @_ };
    }
    else {
        croak "Odd number of arguments: @_";
    }

    my $query = delete $given->{q};
    $given->{query} = $query if defined $query && ! defined $given->{query};

    my $version = delete $given->{v};
    $given->{version} = $version if defined $version && ! defined $given->{version};

    my $referrer = delete $given->{referrer};
    $given->{referer} = $referrer if defined $referrer && ! defined $given->{referer};

    $query = $given->{query};
    my @query;

    while( my( $key, $value ) = each %$given ) {
        next if $key =~ m/^(?:agent|service|uri|query|version|hl|referer|
            key|start|rsz|rsz2number|current|error)$/x;
        carp "Including unknown parameter \"$key\" with query";
        push @query, $key => $value;
    }

    $given->{query} = _inflate_query \@query, $query if @query;
    return $given;
}

for my $service ( keys %Service2URI ) {
    no strict 'refs';
    my $umethod = ucfirst $service;
    my $lmethod = lc $service;
    *$umethod = *$lmethod = sub {
        my $class = shift;
        return $class->new( service => $service, @_ );
    };
}

has agent => qw/ is ro lazy_build 1 isa LWP::UserAgent /;
sub _build_agent {
    my $self = shift;
    my $agent = LWP::UserAgent->new;
    $agent->env_proxy;
    return $agent;
}

has service => qw/ is ro lazy_build 1 /;
sub _build_service { 'web' }

has uri => qw/ is ro lazy_build 1 isa URI /;
sub _build_uri {
    my $self = shift;
    my $service = $self->service;
    my $uri = $self->service2uri( $service );
    croak "Invalid service ($service)" unless $uri;
    return URI->new( $uri );
}

has query => qw/ is ro required 1 /;
sub q { return shift->query( @_ ) }

has version => qw/ is ro lazy_build 1 isa Str /;
sub _build_version { '1.0' }
sub v { return shift->version( @_ ) }

has hl => qw/ is rw predicate has_hl /;

has referer => qw/ is ro isa Str /;
sub referrer { return shift->referer( @_ ) }

has key => qw/ is ro isa Str /;

has start => qw/ is ro lazy_build 1 isa Int /;
sub _build_start { 0 }

has rsz => qw/ is ro lazy_build 1 isa Str /;
sub _build_rsz { 'large' }
has rsz2number => qw/ is ro lazy_build 1 isa Int /;
sub _build_rsz2number {
    my $self = shift;
    my $rsz = $self->rsz;
    return 4 if $rsz eq "small";
    return 8 if $rsz eq "large";
    croak "Don't understand rsz ($rsz)";
}

has _page => qw/ is ro required 1 /, default => sub { [] };
has _result => qw/ is ro required 1 /, default => sub { [] };
has current => qw/ is ro lazy_build 1 /;
sub _build_current {
    return shift->first;
}
has error => qw/ is rw /;

sub request {
    my $self = shift;
    my $http_request = $self->build( @_ );
    return unless my $http_response = $self->agent->request( $http_request );
    return Google::Search::Response->new( http_response => $http_response );
}

sub build {
    my $self = shift;

    my ( @query_form, @header_supplement );

    {
        my $referer = $self->referer;
        my $key = $self->key;

        push @header_supplement, Referer => $referer if $referer;
        push @query_form, key => $key if $key;
    }

    my $query = $self->query;
    # TODO Check for query instead of q?
    push @query_form, @{ _inflate_query $query };
    push @query_form, hl => $self->hl if $self->has_hl;

    my $uri = $self->uri->clone;
    $uri->query_form({ v => $self->version, rsz => $self->rsz, @query_form, @_ });

    if ( $ENV{GS_TRACE} ) {
        warn $uri->as_string, "\n";
    }

    my $request = HTTP::Request::Common::GET( $uri => @header_supplement );

    if ( $ENV{GS_TRACE} && $request ) {
        warn $request->as_string, "\n";
    }

    return $request;
}

sub page {
    my $self = shift;
    my $number = shift;

    $self->error( undef );

    my $page = $self->_page->[$number] ||=
            Google::Search::Page->new( search => $self, number => $number );

    $self->error( $page->error ) if $page->error;

    return $page;
}


sub first {
    my $self = shift;
    return $self->result( $self->start );
}


sub next {
    my $self = shift;
    return $self->current unless $self->{current};
    return $self->{current} = $self->current->next;
}


sub result {
    my $self = shift;
    my $number = shift;

    $self->error( undef );

    return $self->_result->[$number] if $self->_result->[$number];
    my $result = do {
        my $result_number = $number % $self->rsz2number;
        my $page_number = int( $number / $self->rsz2number );
        my $page = $self->page( $page_number );
        my $content = $page->result( $result_number );
        if ( $content ) {
            Google::Search::Result->parse( $content,
                page => $page, search => $self, number => $number);
        }
        else {
            undef;
        }
    };
    return undef unless $result;
    return $self->_result->[$number] = $result;
}


sub all {
    my $self = shift;

    my $result = $self->first;
    1 while $result && ( $result = $result->next ); # Fetch everything
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }

    my @results = @{ $self->_result };
    return wantarray ? @results : \@results;
}


sub match {
    my $self = shift;
    my $matcher = shift;

    my @matched;
    my $result = $self->first;
    while ($result) {
        push @matched, $result if $matcher->($result);
        $result = $result->next;
    }
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }
    return @matched;
}


sub first_match {
    my $self = shift;
    my $matcher = shift;

    my $result = $self->first;
    while ($result) {
        return $result if $matcher->($result);
        $result = $result->next;
    }
    if ($self->error) {
        die $self->error->reason unless $self->error->message eq "out of range start";
    }
    return undef;
}

$_->meta->make_immutable for qw/
    Google::Search
    Google::Search::Response
    Google::Search::Page
    Google::Search::Result
    Google::Search::Error
/;


1;

__END__
=pod

=head1 NAME

Google::Search - Interface to the Google AJAX Search API and suggestion API (DEPRECATED)

=head1 VERSION

version 0.028

=head1 SYNOPSIS

NOTE: The Google AJAX Search API has been deprecated: L<http://developers.google.com/web-search/docs/>

    my $search = Google::Search->Web( query => "rock" );
    while ( my $result = $search->next ) {
        print $result->rank, " ", $result->uri, "\n";
    }

You can also use the single-argument-style invocation:

    Google::Search->Web( "query" )

The following kinds of searches are supported

    Google::Search->Local( ... )
    Google::Search->Video( ... )
    Google::Search->Blog( ... )
    Google::Search->News( ... )
    Google::Search->Image( ... )
    Google::Search->Patent( ... )

You can also take advantage of each service's specialized interface

    # The search below specifies the latitude and longitude:
    $search = Google::Search->Local( query => { q => "rock", sll => "33.823230,-116.512110" }, ... );

    my $result = $search->first;
    print $result->streetAddress, "\n";

You can supply an API key and referrer (referer) if you have them

    my $key = ... # This should be a valid API key, gotten from:
                  # http://code.google.com/apis/ajaxsearch/signup.html

    my $referrer = "http://example.com/" # This should be a valid referer for the above key

    $search = Google::Search->Web(
        key => $key, referrer => $referrer, # "referer =>" Would work too
        query => { q => "rock", sll => "33.823230,-116.512110" }
    );

Get suggestions from the unofficial Google suggestion API using C<suggest>

    my $suggestions = Google::Search->suggest( $term )

=head1 DESCRIPTION

NOTE: The Google AJAX Search API has been deprecated: L<http://developers.google.com/web-search/docs/>

Google::Search is an interface to the Google AJAX Search API (L<http://code.google.com/apis/ajaxsearch/>). 

Currently, their API looks like it will fetch you the top 64 results for your search query.

You may want to sign up for an API key, but it is not required. You can do so here: L<http://code.google.com/apis/ajaxsearch/signup.html>

=head1 Shortcut usage for a specific service

=head2 Google::Search->Web

=head2 Google::Search->Local

=head2 Google::Search->Video

=head2 Google::Search->Blog

=head2 Google::Search->News

=head2 Google::Search->Book

=head2 Google::Search->Image

=head2 Google::Search->Patent

=head1 USAGE

=head2 Google::Search->new( ... ) 

Prepare a new search object (handle)

You can configure the search by passing the following to C<new>:

    query           The search phrase to submit to Google
                    Optionally, this can also be a hash of parameters to submit. You can
                    use the hash form to take advantage of each service's varying interface.
                    Make sure to at least include a "q" parameter with your search

    service         The service to search under. This can be any of: web,
                    local, video, blog, news, book, image, patent

    start           Optional. Start searching from "start" rank instead of 0.
                    Google::Search will skip fetching unnecessary results

    key             Optional. Your Google AJAX Search API key (see Description)

    referrer        Optional. A referrer that is valid for the above key
                    For legacy purposes, "referer" is an acceptable spelling

Both C<query> and C<service> are required

=head2 $search->first 

Returns a L<Google::Search::Result> representing the first result in the search, if any.

Returns undef if nothing was found

=head2 $search->next 

An iterator for $search. Will the return the next result each time it is called, and undef when
there are no more results.

Returns a L<Google::Search::Result>

Returns undef if nothing was found

=head2 $search->result( <rank> )

Returns a L<Google::Search::Result> corresponding to the result at <rank>

These are equivalent:

    $search->result( 0 )

    $search->first

=head2 $search->all

Returns L<Google::Search::Result> list which includes every result Google has returned for the query

In scalar context an array reference is returned, a list otherwise

An empty list is returned if nothing was found

=head2 $search->match( <code> )

Returns a L<Google::Search::Result> list

This method will iterate through each result in the search, passing the result to <code> as the first argument.
If <code> returns true, then the result will be included in the returned list

In scalar context this method returns the number of matches

=head2 $search->first_match( <code> )

Returns a L<Google::Search::Result> that is the first to match <code>

This method will iterate through each result in the search, passing the result to <code> as the first argument.
If <code> returns true, then the result will be returned and iteration will stop.

=head2 $search->error

Returns a L<Google::Search::Error> if there was an error with the last search

If you receive undef from a result access then you can use this routine to see if there was a problem

    warn $search->error->reason;

    warn $search->error->http_response->as_string;

    # Etc, etc.

This will return undef if no error was encountered

=head2 Google::Search->suggest( $term, ... )

Return a nested array from the Google auto-complete suggestion service. Each
inner array consists of: the suggestion, the number of results, and the rank of the suggestion:

    my $suggestions = Google::Search->suggest( 'monkey' )
    print $suggestions->[0][0] # "monkey bread recipe"
    print $suggestions->[0][1] # "413,000 results"
    print $suggestions->[0][2] # 0

    for my $suggestion ( @$suggestions ) {
        ...
    }

To override the language (or any query parameter or to add in your own parameters), pass in an array:

    # Get the results back in German (de)
    Google::Search->suggest( [ hl => 'de' ], 'monkey' )

To alter the URI hostname/path or to give a custom user agent, pass in a hash:

    Google::Search->suggest( [ hl => 'de' ], 'monkey', {
        host => 'clients1.google.de',
        agent => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)'
    } )

The passing order of the array, hash, and string does not matter

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


# $Id: Request.pm,v 1.6 2003/07/14 08:21:08 m_ilya Exp $

package HTTP::WebTest::Request;

=head1 NAME

HTTP::WebTest::Request - HTTP request objects

=head1 SYNOPSIS

    use HTTP::WebTest::Request;
    $request = HTTP::WebTest::Request->new;

    my $uri = $request->uri;

    $request->base_uri($base_uri);
    my $base_uri = $request->base_uri;

    my @params = @{$request->params};
    $request->params([@params]);

=head1 DESCRIPTION

This class is a subclass of L<HTTP::Request|HTTP::Request> class.  It
extends it with continence methods that allow to set or get CGI query
params for HTTP request in uniform way independent of HTTP request
method.

Each URI in GET requests may consist of two portions: URI of
document/resource/etc and CGI query string.  In
L<HTTP::Request|HTTP::Request> method C<uri> doesn't separate them and
operates on them as on single entity. In C<HTTP::WebTest::Request>
method C<uri> is not allowed to modify HTTP request URI.  Instead of
it methods C<base_uri> and C<params> should be used to change or get
these parts independently.

For POST requests method C<base_uri> acts simular to C<uri>.  On the
other hand C<params> set content of HTTP request in case of POST
requests.

CGI request parameters are defined in the way similar to CGI request
parameters defenition in
L<HTTP::Request::Common|HTTP::Request::Common>.  It is an array of
pairs

    ( name1 => value1, name2 => value2, ..., nameN => valueN )

If any value is passed as an array reference it is treated as file
upload.  See L<HTTP::Request::Common|HTTP::Request::Common> for more
details.

By default GET type of HTTP request is assumed.  But if CGI request
parameters have data for file upload then POST type of HTTP request is
assumed.

=head1 CLASS METHODS

=cut

use strict;

use base qw(HTTP::Request);

use HTTP::Request::Common;
use URI;

use HTTP::WebTest::Utils qw(make_access_method);

=head2 base_uri($optional_uri)

Can set non CGI query portion of request URI if C<$optional_uri> is
passed.

=head3 Returns

Non CGI query portion of request URI.

=cut

sub base_uri { shift->SUPER::uri(@_) }

=head2 uri($optional_uri)

Method C<uri> is redefined. It is same as C<base_uri> for non-GET
request. For GET requests it returns URI with query parameters.

=head3 Returns

Whole URI.

=cut

sub uri {
    my $self = shift;

    if(@_) {
	$self->base_uri(@_);
	my $new_uri = $self->base_uri;
        $self->params([]);
    }

    my $uri = $self->base_uri;

    if(@{$self->params} and $self->method and $self->method eq 'GET') {
        $uri->query_form(@{$self->params});
    }

    return $uri;
}

*url = \&uri;

=head2 content_ref

Method C<content_ref> is redefined. For POST requests it returns POST
query content corresponding to query parameters.

=cut

sub content_ref {
    my $self = shift;

    return $self->SUPER::content_ref
	unless defined($self->method) and $self->method eq 'POST';

    my $has_filepart = grep ref($_), @{$self->params};

    my @post;
    if($has_filepart) {
	@post = ($self->uri,
		 Content_Type => 'form-data',
		 Content => $self->params);
    } else {
	@post = ($self->uri, $self->params);
    }

    my $req = POST @post;

    # DANGER: EVIL HACK
    for my $header (qw(Content-Type Content-Length)) {
	if(defined $header) {
	    $self->header($header => $req->header($header));
	} else {
	    $self->remove_header($header);
	}
    }

    return $req->content_ref;
}

=head2 params($optional_params)

Can set CGI request parameters for this HTTP request object if an
array reference C<$optional_params> is passed.

=head3 Returns

An reference to an array that contains CGI request parameters.

=cut

*params = make_access_method('PARAMS', sub { [] });

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::Request|HTTP::Request>

L<HTTP::Request::Common|HTTP::Request::Common>

=cut

1;

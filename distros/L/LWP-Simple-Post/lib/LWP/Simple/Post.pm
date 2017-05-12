package LWP::Simple::Post;
BEGIN {
  $LWP::Simple::Post::VERSION = '0.05';
}

use strict;
use warnings;

use parent "Exporter";
our @EXPORT_OK = qw( post post_xml );

use LWP::UserAgent;
use HTTP::Request;

=head1 NAME

LWP::Simple::Post - Single-method POST requests

=head1 VERSION

version 0.05

=head1 DESCRIPTION

Really simple wrapper to HTTP POST requests

=head1 SYNOPSIS

 use LWP::Simple::Post qw(post post_xml);

 my $response = post('http://production/receiver', 'some text');

=head1 OVERVIEW

B<DON'T USE THIS MODULE! There are very few situations in which
this module would be a win over using LWP::UserAgent directly.
It was a bad idea I implemented a long time ago.>

This module is intended to do for HTTP POST requests what
LWP::Simple did for GET requests. If you want to do anything
complicated, this module is not for you. If you just want to
push data at a URL with the minimum of fuss, you're the target
audience.

=head1 METHODS

=head2 post

 my $content = post( string $url, string $data );

Posts the data in C<$data> to the URL in C<$url>, and returns
what we got back. Returns C<undef> on failure.

=cut

# I have added all sorts of hooks here in case you need to do
# anything complicated, BUT, if you do, you shouldn't be using
# this module...

sub post {
    my ( $url, $data, $params ) = @_;

    # Make the top secret params argument safe to use easily
    $params = {} unless $params and ref $params;

    # Prepare the request itself
    my $request = HTTP::Request->new( POST => $url );
    $request->content($data);
    $request->header( 'Content-type' => 'text/xml' ) if $params->{'as_xml'};
    return $request if $params->{'return_request'};

    # Execute the request
    my $ua = $params->{'ua'} || LWP::UserAgent->new();
    my $response = $ua->request($request);
    return $response if $params->{'return_response'};

    # Give the result to the user
    my $content;
    $content = $response->content if $response->is_success;
    return $content;
}

=head2 post_xml

 my $content = post_xml( string $url, string $data );

Having written this module, it turned out that 99% of what I needed it
for required a content-type of C<text/xml>. This does exactly what C<post>
does, only the content-type header is set to C<text/html>.	

=cut

sub post_xml {
	my ( $url, $data ) = @_;
	return post( $url, $data, { as_xml => 1 });
}

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>

=head1 COPYRIGHT

Copyright 2011 Pete Sergeant.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
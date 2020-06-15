package Future::HTTP::NetAsync;
use strict;
use Net::Async::HTTP;
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use HTTP::Request;
use IO::Async::Future;

our $VERSION = '0.14';

with 'Future::HTTP::Handler';

has ua => (
    is => 'lazy',
    default => sub { my $ua = Net::Async::HTTP->new( %{ $_[0]->_ua_args } ); $_[0]->loop->add($ua); $ua }
);

has _ua_args => (
    is => 'ro',
    default => sub { +{
        max_redirects => 10,
    } } ,
);

has loop => (
    is => 'lazy',
    default => sub { require IO::Async::Loop; IO::Async::Loop->new() }
);

=head1 NAME

Future::HTTP::NetAsync - asynchronous HTTP client with a Future interface

=head1 DESCRIPTION

This is the backend when running with L<IO::Async>. It will execute the
requests asynchronously.

=cut

sub BUILDARGS {
    my( $class, %options ) = @_;

    my @ua_args = keys %options ? (_ua_args => \%options) : ();
    return +{
        @ua_args
    }
}

sub is_async { !0 }

sub _ae_from_netasync( $self, $res ) {
    # Convert the result back to the AnyEvent format
    my( $body )        = $res->content;
    my $headers        = +{ $res->headers->flatten };
    # This means only a single header is allowed! Multiple cookies will vanish!
    $headers->{Status} = $res->code;
    $headers->{Reason} = '';
    $headers->{URL}    = $res->request->url;

    if( $res->redirects) {
        my $r = $headers;
        for my $netasync_result ( reverse $res->redirects ) {
            $r->{Redirect} = [ $self->_ae_from_netasync( $netasync_result ) ];
            $r = $r->{Redirect}->[1]; # point to the new result headers
        };
    };

    return ($body, $headers)
};

sub _request($self, $method, $url, %options) {

    # Munge the parameters from AnyEvent::HTTP to Net::Async::HTTP
    my $h = HTTP::Headers->new( %{ $options{ headers } || {} });
    my $req = HTTP::Request->new(
        $method => $url,
        $h,
        $options{ body },
    );

    # Execute the request (asynchronously)
    $self->ua->do_request(
        request => $req

    )->then( sub( $resp ) {
        my ($body, $headers) = $self->_ae_from_netasync( $resp );
        my $f = IO::Async::Future->new();
        $self->http_response_received( $f, $body, $headers );
    });

}

sub http_request($self,$method,$url,%options) {
    $self->_request(
        $method => $url,
        %options
    )
}

sub http_get($self,$url,%options) {
    $self->_request(
        'GET' => $url,
        %options,
    )
}

sub http_head($self,$url,%options) {
    $self->_request(
        'HEAD' => $url,
        %options
    )
}

sub http_post($self,$url,$body,%options) {
    $self->_request(
        'POST' => $url,
        body   => $body,
        %options
    )
}

=head1 METHODS

=head2 C<< Future::HTTP::NetAsync->new() >>

    my $ua = Future::HTTP::NetAsync->new();

Creates a new instance of the HTTP client.

=head2 C<< $ua->is_async() >>

Returns true, because this backend is asynchronous.

=head2 C<< $ua->http_get($url, %options) >>

    $ua->http_get('http://example.com/',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    });

Retrieves the URL and returns the body and headers, like
the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_head($url, %options) >>

    $ua->http_head('http://example.com/',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    });

Retrieves the header of the URL and returns the headers,
like the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_post($url, $body, %options) >>

    $ua->http_post('http://example.com/api',
        '{token:"my_json_token"}',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    });

Posts the content to the URL and returns the body and headers,
like the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_request($method, $url, %options) >>

    $ua->http_request('PUT' => 'http://example.com/api',
        headers => {
            'Accept' => 'text/json',
        },
        body    => '{token:"my_json_token"}',
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    });

Posts the content to the URL and returns the body and headers,
like the function in L<AnyEvent::HTTP>.

Note that this subclass will automatically collect cookies. This
may or may not be the behaviour you want.

=head1 SEE ALSO

L<Future>

L<AnyEvent::HTTP> for the details of the API

L<Net::Async::HTTP> for the backend

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/future-http>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Future-HTTP>
or via mail to L<future-http-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2020 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;

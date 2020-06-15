package Future::HTTP::AnyEvent;
use strict;
use Future;
use AnyEvent::HTTP ();
use AnyEvent::Future 'as_future_cb';
BEGIN {
    # Versions before that didn't have as_future_cb
    AnyEvent::Future->VERSION(0.02)
}
use Moo 2; # or Moo::Lax if you can't have Moo v2
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

our $VERSION = '0.14';

with 'Future::HTTP::Handler';

=head1 NAME

Future::HTTP::AnyEvent - asynchronous HTTP client with a Future interface

=cut

sub BUILDARGS( $class, %options ) {
    return {}
}

sub is_async { !0 }

sub future_from_result {
    my( $self, $body, $headers ) = @_;

    $body ||= $headers->{Reason}; # just in case we didn't get a body at all
    my $res = Future->new();
    $self->http_response_received( $res, $body, $headers );
    $res
}

sub http_request($self,$method,$url,%options) {
    my $res = AnyEvent::Future->new()->then(sub ($body, $headers) {
        return $self->future_from_result($body, $headers);
    });

    my $r;
    $r = AnyEvent::HTTP::http_request($method => $url, %options, sub ($body, $headers) {
        undef $r;
        $res->done( $body,$headers )
    });

    $res
}

sub http_get($self,$url,%options) {
    $self->http_request('GET',$url, %options)
}

sub http_head($self,$url,%options) {
    $self->http_request('HEAD',$url, %options)
}

sub http_post($self,$url,$body, %options) {
    $self->http_request('POST',$url, body => $body, %options)
}

=head1 DESCRIPTION

This is the backend chosen if L<AnyEvent.pm> or L<AE.pm> are detected
in C<%INC>. It will execute the requests asynchronously
using L<AnyEvent::HTTP>.

=head1 METHODS

=head2 C<< Future::HTTP::AnyEvent->new() >>

    my $ua = Future::HTTP::AnyEvent->new();

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

=head1 SEE ALSO

L<Future>

L<AnyEvent::HTTP> for the details of the API

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

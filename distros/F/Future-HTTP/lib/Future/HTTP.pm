package Future::HTTP;
use strict;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

=head1 NAME

Future::HTTP - provide the most appropriate HTTP client with a Future API

=head1 SYNOPSIS

    my $ua = Future::HTTP->new();
    my $res = $ua->http_get('http://www.nethype.de/')->then(sub {
        my( $body, $data ) = @_;
        # ... handle the response
        return $body
    })->get();

This module is a wrapper combining L<Future> with the API provided
by L<AnyEvent::HTTP>. The backend used for the HTTP protocols
depends on whether one of the event loops is loaded.

=head2 Supported event loops

Currently, the following backends are supported:

=over 4

=item *

L<HTTP::Tiny>

=item *

L<HTTP::Tiny::Paranoid>

=item *

L<Mojolicious>

=item *

L<AnyEvent>

=item *

L<IO::Async>

=back

Support
is planned for L<LWP::UserAgent> and L<POE>
but has not materialized yet.

=cut

our $VERSION = '0.14';

our @loops;
push @loops, (
    ['IO/Async.pm'    => 'Future::HTTP::NetAsync' ],
    ['Mojo/IOLoop.pm' => 'Future::HTTP::Mojo' ],
    ['AnyEvent.pm'    => 'Future::HTTP::AnyEvent'],
    ['AE.pm'          => 'Future::HTTP::AnyEvent'],
    # POE support would be nice
    # LWP::UserAgent support would be nice

    # A threaded backend would also be nice but likely brings in other
    # interesting problems. How will we load this? We have two prerequisites
    # now, threads.pm and HTTP::Tiny...
    #['threads.pm' => 'Future::HTTP::Tiny::threaded' ],

    ['HTTP/Tiny/Paranoid.pm' => 'Future::HTTP::Tiny::Paranoid'],

    # The fallback, will always catch due to loading Future::HTTP
    ['Future/HTTP.pm' => 'Future::HTTP::Tiny'],
);
our $implementation;
our $default = 'Future::HTTP::Tiny';

=head1 METHODS

=head2 C<< Future::HTTP->new() >>

    my $ua = Future::HTTP->new();

Creates a new instance of the HTTP client.

=cut

sub new($factoryclass, @args) {
    $implementation ||= $factoryclass->best_implementation();

    # return a new instance
    $implementation->new(@args);
}

sub best_implementation( $class, @candidates ) {

    if(! @candidates) {
        @candidates = @loops;
    };

    # Find the currently running/loaded event loop(s)
    #use Data::Dumper;
    #warn Dumper \%INC;
    #warn Dumper \@candidates;
    my @applicable_implementations = map {
        $_->[1]
    } grep {
        $INC{$_->[0]}
    } @candidates;

    if( ! @applicable_implementations ) {
        @applicable_implementations = map {$_->[1]} @candidates;
    }

    # Check which one we can load:
    for my $impl (@applicable_implementations) {
        if( eval "require $impl; 1" ) {
            return $impl;
        };
    };

    # This will crash and burn, but that's how it is
    return $default;
};

=head2 C<< $ua->is_async() >>

Returns true if the selected backend is asynchronous, false if it is
synchronous.

=cut

sub is_async {
    die "method is_async must be overloaded by subclass\n";
}

# We support the L<AnyEvent::HTTP> API first

=head2 C<< $ua->http_get($url, %options) >>

    my $res = $ua->http_get('http://example.com/',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        # ... handle the response
    })->get;

Retrieves the URL and returns the body and headers, like
the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_head($url, %options) >>

    my $res = $ua->http_head('http://example.com/',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    })->get;

Retrieves the header of the URL and returns the headers,
like the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_post($url, $body, %options) >>

    my $res = $ua->http_post('http://example.com/api',
        '{token:"my_json_token"}',
        headers => {
            'Accept' => 'text/json',
        },
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    })->get;

Posts the content to the URL and returns the body and headers,
like the function in L<AnyEvent::HTTP>.

=head2 C<< $ua->http_request($method, $url, %options) >>

    my $res = $ua->http_request('PUT' => 'http://example.com/api',
        headers => {
            'Accept' => 'text/json',
        },
        body    => '{token:"my_json_token"}',
    )->then(sub {
        my( $body, $headers ) = @_;
        ...
    })->get;

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

# We should support more APIs like HTTP::Tiny, later
# See L<Future::HTTP::API::HTTPTiny>.

1;

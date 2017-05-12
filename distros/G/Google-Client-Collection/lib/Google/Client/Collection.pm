package Google::Client::Collection;
# ABSTRACT: Google Client Collection
$Google::Client::Collection::VERSION = '0.005';
use Moo;

# Available Google REST APIs
use Google::Client::Files;

has cache => (is => 'ro', required => 1);
has cache_key => (is => 'rw', writer => 'set_cache_key');

sub files {
    my $self = shift;
    return Google::Client::Files->new(
        cache => $self->cache,
        cache_key => $self->cache_key
    );
}

=head1 NAME

Google::Client::Collection - Collection of modules to talk with Googles REST API

=head1 SYNOPSIS

    use Google::Client::Collection;

    my $google = Google::Client::Collection->new(
        cache => CHI::Driver->new(), # ... or anything with a 'get($cache_key)' method
    );

    # then before calling a google clients method, set the key to fetch the access_token from in the cache:
    $google->set_cache_key('user-10-access-token');

    # eg: use a Google::Client::Files client:
    my $json = $google->files->list(); # lists all files available by calling: GET https://www.googleapis.com/drive/v3/files

=head1 DESCRIPTION

A compilation of Google::Client::* clients used to connect to the many resources of L<Googles REST API|https://developers.google.com/google-apps/products>.
All such clients can be found in CPAN under the 'Google::Client' namespace (eg L<Google::Client::Files|https://metacpan.org/pod/Google::Client::Files>).
Each client uses the same constructor arguments, so they can be used separately if desired.

You should only ever have to instantiate C<< Google::Client::Collection >>, which will give you access to all the available REST clients (pull requests welcome to add more!).

Requests to Googles API require authentication, which can be handled via L<Google::OAuth2::Client::Simple|https://metacpan.org/pod/Google::OAuth2::Client::Simple>.

Also, make sure you request the right scopes from the user during authentication before using a client, as you will get unauthorized errors from Google (intended behaviour).

=head1 CONSTRUCTOR ARGS

=head2 cache

Required constructor argument. The cache can be any object
that provides a C<< get($cache_key) >> method to retrieve
the access token. It'll be responsible for eventually
expiring the access token so it's known when to
request a new one.

=head1 METHODS

=head2 cache_key

The key to lookup the access token in the cache. Should be set
before calling any method in a Google Client. It's a good
idea to make this unique (per user maybe?).

=head2 files

A L<Google::Client::Files|https://metacpan.org/pod/Google::Client::Files> client.

=head1 AUTHOR

Ali Zia, C<< <ziali088@gmail.com> >>

=head1 REPOSITORY

L<https://github.com/ziali088/googleapi-client>

=head1 COPYRIGHT AND LICENSE

This is free software. You may use it and distribute it under the same terms as Perl itself.
Copyright (C) 2016 - Ali Zia

=head1 TODO

=over 2

=item *

Catch known Google API errors instead of giving that responsibility to the user of module

=item *

Add more clients

=back

=cut

1;

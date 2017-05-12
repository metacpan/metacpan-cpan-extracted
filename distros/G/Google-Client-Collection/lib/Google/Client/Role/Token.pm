package Google::Client::Role::Token;
$Google::Client::Role::Token::VERSION = '0.005';
use strict;
use warnings;

use Moo::Role;

has cache => (is => 'ro', required => 1);
has cache_key => (is => 'rw', writer => 'set_cache_key');

has access_token => (is => 'rw');

around access_token => sub {
    my ($orig, $self) = @_;
    return undef unless $self->cache_key;
    return $self->cache->get($self->cache_key);
};

=head1 NAME

Google::Client::Role::Token

=head1 DESCRIPTION

A role that provides access token attrs/methods for Google::Client::* modules. Will get the
access_token value keyed by C<< $self->cache_key >> from the cache.

=head1 ATTRIBUTES

=head2 access_token

The access token retrieved from making an access token request to Google. Should only be used to get the value,
as its value will be retrieved from the cache.

=head2 cache

The object which stores the access token. Can be a L<CHI|https://metacpan.org/pod/CHI> instance, or any object
which provides a C<< get($key) >> method. Used to retrieve the access token.

=head2 cache_key

The key from which to get the access token from the cache. Should be set before making requests to Googles API
as that's when we retrieve an access token.

=head1 AUTHOR

Ali Zia, C<< <ziali088@gmail.com> >>

=head1 REPOSITORY

L<https://github.com/ziali088/googleapi-client>

=head1 COPYRIGHT AND LICENSE

This is free software. You may use it and distribute it under the same terms as Perl itself.
Copyright (C) 2016 - Ali Zia

=cut

1;

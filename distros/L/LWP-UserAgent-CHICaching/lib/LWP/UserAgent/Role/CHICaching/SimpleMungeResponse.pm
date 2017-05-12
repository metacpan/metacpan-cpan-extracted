package LWP::UserAgent::Role::CHICaching::SimpleMungeResponse;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Bool);
our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.04';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching::SimpleMungeResponse - A role to manipulate the response when caching

=head1 SYNOPSIS

See L<LWP::UserAgent::Role::CHICaching>.


=head1 DESCRIPTION

When caching, it is sometimes useful to change the response, in
particular the body in some way for caching. In some cases, you might
not want to store the entire body, but compress it in some way, or
store the data in a different data structure than the serialized
version shared over the network.

The methods here are used to first manipulate the response before it
is sent to the cache, and then a cached response before it is returned
to the client.



=head2 Methods

=over


=item C<< cache_set($response, $expires_in) >>

A method that takes the L<HTTP::Response> from the client and an
expires time in seconds and set the actual cache. This role's
implementation stores the response as it is.


=item C<< finalize($cached) >>

A method that takes the cached entry as an argument, and will return a
L<HTTP::Response> to return to the client. This implementation returns
the response directly from the cache.

=back

=head1 TODO

The standard has a C<no-transform> directive that is relevant to this,
since roles such as this can be used to transform the response. This
needs to be dealt with.

=cut


sub finalize {
	return $_[1];
}

sub cache_set {
	my ($self, $res, $expires_in) = @_;
	return $self->cache->set($self->key, $res, { expires_in => $expires_in });
}

1;


__END__


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

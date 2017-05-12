package LWP::UserAgent::Role::CHICaching::SimpleKeyGen;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Str);

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.04';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching::SimpleKeyGen - A role for cache keys when caching LWP::UserAgent

=head1 SYNOPSIS

See L<LWP::UserAgent::Role::CHICaching>.


=head1 DESCRIPTION

L<LWP::UserAgent::Role::CHICaching> is a role for creating caching
user agents. There's some complexity around caching different variants
of the same resource (e.g. the same thing in different natural
languages, different serializations that is considered in L<Section
4.1 of RFC7234|http://tools.ietf.org/html/rfc7234#section-4.1> that
this role is factored out to address in the dumbest way possible: Just
don't cache when the problem arises.

To really solve this problem in a better way, you need to generate a
cache key based on not only the URI, but also on the content
(e.g. C<Content-Language: en>), and so, provide a better
implementation of the C<key> attribute, and then, you also need to
tell the system when it is OK to cache something with a C<Vary> header
by making the C<cache_vary> method smarter. See
L<LWP::UserAgent::Role::CHICaching::VaryNotAsterisk> for an example of
an alternative.

=head2 Attributes and Methods

=over

=item C<< key >>, C<< clear_key >>

The key to use for a response. This role will return the canonical URI of the
request as a string, which is a reasonable default.

=item C<< cache_vary >>

Will never allow a response with a C<Vary> header to be cached.

=back

=cut


has key => (
				is => 'rw',
				isa => Str,
				lazy => 1,
				clearer => 1,
				builder => '_build_key'
			  );

sub _build_key { return shift->request_uri->canonical->as_string }

sub cache_vary {
	my ($self, $res) = @_;
	return (defined($res->header('Vary')) ? 0 : 1);
}

1;

__END__


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2016 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

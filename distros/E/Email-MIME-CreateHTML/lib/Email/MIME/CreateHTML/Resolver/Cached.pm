###############################################################################
# Purpose : Apply caching to another resolver
# Author  : John Alden
# Created : Aug 2006
###############################################################################

package Email::MIME::CreateHTML::Resolver::Cached;

use strict;
use Data::Serializer;
use URI::Escape;

our $VERSION = '1.042';

sub new {
	my ($class, $args) = @_;	
	my $self = {
		'Resolver' => $args->{resolver},
		'Cache'	=> $args->{object_cache},
		'base' => $args->{base},
	};
	return bless($self, $class);
}

sub get_resource {
	my ($self, $uri) = @_;
	my $args = {'uri' => $uri, 'base' => $self->{base}, 'resolver' => ref $self->{Resolver}};
	my $key = join('&', map {$_ . '=' . URI::Escape::uri_escape($args->{$_})} grep {defined $args->{$_}} sort(keys %$args));
	my $cache = $self->{Cache};
	my $serialized = $cache->get( $key );
	my $ds = Data::Serializer->new();
	my @rv;
	if ( defined $serialized ) {
	   my $deserialized = $ds->deserialize( $serialized );
	   @rv = @$deserialized;
	}
	else {
	   @rv = $self->{Resolver}->get_resource( $uri );
	   my $serialized = $ds->serialize( \@rv );
	   $cache->set( $key,$serialized );
	}
	return @rv;
}

1;

=head1 NAME

Email::MIME::CreateHTML::Resolver::Cached - wraps caching around a resource resolver

=head1 SYNOPSIS

	my $o = new Email::MIME::CreateHTML::Resolver::Cached(\%args)
	my ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=head1 DESCRIPTION

This is used by Email::MIME::CreateHTML to load resources.

=head1 METHODS

=over 4

=item $o = new Email::MIME::CreateHTML::Resolver::Cached(\%args)

%args can contain:

=over 4

=item base

Base URI to resolve URIs passed to get_resource.

=item object_cache (mandatory)

A cache object

=item resolver (mandatory)

Another resolver to apply caching to

=back

=item ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=back

=head1 AUTHOR

Tony Hennessy, Simon Flack and John Alden with additional contributions by
Ricardo Signes <rjbs@cpan.org> and Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT

(c) BBC 2005,2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut

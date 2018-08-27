use strict;
use warnings;

package Footprintless::Resource::Provider;
$Footprintless::Resource::Provider::VERSION = '1.29';
# ABSTRACT: A contract for providing resources to the resource manager
# PODNAME: Footprintless::Resource::Provider

use parent qw(Footprintless::MixableBase);

use Carp;
use Footprintless::Util qw(
    temp_file
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub download {
    my ( $self, $resource, @options ) = @_;

    my $ref = ref($resource);
    $resource = $self->resource($resource) if ( !$ref || $ref eq 'HASH' );

    croak("invalid resource [$resource]")
        unless ( $resource->isa('Footprintless::Resource') );

    return $self->_download( $resource, @options );
}

sub _download {
    my ( $self, $resource, @options ) = @_;
    croak( __PACKAGE__ . " does not support [$resource]" );
}

sub resource {
    my ( $self, $spec ) = @_;
    croak( __PACKAGE__ . " does not support [$spec]" );
}

sub supports {
    my ( $self, $spec ) = @_;
    return 0;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Resource::Provider - A contract for providing resources to the resource manager

=head1 VERSION

version 1.29

=head1 DESCRIPTION

The I<abstract> base class for all providers.  The class defines the 
contract that all providers must adhere to.  Providers not intended to 
be used directly.  Instead an instance of 
C<Footprintless::ResourceManager> should be initialized with an ordered
list of providers.  See L<Footprintless::ResourceManager> for usage.

=head1 METHODS

=head2 download($resource, %options)

Downloads C<$resource> and returns the filename it downloaded to.  The
returned filename may be an object which overrides the C<""> operator so
that when used in string context, you will get the actual filename.  All
C<%options> are passed through to the implementation.  At minimum, all
implementations must support these options:

=over 4

=item to

The path of a directory or filename to download to.

=back

=head2 resource($spec)

Returns an instance of the subclass of C<Footprintless::Resource> provided
by this provider, indicated by C<$spec>.

=head2 supports($spec)

Returns C<1> if this provider supports C<$spec>, C<0> otherwise.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Resource::Provider|Footprintless::Resource::Provider>

=item *

L<Footprintless::Resource::Url|Footprintless::Resource::Url>

=item *

L<Footprintless::ResourceManager|Footprintless::ResourceManager>

=item *

L<Footprintless|Footprintless>

=back

=cut

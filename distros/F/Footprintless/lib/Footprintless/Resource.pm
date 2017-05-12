use strict;
use warnings;

package Footprintless::Resource;
$Footprintless::Resource::VERSION = '1.24';
# ABSTRACT: A resource provided by a provider
# PODNAME: Footprintless::Resource

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _init {
    my ( $self, $url ) = @_;

    $self->{url} = $url;

    return $self;
}

sub get_url {
    return $_[0]->{url};
}

1;

__END__

=pod

=head1 NAME

Footprintless::Resource - A resource provided by a provider

=head1 VERSION

version 1.24

=head1 DESCRIPTION

The I<abstract> base class for all resources.  The class defines the 
contract that all resources must adhere to.  Resources are not intended 
to be used directly.  Instead an instance of 
C<Footprintless::ResourceManager> should be initialized with an ordered
list of providers.  See L<Footprintless::ResourceManager> for usage.

=head1 CONSTRUCTORS

=head2 new($url)

See implementation classes.

=head1 ATTRIBUTES

=head2 get_url()

Returns the URL for this resource.

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

L<Footprintless::ResourceManager|Footprintless::ResourceManager>

=item *

L<Footprintless::Resource::Provider|Footprintless::Resource::Provider>

=item *

L<Footprintless|Footprintless>

=back

=cut

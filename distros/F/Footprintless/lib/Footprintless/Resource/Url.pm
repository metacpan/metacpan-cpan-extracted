use strict;
use warnings;

package Footprintless::Resource::Url;
$Footprintless::Resource::Url::VERSION = '1.26';
# ABSTRACT: A resource described by URL
# PODNAME: Footprintless::Resource::Url

use parent qw(Footprintless::Resource);

sub get_uri {
    return $_[0]->{uri};
}

sub _init {
    my ( $self, $url ) = @_;

    $self->{uri} = URI->new($url);
    $self->{uri} = $self->{uri}->abs('file://')
        unless ( $self->{uri}->has_recognized_scheme() );

    $self->Footprintless::Resource::_init( $self->{uri}->as_string() );

    return $self;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Resource::Url - A resource described by URL

=head1 VERSION

version 1.26

=head1 CONSTRUCTORS

=head2 new($url)

Creates a new C<Footprintless::Resource::Url> for the supplied URL.

=head1 ATTRIBUTES

=head2 get_uri()

Returns the C<URI> object for the URL.

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

L<Footprintless::Resource::UrlProvider|Footprintless::Resource::UrlProvider>

=item *

L<Footprintless::ResourceManager|Footprintless::ResourceManager>

=item *

L<Footprintless|Footprintless>

=item *

L<URI|URI>

=back

=cut

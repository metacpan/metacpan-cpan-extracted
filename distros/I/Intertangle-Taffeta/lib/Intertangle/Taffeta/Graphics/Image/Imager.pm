use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Image::Imager;
# ABSTRACT: Raster data stored in Imager object
$Intertangle::Taffeta::Graphics::Image::Imager::VERSION = '0.001';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf);

extends qw(Intertangle::Taffeta::Graphics::Image);

has data => (
	is => 'ro',
	isa => InstanceOf['Imager'],
	required => 1,
);

with qw(Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Image::Imager - Raster data stored in Imager object

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Graphics::Image>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Image::Role::FromCairoImageSurface>

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::WithTransform>

=back

=head1 ATTRIBUTES

=head2 data

An L<Imager> image.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

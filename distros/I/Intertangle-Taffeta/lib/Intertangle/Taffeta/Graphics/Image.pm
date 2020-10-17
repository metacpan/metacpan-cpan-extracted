use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Image;
# ABSTRACT: Graphics object for raster images
$Intertangle::Taffeta::Graphics::Image::VERSION = '0.001';
use Moo;

extends qw(Intertangle::Taffeta::Graphics);

with qw(
	Intertangle::Taffeta::Graphics::Role::WithBounds
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Image - Graphics object for raster images

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Graphics>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Role::WithBounds>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

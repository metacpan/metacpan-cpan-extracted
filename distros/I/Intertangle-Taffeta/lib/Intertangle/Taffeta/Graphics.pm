use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics;
# ABSTRACT: Base class for graphics object
$Intertangle::Taffeta::Graphics::VERSION = '0.001';
use Moo;
use MooX::StrictConstructor;

with qw(
	Intertangle::Taffeta::Graphics::Role::CairoRenderable
	Intertangle::Taffeta::Graphics::Role::SVGRenderable
	Intertangle::Taffeta::Graphics::Role::WithTransform
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics - Base class for graphics object

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Taffeta::Graphics::Role::CairoRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::SVGRenderable>

=item * L<Intertangle::Taffeta::Graphics::Role::WithTransform>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

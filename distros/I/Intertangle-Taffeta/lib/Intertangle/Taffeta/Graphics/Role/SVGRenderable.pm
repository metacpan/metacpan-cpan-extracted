use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::SVGRenderable;
# ABSTRACT: A role for an SVG renderable object
$Intertangle::Taffeta::Graphics::Role::SVGRenderable::VERSION = '0.001';
use Moo::Role;

use Intertangle::Taffeta::Types qw(SVG);
use SVG;

method render_svg( (SVG) $svg ) {
	...
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::SVGRenderable - A role for an SVG renderable object

=head1 VERSION

version 0.001

=head1 METHODS

=head2 render_svg

  method render_svg( (SVG) $svg )

Renders a graphics object to a L<SVG> context.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::CairoRenderable;
# ABSTRACT: A Cairo renderable graphics object
$Intertangle::Taffeta::Graphics::Role::CairoRenderable::VERSION = '0.001';
use Moo::Role;

use Intertangle::Taffeta::Types qw(CairoContext);
use Cairo;

method render_cairo( (CairoContext) $cr ) {
	...
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::CairoRenderable - A Cairo renderable graphics object

=head1 VERSION

version 0.001

=head1 METHODS

=head2 render_cairo

  method render_cairo( (CairoContext) $cr )

Renders a a graphics object to L<Cairo>'s C<Cairo::Context>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

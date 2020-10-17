use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform;
# ABSTRACT: Role for SVG transform parameters
$Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform::VERSION = '0.001';
use Moo::Role;

requires 'transform';

method svg_transform_parameter() {
	my %transform_args = ();
	if( ! $self->transform->is_identity ) {
		%transform_args = (
			transform => $self->transform->svg_transform,
		);
	}

	return %transform_args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::SVGRenderable::Transform - Role for SVG transform parameters

=head1 VERSION

version 0.001

=head1 METHODS

=head2 svg_transform_parameter

Returns transform parameter for SVG based on transform attribute.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

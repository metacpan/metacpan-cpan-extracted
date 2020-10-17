use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::WithTransform;
# ABSTRACT: A role that holds a transform
$Intertangle::Taffeta::Graphics::Role::WithTransform::VERSION = '0.001';
use Mu::Role;
use Intertangle::Taffeta::Transform::Affine2D;

has transform => (
	is => 'ro',
	default => sub {
		Intertangle::Taffeta::Transform::Affine2D->new,
	},
);

lazy transformed_bounds => method () {
	$self->transform->apply_to_bounds( $self->identity_bounds );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::WithTransform - A role that holds a transform

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 transform

The transform to apply.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

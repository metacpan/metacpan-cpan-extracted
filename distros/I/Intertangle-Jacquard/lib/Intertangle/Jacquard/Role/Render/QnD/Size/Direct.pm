use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Size::Direct;
# ABSTRACT: Quick-and-dirty role for computing size from width / height
$Intertangle::Jacquard::Role::Render::QnD::Size::Direct::VERSION = '0.001';
use Mu::Role;

lazy size => method() {
	Intertangle::Yarn::Graphene::Size->new(
		height => ref $self->height ? $self->height->value : $self->height,
		width => ref $self->width ? $self->width->value : $self->width,
	);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Size::Direct - Quick-and-dirty role for computing size from width / height

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct;
# ABSTRACT: Quick-and-dirty role for computing bounds directly using position and size
$Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct::VERSION = '0.002';
use Mu::Role;

requires 'origin_point';
requires 'size';

lazy bounds => method() {
	Intertangle::Yarn::Graphene::Rect->new(
		origin => $self->origin_point,
		size => $self->size,
	);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Bounds::Direct - Quick-and-dirty role for computing bounds directly using position and size

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

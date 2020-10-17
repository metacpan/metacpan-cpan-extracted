use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Cairo::Group;
# ABSTRACT: Quick-and-dirty Cairo group rendering
$Intertangle::Jacquard::Role::Render::QnD::Cairo::Group::VERSION = '0.001';
use Mu::Role;

method render_cairo($cr) {
	$cr->save;
	my $matrix = Cairo::Matrix->init_translate( $self->x->value, $self->y->value )
	->multiply(
		$cr->get_matrix
	);
	$cr->set_matrix( $matrix );
	for my $child (@{$self->children}) {
		$child->render_cairo($cr);
	}
	$cr->restore;
}

with qw(Intertangle::Jacquard::Role::Render::QnD::Cairo);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Cairo::Group - Quick-and-dirty Cairo group rendering

=head1 VERSION

version 0.001

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Role::Render::QnD::Cairo>

=back

=head1 METHODS

=head2 render_cairo

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Layout::Box;
# ABSTRACT: Box layout
$Intertangle::Jacquard::Layout::Box::VERSION = '0.002';
use Mu;
use Intertangle::Punchcard::Backend::Kiwisolver::Context;
use Intertangle::Punchcard::Attributes;

ro 'margin'; # TODO PositiveOrZeroInt

variable 'outer_x';
variable 'outer_y';

lazy context => sub {
	Intertangle::Punchcard::Backend::Kiwisolver::Context->new;
};

method create_constraints($actor) {
	my $items = $actor->children;

	my @constraints;

	my $inner_x = $self->context->new_variable( name => "inner.x" );
	my $inner_y = $self->context->new_variable( name => "inner.y" );
	my $inner_width  = $self->context->new_variable( name => "inner.width" );
	my $inner_height = $self->context->new_variable( name => "inner.height" );

	for my $item_no (0..@$items-1) {
		my $this_item = $items->[$item_no];

		push @constraints, $this_item->x >= $inner_x;
		push @constraints, $this_item->y >= $inner_y;

		push @constraints, $inner_width  >= $this_item->width;
		push @constraints, $inner_height >= $this_item->height;
	}

	push @constraints, $self->outer_x + $self->margin == $inner_x;
	push @constraints, $self->outer_y + $self->margin == $inner_y;

	push @constraints, $actor->width == $inner_width + 2 * $self->margin;
	push @constraints, $actor->height == $inner_height + 2 * $self->margin;

	\@constraints;
}

has _constraints => (
	is => 'rw',
	predicate => 1,
);

method update($actor) {
	my $solver = $self->context->solver;
	my $items = $actor->children;
	my $first_item = $items->[0];

	if( ! $self->_has_constraints ) {
		my $constraints = $self->create_constraints( $actor );
		$self->_constraints( $constraints );

		for my $constraint (@$constraints) {
			$solver->add_constraint($constraint);
		}

		$solver->add_edit_variable($self->outer_x, Graphics::Layout::Kiwisolver::Strength::STRONG );
		$solver->add_edit_variable($self->outer_y, Graphics::Layout::Kiwisolver::Strength::STRONG );
	}

	$solver->suggest_value( $self->outer_x, 0);
	$solver->suggest_value( $self->outer_y, 0);
	$solver->update;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Layout::Box - Box layout

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 margin

Size of margin.

=head1 METHODS

=head2 create_constraints

...

=head2 update

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

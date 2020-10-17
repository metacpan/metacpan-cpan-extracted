use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Layout::Grid;
# ABSTRACT: Grid layout
$Intertangle::Jacquard::Layout::Grid::VERSION = '0.001';
use Mu;
use Intertangle::Punchcard::Backend::Kiwisolver::Context;
use List::AllUtils qw(reduce);

ro 'rows'; # TODO PositiveInt
ro 'columns'; # TODO PositiveInt

lazy context => sub {
	Intertangle::Punchcard::Backend::Kiwisolver::Context->new;
};

method _item_no_to_rc($item_no) {
	( int($item_no / $self->columns), $item_no % $self->columns );
}
method _rc_to_item_no($r, $c) {
	$r * $self->columns + $c;
}

method create_constraints($actor) {
	my $items = $actor->children;

	my @constraints;

	my @rows_constraints = map { $self->context->new_variable( name => "row.$_" ) } (0..$self->rows-1);
	my @cols_constraints = map { $self->context->new_variable( name => "col.$_" ) } (0..$self->columns-1);

	push @constraints, $_ >= 0 for @rows_constraints;
	push @constraints, $_ >= 0 for @cols_constraints;

	for my $item_no (0..@$items-1) {
		my ($row, $col) = $self->_item_no_to_rc($item_no);
		my $this_item = $items->[$item_no];

		push @constraints, $this_item->x >= 0;
		push @constraints, $this_item->y >= 0;
		push @constraints, $cols_constraints[$col] >= (ref $this_item->width  ? $this_item->width->value  : $this_item->width);
		push @constraints, $rows_constraints[$row] >= (ref $this_item->height ? $this_item->height->value : $this_item->height);

		if( $col > 0 ) {
			my $item_left0 = $items->[$self->_rc_to_item_no($row,$col-1)];
			push @constraints, $item_left0->x + $cols_constraints[$col-1] == $this_item->x;
		}
		if( $row > 0 ) {
			my $item_above = $items->[$self->_rc_to_item_no($row-1,$col)];
			push @constraints, $item_above->y + $rows_constraints[$row-1] == $this_item->y;
		}
	}

	push @constraints, $actor->width == reduce { $a + $b } @cols_constraints;
	push @constraints, $actor->height == reduce { $a + $b } @rows_constraints;

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
		$solver->add_edit_variable($first_item->x, Intertangle::API::Kiwisolver::Strength::STRONG );
		$solver->add_edit_variable($first_item->y, Intertangle::API::Kiwisolver::Strength::STRONG );
	}

	#$solver->suggest_value($first_item->x, $actor->x->value);
	#$solver->suggest_value($first_item->y, $actor->y->value);
	$solver->suggest_value($first_item->x, 0);
	$solver->suggest_value($first_item->y, 0);
	$solver->update;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Layout::Grid - Grid layout

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 rows columns

Number of rows / columns.

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

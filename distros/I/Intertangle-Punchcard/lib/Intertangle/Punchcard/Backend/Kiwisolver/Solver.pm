use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Backend::Kiwisolver::Solver;
# ABSTRACT: Solver wrapper for Kiwisolver
$Intertangle::Punchcard::Backend::Kiwisolver::Solver::VERSION = '0.002';
use Mu;
use Graphics::Layout::Kiwisolver;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has _delegate => (
	is => 'ro',
	isa => InstanceOf['Graphics::Layout::Kiwisolver::Solver'],
	default => method() {
		Graphics::Layout::Kiwisolver::Solver->new;
	},
);

method add_constraint($constraint) {
	$self->_delegate->addConstraint($constraint->_delegate);
}

method update() {
	$self->_delegate->updateVariables;
}

method add_edit_variable($variable, $strength) {
	$self->_delegate->addEditVariable($variable->_delegate, $strength);
}

method suggest_value($variable, $value) {
	$self->_delegate->suggestValue($variable->_delegate, $value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Backend::Kiwisolver::Solver - Solver wrapper for Kiwisolver

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 METHODS

=head2 add_constraint

...

=head2 update

...

=head2 add_edit_variable

...

=head2 suggest_value

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Backend::Kiwisolver::Symbolic;
# ABSTRACT: Kiwisolver variable
$Intertangle::Punchcard::Backend::Kiwisolver::Symbolic::VERSION = '0.001';
use Mu;
use Intertangle::API::Kiwisolver;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use overload nomethod => \&_delegate_op;

has name => ( is => 'ro', predicate => 1 );

has _delegate => (
	is => 'ro',
	isa => (
		InstanceOf['Intertangle::API::Kiwisolver::Variable']
		| InstanceOf['Intertangle::API::Kiwisolver::Term']
		| InstanceOf['Intertangle::API::Kiwisolver::Expression']
		| InstanceOf['Intertangle::API::Kiwisolver::Constraint']
		),
	default => method() {
		Intertangle::API::Kiwisolver::Variable->new;
	},
);

method BUILD() {
	if( $self->has_name ) {
		$self->_delegate->setName( $self->name );
	}
}

method _delegate_op($other, $inv, $meth) {
	my $op = overload::Method($self->_delegate, $meth);
	die "Operator $meth not available" unless defined $op;
	my $return =  $op->($self->_delegate, defined $other && ref $other ? $other->_delegate : $other , $inv );

	if( $meth eq '""') {
		return $return;
	}

	my $return_wrapper;
	$return_wrapper = Intertangle::Punchcard::Backend::Kiwisolver::Symbolic->new(
		_delegate => $return,
	);

	$return_wrapper;
}

method value($value = undef) {
	if( defined $value ) {
		$self->_delegate->setValue( $value );
	} else {
		$self->_delegate->value;
	}
}

with qw(Intertangle::Punchcard::Data::Role::Variable);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Backend::Kiwisolver::Symbolic - Kiwisolver variable

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Punchcard::Data::Role::HasValue>

=item * L<Intertangle::Punchcard::Data::Role::Variable>

=back

=head1 ATTRIBUTES

=head2 name

Name for variable.

=head1 METHODS

=head2 C<has_name>

Predicate for C<name>.

=head2 BUILD

=head2 value

Set or get value for variable.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

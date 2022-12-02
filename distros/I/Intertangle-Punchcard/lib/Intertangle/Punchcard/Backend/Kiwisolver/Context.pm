use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Backend::Kiwisolver::Context;
# ABSTRACT: Context for Kiwisolver backend
$Intertangle::Punchcard::Backend::Kiwisolver::Context::VERSION = '0.002';
use Mu;
use Intertangle::Punchcard::Backend::Kiwisolver::Solver;
use Intertangle::Punchcard::Backend::Kiwisolver::Symbolic;

lazy solver => sub {
	Intertangle::Punchcard::Backend::Kiwisolver::Solver->new
};

method new_variable(@args) {
	Intertangle::Punchcard::Backend::Kiwisolver::Symbolic->new( @args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Backend::Kiwisolver::Context - Context for Kiwisolver backend

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 METHODS

=head2 new_variable

Helper for creating new symbolic variable.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::API::Kiwisolver::Term;
# ABSTRACT: Kiwisolver term
$Intertangle::API::Kiwisolver::Term::VERSION = '0.001';
use overload "fallback" => 0, '""' => \&stringify;

sub stringify {
	my ($self) = @_;
	"(@{[ $self->coefficient ]} * @{[ $self->variable ]} : @{[ $self->value ]})"
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Kiwisolver::Term - Kiwisolver term

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::API::Kiwisolver::Variable;
# ABSTRACT: Kiwisolver variable
$Intertangle::API::Kiwisolver::Variable::VERSION = '0.001';
use overload "fallback" => 0, '""' => \&stringify;

sub stringify {
	my ($self) = @_;
	"(@{[ $self->name || '[unnamed]' ]} : @{[ $self->value ]})"
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Kiwisolver::Variable - Kiwisolver variable

=head1 VERSION

version 0.001

=head1 CLASS METHODS

=head2 new

TODO

=head1 METHODS

=head2 name

TODO

=head2 setName

TODO

=head2 value

TODO

=head2 setValue

TODO

=head2 equals

TODO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

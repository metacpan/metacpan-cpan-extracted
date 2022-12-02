use strict;
use warnings;
package Graphics::Layout::Kiwisolver::Constraint;
# ABSTRACT: Kiwisolver constraint
$Graphics::Layout::Kiwisolver::Constraint::VERSION = '0.002';
use overload "fallback" => 0, '""' => \&stringify;

sub stringify {
	my ($self) = @_;
	# TODO
	"";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Layout::Kiwisolver::Constraint - Kiwisolver constraint

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

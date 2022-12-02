use strict;
use warnings;
package Graphics::Layout::Kiwisolver;
# ABSTRACT: API for Kiwisolver constraint solver
$Graphics::Layout::Kiwisolver::VERSION = '0.002';
use XS::Framework;
use XS::Loader;
XS::Loader::load();

use Graphics::Layout::Kiwisolver::Variable;
use Graphics::Layout::Kiwisolver::Term;
use Graphics::Layout::Kiwisolver::Expression;
use Graphics::Layout::Kiwisolver::Constraint;
use Graphics::Layout::Kiwisolver::Strength;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Graphics::Layout::Kiwisolver - API for Kiwisolver constraint solver

=head1 VERSION

version 0.002

=head1 SEE ALSO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

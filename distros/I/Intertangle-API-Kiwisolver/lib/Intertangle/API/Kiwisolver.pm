use Renard::Incunabula::Common::Setup;
package Intertangle::API::Kiwisolver;
# ABSTRACT: API for Kiwisolver constraint solver
$Intertangle::API::Kiwisolver::VERSION = '0.001';
use XS::Framework;
use XS::Loader;
XS::Loader::load();

use Intertangle::API::Kiwisolver::Variable;
use Intertangle::API::Kiwisolver::Term;
use Intertangle::API::Kiwisolver::Expression;
use Intertangle::API::Kiwisolver::Constraint;
use Intertangle::API::Kiwisolver::Strength;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::API::Kiwisolver - API for Kiwisolver constraint solver

=head1 VERSION

version 0.001

=head1 SEE ALSO

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

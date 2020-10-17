use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Data::Role::Variable;
# ABSTRACT: A variable role
$Intertangle::Punchcard::Data::Role::Variable::VERSION = '0.001';
use Mu::Role;

with qw(Intertangle::Punchcard::Data::Role::HasValue);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Data::Role::Variable - A variable role

=head1 VERSION

version 0.001

=head1 CONSUMES

=over 4

=item * L<Intertangle::Punchcard::Data::Role::HasValue>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

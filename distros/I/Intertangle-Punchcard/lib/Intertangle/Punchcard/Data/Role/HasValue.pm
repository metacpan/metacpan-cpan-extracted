use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Data::Role::HasValue;
# ABSTRACT: A role for value-holding data
$Intertangle::Punchcard::Data::Role::HasValue::VERSION = '0.002';
use Mu::Role;

requires 'value';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Data::Role::HasValue - A role for value-holding data

=head1 VERSION

version 0.002

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Renard::Incunabula::Common::Setup;
package Intertangle::Punchcard::Data::Constraint;
# ABSTRACT: Base class for a constraint
$Intertangle::Punchcard::Data::Constraint::VERSION = '0.001';
use Mu;

method inputs($context) {

}

method evaluate($context) {

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Punchcard::Data::Constraint - Base class for a constraint

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 METHODS

=head2 inputs

...

=head2 evaluate

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

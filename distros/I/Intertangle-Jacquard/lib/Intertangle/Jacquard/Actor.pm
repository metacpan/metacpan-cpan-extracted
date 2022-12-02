use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Actor;
# ABSTRACT: Base class for scene graph objects
$Intertangle::Jacquard::Actor::VERSION = '0.002';
use Moo;

with qw(
	Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode
	Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren
);

method BUILD(@) { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Actor - Base class for scene graph objects

=head1 VERSION

version 0.002

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Actor::Role::DataPrinter>

=item * L<Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode>

=item * L<Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren>

=back

=head1 METHODS

=head2 BUILD

C<BUILD> for base class.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

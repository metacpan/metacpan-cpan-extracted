use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Types;
# ABSTRACT: Type library for Jacquard
$Intertangle::Jacquard::Types::VERSION = '0.001';
use Type::Library 0.008 -base,
	-declare => [qw(
		Actor
		State
	)];
use Type::Utils -all;

use Renard::Incunabula::Common::Types qw(InstanceOf);

class_type "Actor",
	{ class => 'Intertangle::Jacquard::Actor' };

class_type "State",
	{ class => "Intertangle::Jacquard::Render::State" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Types - Type library for Jacquard

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 Actor

A type for any reference that extends L<Intertangle::Jacquard::Actor>.

=head2 State

A type for any reference that extends L<Intertangle::Jacquard::Render::State>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

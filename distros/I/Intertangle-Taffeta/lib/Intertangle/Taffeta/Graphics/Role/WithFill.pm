use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::WithFill;
# ABSTRACT: A role for a fill style
$Intertangle::Taffeta::Graphics::Role::WithFill::VERSION = '0.001';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has fill => (
	is => 'ro',
	predicate => 1,
	isa => InstanceOf['Intertangle::Taffeta::Style::Fill'],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::WithFill - A role for a fill style

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 fill

A L<Intertangle::Taffeta::Style::Fill> style to fill the shape.

=head1 METHODS

=head2 has_fill

Predicate for C<fill> attribute.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

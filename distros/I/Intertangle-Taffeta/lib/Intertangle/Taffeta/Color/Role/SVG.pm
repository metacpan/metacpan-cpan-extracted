use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Color::Role::SVG;
# ABSTRACT: SVG colour role
$Intertangle::Taffeta::Color::Role::SVG::VERSION = '0.001';
use Mu::Role;

requires 'r8';
requires 'g8';
requires 'b8';

lazy svg_value => method() {
	"rgb(@{[ $self->r8 ]},@{[ $self->g8 ]},@{[ $self->b8 ]})";
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Color::Role::SVG - SVG colour role

=head1 VERSION

version 0.001

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

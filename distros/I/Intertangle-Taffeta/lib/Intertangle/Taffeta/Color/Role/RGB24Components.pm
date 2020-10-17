use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Color::Role::RGB24Components;
# ABSTRACT: RGB component colour role
$Intertangle::Taffeta::Color::Role::RGB24Components::VERSION = '0.001';
use Moo::Role;
use MooX::ShortHas;
use namespace::autoclean;
use Intertangle::Taffeta::Types qw(RGB24Value RGB24Component);

requires 'value';

lazy r8 => method() { ($self->value & 0xFF0000) >> 16; }, isa => RGB24Component;

lazy g8 => method() { ($self->value & 0x00FF00) >>  8; }, isa => RGB24Component;

lazy b8 => method() { ($self->value & 0x0000FF) >>  0; }, isa => RGB24Component;

method rgb_float_triple() {
	($self->r8 / 0xFF, $self->g8 / 0xFF, $self->b8 / 0xFF );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Color::Role::RGB24Components - RGB component colour role

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 value

A C<RGB24Value>.

=head2 r8

Red component as C<RGB24Component>.

=head2 g8

Green component as C<RGB24Component>.

=head2 b8

Blue component as C<RGB24Component>.

=head1 METHODS

=head2 rgb_float_triple

Returns a list of the float components C<(r_float, g_float, b_float)>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.006;
use strict;
use warnings;

package Dist::Zilla::dumpphases::Role::Theme::SimpleColor;

our $VERSION = '1.000009';

# ABSTRACT: A role for themes that are simple single-color themes with variations of bold/uncolored.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Role::Tiny qw( requires with );













with 'Dist::Zilla::dumpphases::Role::Theme';







requires 'color';

## no critic ( RequireArgUnpacking )
sub _colored {
  require Term::ANSIColor; () = eval { require Win32::Console::ANSI } if 'MSWin32' eq $^O;
  goto \&Term::ANSIColor::colored;
}

sub _color_label_label {
  my $self = shift;
  return _colored( [ $self->color ], @_ );
}

sub _color_label_value {
  shift;
  return _colored( ['bold'], @_ );
}

sub _color_attribute_label {
  my $self = shift;
  return _colored( [ $self->color, 'bold' ], @_ );
}

sub _color_attribute_value {
  my $self = shift;
  return _colored( [ $self->color ], @_ );
}

sub _color_plugin_name {
  shift;
  return @_;
}

sub _color_plugin_package {
  my $self = shift;
  return _colored( [ $self->color ], @_ );
}

sub _color_plugin_star {
  my $self = shift;
  return _colored( [ $self->color ], @_ );
}









sub print_section_header {
  my ( $self, $label, $comment ) = @_;
  return printf "\n%s%s\n", $self->_color_label_label($label), $self->_color_label_value($comment);
}









sub print_section_prelude {
  my ( $self, $label, $value ) = @_;
  return printf "%s%s\n", $self->_color_attribute_label( ' - ' . $label ), $self->_color_attribute_value($value);
}









sub print_star_assoc {
  my ( $self, $name, $value ) = @_;
  return printf "%s%s%s\n",
    $self->_color_plugin_star(' * '),
    $self->_color_plugin_name($name),
    $self->_color_plugin_package( ' => ' . $value );
}















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::dumpphases::Role::Theme::SimpleColor - A role for themes that are simple single-color themes with variations of bold/uncolored.

=head1 VERSION

version 1.000009

=head1 SYNOPSIS

    package Dist::Zilla::dumpphases::Theme::foo;

    use Moo;
    with 'Dist::Zilla::dumpphases::Role::Theme::SimpleColor';
    sub color { 'magenta' };

    ...

    dzil dumpphases --color-theme=foo

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::dumpphases::Role::Theme::SimpleColor",
    "does":"Dist::Zilla::dumpphases::Role::Theme",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 REQUIRED METHODS

=head2 C<color>

You must define a method called C<color> that returns a string (or list of strings ) that C<Term::ANSIColor> recognizes.

=head1 METHODS

=head2 C<print_section_header>

See L<Dist::Zilla::dumpphases::Role::Theme/print_section_header>.

This satisfies that, printing label colored, and the value uncolored.

=head2 C<print_section_prelude>

See L<Dist::Zilla::dumpphases::Role::Theme/print_section_prelude>.

This satisfies that, printing label bold and colored, and the value simply colored.

=head2 C<print_star_assoc>

See L<Dist::Zilla::dumpphases::Role::Theme/print_star_assoc>.

This satisfies that, printing label uncolored, and the value simply colored.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

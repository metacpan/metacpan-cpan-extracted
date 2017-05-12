use 5.006;
use strict;
use warnings;

package Dist::Zilla::dumpphases::Theme::basic::plain;

our $VERSION = '1.000009';

# ABSTRACT: A plain-text theme for dzil dumpphases

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY














use Moo qw( with );

with 'Dist::Zilla::dumpphases::Role::Theme';












sub print_section_header {
  my ( undef, $label, $value ) = @_;
  return printf "\n%s%s\n", $label, $value;
}











sub print_section_prelude {
  my ( undef, $label, $value ) = @_;
  return printf "%s%s\n", ' - ' . $label, $value;
}











sub print_star_assoc {
  my ( undef, $name, $value ) = @_;
  return printf "%s%s%s\n", ' * ', $name, ' => ' . $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::dumpphases::Theme::basic::plain - A plain-text theme for dzil dumpphases

=head1 VERSION

version 1.000009

=head1 SYNOPSIS

    dzil dumpphases --color-theme=basic::plain

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::dumpphases::Theme:::basic::plain",
    "does":"Dist::Zilla::dumpphases::Role::Theme",
    "inherits":"Moo::Object",
    "interface":"class"
}


=end MetaPOD::JSON

=for html <center>
  <img src="http://kentnl.github.io/screenshots/Dist-Zilla-App-Command-dumpphases/theme_basic_plain.png"
       alt="Screenshot"
       width="677"
       height="412"/>
</center>

=head1 METHODS

=head2 C<print_section_header>

See L<Dist::Zilla::dumpphases::Role::Theme/print_section_header>.

This satisfies that, printing C<$label> and C<$value>,uncolored, as

    \n
    $label$value\n

=head2 C<print_section_prelude>

See L<Dist::Zilla::dumpphases::Role::Theme/print_section_prelude>.

This satisfies that, printing C<$label> and C<$value> uncolored, as:

     - $label$value\n

=head2 C<print_star_assoc>

See L<Dist::Zilla::dumpphases::Role::Theme/print_star_assoc>.

This satisfies that, printing C<$label> and C<$value> uncolored, as:

     * $label => $value

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

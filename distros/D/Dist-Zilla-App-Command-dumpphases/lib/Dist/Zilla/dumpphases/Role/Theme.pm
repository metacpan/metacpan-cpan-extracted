use 5.006;
use strict;
use warnings;

package Dist::Zilla::dumpphases::Role::Theme;

our $VERSION = '1.000009';

# ABSTRACT: Output formatting themes for dzil dumpphases

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Role::Tiny qw( requires );












requires 'print_star_assoc';
requires 'print_section_prelude';
requires 'print_section_header';















































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::dumpphases::Role::Theme - Output formatting themes for dzil dumpphases

=head1 VERSION

version 1.000009

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::dumpphases::Role::Theme",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 REQUIRED METHODS

=head2 C<print_star_assoc>

Print some kind of associated data.

    $theme->print_star_assoc($label, $value);

e.g.:

    $theme->print_star_assoc('@Author::KENTNL/Test::CPAN::Changes', 'Dist::Zilla::Plugin::Test::CPAN::Changes');

recommended formatting is:

    \s  * \s label \s => \s $value

Most of the time, C<$label> will be an alias of some kind (e.g: an instance name), and $value will be the thing that alias
refers to (e.g.: an instances class).

=head2 C<print_section_prelude>

Will be passed meta-info pertaining to the section currently being dumped, such as section descriptions, or applicable roles
for sections.

    $theme->print_section_prelude($label, $value);

Recommended format is simply

    \s-\s$label$value

=head2 C<print_section_header>

Will be passed context about a dump stage that is about to be detailed.

    $theme->print_section_header($label, $value);

C<$label> will be a the "kind" of dump that is, for detailing specific phases, C<$label> will be "Phase", and C<$value> will be
a simple descriptor for that phase. ( e.g.: Phase , Prune files , or something like that ).

Recommended format is simply

    \n$label$value\n

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.006;
use strict;
use warnings;

package Dist::Zilla::dumpphases::Theme::basic::blue;

our $VERSION = '1.000009';

# ABSTRACT: A blue color theme for dzil dumpphases

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY














use Moo qw( with );

with 'Dist::Zilla::dumpphases::Role::Theme::SimpleColor';









sub color { return 'blue' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::dumpphases::Theme::basic::blue - A blue color theme for dzil dumpphases

=head1 VERSION

version 1.000009

=head1 SYNOPSIS

    dzil dumpphases --color-theme=basic::blue

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::dumpphases::Theme:::basic::blue",
    "does":"Dist::Zilla::dumpphases::Role::Theme::SimpleColor",
    "inherits":"Moo::Object",
    "interface":"class"
}


=end MetaPOD::JSON

=for html <center>
  <img src="http://kentnl.github.io/screenshots/Dist-Zilla-App-Command-dumpphases/theme_basic_blue.png"
       alt="Screenshot"
       width="708"
       height="372"/>
</center>

=head1 METHODS

=head2 C<color>

See L<Dist::Zilla::dumpphases::Role::Theme::SimpleColor/color> for details.

This simply returns C<'blue'>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

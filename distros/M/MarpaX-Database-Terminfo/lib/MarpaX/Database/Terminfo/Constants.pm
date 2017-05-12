use strict;
use warnings FATAL => 'all';

package MarpaX::Database::Terminfo::Constants;
use Exporter 'import';

use constant TERMINFO_BOOLEAN => 0;
use constant TERMINFO_NUMERIC => 1;
use constant TERMINFO_STRING  => 2;

our @EXPORT_TYPES = qw/TERMINFO_BOOLEAN TERMINFO_NUMERIC TERMINFO_STRING/;

our @EXPORT_OK = (@EXPORT_TYPES);
our %EXPORT_TAGS = ('all'       => \@EXPORT_OK,
                    'types'     => \@EXPORT_TYPES);

# ABSTRACT: Terminfo constants

our $VERSION = '0.012'; # VERSION


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Database::Terminfo::Constants - Terminfo constants

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use MarpaX::Database::Terminfo::Constants qw/:all/;

    my $terminfo_boolean = TERMINFO_BOOLEAN;

=head1 DESCRIPTION

This modules export terminfo interface constants.

=head1 EXPORTS

This module is exporting on demand the following tags:

=over

=item types

The constants TERMINFO_BOOLEAN, TERMINFO_NUMERIC and TERMINFO_STRING.

=item all

All of the above.

=back

=head1 SEE ALSO

L<Unix Documentation Project - terminfo|http://nixdoc.net/man-pages/HP-UX/man4/terminfo.4.html#Formal%20Grammar>

L<GNU Ncurses|http://www.gnu.org/software/ncurses/>

=head1 AUTHOR

jddurand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
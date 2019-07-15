package Clipboard;

use 5.006002;

use strict;
use warnings;

use Carp;

our $VERSION = '0.023';

sub import {
    return;
}

{
    my $clipboard;

    sub copy {
	my ( undef, $content ) = @_;
	$clipboard = $content;
	return;
    }

    sub paste {
	return $clipboard;
    }
}

1;

__END__

=head1 NAME

Clipboard - Mock the Clipboard module

=head1 SYNOPSIS

 use lib qw{ inc/mock };
 
 use Clipboard;
 
 Clipboard->copy( 'We have met the enemy and he is us.' );
 say Clipboard->paste();

=head1 DESCRIPTION

This Perl class is private to the C<Games-Sudoku-General> module. It can
be changed or retracted without notice. Documentation is for the benefit
of the author.

This Perl class mocks the CPAN L<Clipboard|Clipboard> module with
sufficient fidelity to test the portion of its functionality used by
C<Games-Sudoku-General>.

=head1 METHODS

This class supports the following public methods:

=head2 copy

 Clipboard->copy( 'Able was I ere I saw Elba.' );

This static method saves its argument, making it available to the
L<paste()|/paste> method.

=head2 import

This method does nothing. It needs to be present because the real
L<Clipboard|Clipboard> module uses it as a hook to determine which
clipboard interface to use.

=head2 paste

 say Clipboard->paste();

This method returns the data from the most-recent call to
L<copy()|/copy>. If C<copy()> has never been called, the return is
undefined.

=head1 SEE ALSO

L<Clipboard|Clipboard>,
L<Games::Sudoku::General|Games::Sudoku::General>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant (wyant at cpan dot org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :

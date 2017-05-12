package Filter::LiterateComments;
$Filter::LiterateComments::VERSION = '0.01';

use strict;
use Filter::Simple \&lperl_to_perl;

=head1 NAME

Filter::LiterateComments - Haskell-style literate comments

=head1 VERSION

This document describes version 0.01 of Filter::LiterateComments,
released November 4, 2004.

=head1 SYNOPSIS

    use Filter::LiterateComments;

    This literate program prompts the user for a number and prints
    the factorial of that number:

    > print "Enter a number: ";
    > chomp( my $l = <STDIN> );
    > print "n! = ", fact( $l ), $/;

    This is the factorial function, using a recursive definition:

    > sub fact ($) {
    >     $_[0] ? ( $_[0] * fact( $_[0]-1 ) ) : 1;
    > }

=head1 DESCRIPTION

This module supports two modes of literate comments, both taken from
the literate Haskell (F<.lhs>) format, with the I<TeX Mode> replaced with
a similar I<POD Mode>.

The relevant documentation from the Haskell 98 Report is reproduced below.

=head2 Quoted Mode

The I<literate comment> convention, first developed by Richard Bird and Philip
Wadler for Orwell, and inspired in turn by Donald Knuth's I<literate
programming>, is an alternative style for encoding Haskell source code.

The literate style encourages comments by making them the default. A line in
which C<< > >> is the first character is treated as part of the program; all
other lines are comment.

The program text is recovered by taking only those lines beginning with
C<< > >>, and replacing the leading C<< > >> with a space.

=head2 POD Mode

An alternative style of literate programming is particularly suitable for use
with POD (Plain Old Documentation) tools. In this convention, only those parts
of the literate program that are entirely enclosed between C<=begin code> ...
C<=end code> delimiters are treated as program text; all other lines are
comment.

More precisely:

=over 4

=item * 

Program code begins on the first line following a line that starts
with C<=begin code>.

=item *

Program code ends just before a subsequent line that starts with
C<=end code>.

=back

It is not necessary to insert additional blank lines before or after these
delimiters, though it may be stylistically desirable.

With POD mode, the program in the L</SYNOPSIS> will look like this:

    use Filter::LiterateComments;

    This literate program prompts the user for a number and prints
    the factorial of that number:

    =begin code

    print "Enter a number: ";
    chomp( my $l = <STDIN> );
    print "n! = ", fact( $l ), $/;

    =end code

    This is the factorial function, using a recursive definition:

    =begin code

    sub fact ($) {
        $_[0] ? ( $_[0] * fact( $_[0]-1 ) ) : 1;
    }

    =end code

=cut

sub lperl_to_perl {
    if ( s{^=begin\s+code\s*$}{=cut\n}mg ) {
        # POD mode
        s{^=end\s+code\s*$}{=pod\n}mg;
    }
    else {
        # Quoted mode
        s{^(> )?}{$1 ? '' : '# '}meg;
    }
}

sub lperl_to_pod {
    my $in_code = 1;

    s[^(> )?][ scalar (
        ($1) ? $in_code ? ''
                        : (($in_code = 1), "=cut\n\n")
             : $in_code ? (($in_code = 0), "\n=pod\n")
                        : ''
    ) ]meg;
}

sub perl_to_lperl {
    # XXX TODO
}

sub pod_to_lperl {
    # XXX TODO
}

1;

=head1 SEE ALSO

The Vim syntax file F<eg/lperl.vim> in this module's source distribution.

The Haskell 98 Report: L<http://haskell.org/definition> -- see section
9.6, I<literate comments>.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

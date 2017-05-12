package Doc::Simply;
BEGIN {
  $Doc::Simply::VERSION = '0.032';
}
# ABSTRACT:  Generate POD-like documentation from embedded comments in JavaScript, Java, C, C++ source

use warnings;
use strict;


1;

__END__
=pod

=head1 NAME

Doc::Simply - Generate POD-like documentation from embedded comments in JavaScript, Java, C, C++ source

=head1 VERSION

version 0.032

=head1 SYNOPSIS

    doc-simply < source.js > documentation.html

    doc-simply --help

=head1 DESCRIPTION

Doc::Simply is bundled with C<doc-simply>, a commandline application that transforms (special) comments into documentation

It is modeled after Plain Old Documentation but it is not an exact mimic

=head1 OVERVIEW

    * The input document is expected to have JavaScript, Java, C, C++-style comments: /* ... */ // ...
    * The output document is HTML
    * The markup style is POD-like, e.g. =head1, =head2, =body, ...
    * The formatting style is Markdown (instead of the usual C<>, L<>, ...)

=head1 Example JavaScript document

    /* 
     * @head1 NAME
     *
     * Calculator - Add 2 + 2 and return the result
     *
     */

    // @head1 DESCRIPTION
    // @body Add 2 + 2 and return the result (which should be 4)

    /*
     * @head1 FUNCTIONS
     *
     * @head2 twoPlusTwo
     *
     * Add 2 and 2 and return 4
     *
     */

    function twoPlusTwo() {
        return 2 + 2; // Should return 4
    }

=head1 SEE ALSO

L<Text::Markdown>

L<http://daringfireball.net/projects/markdown/syntax>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/Doc-Simply/tree/master>

    git clone git://github.com/robertkrimen/Doc-Simply.git Doc-Simply

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


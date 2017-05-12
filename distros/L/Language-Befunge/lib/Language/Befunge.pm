#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use warnings;
use strict;

package Language::Befunge;
# ABSTRACT: a generic funge interpreter
$Language::Befunge::VERSION = '5.000';
use Language::Befunge::Interpreter;

$| = 1;

sub new {
    shift;
    return Language::Befunge::Interpreter->new(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge - a generic funge interpreter

=head1 VERSION

version 5.000

=head1 SYNOPSIS

    use Language::Befunge;
    my $interp = Language::Befunge->new( { file => 'program.bf' } );
    $interp->run_code( "param", 7, "foo" );

    Or, one can write directly:
    my $interp = Language::Befunge->new;
    $interp->store_code( <<'END_OF_CODE' );
    < @,,,,"foo"a
    END_OF_CODE
    $interp->run_code;

=head1 DESCRIPTION

Enter the realm of topological languages!

This module implements the Funge-98 specifications on a 2D field (also
called Befunge). It can also work as a n-funge implementation (3D and
more).

This Befunge-98 interpreters assumes the stack and Funge-Space cells
of this implementation are 32 bits signed integers (I hope your os
understand those integers). This means that the torus (or Cartesian
Lahey-Space topology to be more precise) looks like the following:

              32-bit Befunge-98
              =================
                      ^
                      |-2,147,483,648
                      |
                      |         x
          <-----------+----------->
  -2,147,483,648      |      2,147,483,647
                      |
                     y|2,147,483,647
                      v

This module also implements the Concurrent Funge semantics.

=head1 PUBLIC METHODS

=head2 new( [params] )

Call directly the C<Language::Befunge::Interpreter> constructor. Refer
to L<Language::Befunge::Interpreter> for more information.

=head1 BUGS

Although this module comes with a full set of tests, there may be subtle bugs
remaining - or maybe I misinterpreted the Funge-98 specs. Please report any
bugs or feature requests to "bug-language-befunge at rt.cpan.org", or through
the web interface at
<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Language-Befunge>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

Here is a list of known "bugs", coming from the specs:

=over 4

=item o

About the 18th cell pushed by the C<y> instruction: Funge specs just
tell to push onto the stack the size of the stacks, but nothing is
said about how user will retrieve the number of stacks.

=item o

About the load semantics. Once a library is loaded, the interpreter is
to put onto the TOSS the fingerprint of the just-loaded library. But
nothing is said if the fingerprint is bigger than the maximum cell
width (here, 4 bytes). This means that libraries can't have a name
bigger than C<0x80000000>, ie, more than four letters with the first
one smaller than C<P> (C<chr(80)>).

Since perl is not so rigid, one can build libraries with more than
four letters, but perl will issue a warning about non-portability of
numbers greater than C<0xffffffff>.

=back

=head1 ACKNOWLEDGEMENTS

I would like to thank Chris Pressey, creator of Befunge, who gave a
whole new dimension to both coding and obfuscating.

Thanks also to Matti Niemenmaa for his mycology test suite, available at
L<http://users.tkk.fi/~mniemenm/befunge/mycology.html>

=head1 SEE ALSO

You can find more information on Befunge at
L<http://www.catseye.mb.ca/esoteric/befunge/>.

Our git repository is located at L<https://github.com/jquelin/language-befunge>.

You can also look for information on this module at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Language-Befunge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Language-Befunge>

=item * Open bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Language-Befunge>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

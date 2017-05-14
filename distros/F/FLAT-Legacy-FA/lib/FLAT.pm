package FLAT;
use Carp;

## let subclasses implement a minimal set of closure properties.
## they can override these with more efficient versions if they like.

1;

__END__

=head1 NAME

FLAT - A finite automata base class

=head1 SYNOPSIS

N/A - this file is really just a stub of a super class.  Use FLAT::FA instead. 

=head1 DESCRIPTION

This module is a base finite automata used by NFA and DFA to encompass common functions.  It is probably of no use other than to organize the DFA and NFA modules.

=head1 AUTHOR

Brett D. Estrade - <estrabd AT mailcan DOT com>

=head1 CAVEATS

Currently, all states are stored as labels.  There is also no integrity checking for consistency among the start, final, and set of all states.

=head1 BUGS

I haven't hit any yet :)

=head1 AVAILABILITY

Perl FLaT Project Website at L<http://perl-flat.sourceforge.net/pmwiki>

=head1 ACKNOWLEDGEMENTS

This suite of modules started off as a homework assignment for a compiler class I took for my MS in computer science at the University of Southern Mississippi.  It then became the basis for my MS research. and thesis.

Mike Rosulek has joined the effort, and is heading up the rewrite of Perl FLaT, which will soon be released as FLaT 1.0.

=head1 COPYRIGHT

This code is released under the same terms as Perl.

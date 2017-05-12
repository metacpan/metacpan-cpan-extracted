package LaTeX::TikZ::Tools;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Tools - Miscellaneous tools for LaTeX::TikZ classes.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Mouse::Util::TypeConstraints 'find_type_constraint';

=head1 CONSTANTS

=head2 C<EPS>

The numerical accuracy enforced by L</numeq>, L</numcmp> and L</numround>.
It is currently set to C<1e-10>.

=cut

use constant EPS => 1e-10;

=head1 FUNCTIONS

=head2 C<numeq>

    numeq($x, $y)

Returns true if and only if C<$x> and C<$y> are equal up to L</EPS>.

=cut

sub numeq { abs($_[0] - $_[1]) < EPS }

=head2 C<numcmp>

    numcmp($x, $y)

Returns a negative number, zero, or a positive number when C<$x> is respectively smaller than, equal to, or greater than C<$y> up to L</EPS>.

=cut

sub numcmp { $_[0] < $_[1] - EPS ? -1 : $_[0] > $_[1] + EPS ? 1 : 0 }

=head2 C<numround>

    numround($x)

Returns the closest integer from C<$x> up to L</EPS>.

=cut

sub numround {
 my $x = $_[0];
 my $i = int $x;
 $x + EPS < $i + 0.5 ? $i : $i + 1;
}

=head2 C<type_constraint>

    my $tc = type_constraint($class)

Finds the type constraint for C<$class> by first trying to load the relevant F<.pm> file.

=cut

sub type_constraint {
 my ($class) = @_;

 my $file = $class;
 $file =~ s{::}{/}g;
 $file .= '.pm';
 unless ($INC{$file}) {
  local $@;
  eval {
   local $SIG{__DIE__}; # See LaTeX::TikZ::Meta::TypeConstraint::Autocoerce
   require $file;
  }
 }

 find_type_constraint($class);
}

=head1 SEE ALSO

L<LaTeX::TikZ>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Tools

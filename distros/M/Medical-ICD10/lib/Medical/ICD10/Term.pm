package Medical::ICD10::Term;

use strict;
use warnings;

use Data::Dumper;
use base 'Class::Accessor';

Medical::ICD10::Term->mk_accessors( qw( term description) );

=head1 NAME

Medical::ICD10::Term - ICD10 term object

=head1 METHODS

=head2 description

Returns a scalar containing the terms description.

   my $desc = $O->description;

=cut

=head2 term

Returns a scalar containing the terms name.

   my $term = $O->term;

=cut

=head1 AUTHOR

Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-medical-icd10 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Medical-ICD10>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SOURCE CODE

The source code can be found on github L<https://github.com/spiros/Medical-ICD10>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Medical::ICD10


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Medical-ICD10>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Medical-ICD10>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Medical-ICD10>

=item * Search CPAN

L<http://search.cpan.org/dist/Medical-ICD10/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Spiros Denaxas.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;
package Medical::ICD10::Graph;

use strict;
use warnings;

use Graph::Directed;

=head1 NAME

Medical::ICD10::Graph - ICD10 Graph object

=head1 METHODS

=head2 new 

   Creates a new graph object with a single edge, the root.
   
   Do not use this module directly, this is for the sole purpose
   of manipulating the internal graph that stores the ontology.

=cut

sub new {
   my $class = shift;
   
   my $self = Graph::Directed->new();
   $self->add_vertex( 'root' );
   $self->set_vertex_attribute('root', 'description', 'This is the root node.' );
   
   return $self;
}


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
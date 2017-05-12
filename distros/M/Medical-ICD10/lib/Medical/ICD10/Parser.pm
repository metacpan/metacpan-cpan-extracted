package Medical::ICD10::Parser;

use strict;
use warnings;

use Data::Dumper;
use Text::CSV;

use Medical::ICD10::Graph;

=head1 NAME

Medical::ICD10::Parser - ICD10 Parser object

=head1 METHODS

=head2 new

   Create a new parser object. 
   
   Do not use directly.

=cut

sub new {
   my $class = shift;
   my $self  = { };
   
   $self->{csv} = 
      Text::CSV->new({ 'sep_char' => "\t" });
   
   $self->{csv}->column_names( qw( icd description) );
      
   $self->{g} =
      Medical::ICD10::Graph->new;
   
   return bless $self, $class;
      
}

=head2 parse

   The main parser function. Accepts a tab separated file of ICD10 codes
   along with their descriptions and parses it.

   Returns true on success and undef on failure.

=cut

sub parse {
   my $self     = shift;
   my $filename = shift;
   
   # UTF8 is needed as there is a single term with an accept character
   # in the term description:
   # M91.1	Juvenile osteochondrosis of head of femur [Legg-Calvé-Perthes]
   
   open my $io, "<:encoding(utf8)", $filename
      || die "$filename: $!";

   ##
   ## First pass: add all the nodes
      
   while ( my $rh = $self->{csv}->getline_hr( $io) ) {
      my $icd    = $rh->{icd};
      $self->{g}->add_vertex( $rh->{icd} );
      $self->{g}->set_vertex_attribute( $rh->{icd}, 'description', $rh->{description} );
   }
   
   ##   
   ## Second pass: add all the edges
   
   my @vertices = $self->{g}->vertices;
   
   foreach my $vertex ( @vertices ) {
         my $parent = $self->_get_parent( $vertex );
         $self->{g}->add_edge( $parent, $vertex );         
   }

   return $self->{g};
     
}

=head2 _get_parent

   Internal parser function used to discover the parent
   of each node. 
   
   Do not use directly.

=cut

sub _get_parent {
   my $self = shift;
   my $term = shift;

   if ( $term eq 'root' ) {
      return 'root';
   }

   my $length = length( $term );
   
   if ( $length == 5 ){
      return substr( $term, 0, 4 );
   } 
   
   elsif ( $length == 4){
      return substr($term, 0, 3);
   } 
   
   elsif ( $length == 3 ) { 
      return 'root'      
   }
   
}

=head2 graph

Returns the internal Medical::ICD10::Graph object.

=cut

sub graph {
   my $self = shift;
   return $self->{g};
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
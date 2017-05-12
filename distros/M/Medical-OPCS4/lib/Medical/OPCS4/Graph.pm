use strict;
use warnings;

package Medical::OPCS4::Graph;
# ABSTRACT: A directed graph class.

use Graph::Directed;

=head1 NAME

Medical::OPCS4::Graph - OPCS4 Graph object

=head1 METHODS

=head2 new 

   Creates a new graph object with a single edge, the root.
   
   Do not use this module directly, this is for the sole purpose
   of manipulating the internal graph that stores the ontology.

=cut

sub new {
   my $self = Graph::Directed->new();
   $self->add_vertex( 'root' );
   $self->set_vertex_attribute('root', 'description', 'This is the root node.' );
   
   return $self;
}

1;
use strict;
use warnings;

package Medical::OPCS4;

use Data::Dumper;

use Medical::OPCS4::Parser;
use Medical::OPCS4::Term;

=head1 NAME

Medical::OPCS4 - OPCS4 Wrapper module

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

OPCS-4 is an abbreviation of the Office of Population, Censuses and Surveys Classification of 
Surgical Operations and Procedures (4th revision)[1]. It translates operations, procedures 
and interventions carried out on a patient during an episode of health care in the NHS into 
alphanumeric code usually done by trained health care professionals working in an area called
clinical coding. As such it is comparable with ICD-10, which is used for coding diagnoses in
the same setting. There are some areas of overlapping between ICD-10 and OPCS-4. for example
both feature codes for the delivery of children. In the U.K. it is recommended clinical coders use
the OPCS-4. codes for these procedures.

This modules provides a wrapper around the NHS CFH OPCS-4 distribution which can be 
found here L<http://www.connectingforhealth.nhs.uk/systemsandservices/data/clinicalcoding/codingstandards/opcs4>

    my $O = Medical::OPCS4->new();
    $O->parse('./t/testdata.txt');
    my $Term = $O->get_term('O16');
    my $Parent = $O->get_parent_term( 'O16.1' );
    my $ra_ch = $O->get_child_terms( 'O16' );

The GitHub page for this module is here L<https://github.com/spiros/Medical-OPCS4>

=head1 METHODS

=head2 new

Creates a new instance of the module.

   my $O = Medical::OPCS4->new();

=cut

sub new {
   my $class = shift;
   my $self  = { };   
   
   $self->{parser} = 
      Medical::OPCS4::Parser->new;
   
   return bless $self, $class;      
}

=head2 parse

Parses the flat file containing the OPCS4 codes.

   $O->parse( "/path/to/tsv/file/with/codes.txt" );

This method returns true on success and undef on failure.

=cut

sub parse {
   my $self     = shift;
   my $filename = shift;
   
   unless ( -e $filename && -r $filename ) {
      die "Error opening/loading $filename";
   }
   
   # Filename exists, lets try to parse it
   # using the parser

   return $self->{parser}->parse( $filename );
      
}

=head2 get_term

   my $Term = $O->get_term( 'A809' );

This method returns an Medical::OPCS4::Term object and undef on error.

=cut

sub get_term {
   my $self = shift;
   my $term = shift;
   
   return undef if ( ! defined $term );
   
   return undef if ( !$self->{parser}->graph->has_vertex( $term ) );
   
   my $description = 
      $self->{parser}->graph->get_vertex_attribute( $term, 'description' );
   
   return Medical::OPCS4::Term->new(
      {
         'term'        => $term,
         'description' => $description,
      } );
      
}


=head2 get_all_terms

   my $ra_all_terms = $O->get_all_terms;

Returns a reference to an array of Medical::OPCS4::Term objects with all terms
in the current file distribution.

This method returns undef on error.

=cut

sub get_all_terms {
   my $self = shift;
   
   my @vertices = 
      $self->{parser}->graph->vertices;
   
   my @out;
   
   foreach my $vertex ( @vertices ) {
      
      my $description = 
         $self->{parser}->graph->get_vertex_attribute( $vertex, 'description');
      
      push @out, Medical::OPCS4::Term->new( 
         { 'term'        => $vertex, 
           'description' => $description } );
   }

   return \@out;

}

=head2 get_all_terms_hashref

   my $rh_all_terms = $O->get_all_terms_hashref;
   
Returns a reference to a hash with all terms in the current file distribution. The keys of
the hash are the OPCS4 terms and the values are the textual descriptions.

This method returns undef on error.

=cut

sub get_all_terms_hashref {
   my $self = shift;
   
   my @vertices = 
      $self->{parser}->graph->vertices;
   
   my $rh_out;

   foreach my $vertex ( @vertices ) {

      my $description = 
         $self->{parser}->graph->get_vertex_attribute( $vertex, 'description');

      $rh_out->{ $vertex } = $description;

   }
   
   return $rh_out;
      
}

=head2 get_parent_term

   my $ParentTerm = $O->get_parent_term( 'A809' );
   
or

   my $ParentTerm = $O->get_parent_term( $Term );

Returns the immediate parent term of a given term as an Medical::OPCS4::Term object. 
This method accepts both a scalar with the term name 
and a Medical::OPCS4::Term object as input

This method returns undef on error.

=cut

sub get_parent_term {
   my $self = shift;
   my $term = shift;
   
   my $search_term;
   
   if ( ref $term && ref $term eq 'Medical::OPCS4::Term' ) {
      $search_term = $term->term;
   } else {
       $search_term  = $term;
   }
   
   return undef 
      if ( !$self->{parser}->graph->has_vertex( $search_term ) );
   
   return undef
      if ( !$self->{parser}->graph->is_predecessorful_vertex( $search_term) );

   my @predecessors =
      $self->{parser}->graph->predecessors( $search_term );
   
   my $predecessor = $predecessors[ 0 ];
   
   my $predecessor_description =
      $self->{parser}->graph->get_vertex_attribute( $predecessor, 'description' );
      
   return Medical::OPCS4::Term->new(
      {
         'term'        => $predecessor,
         'description' => $predecessor_description,
      } );
      
}

=head2 get_parent_term_string

   my $ParentTerm = $O->get_parent_term_string( 'A809' );
   
or

   my $ParentTerm = $O->get_parent_term_string( $Term );

Returns the immediate parent term of a given term as a scalar. 
This method accepts both a scalar with the term name and a 
Medical::OPCS4::Term object as input.

This method returns undef on error.

=cut

sub get_parent_term_string {
   my $self = shift;
   my $term = shift;
   
   return undef 
      unless ( defined $term );
   
   my $predecessor =
      $self->get_parent_term( $term );
   
   return $predecessor->term;
   
}

=head2 get_parent_terms

   my $ra_parent_terms = $O->get_parent_terms( 'A809' );
   
or

   my $ra_parent_terms = $O->get_parent_terms( $Term );

Returns a reference to an array of Medical::OPCS4::Term objects of all parent terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::OPCS4::Term object as input.

This method returns undef on error.

=cut

sub get_parent_terms {
   my $self = shift;
   my $term = shift;

   return undef
      unless defined ( $term );

   my $search_term;
   
   if ( ref $term && ref $term eq 'Medical::OPCS4::Term' ) {
      $search_term = $term->term;
   } else {
       $search_term = $term;
   }
   
   return undef 
      if ( !$self->{parser}->graph->has_vertex( $search_term ) );
   
   return undef
      if ( !$self->{parser}->graph->is_predecessorful_vertex( $search_term) );

   my $ra_out = [ ];

   my @predecessors =
      $self->{parser}->graph->all_predecessors( $search_term );
   
   foreach my $term ( @predecessors ) {
      
      my $predecessor_description =
         $self->{parser}->graph->get_vertex_attribute( $term, 'description' );
      
      my $obj = 
         Medical::OPCS4::Term->new(
            {
               'term'         => $term,
               'description'  => $predecessor_description,
            });
      
      push( @$ra_out, $obj );
      
   }
   
   return $ra_out;
   
}

=head2 get_parent_terms_string 

   my $ra_parent_terms = $O->get_parent_terms_string( 'A809' );
   
or

   my $ra_parent_terms = $O->get_parent_terms_string( $Term );

Returns a reference to an array of scalars of all parent terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::OPCS4::Term object as input.

This method returns undef on error.

=cut

sub get_parent_terms_string {
   my $self = shift;
   my $term = shift;
   
   return undef
      unless ( defined $term );
   
   my $ra_parent_terms = 
      $self->get_parent_terms( $term );
   
   return undef
      unless ( defined $ra_parent_terms && scalar(@$ra_parent_terms) );
   
   my $ra_out = [ ];

   foreach my $term ( @$ra_parent_terms ) {
      push ( @$ra_out, $term->term );
   }
   
   return $ra_out;
   
}


=head2 get_child_terms

   my $ra_child_terms = $O->get_child_terms( 'A809' );
   
or

   my $ra_child_terms = $O->get_child_terms( $Term );

Returns a reference to an array of Medical::OPCS4::Term objects of all child terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::OPCS4::Term object as input.

This method returns undef on error.

=cut

sub get_child_terms {
   my $self = shift;
   my $term = shift;
   
   return undef
      unless ( defined $term );
   
   my $search_term;

   if ( ref $term && ref $term eq 'Medical::OPCS4::Term' ) {
     $search_term = $term->term;
   } else {
       $search_term = $term;
   }
   
   return undef 
      if ( !$self->{parser}->graph->has_vertex( $search_term ) );

   return undef
      if ( !$self->{parser}->graph->is_successorful_vertex( $search_term) );
      
   my @successors =
       $self->{parser}->graph->all_successors( $search_term );

   my $ra_out = [ ];

    foreach my $term ( @successors ) {

       my $successor_description =
          $self->{parser}->graph->get_vertex_attribute( $term, 'description' );

       my $obj = 
          Medical::OPCS4::Term->new(
             {
                'term'         => $term,
                'description'  => $successor_description,
             });

       push( @$ra_out, $obj );

    }

    return $ra_out;   
}


=head2 get_child_terms_string 

   my $ra_child_terms = $O->get_child_terms_string( 'A809' );
   
or

   my $ra_child_terms = $O->get_child_terms_string( $Term );

Returns a reference to an array of scalars of all child terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::OPCS4::Term object as input.

This method returns undef on error.

=cut

sub get_child_terms_string {
   my $self = shift;
   my $term = shift;
   
   return undef
      unless ( defined $term );
   
   my $ra_successor_terms =
      $self->get_child_terms( $term );
   
   return $self->_format_output( $ra_successor_terms, 'string' );
   
}

=head2 _format_output 

Internal method used to format the output from different methods. Do not
use this method directly.

=cut

sub _format_output {
   my $self    = shift;
   my $ra_data = shift;
   my $mode    = shift;
   
   my $ra_out = [ ];
   
   if ( $mode eq 'string' ) {
      
      foreach my $term ( @$ra_data ) {
         push( @$ra_out, $term->term );
      }
      
   } 
   
   elsif ( $mode eq 'objects' ) {

      foreach my $term ( @$ra_data ) {
         
         my $description =
             $self->{parser}->graph->get_vertex_attribute( $term, 'description' );

          my $obj = 
             Medical::OPCS4::Term->new(
                {
                   'term'         => $term,
                   'description'  => $description,
                });

          push( @$ra_out, $obj );
               
      }
            
   }
   
   return $ra_out;
   
}

1; # End of Medical::OPCS4


1;

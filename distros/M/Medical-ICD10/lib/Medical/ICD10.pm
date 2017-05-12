package Medical::ICD10;

use warnings;
use strict;

use Data::Dumper;

use Medical::ICD10::Parser;
use Medical::ICD10::Term;

=head1 NAME

Medical::ICD10 - ICD10 Wrapper module

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

The International Statistical Classification of Diseases and Related Health Problems 10th 
Revision (ICD-10) is a coding of diseases and signs, symptoms, abnormal findings, 
complaints, social circumstances and external causes of injury or diseases, as classified by 
the World Health Organization. (WHO). The code set allows more than 14,400 different codes and 
permits the tracking of many new diagnoses.

You can find more information about ICD10 at: L<http://www.who.int/classifications/icd/en/>

The NHS provides the ICD10 codes as a flat tab separated file which can be obtained from the Connecting For
Health Data Standars helpdesk at: L<http://www.connectingforhealth.nhs.uk/systemsandservices/data/clinicalcoding/codingstandards/icd-10/icd10_prod>

This module is designed to parse that file and provide a wrapper around the ICD10 
classification codes.

   use Medical::ICD10;
   
   my $MICD = Medical::ICD10->new();
   
   $MICD->parse( "/path/to/tsv/file/with/codes.txt" );
   
   ## Get an individual term
   
   my $Term = $MICD->get_term( 'A809' );
   my $description = $Term->description; # "Acute poliomyelitis, unspecified"
   
   ## Get the terms parent
   
   my $ParentTerm = $MICD->get_parent_term_string( 'A809' );
      
   ## Get all the parents from the term
   
   my $ra_parent_terms = $MICD->get_parent_terms( 'A809' );
   my $ra_parent_terms = $MICD->get_parent_terms_string( 'A803' );
      
   ## Get all the children of the term
   
   my $ra_child_terms = $MICD->get_child_terms_string( 'A809' );
   my $ra_child_terms = $MICD->get_child_terms( 'B27' );

=head1 METHODS

=head2 new

Creates a new instance of the module.

   my $MICD = Medical::ICD10->new();

=cut

sub new {
   my $class = shift;
   my $self  = { };   
   
   $self->{parser} = 
      Medical::ICD10::Parser->new;
   
   return bless $self, $class;      
}

=head2 parse

Parses the flat file containing the ICD10 codes.

   $MICD->parse( "/path/to/tsv/file/with/codes.txt" );

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

   my $Term = $MICD->get_term( 'A809' );

This method returns an Medical::ICD10::Term object and undef on error.

=cut

sub get_term {
   my $self = shift;
   my $term = shift;
   
   return undef if ( ! defined $term );
   
   return undef if ( !$self->{parser}->graph->has_vertex( $term ) );
   
   my $description = 
      $self->{parser}->graph->get_vertex_attribute( $term, 'description' );
   
   return Medical::ICD10::Term->new(
      {
         'term'        => $term,
         'description' => $description,
      } );
      
}


=head2 get_all_terms

   my $ra_all_terms = $MICD->get_all_terms;

Returns a reference to an array of Medical::ICD10::Term objects with all terms
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
      
      push @out, Medical::ICD10::Term->new( 
         { 'term'        => $vertex, 
           'description' => $description } );
   }

   return \@out;

}

=head2 get_all_terms_hashref

   my $rh_all_terms = $MICD->get_all_terms_hashref;
   
Returns a reference to a hash with all terms in the current file distribution. The keys of
the hash are the ICD10 terms and the values are the textual descriptions.

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

   my $ParentTerm = $MICD->get_parent_term( 'A809' );
   
or

   my $ParentTerm = $MICD->get_parent_term( $Term );

Returns the immediate parent term of a given term as an Medical::ICD10::Term object. 
This method accepts both a scalar with the term name 
and a Medical::ICD10::Term object as input

This method returns undef on error.

=cut

sub get_parent_term {
   my $self = shift;
   my $term = shift;
   
   my $search_term;
   
   if ( ref $term && ref $term eq 'Medical::ICD10::Term' ) {
      $search_term = $term->term;
   } else {
       $search_term = $term;
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
      
   return Medical::ICD10::Term->new(
      {
         'term'        => $predecessor,
         'description' => $predecessor_description,
      } );
      
}

=head2 get_parent_term_string

   my $ParentTerm = $MICD->get_parent_term_string( 'A809' );
   
or

   my $ParentTerm = $MICD->get_parent_term_string( $Term );

Returns the immediate parent term of a given term as a scalar. 
This method accepts both a scalar with the term name and a 
Medical::ICD10::Term object as input.

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

   my $ra_parent_terms = $MICD->get_parent_terms( 'A809' );
   
or

   my $ra_parent_terms = $MICD->get_parent_terms( $Term );

Returns a reference to an array of Medical::ICD10::Term objects of all parent terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::ICD10::Term object as input.

This method returns undef on error.

=cut

sub get_parent_terms {
   my $self = shift;
   my $term = shift;

   return undef
      unless defined ( $term );

   my $search_term;
   
   if ( ref $term && ref $term eq 'Medical::ICD10::Term' ) {
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
         Medical::ICD10::Term->new(
            {
               'term'         => $term,
               'description'  => $predecessor_description,
            });
      
      push( @$ra_out, $obj );
      
   }
   
   return $ra_out;
   
}

=head2 get_parent_terms_string 

   my $ra_parent_terms = $MICD->get_parent_terms_string( 'A809' );
   
or

   my $ra_parent_terms = $MICD->get_parent_terms_string( $Term );

Returns a reference to an array of scalars of all parent terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::ICD10::Term object as input.

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

   my $ra_child_terms = $MICD->get_child_terms( 'A809' );
   
or

   my $ra_child_terms = $MICD->get_child_terms( $Term );

Returns a reference to an array of Medical::ICD10::Term objects of all child terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::ICD10::Term object as input.

This method returns undef on error.

=cut

sub get_child_terms {
   my $self = shift;
   my $term = shift;
   
   return undef
      unless ( defined $term );
   
   my $search_term;

   if ( ref $term && ref $term eq 'Medical::ICD10::Term' ) {
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
          Medical::ICD10::Term->new(
             {
                'term'         => $term,
                'description'  => $successor_description,
             });

       push( @$ra_out, $obj );

    }

    return $ra_out;   
}


=head2 get_child_terms_string 

   my $ra_child_terms = $MICD->get_child_terms_string( 'A809' );
   
or

   my $ra_child_terms = $MICD->get_child_terms_string( $Term );

Returns a reference to an array of scalars of all child terms
of a given term.  This method accepts both a scalar with the term name and
a Medical::ICD10::Term object as input.

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
             Medical::ICD10::Term->new(
                {
                   'term'         => $term,
                   'description'  => $description,
                });

          push( @$ra_out, $obj );
               
      }
            
   }
   
   return $ra_out;
   
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

1; # End of Medical::ICD10

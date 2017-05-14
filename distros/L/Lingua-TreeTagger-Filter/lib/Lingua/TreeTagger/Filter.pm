#!/usr/bin/perl
package Lingua::TreeTagger::Filter;

use Moose;
use Carp;

use Lingua::TreeTagger;
use Lingua::TreeTagger::Filter::Element;
use Lingua::TreeTagger::Filter::Result;


#===============================================================================
# public
#===============================================================================

has 'sequence' => (
    is       => 'ro',
    isa      => 'ArrayRef[Lingua::TreeTagger::Filter::Element]',
    default  => sub { [] },
    reader   => 'get_sequence',
    writer   => '_set_sequence',
);

#===============================================================================
# Object construction hooks.
#===============================================================================

# Hook to handle entry in line.
around BUILDARGS => sub {

  my $original_buildargs = shift;
  my $class              = shift;
  my $string         = $_[0];

  # Classical creation.
  if ( !defined($string) || $string eq 'sequence') {
    my %param_out = @_;
    return $class->$original_buildargs( %param_out );
  }
  # Creation with a sequence in line.
  else{
    # Initialization.
    my @array_element;
    my @array_return;
    
    @array_element = split( /#/ , $string );
    
    foreach my $element (@array_element) {
    
      # HASH to gather element's parameters.
      my %param;
      
      # Split element's part.
      my @array_values = split( /=| / , $element );
      # Completing the parameters.
      for (my $i = 0; $i < @array_values; $i += 2) {
        $param{$array_values[$i]} = $array_values[$i+1];
      }
      # Adds the element to the sequence.
      push( @array_return , Lingua::TreeTagger::Filter::Element->new(%param)); 
    }
    return $class->$original_buildargs( {sequence => \@array_return} );
   
  }  
};

#===============================================================================
# Public methods
#===============================================================================

#-----------------------------------------------------------------------------
# function apply
#-----------------------------------------------------------------------------
# Synopsis:          apply a lingua::TreeTagger::Filter object on a lingua::
#                    TreeTagger::TaggedText object. This function will write
#                    the position of all matching sequences and return it in
#                    a lingua::TreeTagger::Filter::Result object
# attributes:        - a lingua::TreTagger::TaggedText object
#                    - optionnaly a zero ( when called by apply_no_overlap)        
# Return values:     - a lingua::TreeTagger::Filter::Result object
#-----------------------------------------------------------------------------

sub apply {


    my ( $self, $tagged_text, $putback ) = @_;
    
    # Argument control.
    croak "Attempt to call apply() without any arguments"
      if  !defined($tagged_text);
    croak "Attempt to call apply() without a taggedtext_object"
      if  !($tagged_text->isa('Lingua::TreeTagger::TaggedText'));
    # Empty filter.
    my $filter_test_ref = $self->get_sequence();
    croak "Attempt to call apply() with an empty filter"
      if  !( scalar(@$filter_test_ref) );
    # Empty tagged text.
    my $text_test_ref = $tagged_text->sequence();
    croak "Attempt to call apply() with an empty tagged text"
      if  !( scalar(@$text_test_ref) );

    # Initialization.
    my $filter_index           = 0;
    my $start_position         = 0;
    my $sequence_length        = 0;
    my $counter_current_filter = 0;
    
    # Creating the controlling variables.
    my $lemma;
    my $original;
    my $tag;    

    $putback = 1 if !defined $putback;
    # Creating the new result object.
    my $result = Lingua::TreeTagger::Filter::Result->new(
        hits       => [],
        taggedtext => $tagged_text,
        put_back   => $putback,
    );

    # Extracting the tokens from taggedtext.
    my $array_ref_token = $tagged_text->sequence();
    
    my $text_length = scalar(@$array_ref_token);

    for ( my $i = 0 ; $i < $text_length ; $i++ ) {

        my $current_token = $array_ref_token->[$i];

        # Compare the current filter element to the current token.
        my $ref_return_hash = $self->_compare(
            'filter_index'           => $filter_index,
            'start_position'         => $start_position,
            'sequence_length'        => $sequence_length,
            'token'                  => $current_token,
            'result'                 => $result,
            'counter_current_filter' => $counter_current_filter,
            'text_length'            => $text_length,
            'array_ref_token'        => $array_ref_token,
        );

        # Update the values.
        $filter_index           = $ref_return_hash->{filter_index};
        $start_position         = $ref_return_hash->{start_position};
        $sequence_length        = $ref_return_hash->{sequence_length};
        $counter_current_filter = $ref_return_hash->{counter_current_filter};
        
        my $sequence_ref = $self->get_sequence();
        # Match but end of the tagged text.
        if ( $sequence_length && $i == $text_length-1 &&
          $counter_current_filter >= 1 &&
          $filter_index == @$sequence_ref -1 ){
        
          # Creating the new hit.
            $result->add_element(
                begin_index     => $start_position,
                sequence_length => $sequence_length,
            );
            
            $start_position++;
            $sequence_length        = 0;
            $counter_current_filter = 0;
            $filter_index           = 0;  
        }
        
        if ( $filter_index == 0 && $sequence_length == 0 ) {
            $i = $start_position - 1;
        }
        else {
          $i = $start_position + $sequence_length - 1;
          
          $i = 0 if $i < 0;
        }
    }
    return ($result);
    
    
}


#-----------------------------------------------------------------------------
# function apply_no_overlap
#-----------------------------------------------------------------------------
# Synopsis:          This sub-program is a wrapper for the apply method. It 
#                    provides a way to use apply without overlapping, that means
#                    that after a match the filter will continue the scan from
#                    the last non matching element. 
# attributes:        - a lingua::TreTagger::TaggedText object
#                    - optionnaly a zero ( apply without put back)        
# Return values:     - a lingua::TreeTagger::Filter::Result object
#-----------------------------------------------------------------------------

sub apply_no_overlap {


    my ( $self, $tagged_text ) = @_;
    
    return $self->apply( $tagged_text, 0 );
    
}

#-----------------------------------------------------------------------------
# function substitute
#-----------------------------------------------------------------------------
# Synopsis:          apply a lingua::TreeTagger::Filter object on a lingua::
#                    TreeTagger::TaggedText object. For each matching sequence
#                    it will substitute the original tokens value by the value
#                    of the sub_attributes if this one is not defined the tokens
#                    attribute won't be modified.
# attributes:        - a lingua::TreTagger::TaggedText object
# Return values:     - a lingua::TreTagger::TaggedText object
#-----------------------------------------------------------------------------

sub substitute {

  my ( $self, $tagged_text) = @_;
  
    # Argument control.
    croak "Attempt to call substitute() without any arguments"
      if  !defined($tagged_text);
    croak "Attempt to call substitute() without a taggedtext_object"
      if  !($tagged_text->isa('Lingua::TreeTagger::TaggedText'));
    # Empty filter.
    my $filter_test_ref = $self->get_sequence();
    croak "Attempt to call substitute() with an empty filter"
      if  !( scalar(@$filter_test_ref) );
     # Empty tagged text.
    my $text_test_ref = $tagged_text->sequence();
    croak "Attempt to call substitute() with an empty tagged text"
      if  !( scalar(@$text_test_ref) );
  
  my $result = $self->apply( $tagged_text );
  
  # Extract the matching sequence.
  my $array_hits_ref = $result->get_hits;
  
  # Extract the filter element.
  my @array_filter = @{$self->get_sequence()};
  # Extract the token sequence.
  my @array_sequence = @{$tagged_text->sequence()};
  
  # For each matching sequence.
  foreach my $hit (@$array_hits_ref) {
  
    # Extract the index of the current sequence.
    my $begin_index = $hit->get_begin_index();
    # Extract the length of the current sequence.
    my $sequence_length = $hit->get_sequence_length();
    # Initialization.
    my $filter_index = 0;
    my $current_filter_counter = 0;
    
    # For each element of the matching sequence.
    for (my $i=0; $i < $sequence_length; $i++) {
    
      # Extract the quantifier of the current filter element.
      my $quantifier = $array_filter[$filter_index]->get_quantifier();
      
      # To handle the {} quantifiers.
      my $control_limit = 0;
      my @array_limit = split( /[^0-9]/, $quantifier );
      if ( defined($array_limit[1]) && $array_limit[1] > 1 ) {
        
        $control_limit++;
        
      }
      
      # Quantifier = 1.
      if ( $quantifier eq "1") {
      
        # Substitution method.
        my ($control_substitution, $token) =
          $self->_substitute_elements( $array_sequence[$begin_index + $i], 
          $array_filter[$filter_index] );
          
        # Insert the new token in the sequence.
        $array_sequence[$begin_index + $i] = $token;
        # Next filter element
        $filter_index++;
      
      } 
      
      # Quantifier allows more than 1.
      elsif ( $control_limit == 1 || $quantifier > 1 || $quantifier eq "*" || 
        $quantifier eq "+") {
        
        # Substitution method.
        my ($control_substitution, $token) = $self->_substitute_elements( 
          $array_sequence[$begin_index + $i], $array_filter[$filter_index] 
        );
        # Substitution match.
        if ( $control_substitution) {
        
          # Insert the new token in the sequence.
          $array_sequence[$begin_index + $i] = $token;
          $current_filter_counter++;
          
        }
        # Substitution doesn't match.
        else {
        
          $filter_index++;
          $i--;
          $current_filter_counter = 0;
        
        }
      }
      
      # No match, tries with the next filter element.
      else {
      
        $filter_index++;
        $i--;
        $current_filter_counter = 0;
        
      }
    
    
    }
  
  
  
  }
  
  # Create a copy with the new taggedtext.
  my $new_tagged_text = $tagged_text;
  my $sequence_ref   = $new_tagged_text->sequence();
  # Replace brutally the sequence.
  @$sequence_ref = @array_sequence;
  
  return($new_tagged_text);
  

}

#-----------------------------------------------------------------------------
# function add_element
#-----------------------------------------------------------------------------
# Synopsis:          add an element to the sequence (creating a
#                    Lingua::TreeTagger::Filter::Element object or adding
#                    one created earlier)
# parameters:        - element_object (Lingua::TreeTagger::Filter::Element)
#                    - OR (to create ne new element object)
#                     - original (str) (if ommited,argument initialized to the
#                       values '.' that means all will match)
#                     - tag (str) (if ommited,argument initialized to the
#                       values '.' that means all will match)
#                     - lemma (str) (if ommited,argument initialized to the
#                       values '.' that means all will match)
#                     - quantifier (str but must be part of the perl quantifier)
#                     - For all these parameters you can define the corresponding
#                       anchor_attribute parameter (for example anchor_original), 
#                       only accepted value = 0
#                     - For all these parameters you can define the corresponding
#                       sub_attribute parameter (for example sub_original), 
#                       a string.
#                    - position (optional parameter, if defined the element
#                      will be inserted in the sequence with the corresponding
#                      index. If not defined the element will be added at the end
#                      of the sequence (as a PUSH))
# Return values:     - 1 if ok otherwise a string with an error message
#-----------------------------------------------------------------------------

sub add_element {

    my ( $self, %param ) = @_;
    my $element;

    # Case of an existing element.
    if ( defined( $param{element_object} ) ) {
        
        # Argument control.
        croak "Attempt to call add_element() with incorrect element object"
          if !(
            $param{element_object}->isa('Lingua::TreeTagger::Filter::Element')
        );
        $element = $param{element_object};
    }

    # Case of creating the new object/text.
    else {
        $element = Lingua::TreeTagger::Filter::Element->new( \%param );
    }

    # Extracting the members of current sequence.
    my $ref_tab_element = $self->get_sequence();

    # Converting the reference to an array.
    my @tab_element = @$ref_tab_element;

    # Index defined.
    if ( defined( $param{position} ) ) {
    
        # Control that position is numeric.
        { 
          no warnings "numeric"; 
          if( $param{position} ne "0" && $param{position} == 0 ){
            croak "Attempt to call add_element() with a non-numeric argument";
          }
        }
          
        my @work_array = @tab_element;

        # Test the requested index.
        if ( $param{position} > @work_array ) {

            croak "add_element(), out of index";
        }
        else {

            # Composing the new tab.
            for ( my $i = 0 ; $i <= scalar @work_array ; $i++ ) {

                if ( $i == $param{position} ) {
                    $tab_element[$i] = $element;
                }
                elsif ( $i > $param{position} ) {
                    $tab_element[$i] = $work_array[ $i - 1 ];
                }
            }
        }

    }

    # Index undefined --> add at the end of sequence.
    else {

        # Adding the new element.
        push( @tab_element, $element );
    }

    # Modifing the attribute.
    $self->_set_sequence( \@tab_element );
    return (1);

}

#-----------------------------------------------------------------------------
# function remove_element
#-----------------------------------------------------------------------------
# Synopsis:          removes an element from the sequence. This element is
#                    pointed by his index value.
# attributes:        - index_value (int)
# Return values:     - the removed object
#-----------------------------------------------------------------------------

sub remove_element {

    my ( $self, $index_value ) = @_;
    
    # Argument control.
    croak "Attempt to call remove_element() without argument"
      if !defined( $index_value );
    # Control that argument is numeric.
    { 
      no warnings "numeric"; 
      if( $index_value ne "0" && $index_value == 0 ){
        croak "Attempt to call remove_element() with a non-numeric argument";
      }
    }

    my $ref_tab_element = $self->get_sequence();
    my @new_tab_element;
    my $controle = 1;
    my $counter  = 0;
    my $returned_element;

    foreach my $element (@$ref_tab_element) {

        if ( $index_value != $counter ) {

            push( @new_tab_element, $element );

        }
        else {

            $controle         = 0;
            $returned_element = $element;

        }
        $counter++;

    }

    if ($controle) {
        croak ("the asked element is not part of the sequence \n");
    }
    else {

        # Modifing the attribute.
        $self->_set_sequence( \@new_tab_element );
        return ($returned_element);
    }

}

#-----------------------------------------------------------------------------
# function init_with_string
#-----------------------------------------------------------------------------
# Synopsis:          receive the entire filter in one line formulation.
#                    This function will split it and construct the corresponding
#                    filter elements and filter.
# attributes:        - a string
# Return values:     - 1 if ok otherwise a string with an error message
#-----------------------------------------------------------------------------

sub init_with_string {

  my ( $self, $string ) = @_;
  
  # Argument control.
  croak "Attempt to call init_with_string() without argument"
    if !defined( $string );
    
  # Initialization.
  my @array_element;
  
  @array_element = split( /#/ , $string );
  
  $self->_set_sequence([]);
  
  foreach my $element (@array_element) {
  
    # HASH to gather element's parameters.
    my %param;
    
    # Split element's part.
    my @array_values = split( /=| / , $element );
    # Completing the parameters.
    for (my $i = 0; $i < @array_values; $i += 2) {
      $param{$array_values[$i]} = $array_values[$i+1];
    }
    $self->add_element(%param); 
  }
  
  
}

#-----------------------------------------------------------------------------
# function extract_ngrams
#-----------------------------------------------------------------------------
# Synopsis:          extracts the n-grams from a given taggedtext
# attributes:        - ref to a taggedtext
#                    - length of the sequence
# Return values:     - a Lingua::TreeTagger::Filter::Result object
#-----------------------------------------------------------------------------

sub extract_ngrams {

  my ( $self, $tagged_text, $seq_length ) = @_;
  
  # Argument control.
  croak "Attempt to call extract_ngrams() without any arguments"
    if  !defined($tagged_text);
  croak "Attempt to call extract_ngrams() without a taggedtext_object"
    if  !($tagged_text->isa('Lingua::TreeTagger::TaggedText'));
  # Empty tagged text.
  my $text_test_ref = $tagged_text->sequence();
  croak "Attempt to call extract_ngrams() with an empty tagged text"
    if  !( scalar(@$text_test_ref) );
  # Control that argument is numeric.
  { 
    no warnings "numeric"; 
    if( $seq_length ne "0" && $seq_length == 0 ){
      croak "Attempt to call extract_ngrams() with a non-numeric argument";
    }
  }
  
  # Creating the new result object.
  my $result = Lingua::TreeTagger::Filter::Result->new(
      'hits'       => [],
      'taggedtext' => $tagged_text,
  );
  
  # Calculating the number of tokens.
  my $array_ref_token = $tagged_text->sequence();
  
  my $text_length = @$array_ref_token;
  
  # Loop to extract the n-grams.
  for (
    my $begin_index = 0; 
    $begin_index < $text_length-($seq_length-1); 
    $begin_index++
  ) {
  
    # Adding the current n-gram to the hits.
    $result->add_element(
        'begin_index'     => $begin_index,
        'sequence_length' => $seq_length,
    );
      
  }
  
  return $result;
  
}




#===============================================================================
# Private methods
#===============================================================================

#-----------------------------------------------------------------------------
# function _compare
#-----------------------------------------------------------------------------
# Synopsis:          apply a regular expression on the current element
# attributes:        - filter_index (Int)
#                    - start_position (Int)
#                    - sequence_length (Int)
#                    - counter_current_filter (Int)
#                    - token (a Lingua::TreeTagger::Token object)
#                    - result (a Lingua::TreeTagger::Filter::Result object)
#                    - text_length (Int)
#                    - array_ref_token (ref to a Lingua::TreeTagger::TaggedText)
# Return values:     - a Hash
#-----------------------------------------------------------------------------

sub _compare {

    my ( $self, %param ) = @_;

    # Extracting the variables.
    my $filter_index           = $param{filter_index};
    my $start_position         = $param{start_position};
    my $sequence_length        = $param{sequence_length};
    my $token                  = $param{token};
    my $result                 = $param{result};
    my $counter_current_filter = $param{counter_current_filter};  
    my $text_length            = $param{text_length};
    my $array_ref_token        = $param{array_ref_token};
    my $ref_filter             = $self->get_sequence;
    my @filter                 = @$ref_filter;
    
    
    # Current filter element.
    my $filter_current = $filter[$filter_index];
    my @array_limit;
    
    if($token->is_SGML_tag == 1){
      return (
        {
            'filter_index'           => $filter_index,
            'start_position'         => $start_position,
            'sequence_length'        => $sequence_length++,
            'counter_current_filter' => $counter_current_filter,
        }
      );
    }

    # Case of a {} quantifier.
    if ( ( $filter_current->get_quantifier() ) =~ /,/ ) {

        # Splitting the quantifier to get the two limit values.
        @array_limit = split( /[^0-9]/, $filter_current->get_quantifier() );
        @array_limit = grep( $_ ne "", @array_limit );

        # Non standard case {n,} and {,n}.
        if ( @array_limit != 2 ) {

            # Splitting the quantifier and conserving "," .
            my @array_limit_prov =
              split( /[^0-9,]/, $filter_current->get_quantifier() );
            @array_limit_prov = grep( $_ ne "", @array_limit_prov );
            @array_limit_prov = split( //, $array_limit_prov[0] );
            @array_limit_prov = grep( $_ ne "", @array_limit_prov );

            # , comes first.
            if ( $array_limit_prov[0] eq "," ) {

                # Inserting the first limit in array.
                unshift( @array_limit, 0 );

            }
            else {
                push( @array_limit, $text_length );

            }

        }
    }

    # Filter and tagtext are matching.
    if ( $self->_compare_elements( $token, $filter_current ) ) {

        # Quantifier = 1, this is the simpliest case.
        if (   ( $filter_current->get_quantifier() ) eq "1"
            || ( $filter_current->get_quantifier() ) eq "?"
        ){
            $filter_index++;
            $sequence_length++;
        }

        # Match and quantifier allows to keep the same filter element.
        elsif (( $filter_current->get_quantifier() ) eq "*"
            || ( $filter_current->get_quantifier() ) eq "+" )
        {
            
            # Ungreedy quantifier.
            if ( !$filter_current->get_is_greedy() && 
              ( $filter_current->get_quantifier() eq "*" ||
                $counter_current_filter >= 1 ) 
            ) {
            
              # Extracting the next filter element.
              my $filter_next = $filter[$filter_index+1];
              
              print( $start_position . "\n" . $sequence_length . "\n" );
              print($filter[$filter_index+1]->get_is_null() );
              # Test if next element match with token.
              if ( $self->_compare_elements( $token, $filter_next ) ) {
              
                # Bypass the next filter element.
                $filter_index += 2;
                # Reset counter.
                $counter_current_filter = 0;
                
              }
              # End of text, no match but quantifier authorize 0.
              elsif ( ($start_position + $sequence_length) == $text_length -1 && 
                $filter_index < @filter - 1 &&
                $counter_current_filter > 0 &&
                $filter[$filter_index+1]->get_is_null() 
              ){
                my $counter_token = $start_position + 
                  ( $sequence_length - $counter_current_filter);
                my $counter_element = ++$filter_index;
                my $control = 0;
                print("etape 1 \n");
                # Extract the tokens.
                my @array_token = @$array_ref_token;
                
                # Loop on the filter elements.
                for ( ; $counter_element < @filter ; $counter_element++) {
                
                  my $loop_filter_element = $filter[$counter_element];
                
                  # Control that the previous element allows 0.
                  if ($filter[$counter_element-1]->get_is_null){
                    print("etape 2 \n");
                  
                    # Loop on the tokens.
                    for ( ; $counter_token < @array_token; $counter_token++ ){
                    
                      my $loop_token = $array_token[$counter_token];
                       print("etape 3 $loop_token $loop_filter_element\n");
                    
                      # Make the comparison.
                      $control = $self->_compare_elements( 
                        $loop_token, $loop_filter_element 
                      );
                      print("ok");
                      
                      # Match.
                      if ( $control ) {
                      
                        print("match");
                        $counter_current_filter = 0;
                        
                        $sequence_length  += $counter_token;
                        $filter_index     += $counter_element - $filter_index -1; 
                      
                      }
                      
                    }
                    $filter_index++;
                  }
                }
              }
              
              
            }
            # Optimize wildcard treatment.
            if ( $filter_current->get_is_wildcard() &&
              $filter_current->get_is_greedy()
            ) {
            
              $counter_current_filter = 
                  $text_length - ( $start_position + $sequence_length );
              $sequence_length        = $text_length - $start_position;
              
              # Filter element is the last of the sequence, create the new hit.
              if ( $filter_index == @filter - 1) {
                
                # Creating the new hit.
                $result->add_element(
                    begin_index     => $start_position,
                    sequence_length => $sequence_length,
                );
                
                # Reset values for a new sequence.
                $start_position++;
                $filter_index           = 0;
                $sequence_length        = 0;
                $counter_current_filter = 0;
                
                return (
                  {
                      'filter_index'           => $filter_index,
                      'start_position'         => $start_position,
                      'sequence_length'        => $sequence_length,
                      'counter_current_filter' => $counter_current_filter,
                  }
                );
              
              }
              
            }
            # Element is not a wildcard or quantifier isn't greedy.
            else {
              
              $sequence_length++;
              $counter_current_filter++;
              
            }
            
            if ( ($start_position + $sequence_length) == $text_length && 
              $filter_index < @filter - 1 && $filter_current->get_is_greedy()) {
            
              $filter_index++;
              return $self->_quantifier(
                  'filter_index'           => $filter_index,
                  'start_position'         => $start_position,
                  'sequence_length'        => $sequence_length,
                  'token'                  => $token,
                  'result'                 => $result,
                  'counter_current_filter' => $counter_current_filter,
                  'text_length'            => $text_length,
                  'array_ref_token'        => $array_ref_token,
              );
            }
        }

      # Match and quantifier admit a semi-defined repetition.
        elsif ( defined( $array_limit[1] ) )
        {
            # Optimized wildcard treatment.
            if ( $filter_current->get_is_wildcard() ) {
            
              # There is enough space to use the interval up limit.
              if ( 
                $array_limit[1] <= $text_length -
                ( $start_position + $sequence_length) 
              ) {
              
                $sequence_length += $array_limit[1] - 1;
                $counter_current_filter = $array_limit[1] - 1;
              
              }
              # Use the available space.
              else {
              
                $counter_current_filter = 
                  ( $text_length - 1 )- ( $start_position + $sequence_length );
                $sequence_length        = ( $text_length -1 ) - $start_position;
              
              }
              
            }

            # Up limit reached.
            if ( $array_limit[1] == ( $counter_current_filter + 1 ) ){

                $filter_index++;
                $counter_current_filter++;
                $sequence_length++;
                
                # If it isn't the last element of the filter.
                if ( $filter_index != @filter ) {
                
                  return $self->_quantifier(
                    'filter_index'           => $filter_index,
                    'start_position'         => $start_position,
                    'sequence_length'        => $sequence_length,
                    'token'                  => $token,
                    'result'                 => $result,
                    'counter_current_filter' => $counter_current_filter,
                    'text_length'            => $text_length,
                    'array_ref_token'        => $array_ref_token,
                  );
                
                }

            }
            elsif ( ($start_position + $sequence_length) == $text_length - 1 &&
              $counter_current_filter > $array_limit[0] ) {
            
              # End of text and quantifier satisfied.
              $filter_index++;
              return $self->_quantifier(
                  'filter_index'           => $filter_index,
                  'start_position'         => $start_position,
                  'sequence_length'        => $sequence_length,
                  'token'                  => $token,
                  'result'                 => $result,
                  'counter_current_filter' => $counter_current_filter,
                  'text_length'            => $text_length,
                  'array_ref_token'        => $array_ref_token,
              );
            }
            else {

                # Keep same filter element, increment sequence.
                $sequence_length++;
                $counter_current_filter++;

            }

        }
        # Match and quantifier admit a defined repetition.
        elsif ( $filter_current->get_quantifier()  > 1 ) {
        
          # Up limit reached.
          if ( 
            $counter_current_filter + 1 == $filter_current->get_quantifier()
          ){
          
            $sequence_length++;
            $filter_index++;
            $counter_current_filter = 0;
            
          }
          # Up limit not yet reached.
          else {
            $sequence_length++;
            $counter_current_filter++;
          }
        
        }

        # The sequence is complete.
        if ( @filter == $filter_index ) {

            # Creating the new hit.
            $result->add_element(
                begin_index     => $start_position,
                sequence_length => $sequence_length,
            );
            if ( $result->get_put_back() ){
              $start_position++; 
            }
            else {
              $start_position += $sequence_length;
            }
            $filter_index           = 0;
            $counter_current_filter = 0;
            $sequence_length        = 0;
            
            
            return (
              {
                  'filter_index'           => $filter_index,
                  'start_position'         => $start_position,
                  'sequence_length'        => $sequence_length,
                  'counter_current_filter' => $counter_current_filter,
              }
          );
        }
    }
    
    # Filter and tagtext are NOT matching but the sequence is complete.
    elsif ( @filter == ( $filter_index + 1 )
        && $counter_current_filter > 0 )
    {

        # Creating the new hit.
        $result->add_element(
            'begin_index'     => $start_position,
            'sequence_length' => $sequence_length,
        );

        # Reset values for a new sequence.
        if ( $result->get_put_back() ){
          $start_position++ 
        }
        else {
          $start_position += $sequence_length;
        }
        $filter_index           = 0;
        $sequence_length        = 0;
        $counter_current_filter = 0;
        
        return (
          {
              'filter_index'           => $filter_index,
              'start_position'         => $start_position,
              'sequence_length'        => $sequence_length,
              'counter_current_filter' => $counter_current_filter,
          }
        );
    }

    # Filter and tagtext are  NOT matching but quantifier allowed 0.
    elsif ( $filter_current->get_quantifier() eq '?' ||
            $filter_current->get_quantifier() eq '*' ||
            ( defined($array_limit[0]) && $array_limit[0] == 0 ) ) {
        
        if ($filter_index < @filter) {
        
          $filter_index++;
          $counter_current_filter = 0;
        
        }
        
        else {
        
          $counter_current_filter++;
        
        }
        return $self->_compare(
              'filter_index'           => $filter_index,
              'start_position'         => $start_position,
              'sequence_length'        => $sequence_length,
              'token'                  => $token,
              'result'                 => $result,
              'counter_current_filter' => $counter_current_filter,
              'text_length'            => $text_length,
              'array_ref_token'        => $array_ref_token,
        );
        

    }    
    # Filter and tagtext are  NOT matching but quantifier is satisfied.
    elsif ( $filter_current->get_quantifier() eq '+' &&
            $counter_current_filter >= 1 ) {

        if ($filter_index < @filter) {
        
          $filter_index++;
        
        }
        return $self->_quantifier(
            'filter_index'           => $filter_index,
            'start_position'         => $start_position,
            'sequence_length'        => $sequence_length,
            'token'                  => $token,
            'result'                 => $result,
            'counter_current_filter' => $counter_current_filter,
            'text_length'            => $text_length,
            'array_ref_token'        => $array_ref_token,
        );

    }
    

    # No match but quantifier = {}.
    elsif ( ( defined( $array_limit[1] ) ) ) {

        
        # Counter is in the limits.
        if ( $array_limit[0] <= $counter_current_filter ) {

            $filter_index++;
            return $self->_quantifier(
                'filter_index'           => $filter_index,
                'start_position'         => $start_position,
                'sequence_length'        => $sequence_length,
                'token'                  => $token,
                'result'                 => $result,
                'counter_current_filter' => $counter_current_filter,
                'text_length'            => $text_length,
                'array_ref_token'        => $array_ref_token,
            );

        }

        # Counter is off limits.
        else {

            $start_position++;
            $filter_index           = 0;
            $counter_current_filter = 0;
            $sequence_length        = 0;

        }
    }

    # Filter and tagtext are  NOT matching.
    else {

        $start_position++;
        $filter_index           = 0;
        $counter_current_filter = 0;
        $sequence_length        = 0;

    }

    return (
        {
            'filter_index'           => $filter_index,
            'start_position'         => $start_position,
            'sequence_length'        => $sequence_length,
            'counter_current_filter' => $counter_current_filter,

        }
    );

}

#-----------------------------------------------------------------------------
# function _quantifier
#-----------------------------------------------------------------------------
# Synopsis:          walks back the matching sequence to handle semi-defined
#                    quantifiers. 
# attributes:        - filter_index (Int)
#                    - start_position (Int)
#                    - sequence_length (Int)
#                    - counter_current_filter (Int)
#                    - token (a Lingua::TreeTagger::Token object)
#                    - result (a Lingua::TreeTagger::Filter::Result object)
#                    - text_length (Int)
#                    - array_ref_token (ref to a Lingua::TreeTagger::TaggedText)
# Return values:     - a Hash
#-----------------------------------------------------------------------------

sub _quantifier {

   my ( $self, %param ) = @_;

    # Extracting the variables.
    my $filter_index           = $param{filter_index};
    my $start_position         = $param{start_position};
    my $sequence_length        = $param{sequence_length};
    my $token                  = $param{token};
    my $result                 = $param{result};
    my $counter_current_filter = $param{counter_current_filter};  
    my $text_length            = $param{text_length};
    my $array_ref_token        = $param{array_ref_token};
    my $ref_filter             = $self->get_sequence;
    my @filter                 = @$ref_filter;
    
    my $limit_down;
    
     # Current filter element.
    my $filter_current    = $filter[$filter_index];
    my $filter_quantifier = $filter[$filter_index-1];
    my @array_limit;
    
    # Case of a {} quantifier.
    if ( ( $filter_quantifier->get_quantifier() ) =~ /,/ ) {

        # Splitting the quantifier to get the two limit values.
        @array_limit = split( /[^0-9]/, $filter_quantifier->get_quantifier() );
        @array_limit = grep( $_ ne "", @array_limit );

        # Non standard case {n,} and {,n}.
        if ( @array_limit != 2 ) {

            # Splitting the quantifier and conserving "," .
            my @array_limit_prov =
              split( /[^0-9,]/, $filter_quantifier->get_quantifier() );
            @array_limit_prov = grep( $_ ne "", @array_limit_prov );
            @array_limit_prov = split( //, $array_limit_prov[0] );
            @array_limit_prov = grep( $_ ne "", @array_limit_prov );

            # , comes first.
            if ( $array_limit_prov[0] eq "," ) {

                # Inserting the first limit in array.
                unshift( @array_limit, 0 );

            }
            else {
                push( @array_limit, $text_length );

            }

        }
    }
    
    # limit down.
    if ( $filter_quantifier->get_quantifier() eq '*') 
    {
         
      # Starting value for the back loop.
      $limit_down = $start_position + 
        ( $sequence_length - $counter_current_filter );  
      
    }
    elsif ($filter_quantifier->get_quantifier() eq '+') {
    
      # Starting value for the back loop.
      $limit_down = $start_position + 
        ( $sequence_length - $counter_current_filter + 1 );
    } 
    else {
    
      # Starting value for the back loop.
      $limit_down = $start_position + ( $sequence_length - 
        ( $counter_current_filter - $array_limit[0]));
    
    }
    
    my @array_token = @$array_ref_token;
    my $i;
    if ( $start_position + $sequence_length < $text_length ){
      $i = $start_position + $sequence_length;
    }
    # No more tokens.
    else {
      # Begin the loop with the last token.
      $i = $text_length-1;
      # Update the sequence length. 
      $sequence_length--;
    }
    my $store_i = $i;
    my $store_sequence_length = $sequence_length;
    # Back loop.
    for ( ; $i >= $limit_down; $i-- ) {
    
      my $token_current = $array_token[$i];
      my $control       = $self->_compare_elements( 
        $token_current, $filter_current
      );
      
      
      # If match back to the apply fonction.
      if ( $control ) {
      
        return (
          {
              'filter_index'           => $filter_index,
              'start_position'         => $start_position,
              'sequence_length'        => $sequence_length,
              'counter_current_filter' => 0,

          }
        );
        
      
      }
      
      $sequence_length--;
      
      # Limit reached but quantifier authorize 0.
      if ( $filter_current->get_is_null && $i == $limit_down ) {
          
        $filter_current    = $filter[++$filter_index];
        $i                 = $store_i + 1;
        $sequence_length   = $store_sequence_length;
           
      }
      
    }
    return (
      {
          'filter_index'           => 0,
          'start_position'         => $start_position + 2,
          'sequence_length'        => 0,
          'counter_current_filter' => 0,

      }
    );    
}
#-----------------------------------------------------------------------------
# function _compare_elements
#-----------------------------------------------------------------------------
# Synopsis:          compares a token (treetagger output) to a filter element
#                    which contains string that will be interpreted as regular
#                    expression. These regexp will be applied on the token. If
#                    match return values is 1 otherwise 0
# attributes:        - a token (a lingua::TreeTagger::Token object)
#                    - a filter element (a lingua::TreeTagger::Filter::Element 
#                      object)
# Return values:     - an Int (1||0)
#-----------------------------------------------------------------------------

sub _compare_elements {

    my ( $self, $token, $filter_element ) = @_;

    my $control = 1;
    
    # Element is a wildcard.
    return $control if  $filter_element->get_is_wildcard();  

    # Compares original element.
    my $current_filter_attribute = $filter_element->original();
    if( $current_filter_attribute ne ".") {
      if (!$filter_element->get_neg_original()) {
        if ( !( $token->original() =~ /$current_filter_attribute/ ) ) {
    
            $control = 0;
            return ($control);
    
        }
      }
      else{
        if ( $token->original() =~ /$current_filter_attribute/ ) {
    
            $control = 0;
            return ($control);
    
        }
      
      }
    }
    

    # Compares lemma element.
    $current_filter_attribute = $filter_element->lemma();
    if( $current_filter_attribute ne ".") {
      if (!$filter_element->get_neg_lemma()) {
        if ( !( $token->lemma() =~ /$current_filter_attribute/ ) ) {
    
            $control = 0;
            return ($control);
    
        }
      }
      else{
        if ( $token->lemma() =~ /$current_filter_attribute/ ) {
    
            $control = 0;
            return ($control);
    
        }
      }
    }

    # Compares tag element.
    $current_filter_attribute = $filter_element->tag();
    if( $current_filter_attribute ne ".") {
      if (!$filter_element->get_neg_tag()) {
        if ( !( $token->tag() =~ /$current_filter_attribute/ ) ) {
    
            $control = 0;
            return ($control);
    
        }
      }
      else{
        if ( $token->tag() =~ /$current_filter_attribute/ ) {
    
            $control = 0;
            return ($control);
    
        }
      
      }
    }
    
    return ($control);
}

#-----------------------------------------------------------------------------
# function _substitute_elements
#-----------------------------------------------------------------------------
# Synopsis:          makes the substitution in the matching sequence. 
# attributes:        - a token (a lingua::TreeTagger::Token object)
#                    - a filter element (a lingua::TreeTagger::Filter::Element 
#                      object)
# Return values:     - an Int (1||0) and the modified token
#-----------------------------------------------------------------------------

sub _substitute_elements {

    my ( $self, $token, $filter_element ) = @_;

    my $control = 1;
    my %param;
    
    $param{is_SGML_tag} = 0; 

    # Substitute original element.
    my $filter_attribute     = $filter_element->original();
    my $filter_substitute    = $filter_element->get_sub_original();
    my $filter_neg_attribute = $filter_element->get_neg_original();
    my $token_attribute      = $token->original();
    
    my @result = $self->_substitute_attribute(
      'filter_attribute'     => $filter_attribute,
      'filter_substitute'    => $filter_substitute,
      'filter_neg_attribute' => $filter_neg_attribute,
      'token_attribute'      => $token_attribute,
    );
    
    # Substitution unsuccessful.
    if (!$result[0]) {
      $control = 0;
    }
    # Substitution successful.
    else {
      $param{original} = $result[1];
    }
    
    # Substitute tag element.
    $filter_attribute     = $filter_element->tag();
    $filter_substitute    = $filter_element->get_sub_tag();
    $filter_neg_attribute = $filter_element->get_neg_tag();
    $token_attribute      = $token->tag();
    
    @result = $self->_substitute_attribute(
      filter_attribute     => $filter_attribute,
      filter_substitute    => $filter_substitute,
      filter_neg_attribute => $filter_neg_attribute,
      token_attribute      => $token_attribute,
    );
    
    # Substitution unsuccessful.
    if (!$result[0]) {
      $control = 0;
    }
    # Substitution successful.
    else {
      $param{tag} = $result[1];
    }
    
    # Substitute lemma element.
    $filter_attribute     = $filter_element->lemma();
    $filter_substitute    = $filter_element->get_sub_lemma();
    $filter_neg_attribute = $filter_element->get_neg_lemma();
    $token_attribute      = $token->lemma();
    
    @result = $self->_substitute_attribute(
      'filter_attribute'     => $filter_attribute,
      'filter_substitute'    => $filter_substitute,
      'filter_neg_attribute' => $filter_neg_attribute,
      'token_attribute'      => $token_attribute,
    );
    
    # Substitution unsuccessful.
    if (!$result[0]) {
      $control = 0;
    }
    # Substitution successful.
    else {
      $param{lemma} = $result[1];
    }
    
    my $token_return;
    if ($control) {
      $token_return = Lingua::TreeTagger::Token->new( %param );
    }  
    return ($control, $token_return);
}

#-----------------------------------------------------------------------------
# function _substitute_attribute
#-----------------------------------------------------------------------------
# Synopsis:          makes the comparison to ensure the substitution. It makes
#                    this comparison for one attribute. If there is a match,
#                    it returns a control value and the value of the 
#                    new value of the attribute. If it doesn't match. It
#                    returns the control value and an undef var.  
# parameters         - filter_attribute: a str, the current attribute of the 
#                      current filter
#                    - filter_substitute: a str, the corresponding sub_attribute
#                    - filter_neg_attribute: 1/0, corresponds to the 
#                      neg_attribute of the filter element
#                    - token_attribute: a str, the current attribute of the 
#                      token
# Return values:     - an Int (1||0) and the new value of the attribute (if 1)
#-----------------------------------------------------------------------------

sub _substitute_attribute {

  my ( $self, %param ) = @_;
  
  # Initialization.
  my $control = 1;
  my $return_value;
  
  if( $param{filter_attribute} eq "." ) {
      
      if ( $param{filter_substitute} eq "." ){
      
        $return_value = $param{token_attribute};  
      
      }
      else {
      
        $return_value = $param{filter_substitute};  
      
      } 
      
    }
    elsif ( $param{token_attribute} =~ /$param{filter_attribute}/ ) {
       if ( $param{filter_substitute} eq "." ){
      
        $return_value = $param{token_attribute};  
      
      }
      else {
      
        $return_value = $param{filter_substitute};  
      
      }
    }
    elsif ( $param{filter_neg_attribute} ) {
       if ( $param{filter_substitute} eq "." ){
      
        $return_value = $param{token_attribute};  
      
      }
      else {
      
        $return_value = $param{filter_substitute};  
      
      } 
    }
    else {
      $control = 0;
    }
  
   return( $control, $return_value ); 
}

#=cut
#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

Lingua::TreeTagger::Filter - handle a Lingua::TreeTagger output 

=head1 VERSION

Version 0.01


=head1 SYNOPSIS
  
  use Lingua::TreeTagger::Filter;

  # Create a tree tagger object.
  my $tagger = Lingua::TreeTagger->new(
      'language' => 'english',
      'options'  => [qw( -token -lemma -no-unknown )],
  );
  
  my $text = "This is a test";
  
  # Tag some text and get a new TaggedText object.
  my $tagged_text = $tagger->tag_text( \$text );
  
  # Create a filter object.
  my $filter = Lingua::TreeTagger::Filter->new();
  
  # This filter will extract all sequences starting with tag DT...
  $filter->add_element( tag => 'DT', );
  
  # ... followed by any sequence up to 4 elements...
  $filter->add_element( 'quantifier' => '{0,4}', );
  
  # ... and followed by another lemma than "house".
  $filter->add_element( lemma => '!house', );
  
  # Alternatively use the init_with_string method (see documentation below)
  $filter->init_with_string("tag=DT#quantifier={0,4}#lemma=!house");
  
  # Apply the filter to the taggedtext.
  my $result = $filter->apply($tagged_text);
  
  # Display the matching sequences.
  print( $result->as_text() );
  
  # Extract bi-grams.
  $result = $filter->extract_ngrams( $tagged_text, 2 );
  
  # Display the bi-grams.
  print( $result->as_text() );
  
  # Makes a substitution.
  # Initialize the filter...
  $filter->init_with_string("tag=NN sub_tag=Test");
  
  # ...use the substitute() method
  $result = $filter->substitute($tagged_text);
  
  # ... display the result.
  print( $result->as_text() );
  
  

=head1 DESCRIPTION

This module allows you to search or to modify sequences ( tag, 
original, lemma) in a Lingua::TreeTagger::Taggedtext object (output by 
Lingua::Treetagger).

=head1 METHODS

=over 4

=item C<new()>

You can use this constructor in two different ways

=over 2

=item empty filter


Initialize a new, empty filter. It doesn't need any attributes.


=item init_with_string filter


by using the constructor with a string argument, you can directly 
define the filter sequence. For more informations about the syntax see
documentation of the init_with_string() method.
Example
  my $string = "tag=NN#quantifier={0,4}#lemma=!house"; 
  my $filter = 
    Lingua::TreeTagger::Filter->new( $string );
    
is equivalent to:
  my $filter = Lingua::TreeTagger::Filter->new();
  $filter->init_with_string( "tag=NN#quantifier={0,4}#lemma=!house" );  

=back

=item C<apply()>

Takes one required argument, a Lingua::TreeTagger::TaggedText object.
Optionaly you can give a second argument with the value of 0. 

This method is the core of this distribution. It applies the filter on
a taggedtext and returns the matching sequences.

Each attribute of the filter element are inserted in a regular 
expression. The comparison is made as follows:

taggedtext_element =~ /^element_filter$/

to take a lesser abstract example: 

=over 2

current token original attribute = house

current filter element original attribute = house

gives:

house =~ /^house$/ -> match

=back 

So you can use all the possibilities offered by Perl regular 
expressions. By default the attribute is inserted between anchors to 
ensure a strict match. If you don't want to use anchors, you can 
define a parameter anchor_attribute with the value of 0.
For example, for the original value "house".
  
  original        => house,
  anchor_original => 0

gives the result
  
  something =~/house/

So it will match "house" but any word containing "house" too, as 
"housewife" or "housekeper".

This comparison is made for each attributes (original, tag, lemma) of 
the current filter element and  the current token, if there is a match 
between every  attributes --> match between current filter element 
and current token (the default attribute value "." match everything).

If you want to negate an element, you can do it by adding a "!" 
in the front of the attribute. This will modify the comparison as 
follows taggedtext_element !~ /element_filter/

You can modify the negation symbol if it's necessary. For further 
details see the documentation of the add_element() method.

To obtain precision on the attributes of a filter element,please refer
to the documentation of the add_element() method.

The return value is a Lingua::TreeTagger::Filter::Result object.

samples:

=over 2

  $filter->add_element (
    tag => 'DT',
  );
  $filter->add_element (
    original => 'house',
  );

This filter will match all the sequences in the taggedtext which are 
made up of a determiner preceding the word "house" (for example
the sequence: "a house" will be matched). To match something larger, 
modify the second element as follows:

  $filter->add_element (
    tag => '!DT',
  );
  $filter->add_element (
    original => 'house',
  );

This filter will match all the sequences of word in which any word but
a determiner preceeds a word containing "house" as "nice housekeeper".

Lets focus on the quantifier role:
  
  $filter->add_element (
    quantifier => '+',
    tad        => 'DT',
  );
  $filter->add_element (
    original => 'house',
  );

This filter will match all the sequences which begin by one or 
more determiner and immediately followed by the word 
"house". You also can use the  other quantifier symbols of the 
language ( ". ", " ?", " * ")

You can define intervals:

  $filter->add_element (
    quantifier => '{1,3}',
    tag        => 'DT',
  );
  $filter->add_element (
    original => 'house',
  );

This filter will match all the sequences begining by up to 3 
determiners and  followed by the word "house". You can also use the 
syntax {,3} (0 to 3) and {2,}(2 to infinity).

=back

=item C<apply_no_overlap()>

This method is a extension of the apply basic method. In the classic method, 
after a match, the filter continues his scan from the second element of the 
last matched sequence. With the no overlap apply the scan continues from the 
next element after the last matched sequence. With this second method, an 
element cannot be part of two more matching sequences.

It take one attribute as the apply method, a taggedtext.

=item C<substitute()>

It takes one required argument, a Lingua::TreeTagger::TaggedText 
object.

This method is a prolongation of the the apply() method. For each 
matching sequence the filter will makes a second passage, each
defined sub_attribute will replace the corresponding attribute of
the original token.
Example:

Original token:

  original = is
  tag      = VBZ
  lemma    = be

Filter Element:

  original = "."
  tag      = VBZ
  lemma    = "."
  sub_tag  = TEST

New token after substitution

  original = is
  tag      = TEST
  lemma    = be
  
Example:

This text "this is a test" gives this tagged sequence

  this    DT      this
  is      VBZ     be
  a       DT      a
  trial   NN      trial

if you use the substitute method with a filter with this unique 
element:

  $filter->add_element(
    tag     => 'NN',
    sub_tag => 'Test',
  );

gives this new tagged sequence

  this    DT      this
  is      VBZ     be
  a       DT      a
  trial   Test    trial

This method creates a copy of the taggedtext object so it conserves 
the original sequence in the original object. The new sequence is 
stored in the returned object.

if you don't define any sub_attribute, the method still runs and you
will obtain a new object with the same sequence.


=item C<add_element()>

Adds element to the sequence. It can be an existing
Lingua::TreeTagger::Filter::Element object or you can create a new one
using this method.

This method takes named parameters.

=over 4

=item position

an optional intenger, specifying where the element should be added in
the sequence. If not defined the element will be added at the end
of the filter sequence (as a PUSH))

=back 

=item existing element

=over 4

=item element_object

optional, an existing Lingua::TreeTagger::Filter::Element

=back

=item new element object

=over 4

All the parameters in this section must be omitted if the parameter 
element_object is defined. If element_object is not defined and a 
parameter (tag, original, lemma) is omitted, the value of 
the corresponding attribute in the corresponding filter element will 
be initiated to "." that implies a match of everything.

=back

=over 4

=item original

optional, a string containing the expression to be compared with the 
original attribute from the tokens of a Lingua::TreeTagger output.

=item tag

optional, a string containing the expression to be compared with the 
tag attribute from the tokens of a Lingua::TreeTagger output.

=item lemma

optional, a string containing the expression to be compared with the 
lemma attribute from the tokens of a Lingua::TreeTagger output.

=item quantifier

optional, a string, must respect the syntax of Perl quantifiers.
 
samples: +/*/?/{n}/{n,m}

The quantifier defines the number of repetitions of the current 
element in the filter sequence.

If element_object is not defined and quantifier is omitted, the value 
of quantifier attribute in the corresponding filter element will be 
initiated to 1(the correpsonding element must appear exactly one time)

By default the quantifier are greedy (here the definition is a litte
different as in the perl regular expression. Here greedy works stricly
with the next element and not with the whole expression. The element
will match as many element as possible ensuring the match of the next 
element and doesn't ensure the match of the whole sequence
For example this filter:
  
  tag=DT#quantifier=*#lemma=house#quantifier=*#lemma=house

Won't match this text: "This is a house, a nice house" because the 
three first element matched from "a" to the second "house") 
  
The quantifiers "+" and "*" can be use in a ungreedy way. By adding a "?"
directly afer it, the quantifier becomes ungreedy, that means that he will
try to match the current element as long as the next element does'nt match.
For example this filter:
  
  tag=DT#quantifier=*?#lemma=house
  
with this text: "This is a  great house, a nice house". Will sent back:
[ "a great house", "a nice house"] (greedy version (put back)[ "a great
house, a nice house", "a nice house"  ]) 

=back

By default the attributes (tag, original, lemma) are inserted between 
anchors in the regular expression (see the documentation of apply() 
method for further details). If you want to avoid anchors 
you have to define the corresponding "anchor_attribute" parameter with
the value of 0 (Caution: 0 is the only accepted value!).

=over 4

=item anchor_original

optional, 0, an int

=item anchor_tag

optional, 0, an int

=item anchor_lemma

optional, 0, an int

=back

For these attributes (tag, original, lemma), you can define a 
corresponding "sub_attribute" which will be used by the substitute()
method. See method documentation for further informations.

=over 4

=item sub_original 

optional, a string

=item sub_lemma 

optional, a string 

=item sub_tag 

optional, a string

=back  

You can negate an attribute by adding "!" in front of it
sample: "tag=!ADJ" -> signifies that it will match any non-adjective
token. You can change this symbol by defining the "neg_symbol" 
parameters.

=over 4

=item neg_symbol

optional parameter, is a string containing a unique symbol which is 
used to negate an assertion. This:

  neg_symbol => '?' 

implies that in the current element the default negation symbol ("!") 
is replaced by "?"

=back

sample:

=over 2

add_element (case of a new object ) with all parameters explicit 
(excepted "anchor_original" and "anchor_lemma")  
  
  $filter -> add_element (
      lemma         => 'be',
      original      => 'is',
      tag           => 'VBZ',
      anchor_tag    => 0,
      sub_tag       => 'Test',
      sub_original  => 'Test',
      sub_lemma     => 'Test',
      quantifier    => '1',
      position      => 1,
  );

=back

=item C<remove_element()>

This method allows you to remove an element from the Filter.It 
requires one argument.

an int, defines the index of the element to remove.

=item C<init_with_string()>

This method allows you to write a filter in a one line instruction.
This function needs a string as argument.

Be careful, if you have any  elements in your filter at this time, they will
be deleted! Use add_element() if you want to complete a filter.

syntax is:

"#" separates the elements (Lingua::TreeTagger::Filter::Element 
object) begining the sequence with a "#" signifies that your filter 
begins with an element matching any token (wildcard). 
"something# #something" in the line signifies that the method will
insert a wildcard at the place of the space. Inside an  element, 
syntax is as following:

to define an attribute:

  attributes_name=value (no space must be inserted)

example: "tag=NN" -> will initiate the value of tag for the 
corresponding element to "NN"

to separate the attributes:

  attributes_name1=value1 attributes_name2=value2

the space is used to separate attributes (that explain why space is 
forbidden just above)
example: "tag=NN original=house" will initiate the value of tag for 
the corresponding element to "NN" and the value of original for the 
same element to "house"

As in the simple method add_element(), you can negate an attribute by 
adding "!" in front of it
example: "tag=!JJ" -> signifies that it will match any non-adjective
token

You can also modify this symbol by defining the parameter "neg_symbol"
"tag=?JJ neg_symbol=?" is equivalent to "tag=!JJ"

Samples:

=over 2

sample 1:

 $filter->init_with_string("tag=NN original=house#tag=!JJ")

is equivalent to:

  $filter->add_element(
    tag      => 'NN',
    original => 'house',
  );
  
  $filter->add_element(
    tag => '!JJ',
  );

sample 2:
  
  $filter->init_with_string("lemma=be# #tag=!DT")

is equivalent to:

  $filter->add_element(
    lemma => 'be',
  );
  
  $filter->add_element();
  
  $filter->add_element(
    tag => '!DT',
  );

sample 3:

  $filter->init_with_string("#tag=!DT")
  
is equivalent to:
  
  $filter->add_element();
  
  $filter->add_element(
    tag => '!DT',
  );

=back


=item C<extract_ngrams()>

This method allows you to extract n-grams, it requires two attributes

The first one is a Lingua::TreeTagger::TaggedText object (the tagged 
text in which you want to extract the ngrams).

The second one is the length of the sequence. 2 to extract 2-grams, 
3 to extract 3-grams...

This method return a Lingua::TreeTagger::Filter::Result object

=back

=head1 ACCESSORS

=over 4

=item C<get_sequence()>

Read-only accessor for the 'sequence' attribute of a Filter object.

=back

=head1 DIAGNOSTICS

=over 4

=item apply()

=over 4

=item Attempt to call apply() without any arguments

This exception is raised by the apply() method when the user doesn't
give any argument.

=item Attempt to call apply() without a tagged text object

This exception is raised by the apply() method when the user gives an
an argument which is not a Lingua::TreeTagger::TaggedText object.

=item Attempt to call apply() with an empty filter

This exception is raised by the apply() method when the user tries to 
call the method with an empty filter (a filter without any filter 
element).

=item Attempt to call apply() with an empty tagged text

This exception is raised by the apply() method when user gives an 
empty tagged text as argument.  

=back

=item substitute()

=over 4

=item Attempt to call substitute() without any arguments

This exception is raised by the substitute() method when the user doesn't
give any argument.

=item Attempt to call substitute() without a taggedtext_object

This exception is raised by the substitute() method when the user gives
an argument which is not a Lingua::TreeTagger::TaggedText object.

=item Attempt to call substitute() with an empty filter

This exception is raised by the substitute() method when the user tries to 
call the method with an empty filter (a filter without any filter 
element).

=item Attempt to call substitute() with an empty tagged text

This exception is raised by the substitute() method when user gives an 
empty tagged text as argument.

=back 

=item add_element()

=over 4

=item Attempt to call add_element() with incorrect element object

This exception is raised by the add_element() method when the user 
gives an incorrect value for the element_object parameter (should be
an Lingua::TreeTagger::Filer::Element object).

=item Attempt to call add_element() with a non-numeric argument

This exception is raised by the add_element() method when the user 
gives an non-numerical value for the position parameter.

=back

=item remove_element()

=over 4

=item remove_element(), out of index

This exception is raised by the remove_element() method when the user 
gives an index values which is not part or directly after the sequence

=item Attempt to call remove_element() without argument

This exception is raised be the remove_element() method when the user 
doesn't give any argument.

=item Attempt to call remove_element() with a non-numeric argument

This exception is raised by the remove_element() method when the user 
gives an non-numerical as argument.

=item the asked element is not part of the sequence

This exception is raised by the remove_element() method when the user 
gives an index values which is not part the sequence

=back

=item init_with_string()

=over 4

=item Attempt to call init_with_string() without argument

This exception is raised be the init_with_string() method when the 
user doesn't give any argument.

=back

=item extract_ngrams()

=over 4

=item Attempt to call extract_ngrams() without argument

This exception is raised be the extract_ngrams() method when the 
user doesn't give any argument.

=item Attempt to call extract_ngrams() without a tagged text object

This exception is raised by the extract_ngrams() method when the user gives
a first argument which is not a Lingua::TreeTagger::TaggedText object.

=item Attempt to call extract_ngrams() with an empty tagged text

This exception is raised by the extract_ngrams() method when user gives an 
empty tagged text as argument as first argument.

=item Attempt to call extract_ngrams() with a non-numerical argument

This exception is raised by the extract_ngrams() method when the user 
gives an non-numerical as argument.

=back

=back

=head1 CONFIGURATION AND ENVIRONMENT

For the configuration and environnement, please refer to the 
documentation of the required module Lingua::TreeTagger by 
Aris Xanthos. You will find  there further informations to install 
and run TreeTagger.

=head1 DEPENDENCIES

This is the base module of the Lingua::TreeTagger::Filter 
distribution. It uses modules L<Lingua::TreeTagger::Filter::Element>,
 L<Lingua::TreeTagger::Filter::Result>, 
and L<Lingua::TreeTagger::Filter::Result::Hit>.

This module requires module Lingua::TreeTagger. It is really thought 
to work together, several fonctionnalities or part of this 
documentation are directly  issued from this distribution.

This module requires module Moose and was developed using version 
1.09. Please report incompatibilities with earlier versions to the 
author.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Benjamin Gay (Benjamin.Gay@unil.ch)

Please note that this distribution is still a beta version. I think that the 
basical cases are pretty well tested.  I tested the content the best as I can 
but I fear that there is still some bugs. 
The matter was really hard to test for me. So please report 
any bugs if you find one or more of them.  

Patches are welcome.

=head1 ACKNOWLEDGEMENTS

The author is grateful to Aris Xanthos for his leading in the 
realization of this project.

Thanks to Leonard Gay for his useful and quick feedback.

=head1 AUTHOR

Benjamin Gay, C<< <Benjamin.Gay at unil.ch> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Benjamin Gay.

This program is free software; you can redistribute it and/or modify 
it under the terms of either: the GNU General Public License as 
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::TreeTagger::Filter

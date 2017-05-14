#!/usr/bin/perl
package Lingua::TreeTagger::Filter::Result;

use Moose;
use Carp;

use Lingua::TreeTagger::Filter::Result::Hit;

#===============================================================================
# Initialization.
#===============================================================================

my @_default_field_order     = qw( original tag lemma );

my $_default_seq_delimiter   = "\n";
my $_default_field_delimiter = "\t";
my $_default_token_delimiter = "\n";

my $_default_sequence        = 'seq';
my $_default_element         = 'w';

my %_default_attributes      = (
    'lemma' => 'lemma',
    'tag'   => 'type',
);

my $_default_content         = 'original';


#===============================================================================
#attributes
#===============================================================================

has 'hits' => (
    is       => 'ro',
    isa      => 'ArrayRef[Lingua::TreeTagger::Filter::Result::Hit]',
    default  => sub { [] },
    reader   => 'get_hits',
    writer   => '_set_hits'
);

has 'taggedtext' => (
    is       => 'ro',
    isa      => 'Lingua::TreeTagger::TaggedText',
    required => 1,
    reader   => 'get_taggedtext',
);

has 'put_back' => (
    is       => 'ro',
    isa      => 'Int',
    default  => 1,
    reader   => 'get_put_back',
);

#===============================================================================
# Public methods
#===============================================================================

#-------------------------------------------------------------------------------
# function as_text
#-------------------------------------------------------------------------------
# Synopsis:      returns the matching sequences as a string
# Arguments:     An optional reference to a hash with the following optional
#                named parameters:
#                - 'fields':          a reference to a list of fields.
#                - 'seq_delimiter':   a string to be inserted between sequences
#                - 'field_delimiter': a string to be inserted between fields.
#                - 'token_delimiter': a string to be inserted between tokens.
# Return values: A string.
#-------------------------------------------------------------------------------

sub as_text {

    my ( $self, $parameters_ref ) = @_;
    my ( @requested_fields, $fields_delimiter, $separator_delimiter );

    # Create a reference to an empty hash if it was not provided by the caller.
    $parameters_ref ||= {};

    # If the fields parameter was provided...
    if ( defined $parameters_ref->{'fields'} ) {

        @requested_fields = @{ $parameters_ref->{'fields'} };

        # Throw exception if no field was requested.
        croak "Attempt to call as_text with empty 'field' parameter"
            if scalar @requested_fields == 0;

        # Check requested fields (and possibly croak)...
        my $tagged_text = $self->get_taggedtext();
        $tagged_text->_check_requested_fields( @requested_fields );
    }
    # Else if no fields parameter was provided, use default field order.
    else { @requested_fields = @_default_field_order; }

    # Use default sequence, field and token delimiters if they were not provided.
    my $seq_delimiter
        = $parameters_ref->{'seq_delimiter'} ||= $_default_seq_delimiter;
    my $field_delimiter
        = $parameters_ref->{'field_delimiter'} ||= $_default_field_delimiter;
    my $token_delimiter
        = $parameters_ref->{'token_delimiter'} ||= $_default_token_delimiter;

    # Initialisation.
    my $string_return;

    # Extracting the members of current sequence.
    my $ref_tab_token = ( $self->get_taggedtext() )->sequence();

    # Extracting the members of current sequence.
    my $ref_tab_hits = $self->get_hits();

    if ( @$ref_tab_hits > 0 ) {
        my $counter = 1;
        foreach my $hit (@$ref_tab_hits) {

            my $sequence_length = $hit->get_sequence_length();
            my $begin_index     = $hit->get_begin_index();
            $string_return .= "matching sequence: " . $counter . 
              $token_delimiter;

            for (
                my $i = $begin_index ;
                $i < ( $begin_index + $sequence_length ) ;
                $i++
              )
            {

                # Extracting current token.
                my $token = $ref_tab_token->[$i];
                my @token_fields;

                REQUESTED_FIELDS:
                foreach my $requested_field (@requested_fields) {

                  my $field_value =
                      $requested_field eq 'original' ? $token->original()
                    : $requested_field eq 'lemma'    ? $token->lemma()
                    :                                  $token->tag()
                    ;
  
                  push @token_fields, $field_value;
                }

                $string_return .= join $field_delimiter, @token_fields;

                $string_return .= $token_delimiter;

            }
            $string_return .= $seq_delimiter;
            $counter++;
        }
        return ($string_return);
    }
    else {
        # No match.
        return;
    }
    return ($string_return);

}

#-------------------------------------------------------------------------------
# Method as_XML
#-------------------------------------------------------------------------------
# Synopsis:      Returns the content of a TaggedText in XML format.
# Arguments:     An optional reference to a hash with the following optional
#                named parameters:
#                - 'sequence':   A string specifying the name of the XML tag
#                                corresponding to a sequence.
#                - 'element':    A string specifying the name of the XML tag
#                                corresponding to a token.
#                - 'attributes': A reference to a hash where each key-value pair
#                                specifies a field to include as an attribute
#                                and the name of this attribute in the output.
#                - 'content':    A string specifying the field that constitute
#                                the content of an element.
# Return values: A string.
#-------------------------------------------------------------------------------

sub as_XML {
    my ( $self, $parameters_ref ) = @_;
    my ( %requested_attributes, $element , $sequence );

    # Create a reference to an empty hash if it was not provided by the caller.
    $parameters_ref ||= {};

    # If the attributes parameter was provided...
    if ( defined $parameters_ref->{'attributes'} ) {

        %requested_attributes = %{ $parameters_ref->{'attributes'} };

        # Check requested attributes (and possibly croak)...
        $self->_check_requested_fields( keys %requested_attributes );
        
        # Check that attribute names are not empty...
        foreach my $attribute (keys %requested_attributes) {
            croak "Empty attribute names are not allowed"
                if $requested_attributes{ $attribute } eq q{};
        }
    }
    # Else if no attributes parameter was provided, use default attributes.
    else { %requested_attributes = %_default_attributes; }

    # If the sequence parameter was provided...
    if ( defined $parameters_ref->{'sequence'} ) {

        $sequence = $parameters_ref->{'sequence'};

        # Check that the element parameter is not empty.
        croak "Attempt to call as_XML with empty 'element' parameter"
            if $sequence eq q{};
    }
    # Else if no element parameter was provided, use default element.
    else { $sequence = $_default_sequence; }
    
    # If the element parameter was provided...
    if ( defined $parameters_ref->{'element'} ) {

        $element = $parameters_ref->{'element'};

        # Check that the element parameter is not empty.
        croak "Attempt to call as_XML with empty 'element' parameter"
            if $element eq q{};
    }
    # Else if no element parameter was provided, use default element.
    else { $element = $_default_element; }

    # If no content parameter was provided, use default content.
    my $content = $parameters_ref->{'content'} ||= $_default_content;

    # Check content parameter (and possibly croak)...
    my $tagged_text = $self->get_taggedtext();
    $tagged_text->_check_requested_fields( $content );

    my $string;

    # Initialisation.
    my $string_return;

    # Extracting the members of current sequence.
    my $ref_tab_token = ( $self->get_taggedtext() )->sequence();

    # Extracting the members of current sequence.
    my $ref_tab_hits = $self->get_hits();

    if ( @$ref_tab_hits > 0 ) {
        my $counter = 1;
        foreach my $hit (@$ref_tab_hits) {

            my $sequence_length = $hit->get_sequence_length();
            my $begin_index     = $hit->get_begin_index();
            $string_return .= "<" . $sequence . " number=\"" . $counter . "\">\n";

            for (
                my $i = $begin_index ;
                $i < ( $begin_index + $sequence_length ) ;
                $i++
              )
            {

                # Extracting current token.
                my $token = $ref_tab_token->[$i];
                
                # Make up the XML output...
            
                # SGML tags...
                if ( $token->is_SGML_tag ) {
                    $string .= $token->tag();
                }
                # Part-of-speech tags...
                else {
        
                    $string_return .= '<' . $element;
        
                    REQUESTED_ATTRIBUTES:
                    foreach my $requested_attribute (keys %requested_attributes) {
        
                        my $attribute_value =
                            $requested_attribute eq 'original' ? $token->original()
                          : $requested_attribute eq 'lemma'    ? $token->lemma()
                          :                                      $token->tag()
                          ;
        
                        $string_return .= q{ }
                                .  $requested_attributes{ $requested_attribute }
                                .  q{="}
                                .  $attribute_value
                                .  q{"}
                                ;
                    }
        
                    $string_return .= '>';
        
                    my $content_value =
                        $content eq 'original' ? $token->original()
                      : $content eq 'lemma'    ? $token->lemma()
                      :                          $token->tag()
                      ;
        
                    $string_return .= $content_value . '</' . $element . '>';
                }
        
                $string_return .= "\n";
            }
            $string_return .= "</" . $sequence .">\n";
            $counter++;
        }
    }
    else {
      # No match.
      return;
    }
    return $string_return;
}

#-----------------------------------------------------------------------------
# function add_element
#-----------------------------------------------------------------------------
# Synopsis:          adds an element to the sequences. This method is normaly
#                    called by the apply method from the
#                    class Filter
# attributes:        - begin_index (int)
#                    - sequence_length (int)
# Return values:     - none
#-----------------------------------------------------------------------------

sub add_element {

    my ( $self, %param ) = @_;

    # Creating the new object/text.
    my $hit = Lingua::TreeTagger::Filter::Result::Hit->new( \%param );

    # Extracting the members of current sequence.
    my $ref_tab_hits = $self->get_hits();

    # Adding the new element.
    push( @$ref_tab_hits, $hit );

    # Modifing the attribute.
    $self->_set_hits( $ref_tab_hits );

}



#===============================================================================
# Private methods
#===============================================================================


#-----------------------------------------------------------------------------
# function
#-----------------------------------------------------------------------------
# Synopsis:
# attributes:        -
# Return values:     -
#-----------------------------------------------------------------------------

#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Lingua::TreeTagger::Filter::Result - store and display the matching 
sequences.

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS
  
  use Lingua::TreeTagger::Filter;
  
  
  # Tagging a trial text.
  my $tagger = Lingua::TreeTagger->new(
      'language' => 'english',
  );
  
  my $text   = 'This is a trial';
  my $tagged_text = $tagger->tag_text(\$text);
  
  # Creating a filter.
  $filter = Lingua::TreeTagger::Filter->new( 'tag=DT#tag=NN');
  
  # Apply the filter to the taggedtext.
  $result = $filter->apply($tagged_text);
  
  # Display matching sequences as raw text.
  print($result->as_text());
  
  # Display matching sequences as XML.  
  print($result->as_XML());



=head1 Description

This module is part of the Lingua::TreeTagger::Filter distribution. It
 defines a class to store the matching sequences. It also handles the
display and extraction of result.   
See also Lingua::TreeTagger::Filter,
Lingua::TreeTagger::Filter::Result and
Lingua::TreeTagger::Filter::Result::Hit

=head1 METHODS

=over 4

=item C<new()>

This constructor is normally called by the method apply of the module
Lingua::TreeTagger::Filter and not directly by the user
The constructor has two required parameters.

=over 4

=item C<hits>

a reference to an array containing 
Lingua::TreeTagger::Filter::Result::Hit object  


=item C<taggedtext>

a Lingua::TreeTagger::Taggedtext object. It is the text on which the 
filter was applied.

=back


=item C<as_text()>

    # Outputs the matching tokens sequences in standard TreeTagger format.
    print $tagged_text->as_text();

    # Custom formatting.
    print $tagged_text->as_text( {
        'fields'             => [ qw( lemma original ) ],
        'field_delimiter'    => q{:},
        'token_delimiter'    => q{ },
        'sequence_delimiter' => q{;},
    } );


Outputs the matching tokens sequences in a TaggedText object as raw 
text. The only (optional) argument is a reference to a hash containing
the following optional named parameters:

=over 4

=item C<fields>

A reference to the list of token attributes to be included in the 
output, in the requested appearance order. Three such attributes are
supported: C<original> (the original word token), C<tag> 
(the part-of-speech tag), and C<lemma> (the lemma). Inclusion of other
attributes (or attributes not present in the TaggedText because they 
are not part of the output of the creator TreeTagger object) raises a
fatal exception. The value of this parameter defaults to 
C<[ qw( original tag lemma ) ]>, which corresponds to the standard 
output of TreeTagger.

=item C<field_delimiter>

The string that will be inserted between token attributes. Defaults 
to C<"\t">, which corresponds to the standard output of TreeTagger.

=item C<token_delimiter>

The string that will be inserted between tokens. Defaults to C<"\n">,
which corresponds to the standard output of TreeTagger.

=item C<sequence_delimiter>

The string that will be inserted between matching sequences. Defaults
to C<"\n">

=back

=item C<as_XML()>

    # Outputs the  matching tokens sequences in XML format.
    print $tagged_text->as_XML();

    # Custom XML formatting 
    #(e.g. C<foo_bis><foo bar="men" baz="man">NN</foo></foo_bis>).
    print $tagged_text->as_XML( {
        'element'       => 'foo',
        'sequence'      => 'foo_bis',
        'attributes'    => {
            'original'      => 'bar',
            'lemma'         => 'baz',
        },
        'content'       => 'tag',
    } ),


Outputs the  matching tokens sequences in a TaggedText object as a 
list of XML tags, with one tag per line. The only (optional) argument
is a reference to a  hash containing the following optional named
parameters:

=over 4

=item C<element>

The string that will be used as the name of the XML tag corresponding
to a token. Defaults to C<'w'>.

=item C<sequence>

The string that will be used as the name of the XML tag corresponding 
to a sequence. Defaults to C<'seq'>.

=item C<attributes>

A reference to a hash where (i) each key is a token attribute to be 
included in the output as an XML attribute and (ii) each value is the 
desired name for this XML attribute. As with method C<as_text()>, 
three token attributes are supported: C<original> (the original word 
token), C<tag> (the part-of-speech tag), and C<lemma> (the lemma). 
Inclusion of other token attributes (or attributes not present in the 
TaggedText because they are not part of the output of the creator 
TreeTagger object) raises a fatal exception. The value of this
parameter defaults to C<{ 'lemma' =E<gt> 'lemma', 'tag' =E<gt> 
'type' }>.

=item C<content>

A string specifying the token attribute that will be used as the 
content of the XML element. Defaults to C<'original'>.

=back

=item C<add_element()>

adds an element to the sequences. This method is normaly called by the 
apply method from the class Filter

=over 4

=item C<begin_index>

an Int corresponding to the index of the beginning from the matching 
sequence in  the taggedtext sequence (an array, attribute 'sequence' 
from the taggedtext object)


=item C<sequence_length>

an Int corresponding to the number of tokens composing the matching 
sequence

=back

=back

=head1 ACCESSORS

=over 4

=item C<get_hits()>

Read-only accessor for the 'get_hits' attribute

=item C<get_taggedtext()>

Read-only accessor for the 'get_taggedtext' attribute


=back

=head1 DIAGNOSTICS

=over 4

=item Attempt to call as_text with empty 'field' parameter

This exception is raised when method L<as_text()> is called with a 
reference to an empty list as value for parameter 'field'.

=item Empty attribute names are not allowed

This exception is raised when method L<as_XML()> is called with a 
value for parameter 'attributes' such that one or more attributes are 
associated with an empty string.

=item Attempt to call as_XML with empty 'element' parameter

This exception is raised when method L<as_XML()> is called with an 
empty string as value for the 'element' parameter.

=item Unavailable field(s) (...) requested

This exception is raised when the 'fields' parameter of method 
L<as_text()> or the 'attributes' or 'content' parameters of method 
L<as_XML()> specify one or more token attributes that are not 
available for this TaggedText object (because they were not part of 
the creator TreeTagger object's output).

=back

=head1 DEPENDENCIES

This is part of the Lingua::TreeTagger::Filter 
distribution. It is not intended to be used as an independent module.

This module requires module Moose and was developed using version 
1.09. Please report incompatibilities with earlier versions to the 
author.


=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Benjamin Gay (Benjamin.Gay@unil.ch)

Patches are welcome.


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

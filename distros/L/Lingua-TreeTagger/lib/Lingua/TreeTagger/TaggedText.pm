package Lingua::TreeTagger::TaggedText;

use Moose;
use Carp;
use List::Util qw( first );

use Lingua::TreeTagger::Token;

our $VERSION = '0.02';


#===============================================================================
# Initialization.
#===============================================================================

my @_default_field_order     = qw( original tag lemma );

my $_default_field_delimiter = "\t";
my $_default_token_delimiter = "\n";

my $_default_element         = 'w';

my %_default_attributes      = (
    'lemma' => 'lemma',
    'tag'   => 'type',
);

my $_default_content         = 'original';


#===============================================================================
# Public attributes.
#===============================================================================

has 'sequence'  => (
      is        => 'ro',
      isa       => 'ArrayRef[Lingua::TreeTagger::Token]',
      required  => 1,
);

has 'length'  => (
      is        => 'ro',
      isa       => 'Num',
      required  => 1,
);


#===============================================================================
# Private attributes.
#===============================================================================

has '_creator'  => (
      is        => 'ro',
      isa       => 'Lingua::TreeTagger',
      required  => 1,
);

has '_fields'  => (
      is        => 'ro',
      isa       => 'ArrayRef[Str]',
      required  => 1,
);


#===============================================================================
# Object construction hooks.
#===============================================================================

around BUILDARGS => sub {

    my ( $original_buildargs, $class, $array_ref, $creator ) = @_;

    # Array reference and reference to creator are required...
    croak "Attempt to create TaggedText object without array reference argument"
        if ! defined $array_ref;
    croak "Attempt to create TaggedText object without reference to creator"
        if ! defined $creator;

    # Initialize an array for storing the sequence of tokens.
    my @sequence;

    # Build the list of expected fields in a tagged line...
    my @expected_fields = _get_fields( $creator );

    TAGGED_LINES:
    foreach my $tagged_line (@$array_ref) {

        # If the line contains a single SGML tag...
        if ( $tagged_line =~ /^(<[^>]+>)\n?$/ ) {

            # Create and store a token for which is_SGML_tag is true.
            push @sequence, Lingua::TreeTagger::Token->new(
                'tag'           => $1,
                'is_SGML_tag'   => 1,
            )
        }

        # Otherwise if the line is really a tagged line...
        else {

            # Split line into fields.
            my @fields = split /[\t\n]/, $tagged_line;

            # Remove the last field if it is empty.
            if ( $fields[$#fields] eq q{} ) { pop @fields; }
        
            # Initialize an empty hash for this token's parameters.
            my %new_token_parameters;

            EXPECTED_FIELDS:
            foreach my $expected_field (@expected_fields) {

                # Add this field to the parameter hash.
                $new_token_parameters{ $expected_field } = shift @fields;
            }

            # Create and store a token for which is_SGML_tag is not true.
            push @sequence, Lingua::TreeTagger::Token->new(
                %new_token_parameters,
                'is_SGML_tag'   => 0,
            )
        }
    }

    # Gather attributes to be forwarded to constructor...
    my %forwarded_attributes = (
        'sequence'  => \@sequence,
        'length'    => scalar @sequence,
        '_creator'  => $creator,
        '_fields'   => \@expected_fields,
    );

    return $class->$original_buildargs( %forwarded_attributes );
};


#===============================================================================
# Public instance methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method as_text
#-------------------------------------------------------------------------------
# Synopsis:      Returns the content of a TaggedText in raw text format (i.e.
#                the standard output of TreeTagger).
# Arguments:     An optional reference to a hash with the following optional
#                named parameters:
#                - 'fields':          a reference to a list of fields.
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
        $self->_check_requested_fields( @requested_fields );
    }
    # Else if no fields parameter was provided, use default field order.
    else { @requested_fields = @_default_field_order; }

    # Use default field and token delimiters if they were not provided.
    my $field_delimiter
        = $parameters_ref->{'field_delimiter'} ||= $_default_field_delimiter;
    my $token_delimiter
        = $parameters_ref->{'token_delimiter'} ||= $_default_token_delimiter;

    my $string;

    # Make up the text output...
    TOKENS:
    foreach my $token (@{ $self->sequence() }) {

        # SGML tags...
        if ( $token->is_SGML_tag ) {
            $string .= $token->tag();
        }
        # Part-of-speech tags...
        else {

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

            $string .= join $field_delimiter, @token_fields;
        }

        $string .= $token_delimiter;
    }

    return $string;
}


#-------------------------------------------------------------------------------
# Method as_XML
#-------------------------------------------------------------------------------
# Synopsis:      Returns the content of a TaggedText in XML format.
# Arguments:     An optional reference to a hash with the following optional
#                named parameters:
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
    my ( %requested_attributes, $element );

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
    _check_requested_fields( $content );

    my $string;

    # Make up the XML output...
    TOKENS:
    foreach my $token (@{ $self->sequence() }) {

        # SGML tags...
        if ( $token->is_SGML_tag ) {
            $string .= $token->tag();
        }
        # Part-of-speech tags...
        else {

            $string .= '<' . $element;

            REQUESTED_ATTRIBUTES:
            foreach my $requested_attribute (sort keys %requested_attributes) {

                my $attribute_value =
                    $requested_attribute eq 'original' ? $token->original()
                  : $requested_attribute eq 'lemma'    ? $token->lemma()
                  :                                      $token->tag()
                  ;

                $string .= q{ }
                        .  $requested_attributes{ $requested_attribute }
                        .  q{="}
                        .  $attribute_value
                        .  q{"}
                        ;
            }

            $string .= '>';

            my $content_value =
                $content eq 'original' ? $token->original()
              : $content eq 'lemma'    ? $token->lemma()
              :                          $token->tag()
              ;

            $string .= $content_value . '</' . $element . '>';
        }

        $string .= "\n";
    }

    return $string;
}


#===============================================================================
# Private instance methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method _check_requested_fields
#-------------------------------------------------------------------------------
# Synopsis:      Check if every attribute in a list is available for this
#                TaggedText and throw an exception otherwise.
# Arguments:     A list of requested fields.
# Return values: None.
#-------------------------------------------------------------------------------

sub _check_requested_fields {
    my ( $self, @requested_fields ) = @_;

    # Check requested fields...
    my @unavailable_fields;
    foreach my $requested_field (@requested_fields) {
        if ( ! first { $_ eq $requested_field } @{ $self->_fields() } ) {
            push @unavailable_fields, $requested_field;
        }
    }

    # Throw exception if there are unknown fields...
    if ( @unavailable_fields ) {
        my $error_message .= 'Unavailable field(s) ('
                          .  join( q{, }, @unavailable_fields )
                          .  ') requested'
                          ;
        croak $error_message;
    }

    return;
}


#===============================================================================
# Private class methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Method _get_fields
#-------------------------------------------------------------------------------
# Synopsis:      Returns the ordered list of fields in a TaggedText, based on
#                the creator tagger's options.
# Arguments:     A reference to the creator tagger.
# Return values: An array of fields (i.e. strings).
#-------------------------------------------------------------------------------

sub _get_fields {
    my ( $creator ) = @_;
    my @fields;
    
    # Original...
    if ( first { $_ eq '-token' } @{ $creator->options() } ) {
      push @fields, 'original';
    }
    
    # Tag...
    push @fields, 'tag';
    
    # Lemma...
    if ( first { $_ eq '-lemma' } @{ $creator->options() } ) {
      push @fields, 'lemma';
    }
    
    return @fields;
}


#===============================================================================
# Standard Moose cleanup.
#===============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::TreeTagger::TaggedText - Storing and manipulating the output of
TreeTagger.

=head1 VERSION

This documentation refers to Lingua::TreeTagger::TaggedText version 0.01.

=head1 SYNOPSIS

    use Lingua::TreeTagger;

    # Create a Tagger object.
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
    );

    # Tag some text and get a new TaggedText object.
    my $tagged_text = $tagger->tag_file( 'path/to/some/file.txt' );

    # A TaggedText object is a sequence of Lingua::TreeTagger::Token objects,
    # which can be stringified as raw text...
    print $tagged_text->as_text();

    # ... or in XML format.
    print $tagged_text->as_XML();
    
    # Token objects may be accessed directly for more specific purposes.
    foreach my $token ( @{ $tagged_text->sequence() } ) {
        print $token->original(), '|', $token->tag(), "\n";
    }

=head1 DESCRIPTION

This module is part of the Lingua::TreeTagger distribution. It defines a class
for storing and manipulating the output of TreeTagger in an object-oriented way.
See also L<Lingua::TreeTagger> and L<Lingua::TreeTagger:Token>.

=head1 METHODS

=over 4

=item C<new()>

Creates a new TaggedText object. This is normally called by a Lingua::TreeTagger
object rather than directly by the user. It requires two arguments:

=over 4

=item 1

A reference to a list containing the textual output of TreeTagger: each item
in the list is a carriage-return-terminated line containing either (i) exactly
one part-of-speech tag and possibly a token and a lemma (tab-delimited) or
(ii) an SGML tag.

=item 2

A reference to the Lingua::TreeTagger object that has generated the previous
list.

=back

=item C<as_text()>

    # Outputs token sequence in standard TreeTagger format.
    print $tagged_text->as_text();

    # Custom formatting.
    print $tagged_text->as_text( {
        'fields'          => [ qw( lemma original ) ],
        'field_delimiter' => q{:},
        'token_delimiter' => q{ },
    } );


Outputs the sequence of tokens in a TaggedText object as raw text. The only
(optional) argument is a reference to a hash containing the following optional
named parameters:

=over 4

=item C<fields>

A reference to the list of token attributes to be included in the output, in the
requested appearance order. Three such attributes are supported: C<original>
(the original word token), C<tag> (the part-of-speech tag), and C<lemma> (the
lemma). Inclusion of other attributes (or attributes not present in the
TaggedText because they are not part of the output of the creator TreeTagger
object) raises a fatal exception. The value of this parameter defaults to
C<[ qw( original tag lemma ) ]>, which corresponds to the standard output of
TreeTagger.

=item C<field_delimiter>

The string that will be inserted between token attributes. Defaults to C<"\t">,
which corresponds to the standard output of TreeTagger.

=item C<token_delimiter>

The string that will be inserted between tokens. Defaults to C<"\n">, which
corresponds to the standard output of TreeTagger.

=back

NB: if SGML tags are present in the token sequence, they receive no particular
formatting beyond the concatenation of the requested token delimiter.

=item C<as_XML()>

    # Outputs token sequence in XML format.
    print $tagged_text->as_XML();

    # Custom XML formatting (e.g. C<foo bar="men" baz="man">NN</foo>).
    print $tagged_text->as_XML( {
        'element'       => 'foo',
        'attributes'    => {
            'original'      => 'bar',
            'lemma'         => 'baz',
        },
        'content'       => 'tag',
    } ),


Outputs the sequence of tokens in a TaggedText object as a list of XML tags,
with one tag per line. The only (optional) argument is a reference to a hash
containing the following optional named parameters:

=over 4

=item C<element>

The string that will be used as the name of the XML tag. Defaults to C<'w'>.

=item C<attributes>

A reference to a hash where (i) each key is a token attribute to be included in
the output as an XML attribute and (ii) each value is the desired name for this
XML attribute. As with method C<as_text()>, three token attributes are
supported: C<original> (the original word token), C<tag> (the part-of-speech
tag), and C<lemma> (the lemma). Inclusion of other token attributes (or
attributes not present in the TaggedText because they are not part of the output
of the creator TreeTagger object) raises a fatal exception. The value of this
parameter defaults to C<{ 'lemma' =E<gt> 'lemma', 'tag' =E<gt> 'type' }>.

=item C<content>

A string specifying the token attribute that will be used as the content of the
XML element. Defaults to C<'original'>.

=back

NB: if SGML tags are present in the token sequence, they receive no particular
formatting.

=back

=head1 ACCESSORS

=over 4

=item C<sequence()>

Read-only accessor for the sequence of tokens in a TaggedText object. Returns a
reference to an array of tokens, and thus should be de-referenced (see
L</Synopsis>).

=item C<length()>

Read-only accessor for the 'length' attribute of a TaggedText
object.

=back

=head1 DIAGNOSTICS

=over 4

=item Attempt to create TaggedText object without array reference argument

This exception is raised by the class constructor when a new TaggedText object
is created without passing a reference to a list of tagged lines.

=item Attempt to create TaggedText object without reference to creator

This exception is raised by the class constructor when a new TaggedText object
is created without passing a reference to the creator TreeTagger object (see
L<Bugs and limitations>).

=item Attempt to call as_text with empty 'field' parameter

This exception is raised when method L<as_text()> is called with a reference to
an empty list as value for parameter 'field'.

=item Empty attribute names are not allowed

This exception is raised when method L<as_XML()> is called with a value for
parameter 'attributes' such that one or more attributes are associated with
an empty string.

=item Attempt to call as_XML with empty 'element' parameter

This exception is raised when method L<as_XML()> is called with an empty string
as value for the 'element' parameter.

=item Unavailable field(s) (...) requested

This exception is raised when the 'fields' parameter of method L<as_text()> or
the 'attributes' or 'content' parameters of method L<as_XML()> specify one or more
token attributes that are not available for this TaggedText object (because they
 were not part of the creator TreeTagger object's output).

=back

=head1 DEPENDENCIES

This module is part of the Lingua::TreeTagger distribution. It is not intended
to be used as an independent module. In particular, it uses module
L<Lingua::TreeTagger::Token>, version 0.01.

It requires module Moose and was developed using version 1.09. Please
report incompatibilities with earlier versions to the author.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

The current version has the limitation that every TaggedText object must hold
a reference to the TreeTagger object that created it. Methods L<as_text()> and
L<as_XML()> use this internally to determine whether token attributes requested
to appear in their output are actually available for this TaggedText object.
This results in a tight coupling of the TaggedText and TreeTagger classes, which
is obviously not desirable. In a future version, I expect to implement a better
solution based on Moose's introspection capabilities

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::TreeTagger>, L<Lingua::TreeTagger::Token>



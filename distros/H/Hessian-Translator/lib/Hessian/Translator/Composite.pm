package Hessian::Translator::Composite;

use Moose::Role;

with 'Hessian::Translator::Envelope';

#
use YAML;
use Hessian::Exception;
use Hessian::Simple;
use Contextual::Return;
use feature "switch";
#use Smart::Comments;

sub assemble_class {    #{{{
    ### assemble_class
    my ( $self,             $args )       = @_;
    my ( $class_definition, $class_type ) = @{$args}{qw/class_def type/};
    my $datastructure = pop @{ $self->reference_list() } || $args->{data};
    my $simple_obj = bless $datastructure, $class_type;
    push @{ $self->reference_list() }, $simple_obj;

    #    $self->reference_list()->[-1] = $simple_obj;
    {
        ## no critic
        no strict 'refs';
        push @{ $class_type . '::ISA' }, 'Hessian::Simple';
        ## use critic
    }
    foreach my $field ( @{ $class_definition->{fields} } ) {
        $simple_obj->meta()->add_attribute( $field, is => 'rw' );
        my $value = $self->deserialize_data();
        $simple_obj->$field($value);
    }
    return $simple_obj;

}

sub read_typed_list_element {    #{{{
    ### read_typed_list_element
    my ( $self, $type, $args ) = @_;
    my ( $element, $first_bit );
    if ( $args->{first_bit} ) {
        $first_bit = $args->{first_bit};
    }
    else {
        $first_bit = $self->read_from_inputhandle(1);
    }
    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit eq $self->end_of_datastructure_symbol();
    my $map_type = 'map';
    given ($type) {
        when (/boolean/) {
            $element = $self->read_boolean_handle_chunk($first_bit);
        }
        when (/int/) {
            $element = $self->read_integer_handle_chunk($first_bit);
        }
        when (/long/) {
            $element = $self->read_long_handle_chunk($first_bit);
        }
        when (/double/) {
            $element = $self->read_double_handle_chunk($first_bit);
        }
        when (/date/) {
            $element = $self->read_date_handle_chunk($first_bit);
        }
        when (/string/) {
            $element = $self->read_string_handle_chunk($first_bit);
        }
        when (/binary/) {
            $element = $self->read_binary_handle_chunk($first_bit);
        }
        when (/list/) {
            $element = $self->read_composite_datastructure($first_bit);
        }
    }
    return $element;
}

sub read_list_type {    #{{{
    ### read_list_type
    my $self        = shift;
    my $type_length = $self->read_from_inputhandle(1);
    my $type        = $self->read_string_handle_chunk($type_length);
    return $type;
}

sub store_fetch_type {    #{{{
    ### store_fetch_type
    my ( $self, $entity_type ) = @_;
    my $type;
    if ( $entity_type =~ /^([^\x00-\x0f].*)/ ) {
        $type = $1;
        push @{ $self->type_list() }, $type;
    }
    else {
        my $integer = unpack 'C*', $entity_type;
        $type = $self->type_list()->[$integer] if $integer;

    }
    return $type;
}

sub store_class_definition {    #{{{
    ### store_class_definition
    my ( $self, $class_type ) = @_;
    my $length           = $self->read_from_inputhandle(1);
    my $number_of_fields = $self->read_integer_handle_chunk($length);
    my @field_list;

    foreach my $field_index ( 1 .. $number_of_fields ) {

        # using the wrong function here, but who cares?
        my $field = $self->read_hessian_chunk();
        push @field_list, $field;

    }

    my $class_definition = { type => $class_type, fields => \@field_list };
    push @{ $self->class_definitions() }, $class_definition;
    return $class_definition;
}

sub read_hessian_chunk {    #{{{
    ### read_hessian_chunk
    my ( $self, $args ) = @_;
    my ( $first_bit, $element );

    #    my $end_symbol = $self->end_of_datastructure_symbol();
    if ( 'HASH' eq ( ref $args ) and $args->{first_bit} ) {
        $first_bit = $args->{first_bit};
    }
    else {
        $first_bit = $self->read_from_inputhandle(1);
    }
    EndOfInput::X->throw( error => 'Reached end of datastructure.' )
      if $first_bit eq $self->end_of_datastructure_symbol();
    return $self->read_simple_datastructure($first_bit);
}

sub fetch_class_for_data {    #{{{
    ### fetch_class_for_data
    my $self                    = shift;
    my $length                  = $self->read_from_inputhandle(1);
    my $class_definition_number = $self->read_integer_handle_chunk($length);
    return $self->instantiate_class($class_definition_number);

}

sub instantiate_class {    #{{{
    ### instantiate_class
    my ( $self, $index ) = @_;
    my $class_definitions = $self->class_definitions;
    my $class_definition  = $self->class_definitions()->[$index];
    my $class_type        = $class_definition->{type};
    return unless $class_type;
    return $self->assemble_class(
        {
            class_def => $class_definition,
            type      => $class_type
        }
    );
}

sub read_list_length {    #{{{
    ### read_list_length
    my ( $self, $first_bit ) = @_;

    my $array_length;
    if ( $first_bit =~ /[\x56\x58]/ ) {    # read array length
        my $length = $self->read_from_inputhandle(1);
        $array_length = $self->read_integer_handle_chunk($length);
    }
    elsif ( $first_bit =~ /[\x70-\x77]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x70;
    }
    elsif ( $first_bit =~ /[\x78-\x7f]/ ) {
        my $hex_bit = unpack 'C*', $first_bit;
        $array_length = $hex_bit - 0x78;
    }
    elsif ( $first_bit =~ /\x6c/ ) {
        $array_length = $self->read_integer_handle_chunk('I');
    }
    ### found array length: $array_length
    return $array_length;
}

sub write_hessian_chunk {    #{{{
    ### write_hessian_chunk
    my ( $self, $element ) = @_;
    my $hessian_element;
    my $element_type = ref $element ? ref $element : \$element;
    given ("$element_type") {
        when (/SCALAR/) {
            $hessian_element = $self->write_scalar_element($element);
        }
        when (/DateTime/) {
            $hessian_element = $self->write_date($element);
        }
        default {
            my $reference_list = $self->reference_list();
            my @list           = @{$reference_list};
            my ( $referenced_index, $found_reference );
            foreach my $index ( 0 .. $#{$reference_list} ) {
                my $referenced_element = $reference_list->[$index];
                if ( $element == $referenced_element ) {
                    $found_reference  = 1;
                    $referenced_index = $index;
                    last;
                }
            }
            if ($found_reference) {
                $hessian_element =
                  $self->write_referenced_data($referenced_index);
            }
            else {
                push @{ $self->reference_list() }, $element;
                $hessian_element = $self->write_composite_element($element);
            }
        }
    }
    return $hessian_element;
}

sub write_composite_element {    #{{{
    ### write_composite_element
    my ( $self, $datastructure ) = @_;
    my $element_type =
      ref $datastructure ? ref $datastructure : \$datastructure;
    ### element type: $element_type
    my $hessian_string;
    given ($element_type) {
        when (/HASH/) {
            $hessian_string = $self->write_hessian_hash($datastructure);
        }
        when (/ARRAY/) {
            $hessian_string = $self->write_hessian_array($datastructure);
        }
        default {
            $hessian_string = $self->write_object($datastructure);
        }
    }
    return $hessian_string;
}

sub write_scalar_element {    #{{{
    my ( $self, $element ) = @_;

    my $hessian_element;
    given ($element) {       # Integer or String
        when (/^-?[0-9]+$/) {
            $hessian_element = $self->write_integer($element);
        }
        when (/^-?[0-9]*\.[0-9]+/) {
            $hessian_element = $self->write_double($element);
        }
        when (/^[\x20-\x7e\xa1-\xff]+$/) {    # a string
            my @chunks = $element =~ /(.{1,66})/g;
            $hessian_element = $self->write_hessian_string( \@chunks );
        }
    }
    return $hessian_element;
}

sub write_hessian_array {    #{{{
    my ( $self, $datastructure ) = @_;
    my $anonymous_array_string = "V";
    foreach my $element ( @{$datastructure} ) {
        my $hessian_element = $self->write_hessian_chunk($element);
        $anonymous_array_string .= $hessian_element;
    }
    $anonymous_array_string .= "z";
    return $anonymous_array_string;
}

sub read_composite_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    return $self->read_composite_data($first_bit);
}

#sub read_map_handle {    #{{{
#    my $self    = shift;
#    my $v1_type = $self->read_v1_type();
#    my ( $entity_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
#    my $type;
#    $type = $self->store_fetch_type($entity_type) if $entity_type;
#    my $key;
#    if ($next_bit) {
#        $key = $self->read_hessian_chunk( { first_bit => $next_bit } );
#    }

#    # For now only accept integers or strings as keys
#    my @key_value_pairs;
#  MAPLOOP:
#    {
#        eval { $key = $self->read_hessian_chunk(); } unless $key;
#        last MAPLOOP
#          if Exception::Class->caught('EndOfInput::X')
#              or Exception::Class->caught('MessageIncomplete::X');
#        my $value = $self->read_hessian_chunk();
#        push @key_value_pairs, $key => $value;
#        undef $key;
#        redo MAPLOOP;
#    }

#    # should throw an exception if @key_value_pairs has an odd number of
#    # elements

#    my $datastructure = $self->reference_list()->[-1];
#    my $hash          = {@key_value_pairs};
#    foreach my $key ( keys %{$hash} ) {
#        $datastructure->{$key} = $hash->{$key};
#    }
#    my $map = defined $type ? bless $datastructure => $type : $datastructure;
#    return $map;

#}

sub read_v1_type {    #{{{
    my ( $self, $list_bit ) = @_;
    my ( $type, $first_bit, $array_length );
    if ( $list_bit and $list_bit =~ /\x76/ ) {    # v
        $type         = $self->read_from_inputhandle(1);
        $array_length = $self->read_from_inputhandle(1);
    }
    else {
        $first_bit = $self->read_from_inputhandle(1);
        if ( $first_bit =~ /t/ ) {
            $type = $self->read_hessian_chunk( { first_bit => 'S' } );
        }
    }

    return { type => $type, next_bit => $array_length } if $type;
    return { next_bit => $first_bit };
}

#sub read_remote_object {    #{{{
#    my $self        = shift;
#    ### read_remote_object
#    my $remote_type = $self->read_v1_type()->{type};
#    $remote_type =~ s/\./::/g;
#    my $class_definition = {
#        type   => $remote_type,
#        fields => ['remote_url']
#    };

#    ### class definition: Dump($class_definition)
#    return $self->assemble_class(
#        {
#            type      => $remote_type,
#            data      => {},
#            class_def => $class_definition
#        }
#    );
#}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::Composite - Translate composite datastructures to and from hessian.

=head1 SYNOPSIS

These methods are meant for internal use only.

=head1 DESCRIPTION


This module implements the basic methods needed for processing complex
datatypes like arrays, hash maps and classes.

=head1 INTERFACE


=head2 assemble_class

Constructs a class from raw Hessian data using either a class definition from
the class definition list and encoded object data for the attributes.

=head2 fetch_class_for_data


=head2 instantiate_class

Instantiates the freshly assembled class data. 


=head2 read_composite_datastructure

Reads a complex datastructure (ARRAY, HASH or object) from the Hessian stream.

=head2 read_hessian_chunk


=head2 read_list_length


=head2 read_list_type


=head2 read_typed_list_element


=head2 store_class_definition


=head2 store_fetch_type


=head2 write_composite_element


=head2 write_hessian_chunk


=head2 write_list


=head2 write_map

=head2 write_scalar_element

=head2 write_hessian_date

Writes a L<DateTime|DateTime> object into the outgoing Hessian message. 


=head2 read_map_handle

Read a map (perl HASH) from the stream. If a type attribute is present, the
hash will be I<blessed> into an object.


=head2 read_typed_list


=head2 read_untyped_list


=head2 read_v1_type

Read the type attribute (if present) from a Hessian 1.0 list or map.

=head2 read_remote_object

=head2 write_hessian_array

Writes an array datastructure into the outgoing Hessian message. 

Note: This object only writes B<untyped variable length> arrays.




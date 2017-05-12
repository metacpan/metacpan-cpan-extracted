package Hessian::Translator::V2;

use Moose::Role;

#
use YAML;
use Hessian::Exception;
use Hessian::Simple;
#use Smart::Comments;
use feature "switch";

has 'string_chunk_prefix'       => ( is => 'ro', isa => 'Str', default => 'R' );
has 'string_final_chunk_prefix' => ( is => 'ro', isa => 'Str', default => 'S' );
has 'end_of_datastructure_symbol' =>
  ( is => 'ro', isa => 'Str', default => 'Z' );

sub read_message_chunk_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $datastructure;
    ### message chunk data
    ### first bit: $first_bit
    given ($first_bit) {
        when (/\x48/) {            # TOP with version#{{{
            $self->in_interior(0);
            if ( $self->chunked() ) {    # use as hashmap if chunked
                my $params = { first_bit => $first_bit };
                $datastructure = $self->deserialize_data($params);
            }
            else {
                ### reading version
                my $hessian_version = $self->read_version();
                $datastructure = { hessian_version => $hessian_version };
            }
        }

       #        when /\x43/ {                    # Hessian Remote Procedure Call
       #            if ( $self->in_interior() ) {

        #                my $params = { first_bit => $first_bit };
        #                $datastructure = $self->deserialize_data($params);
        #            }
        #            else {

#          # call will need to be dispatched to object designated in some kind of
#          # service descriptor
#                my $rpc_data = $self->read_rpc();
#                $datastructure = { call => $rpc_data };

        #            }
        #        }
        when (/\x45/) {    # Envelope
            $datastructure = $self->read_envelope();
        }
        when (/\x46/) {    # Fault
            $self->in_interior(1);
            my $result                = $self->deserialize_data();
            my $exception_name        = $result->{code};
            my $exception_description = $result->{message};
            $exception_name->throw( error => $exception_description );
        }
        when (/\x52/) {    # Reply
            $self->in_interior(1);
            my $reply_data = $self->deserialize_data();
            $datastructure = { reply_data => $reply_data };
        }
        default {
            my $params = { first_bit => $first_bit };
            $datastructure = $self->deserialize_data($params);
        }
    }
    return $datastructure;
}

sub read_composite_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my ( $datastructure, $save_reference );
    given ($first_bit) {
        when (/[\x55\x56\x70-\x77]/) {    # typed lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list( $first_bit, );
        }

        when (/[\x57\x58\x78-\x7f]/ ){    # untyped lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_untyped_list( $first_bit, );
        }
        when (/\x48/) {
            push @{ $self->reference_list() }, {
            };
            $datastructure = $self->read_map_handle();
        }
        when (/\x4d/) {                   # typed map

            push @{ $self->reference_list() }, {
            };

            # Get the type for this map. This seems to be more like a
            # perl style object or "blessed hash".

            my $entity_type = $self->read_hessian_chunk();
            my $map_type    = $self->store_fetch_type($entity_type);
            my $map         = $self->read_map_handle();
            $datastructure = bless $map, $map_type;

        }
        when (/[\x43\x4f\x60-\x6f]/) {
            if ( $first_bit !~ /\x43/ ) {
                push @{ $self->reference_list() }, {
                };
                $datastructure = $self->read_class_handle( $first_bit, );
            }
            else {
                $self->read_class_handle( $first_bit, );
                return;
            }

        }
    }

    #    push @{ $self->reference_list() }, $datastructure
    #      if $save_reference;
    return $datastructure;

}

sub read_typed_list {    #{{{
    my ( $self, $first_bit ) = @_;
    my $entity_type   = $self->read_hessian_chunk();
    my $type          = $self->store_fetch_type($entity_type);
    my $array_length  = $self->read_list_length($first_bit);
    my $datastructure = $self->reference_list()->[-1];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_typed_list_element($type); };
        if ( my $e = $@ ) {
            if ( $e->isa('MessageIncomplete::X')
                or ( $first_bit =~ /\x55/ and $e->isa('EndOfInput::X') ) )
            {
                last LISTLOOP;
            }
        }

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}

sub read_class_handle {    #{{{
    my ( $self, $first_bit ) = @_;
    my ( $save_reference, $datastructure );
    given ($first_bit) {
        when (/\x43/) {      # Read class definition
            my $class_type = $self->read_hessian_chunk();
            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            $self->store_class_definition($class_type);

            return;

       #            $datastructure = $self->store_class_definition($class_type);
        }
        when (/\x4f/) {    # Read hessian data and create instance of class
            $save_reference = 1;
            $datastructure  = $self->fetch_class_for_data();
        }
        when (/[\x60-\x6f]/) {    # The class definition is in the ref list
            $save_reference = 1;
            my $hex_bit = unpack 'C*', $first_bit;
            my $class_definition_number = $hex_bit - 0x60;
            $datastructure = $self->instantiate_class($class_definition_number);
        }
    }

    #    push @{ $self->reference_list() }, $datastructure
    #      if $save_reference;
    return $datastructure;
}

sub read_map_handle {    #{{{
    my $self = shift;

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        my $key;
        eval { $key = $self->read_hessian_chunk(); };
        last if not $key or $key eq '';
        last MAPLOOP
          if ( Exception::Class->caught('EndOfInput::X')
            or Exception::Class->caught('MessageIncomplete::X') );
        my $value = $self->read_hessian_chunk();
        push @key_value_pairs, $key => $value;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements
    my $hash          = {@key_value_pairs};
    my $datastructure = $self->reference_list()->[-1];
    foreach my $key ( keys %{$hash} ) {
        $datastructure->{$key} = $hash->{$key};
    }
    return $datastructure;

}

sub read_untyped_list {    #{{{
    my ( $self, $first_bit ) = @_;
    my $array_length  = $self->read_list_length( $first_bit, );
    my $datastructure = [];
    my $index         = 0;
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_hessian_chunk(); };
        if ( my $e = $@ ) {
            if ( $e->isa('MessageIncomplete::X')
                or ( $first_bit =~ /\x57/ and $e->isa('EndOfInput::X') ) )
            {
                last LISTLOOP;
            }
        }
        if ( defined $element ) {
            push @{$datastructure}, $element;
            $index++;

        }
        redo LISTLOOP;
    }
    return $datastructure;
}

sub read_simple_datastructure {    #{{{
    my ( $self, $first_bit ) = @_;
    my $element;
    given ($first_bit) {
        when (/\x4e/) {              # 'N' for NULL
            $element = undef;
        }
        when (/[\x46\x54]/ ){        # 'T'rue or 'F'alse
            $element = $self->read_boolean_handle_chunk($first_bit);
        }
        when (/[\x49\x80-\xbf\xc0-\xcf\xd0-\xd7]/ ){
            $element = $self->read_integer_handle_chunk($first_bit);
        }
        when (/[\x4c\x59\xd8-\xef\xf0-\xff\x38-\x3f]/) {
            $element = $self->read_long_handle_chunk($first_bit);
        }
        when (/[\x44\x5b-\x5f]/) {
            $element = $self->read_double_handle_chunk($first_bit);
        }
        when (/[\x4a\x4b]/) {
            $element = $self->read_date_handle_chunk($first_bit);
        }
        when (/[\x52\x53\x00-\x1f\x30-\x33]/) {    #   for version 1: \x73
            $element = $self->read_string_handle_chunk($first_bit);
        }
        when (/[\x41\x42\x20-\x2f]/) {
            $element = $self->read_binary_handle_chunk($first_bit);
        }
        when (/[\x43\x4d\x4f\x48\x55-\x58\x60-\x6f\x70-\x7f]/)
        {                                        # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        when (/\x51/) {
            my $reference_id = $self->read_hessian_chunk();
            $element = $self->reference_list()->[$reference_id];

        }
    }
    return $element;

}

sub read_rpc {    #{{{
    my $self      = shift;
    my $call_data = {};
    my $call_args;
    my $method_name = $self->read_hessian_chunk();
    $call_data->{method} = $method_name;
    my $number_of_args = $self->read_hessian_chunk();
    foreach ( 1 .. $number_of_args ) {
        my $argument = $self->read_hessian_chunk();
        push @{$call_args}, $argument;
    }
    $call_data->{arguments} = $call_args;
    return $call_data;

}

sub write_hessian_hash {    #{{{
    my ( $self, $datastructure ) = @_;
    my $anonymous_map_string = "H";    # start an anonymous hash
    foreach my $key ( keys %{$datastructure} ) {
        my $hessian_key   = $self->write_scalar_element($key);
        my $value         = $datastructure->{$key};
        my $hessian_value = $self->write_hessian_chunk($value);
        $anonymous_map_string .= $hessian_key . $hessian_value;
    }
    $anonymous_map_string .= $self->end_of_datastructure_symbol();
    return $anonymous_map_string;
}

sub write_typed_map {    #{{{
    my ( $self, $datastructure ) = @_;
    my $type             = ref $datastructure;
    my $hessian_type     = $self->write_scalar_element($type);
    my $typed_map_string = 'M' . $hessian_type;

    foreach my $key ( keys %{$datastructure} ) {
        my $hessian_key   = $self->write_scalar_element($key);
        my $value         = $datastructure->{$key};
        my $hessian_value = $self->write_hessian_chunk($value);
        $typed_map_string .= $hessian_key . $hessian_value;
    }
    $typed_map_string .= $self->end_of_datastructure_symbol();
    return $typed_map_string;
}

sub write_hessian_array {    #{{{
    my ( $self, $datastructure ) = @_;
    my $anonymous_array_string = "\x57";
    foreach my $element ( @{$datastructure} ) {
        my $hessian_element = $self->write_hessian_chunk($element);
        $anonymous_array_string .= $hessian_element;
    }
    $anonymous_array_string .= "Z";
    return $anonymous_array_string;
}

sub write_hessian_string {    #{{{
    my ( $self, $chunks ) = @_;
    return $self->write_string( { chunks => $chunks } );

}

sub write_object {    #{{{
    my ( $self, $datastructure ) = @_;
    return $self->write_typed_map($datastructure);
#    my $type              = ref $datastructure;
#    my @fields            = keys %{$datastructure};
#    my @class_definitions = @{ $self->class_definitions() };
#    {
#        ## no critic
#        no strict 'refs';
#        push @{ $type . '::ISA' }, 'Hessian::Simple';
#        ## use critic
#    }
#    foreach my $field (@fields) {
#        $datastructure->meta()->add_attribute( $field, is => 'rw' );
#    }
#    my ( $hessian_string, $class_already_stored );
#    my $index = 0;
#    foreach my $class_def (@class_definitions) {
#        my $defined_type = $class_def->{type};
#        if ( $defined_type eq $type ) {
#            $class_already_stored = 1;
#            last;
#        }
#        $index++;
#    }
#    if ( not $class_already_stored ) {
#        my $hessian_type = $self->write_scalar_element($type);
#        $hessian_string = "C" . $hessian_type;
#        my $num_of_fields = scalar @fields;
#        $hessian_string .= ( $self->write_scalar_element($num_of_fields) );
#        foreach my $field (@fields) {
#            my $hessian_field = $self->write_scalar_element($field);
#            $hessian_string .= $hessian_field;
#        }
#        my $store_definition = { type => $type, fields => \@fields };
#        push @{ $self->class_definitions() }, $store_definition;
#        $index = ( scalar @{ $self->class_definitions } ) - 1;
#    }
#    $hessian_string .= 'O';
#    $hessian_string .= ( $self->write_scalar_element($index) );
#    foreach my $field (@fields) {
#        my $value = $datastructure->$field();

#        #        my $value = $datastructure->{$field};
#        $hessian_string .= ( $self->write_scalar_element($value) );
#        ### hessian_string: $hessian_string
#    }
#    return $hessian_string;
}

sub write_referenced_data {    #{{{
    my ( $self, $index ) = @_;
    my $hessian_string = "\x51";
    my $hessian_index  = $self->write_scalar_element($index);
    $hessian_string .= $hessian_index;
    return $hessian_string;
}

sub write_hessian_call {    #{{{
    my ( $self, $datastructure ) = @_;
    my $hessian_call   = "C";
    my $method         = $datastructure->{method};
    my $hessian_method = $self->write_scalar_element($method);
    $hessian_call .= $hessian_method;
    my $arguments   = $datastructure->{arguments};
    my $num_of_args = scalar @{$arguments};
    my $hessian_num = $self->write_scalar_element($num_of_args);
    $hessian_call .= $hessian_num;

    foreach my $argument ( @{$arguments} ) {
        my $hessian_arg = $self->write_hessian_chunk($argument);
        $hessian_call .= $hessian_arg;
    }
    return $hessian_call;
}

sub serialize_message {    #{{{
    my ( $self, $datastructure ) = @_;
    my $result = $self->write_hessian_message($datastructure);
    ### result: $result
    return $result if $self->chunked();
    my $message = "H\x02\x00" . $result;
    return $message;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::V2 - Translate datastructures to and from Hessian 2.0.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE


=head2 read_class_handle

Read a class definition from the Hessian stream and possibly create an object
from the definition and given parameters.

=head2 read_composite_data

Read Hessian 2.0 specific datastructures from the stream.

=head2 read_map_handle

Read a map (perl HASH) from the stream.

=head2 read_message_chunk_data

Read Hessian 2.0 envelope.  For version 2.0 of the protocol this applies to
I<envelope>, I<packet>, I<reply>, I<call> and I<fault> objects.


=head2 read_rpc

Read a remote procedure call from the input stream.

=head2 read_simple_datastructure

Read a scalar of one of the basic Hessian datatypes from the stream.  This can
be one of: 

=over 2

=item
string

=item
integer

=item
long

=item
double

=item
boolean

=item
null


=back


=head2 read_typed_list

Read a Hessian 2.0 typed list.  Note that this is mainly for compatability
with other servers that are implemented in languages like Java where I<type>
is actually relevant.  

=head2 read_untyped_list

Read a list of arbitrarily typed entities.

=head2 write_hessian_array

Writes an array datastructure into the outgoing Hessian message. 

Note: This object only writes B<untyped variable length> arrays.

=head2 write_hessian_hash

Writes a HASH reference into the outgoing Hessian message.

=head2 write_hessian_string

Writes a string scalar into the outgoing Hessian message.

=head2 serialize_message

Serialize a datastructure into a Hessian 2.0 message.

=head2 write_hessian_call

Writes out a Hessian 2 specific remote procedure call

=head2 write_typed_map

Work around for L<write_object|Hessian::Translator::V2/write_object> for
serializing I<typed> hash references  and objects until I find a better way to distinguish between the two.

=head2 write_object

Serialize an object into a Hessian 1.0 string.

=head2 write_referenced_data

Write a referenced datastructure into a Hessian 1.0 string.

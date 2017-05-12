package Hessian::Translator::V1;

use Moose::Role;

#
use YAML;
use Hessian::Exception;
use Hessian::Simple;
use feature "switch";
#use Smart::Comments;

has 'string_chunk_prefix'       => ( is => 'ro', isa => 'Str', default => 's' );
has 'string_final_chunk_prefix' => ( is => 'ro', isa => 'Str', default => 'S' );
has 'end_of_datastructure_symbol' => (is => 'ro', isa => 'Str', default => 'z');

sub read_message_chunk_data {    #{{{
    my ( $self, $first_bit ) = @_;
    my $input_handle = $self->input_handle();
    my $datastructure;
    given ($first_bit) {
        when (/\x63/) {            # version 1 call
            my $hessian_version = $self->read_version();
            my $rpc_data        = $self->read_rpc();
            $datastructure = {
                hessian_version => $hessian_version,
                call            => $rpc_data
            };

        }
        when (/\x66/) {            # version 1 fault
            my @tokens;
            eval {
                while ( my $token = $self->deserialize_data() )
                {
                    push @tokens, $token;
                }
            };
            if ( Exception::Class->caught('EndOfInput::X') ) {
                my $exception_name        = $tokens[1];
                my $exception_description = $tokens[3];
                $exception_name->throw( error => $exception_description );
            }
        }
        when (/\x72/) {    # version 1 reply
            my $hessian_version = $self->read_version();
            $datastructure =
              { hessian_version => $hessian_version, state => 'reply' };
        }
        default {
            my $param = { first_bit => $first_bit };
            $datastructure = $self->deserialize_data($param);
        }
    }
    return $datastructure;

}

sub read_composite_data {    #{{{
    my ( $self, $first_bit ) = @_;
    ### read_composite_data
    my $input_handle = $self->input_handle();
    my ( $datastructure, $save_reference );
    given ($first_bit) {
        when (/\x72/ ){
            $datastructure = $self->read_remote_object();
        }
        when (/[\x56\x76]/) {    # typed lists
            push @{ $self->reference_list() }, [];
            $datastructure = $self->read_typed_list($first_bit);
        }
        when (/\x4d/) {          # typed map
            push @{ $self->reference_list() }, {
            };
            $datastructure = $self->read_map_handle();
        }
        when (/[\x4f\x6f]/) {    # object definition or reference
            push @{ $self->reference_list() }, {
            };
            $datastructure = $self->read_class_handle( $first_bit, );
        }
    }
    return $datastructure;

}

sub read_typed_list {    #{{{
    my ( $self, $first_bit ) = @_;
    ### read_typed_list
    my $input_handle = $self->input_handle();
    my $v1_type      = $self->read_v1_type($first_bit);
    my ( $entity_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
    return $self->read_untyped_list($next_bit) unless defined $entity_type;

    my $type = $self->store_fetch_type($entity_type);
    my $array_length;
    read $input_handle, $next_bit, 1 unless $next_bit;
    if ( $next_bit eq 'l' ) {
        $array_length = $self->read_list_length($next_bit);
    }

    my $datastructure = $self->reference_list()->[-1];
    my $index         = 0;
  LISTLOOP:
    {

        #  last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_typed_list_element($type); };
        last LISTLOOP if Exception::Class->caught('EndOfInput::X');
        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}

sub read_remote_object {    #{{{
    my $self         = shift;
    ### read_remote_object
    my $input_handle = $self->input_handle();
    my $remote_type  = $self->read_v1_type()->{type};
    $remote_type =~ s/\./::/g;
    my $class_definition = {
        type   => $remote_type,
        fields => ['remote_url']
    };
    ### class definition: Dump($class_definition)
    return $self->assemble_class(
        {
            type      => $remote_type,
            data      => {},
            class_def => $class_definition
        }
    );
}

sub read_v1_type {    #{{{
    my ( $self, $list_bit ) = @_;
    ### read_v1_type
    my ( $type, $first_bit, $array_length );
    my $input_handle = $self->input_handle();
    if ( $list_bit and $list_bit =~ /\x76/ ) {    # v
        read $input_handle, $type,         1;
        read $input_handle, $array_length, 1;
    }
    else {
        read $input_handle, $first_bit, 1;
        if ( $first_bit =~ /t/ ) {
            $type = $self->read_hessian_chunk( { first_bit => 'S' } );
        }
    }
    ### found type: $type
    return { type => $type, next_bit => $array_length } if $type;
    return { next_bit => $first_bit };
}

sub read_class_handle {    #{{{
    my ( $self, $first_bit ) = @_;
    ### read_class_handle
    my $input_handle = $self->input_handle();
    my ( $save_reference, $datastructure );
    given ($first_bit) {
        when (/\x4f/) {      # Read class definition
            my $class_name_length = $self->read_hessian_chunk();
            my $class_type;
            read $input_handle, $class_type, $class_name_length;

            $class_type =~ s/\./::/g;    # get rid of java stuff
                                         # Get number of fields
            $datastructure = $self->store_class_definition($class_type);
        }
        when (/\x6f/) {    # The class definition is in the ref list
            $save_reference = 1;
            $datastructure  = $self->fetch_class_for_data();
        }
    }

    return $datastructure;
}

sub read_map_handle {    #{{{
    my $self         = shift;
    ### read_map_handle
    my $input_handle = $self->input_handle();
    my $v1_type      = $self->read_v1_type();
    my ( $entity_type, $next_bit ) = @{$v1_type}{qw/type next_bit/};
    my $type;
    $type = $self->store_fetch_type($entity_type) if $entity_type;
    my $key;
    if ($next_bit) {
        $key = $self->read_hessian_chunk( { first_bit => $next_bit } );
    }

    # For now only accept integers or strings as keys
    my @key_value_pairs;
  MAPLOOP:
    {
        eval { $key = $self->read_hessian_chunk(); } unless $key;
        last MAPLOOP if Exception::Class->caught('EndOfInput::X');
        my $value = $self->read_hessian_chunk();
        push @key_value_pairs, $key => $value;
        undef $key;
        redo MAPLOOP;
    }

    # should throw an exception if @key_value_pairs has an odd number of
    # elements

    my $datastructure = $self->reference_list()->[-1];
    my $hash          = {@key_value_pairs};
    foreach my $key ( keys %{$hash} ) {
        $datastructure->{$key} = $hash->{$key};
    }
    my $map = defined $type ? bless $datastructure => $type : $datastructure;
    return $map;

}

sub read_untyped_list {    #{{{
    my ( $self, $first_bit ) = @_;
    ### read_untyped_list
    my $input_handle = $self->input_handle();
    my $array_length;
    my $datastructure = $self->reference_list()->[-1];
    my $index         = 0;
    if ( $first_bit eq 'l' ) {
        $array_length = $self->read_list_length( $first_bit, );
    }
    else {
        my $param = { first_bit => $first_bit };
        my $first_element = $self->read_hessian_chunk($param);
        push @{$datastructure}, $first_element;
        $index++;
    }
  LISTLOOP:
    {
        last LISTLOOP if ( $array_length and ( $index == $array_length ) );
        my $element;
        eval { $element = $self->read_hessian_chunk(); };
        last LISTLOOP
          if Exception::Class->caught('EndOfInput::X');

        push @{$datastructure}, $element;
        $index++;
        redo LISTLOOP;
    }
    return $datastructure;
}

sub read_simple_datastructure {    #{{{  
    my ( $self, $first_bit ) = @_;
    ### read_simple_datastructure V1 translator 
    ### first bit: $first_bit
    my $input_handle = $self->input_handle();
    my $element;
    given ($first_bit) {
        when (/\x00/) {
            $element = $self->read_hessian_chunk();
        }
        when (/\x4e/) {              # 'N' for NULL
            $element = undef;
        }
        when (/[\x46\x54]/) {        # 'T'rue or 'F'alse
            $element = $self->read_boolean_handle_chunk($first_bit);
        }
        when (/[\x49\x80-\xaf\xc0-\xcf\xd0-\xd7]/) {
            $element = $self->read_integer_handle_chunk($first_bit);
        }
        when (/[\x4c\xd8-\xef\xf0-\xff\x38-\x3f]/) {
            $element = $self->read_long_handle_chunk($first_bit);
        }
        when (/\x44/) {
            $element = $self->read_double_handle_chunk($first_bit);
        }
        when (/\x64/ ){
            $element = $self->read_date_handle_chunk($first_bit);
        }
        when (/[\x53\x58\x73\x78\x00-\x0f]/) {    #   for version 1: \x73
            $element = $self->read_string_handle_chunk($first_bit);
        }
        when (/[\x42\x62]/) {
            $element = $self->read_binary_handle_chunk($first_bit);
        }
        when (/[\x4d\x4f\x56\x6f\x72\x76]/) {     # recursive datastructure
            $element = $self->read_composite_datastructure( $first_bit, );
        }
        when (/\x52/) {
            my $reference_id = $self->read_integer_handle_chunk('I');
            $element = $self->reference_list()->[$reference_id];
        }
        when (/[\x48\x6d]/) {                     # a header or method name
            $element = $self->read_string_handle_chunk('S');
        }
    }
    binmode( $input_handle, 'bytes' );
    return $element;

}

sub read_list_type {    #{{{
    ### read_list_type
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $type_length;
    read $input_handle, $type_length, 1;
    my $type = $self->read_string_handle_chunk( $type_length, $input_handle );
    binmode( $input_handle, 'bytes' );
    return $type;
}

sub read_rpc {    #{{{
    ### read_rpc
    my $self         = shift;
    my $input_handle = $self->input_handle();
    my $call_data    = {};
    my $call_args;
    my $in_header;
  RPCSTRUCTURE: {
        my $first_bit;
        read $input_handle, $first_bit, 1;
        my $element;
        eval {
            $element = $self->read_hessian_chunk( { first_bit => $first_bit } );
        };
        last RPCSTRUCTURE if Exception::Class->caught('EndOfInput::X');
        given ($first_bit) {
            when (/\x6d/) {
                $in_header = 0;
                $call_data->{method} = $element;
            }
            when (/\x48/) {
                $in_header = 1;
                push @{ $call_data->{headers} }, { header => $element };
            }

            default {
                if ($in_header) {
                    push @{ $call_data->{headers}->[-1]->{elements} }, $element;
                }
                else {
                    push @{$call_args}, $element;
                }
            }
        }
        redo RPCSTRUCTURE;
    }
    $call_data->{arguments} = $call_args;
    return $call_data;
}

sub write_hessian_hash {    #{{{
    ### write_hessian_hash
    my ( $self, $datastructure ) = @_;
    my $anonymous_map_string = "M";    # start an anonymous hash
    foreach my $key ( keys %{$datastructure} ) { ### writing hash... done 
        my $hessian_key   = $self->write_scalar_element($key);
        my $value         = $datastructure->{$key};
        my $hessian_value = $self->write_hessian_chunk($value);
        $anonymous_map_string .= $hessian_key . $hessian_value;
    }
    $anonymous_map_string .= $self->end_of_datastructure_symbol();
    return $anonymous_map_string;
}

sub write_hessian_array {    #{{{
    ### write_hessian_array
    my ( $self, $datastructure ) = @_;
    my $anonymous_array_string = "V";
    foreach my $element ( @{$datastructure} ) { ### writing array... done
        my $hessian_element = $self->write_hessian_chunk($element);
        $anonymous_array_string .= $hessian_element;
    }
    $anonymous_array_string .= "z";
    return $anonymous_array_string;
}

sub write_hessian_string {    #{{{
    ### write_hessian_string
    my ( $self, $chunks ) = @_;
    return $self->write_string( { chunks => $chunks } );

}

#sub write_hessian_date {    #{{{
#    my ( $self, $datetime ) = @_;
#    my $epoch = $datetime->epoch();
#    return $self->write_date( $epoch, 'd' );
#}

sub write_hessian_call {    #{{{
    ### write_hessian_call
    my ( $self, $datastructure ) = @_;
    my $hessian_call   = "c\x01\x00";
    my $method         = $datastructure->{method};
    my $hessian_method = $self->write_scalar_element($method);
    $hessian_method =~ s/^S/m/;
    $hessian_call .= $hessian_method;
    my $arguments = $datastructure->{arguments};
    foreach my $argument ( @{$arguments} ) { ### writing call... done
        my $hessian_arg = $self->write_hessian_chunk($argument);
        $hessian_call .= $hessian_arg;
    }
    $hessian_call .= "z";
    return $hessian_call;
}

sub write_object { #{{{
    ### write_object
    my ($self , $datastructure) = @_;
    my $type = ref $datastructure;
    my $hessian_string = "\x4d";
    my $hessian_type = $self->write_scalar_element($type);
    $hessian_type =~ s/^S/t/;
    $hessian_string .= $hessian_type;
    my @fields = keys %{$datastructure};
    foreach my $field (@fields) { ### object fields... done
        my $hessian_field = $self->write_scalar_element($field);
        my $value = $datastructure->{$field};
        my $hessian_value = $self->write_hessian_chunk($value);
        $hessian_string .= $hessian_field . $hessian_value;
    }
    $hessian_string .= "z";
    return $hessian_string;

}

sub write_referenced_data  { #{{{
    ### write_referenced_data
    my ( $self, $index) = @_;
    my $hessian_string = "R";
    # Bypass write integer for now
    my $new_int = pack 'N', $index;
    $hessian_string .= $new_int;
    return $hessian_string;
}

sub serialize_message {    #{{{
    ### serialize_message
    my ( $self, $datastructure ) = @_;
    my $result = $self->write_hessian_message($datastructure);
    return $result;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Translator::V1 - Translate datastructures to and from Hessian 1.0.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 read_class_handle

Read a class definition from the Hessian stream and possibly create an object
from the definition and given parameters.

=head2 read_composite_data

Read Hessian 1.0 specific datastructures from the stream.

=head2 read_list_type

Read the I<type> attribute of a Hessian 1.0 typed list

=head2 read_map_handle

Read a map (perl HASH) from the stream. If a type attribute is present, the
hash will be I<blessed> into an object.

=head2 read_message_chunk_data

Read Hessian 1.0 envelope.  For version 1.0 of the protocol this mainly
applies to I<reply>, I<call> and I<fault> objects.

=head2 read_remote_object


=head2 read_rpc

Read a remote procedure call from the input stream.

=head2 read_simple_datastructure

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


=head2 read_untyped_list


=head2 read_v1_type

Read the type attribute (if present) from a Hessian 1.0 list or map.

=head2 write_hessian_array

Writes an array datastructure into the outgoing Hessian message. 

Note: This object only writes B<untyped variable length> arrays.

=head2 write_hessian_date

Writes a L<DateTime|DateTime> object into the outgoing Hessian message. 

=head2 write_hessian_hash

Writes a HASH reference into the outgoing Hessian message.

=head2 write_hessian_string


Writes a string scalar into the outgoing Hessian message.

=head2 write_hessian_call

=head2 serialize_message

Performs Hessian 1 specific processing of datastructures into hessian.
 
=head2 write_object

Serialize an object into a Hessian 1.0 string.

=head2 write_referenced_data

Write a referenced datastructure into a Hessian 1.0 string.

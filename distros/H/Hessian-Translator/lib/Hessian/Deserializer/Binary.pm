package  Hessian::Deserializer::Binary;

use Moose::Role;

#
use feature "switch";
##use Smart::Comments;

sub read_binary_handle_chunk  {    #{{{
    my ( $self, $first_bit ) = @_;
    ### read_binary_handle_chunk
    my $input_handle = $self->input_handle();
    my ($data, $length );
    given ($first_bit) {
        when (/[\x42\x62]/) {
            read $input_handle, $data, 2;
            $length = unpack "n", $data;
        }
        when (/[\x20-\x2f]/) {
            my $raw_octet = "\x00" . $first_bit;
            $length = unpack 'n', $raw_octet;
            $length -= 0x20;
        }
    }


    my $binary = $self->read_from_inputhandle($length);
    return $binary;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::Binary - Deserialization of Hessian into binary

=head1 SYNOPSIS

These methods are only made to be used within the Hessian framework.

=head1 DESCRIPTION

This module reads the current input file handle to translate Hessian into
binary.

=head1 INTERFACE

=head2 read_binary_handle_chunk

Reads binary data from the input handle.



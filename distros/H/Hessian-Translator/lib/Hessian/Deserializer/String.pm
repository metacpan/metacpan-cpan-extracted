package  Hessian::Deserializer::String;

use Moose::Role;

#
use feature "switch";

sub read_string_handle_chunk  {    #{{{
    my ($self, $first_bit) = @_;
    my ( $string, $data, $length );
    given ($first_bit) {
        when (/[\x00-\x1f]/) {
            $length = unpack "n", "\x00" . $first_bit;
        }
        when (/[\x30-\x33]/) {
            $data = $self->read_from_inputhandle(1);
            my $first_part = $first_bit - 0x30;
            my $string_length = $first_part . $data;

            $length = unpack "n", "\x00".$data;
        }
        when (/[\x52-\x53\x73]/) {
            $data = $self->read_from_inputhandle(2);
            $length = unpack "n", $data;
        }
    }
 
#    binmode( $input_handle, 'utf8' );
    $string = $self->read_from_inputhandle($length);
    return $string;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Deserializer::String - Methods for serialization of strings

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 read_string_handle_chunk

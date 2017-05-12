package  Hessian::Serializer;

use Moose::Role;

with qw/
  Hessian::Serializer::Numeric
  Hessian::Serializer::String
  Hessian::Serializer::Date
  Hessian::Serializer::Binary
  /;


sub serialize_chunk {    #{{{
    my ( $self, $datastructure ) = @_;
    my $result = $self->write_hessian_chunk($datastructure);
    return $result;
}

#sub serialize_message {    #{{{
#    my ( $self, $datastructure ) = @_;
#    my $message;
#    $message = "H\x02\x00" if $self->version() == 2;
#    $message .= $self->write_hessian_message($datastructure);
#    return  $message;
#}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer - Serialize data into Hessian messages

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2   serialize_chunk

=head2 serialize_message

Performs Hessian versioversion specific processing of datastructures into hessian.
 

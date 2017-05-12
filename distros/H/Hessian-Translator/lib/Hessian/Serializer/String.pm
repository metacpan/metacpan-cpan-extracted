package  Hessian::Serializer::String;

use Moose::Role;

sub write_chunk {    #{{{
    my $string = shift;
    my $hessian_message = pack 'n/a*', $string;
    return $hessian_message;
}

sub write_string  {    #{{{
    my ($self, $params) = @_;
    my $prefixes = {};
    @{$prefixes}{qw/prefix last_prefix/} 
        = ($self->string_chunk_prefix(), $self->string_final_chunk_prefix());
    my @string_chunks = @{ $params->{chunks} };
    my $message = $self->hessianify_chunks( $prefixes, @string_chunks );
    return join "" => @{$message};
}

sub write_xml {    #{{{
    my ($self, $params) = @_;

    my @xml_chunks = @{ $params->{chunks}  };
    my $message =
      $self->hessianify_chunks( 
        { prefix => 'x', last_prefix => 'X' }, 
        @xml_chunks 
      );
    return join "" => @{$message};
}

sub  write_packet { #{{{
    my ($self, $params) = @_;
    my @packets = @{ $params->{packets}};
    my $message = 
    $self->hessianify_chunks({
       prefix => "\x4f", last_prefix => "P" 
        }, @packets);
    return $message;
}

sub hessianify_chunks {    #{{{
    my ($self, $prefixes, @chunks ) = @_;
    my $last_chunk = pop @chunks;
    my $prefix = $prefixes->{prefix};
    my @message    = map {
        ( $prefixes->{prefix} ) . write_chunk($_);
    }
    @chunks[ 0 .. ( $#chunks ) ];
    my $last_prefix = $prefixes->{last_prefix};
    my $processed_last_chunk = ($last_prefix . write_chunk($last_chunk));
    push @message, $processed_last_chunk;
    return \@message;
}

"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer::String - Role for serialization of strings into hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 hessianify_chunks


=head2 write_chunk


=head2 write_string


=head2 write_xml

=head2 write_packet

Enclose a datastructure in packets for chunked transmission.

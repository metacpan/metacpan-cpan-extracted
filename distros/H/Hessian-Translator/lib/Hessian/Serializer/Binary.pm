package Hessian::Serializer::Binary;

use Moose::Role;

sub write_binary {    #{{{
    my ($self, @chunks) = @_;
    my $last_chunk = pop @chunks;
    my @message    = map {
        'b' . ( pack 'n/a*', $_ );
    }
    @chunks[ 0 .. ( $#chunks ) ];
    push @message, 'B' . ( pack 'n/a*', $last_chunk);
    
    my $result = join "" => @message;
    return $result;
}


"one, but we're not the same";

__END__


=head1 NAME

Hessian::Serializer::Binary - Methods for serializing data into Hessian.

=head1 VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 write_binary

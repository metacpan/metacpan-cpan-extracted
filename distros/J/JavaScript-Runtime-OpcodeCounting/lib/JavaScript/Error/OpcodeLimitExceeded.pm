package JavaScript::Error::OpcodeLimitExceeded;

use strict;
use warnings;

use overload q{""} => 'as_string', fallback => 1;

sub as_string {
	my $self = shift;
	return $self->message();
}

sub message {
	my $self = shift;
	return "Opcode limit " . $$self . " exceeded;";
}

1;
__END__

=head1 NAME

JavaScript::Error::OpcodeLimitExceeded - Error class that is thrown when we execute too many opcodes

=head1 DESCRIPTION

This special error class is thrown by a context if it's running in an C<JavaScript::Runtime::OpcodeCounting>-runtime. 

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item as_string

=item message

Returns a string representation of the exception.

=back

=cut

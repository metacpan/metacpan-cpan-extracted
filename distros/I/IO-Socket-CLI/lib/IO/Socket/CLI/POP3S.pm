package IO::Socket::CLI::POP3S;
$IO::Socket::CLI::POP3S::VERSION = '0.041';
use 5.006;
use strict;
use warnings;
use IO::Socket::CLI;
our @ISA = ("IO::Socket::CLI");

$IO::Socket::CLI::PORT = '995';
$IO::Socket::CLI::SSL = 1;
$IO::Socket::CLI::BYE = qr'^\+OK(?: |\r?$)'; # string received when a POP3 server disconnects,
                                             # or anything else goes right. hence, is_open() is overridden.

sub is_open {
    my $self = shift;
    $self->{_OPEN} = ($self->{_SOCKET}->connected()) ? 1 : 0;
    foreach (@{$self->{_SERVER_RESPONSE}}) {
        $self->{_OPEN} = 0 if (/$IO::Socket::CLI::BYE/ && $self->{_COMMAND} =~ /^quit$/i);
        last;
    }
    return $self->{_OPEN};
}

1;

__END__

=head1 NAME

IO::Socket::CLI::POP3S - Command-line interface to an SSL POP3 server.

=head1 VERSION

version 0.041

=head1 SYNOPSIS

 use IO::Socket::CLI::POP3S;
 my $pop3 = IO::Socket::CLI::POP3S->new(HOST => 'pop.gmail.com');
 $pop3->read();
 do {
     $pop3->prompt();
     $pop3->read();
 } while ($pop3->is_open());

=head1 DESCRIPTION

C<IO::Socket::CLI::POP3S> provides a command-line interface to
L<IO::Socket::INET6> and L<IO::Socket::SSL>.

=for comment
=head1 EXPORT
None by default.

=head1 METHODS

See C<IO::Socket::CLI>.

=head2 is_open()

Returns if the server hung up according to the last server response.
Override as POP3 gives no special response for closing a connection, so this
verifies an C<+OK> response after sending a C<quit> command.

=head1 BUGS

Does not verify SSL connections. Has not been tried with STARTTLS.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<IO::Socket::CLI>

L<IO::Socket::INET6>

L<IO::Socket::INET>

L<IO::Socket::SSL>

L<IO::Socket>

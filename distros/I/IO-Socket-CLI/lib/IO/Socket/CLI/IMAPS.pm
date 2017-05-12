package IO::Socket::CLI::IMAPS;
$IO::Socket::CLI::IMAPS::VERSION = '0.041';
use 5.006;
use strict;
use warnings;
use IO::Socket::CLI;
our @ISA = ("IO::Socket::CLI");

$IO::Socket::CLI::PORT = '993';
$IO::Socket::CLI::SSL = 1;
$IO::Socket::CLI::BYE = qr'^\* BYE( |\r?$)'; # string received when an IMAP server disconnects

1;

__END__

=head1 NAME

IO::Socket::CLI::IMAPS - Command-line interface to an SSL IMAP server.

=head1 VERSION

version 0.041

=head1 SYNOPSIS

 use IO::Socket::CLI::IMAPS;
 my $imap = IO::Socket::CLI::IMAPS->new(HOST => '192.168.1.3');
 $imap->read();
 do {
     $imap->prompt();
     $imap->read();
 } while ($imap->is_open());

=head1 DESCRIPTION

C<IO::Socket::CLI::IMAPS> provides a command-line interface to
L<IO::Socket::INET6> and L<IO::Socket::SSL>.

=for comment
=head1 EXPORT
None by default.

=head1 METHODS

See C<IO::Socket::CLI>.

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

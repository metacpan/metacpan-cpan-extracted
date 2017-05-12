package IO::Socket::CLI::SMTP;
$IO::Socket::CLI::SMTP::VERSION = '0.041';
use 5.006;
use strict;
use warnings;
use IO::Socket::CLI;
our @ISA = ("IO::Socket::CLI");

$IO::Socket::CLI::PORT = '25'; # 587 common for login
$IO::Socket::CLI::BYE = qr'^(?:221|421)(?: |\r?$)'; # string received when a SMTP server disconnects, i think something *must* follow the code

1;

__END__

=head1 NAME

IO::Socket::CLI::SMTP - Command-line interface to an SMTP server.

=head1 VERSION

version 0.041

=head1 SYNOPSIS

 use IO::Socket::CLI::SMTP;
 my $smtp = IO::Socket::CLI::SMTP->new(HOST => '192.168.1.3');
 $smtp->read();
 do {
     $smtp->prompt();
     $smtp->read();
 } while ($smtp->is_open());

=head1 DESCRIPTION

C<IO::Socket::CLI::SMTP> provides a command-line interface to
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

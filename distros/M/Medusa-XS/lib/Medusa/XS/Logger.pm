package Medusa::XS::Logger;

use strict;
use warnings;

use Medusa::XS ();

1;

__END__

=encoding utf8

=head1 NAME

Medusa::XS::Logger - XS-accelerated file logger with flock locking

=head1 VERSION

Part of L<Medusa::XS> version 0.01.

=head1 SYNOPSIS

    use Medusa::XS::Logger;

    my $logger = Medusa::XS::Logger->new(file => '/var/log/audit.log');

    $logger->debug("Starting process");
    $logger->info("User logged in: user123");
    $logger->error("Failed to connect to database");

    # Or use the generic log method:
    $logger->log("any message");

=head1 DESCRIPTION

Medusa::XS::Logger is a pure-C file logger used as the default logging
backend for L<Medusa::XS>.  All I/O is performed in C via C<PerlIO> with
C<flock(2)>-based locking, making it safe for concurrent writes from
multiple processes.

The logger is automatically instantiated by C<Medusa::XS> when the first
C<:Audit>-wrapped subroutine is called, using the C<LOG_FILE> value from
C<%Medusa::XS::LOG>.  You can also create instances directly.

When C<Medusa::XS> detects that the configured logger is a
C<Medusa::XS::Logger> instance, it bypasses Perl method dispatch entirely
and writes directly from C — eliminating all call overhead on the logging
path.

=head1 CONSTRUCTOR

=head2 new

    my $logger = Medusa::XS::Logger->new();
    my $logger = Medusa::XS::Logger->new(file => 'audit.log');
    my $logger = Medusa::XS::Logger->new({ file => 'audit.log' });

Creates a new logger and opens the file for appending.  Accepts arguments
as a hash, a list of key-value pairs, or a hash reference.

=over 4

=item B<file> I<(string, default C<"audit.log">)>

Path to the log file.  The file is opened in append mode (C<< >> >>)
and created if it does not exist.

=back

Dies if the file cannot be opened.

=head1 METHODS

All write methods acquire an exclusive C<flock> before writing, flush the
handle, and release the lock — ensuring atomic line writes even under
concurrent access.

=head2 debug

    $logger->debug("message text");

Writes a line to the log file.

=head2 info

    $logger->info("message text");

Writes a line to the log file.

=head2 error

    $logger->error("message text");

Writes a line to the log file.

=head2 log

    $logger->log("message text");

Generic write — identical behaviour to C<debug>, C<info>, and C<error>.
The level-named methods exist for API compatibility with higher-level
loggers; C<Medusa::XS::Logger> does not filter by level.

=head1 DESTRUCTION

The file handle is closed automatically when the logger object goes out
of scope.  Cleanup is handled by a C-level magic destructor attached to
the underlying SV.

=head1 SEE ALSO

L<Medusa::XS> — the audit framework that uses this logger.

=head1 LICENSE

This module is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=cut

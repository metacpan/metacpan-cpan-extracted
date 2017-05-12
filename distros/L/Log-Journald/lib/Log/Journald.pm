=head1 NAME

Log::Journald - Send messages to a systemd journal

=head1 SYNOPSIS

  use Log::Journald;
  use Sys::Syslog qw/:macros/;

  # Easy.
  journald_log(LOG_INFO, "Hello from PID $$!");

  # Send arbitrary fields, even binary data
  Log::Journald::send(PRIORITY => LOG_INFO,
       MESSAGE => "Hello from PID $$!",
       PERL_PACKAGE => __PACKAGE__,
       _YOLO => "SW\x00AG");
       or warn "Could not send log: $!";

  # Raw
  Log::Journald::sendv('PRIORITY=6',
       "MESSAGE=Hello from PID $$!");

Please consider this an alpha quality code, whose API can change
at any time, until we reach version 1.00.

=head1 DESCRIPTION

This module wraps L<sd-journal(3)> APIs for easy use in Perl. It makes it 
possible to easily use L<systemd-journald.service(8)>'s structured logging 
capabilities and includes location of the logging point in the source code in 
the messages.

Backends for L<Log::Dispatch> and L<Log::Log4perl> exist: Use
L<Log::Dispatch::Journald> and L<Log::Log4perl::Appender::Journald>
respectively.

=cut

package Log::Journald;

use strict;
use warnings;

require Exporter;

our $VERSION = '0.20';
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/journal_log send sendv/;
our @EXPORT = qw/journal_log send sendv/;

require XSLoader;
XSLoader::load('Log::Journald', $VERSION);

1;

=head1 SUBROUTINES

=over 4

=item B<journal_log> PRIORITY MESSAGE

Log a message at given priority. Exported by default.

Returns true upon success, false while setting C<$!> on failure.

=item B<send> KEY VALUE ...

Log a message with given key-value pairs. C<MESSAGE> and C<PRIORITY> keys are 
mandatory. See L<systemd.journal-fields(7)> for list and description of known 
fields.

Returns true upon success, false while setting C<$!> on failure.

=item B<sendv> STRING ...

Same as above, apart from that instead of key and value pair, strings that 
contain key and value concatenated with "=" are expected. This avoids an extra 
copy and might me slightly more efficient.

Returns true upon success, false while setting C<$!> on failure.

=back

=head1 SEE ALSO

=over

=item *

L<Sys::Syslog> -- Traditiona logging mechanism. The module provides useful
macros.
 
=item *

L<sd-journal(3)> -- Description of C language API for journal.

=item *

L<systemd-journald.service(8)> -- Manual of the journal service.

=item *

L<Log::Dispatch::Journald> -- L<Log::Dispatch> backend.

=item *

L<Log::Log4perl::Appender::Journald> -- L<Log::Log4perl> appender.

=back

=head1 BUGS

C<journal_log()> terminates the message at a NUL byte. You need to use another
interface to log binary data.

To get priority constants, you still need to include L<Sys::Syslog>.

There's no way to override caller depth. Therefore if you add a wrapper for any
of this module's interfaces, you'll get the location of the wrapper in the
messages.

A way to disable or override inclusion of code location would be nice.

=head1 COPYRIGHT

Copyright 2014 Lubomir Rintel

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

Lubomir Rintel, L<< <lkundrak@v3.sk> >>

The code is hosted on GitHub L<http://github.com/lkundrak/perl-Log-Journald>.
Bug fixes and feature enhancements are always welcome.

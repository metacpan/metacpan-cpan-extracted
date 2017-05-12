#
# $Id: QmailRemoteXS.pm,v 1.3 2007/11/25 21:23:12 rsandberg Exp $

package Mail::QmailRemoteXS;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
	
);
$VERSION = '1.3';

bootstrap Mail::QmailRemoteXS $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Mail::QmailRemoteXS - Lightweight (XS) SMTP send function based on Qmail's qmail-remote

=head1 SYNOPSIS

  use Mail::QmailRemoteXS;
  
  $ret = Mail::QmailRemoteXS::mail($to_domain,$from_address,$to_address,$msg,$helo,$net_timeout,$net_timeoutconnect);

=head1 DESCRIPTION

This module provides a single function C<mail> that sends an e-mail message via SMTP. It uses an XS implementation of
Qmail's qmail-remote binary written in C so is very lightweight and fast (compared to Net::SMTP).

The difference between Mail::QmailRemote (IKEBE Tomohiro) and Mail::QmailRemoteXS is that the former requires
the qmail package to be installed and simply invokes a wrapper around the qmail-remote binary for each send.
This module statically links code based on qmail-remote and has no dependencies other that a working resolver.

=head1 FUNCTIONS

=over 4

=item C<mail>

 $ret = Mail::QmailRemoteXS::mail($to_domain,$from_address,$to_address,$msg,$helo,$net_timeout,$net_timeoutconnect);

Send an email message $msg (which includes rfc822 headers) to $to_address from $from_address using $helo as
the SMTP HELO greeting. $net_timeoutconnect is for the initial SMTP connection and $net_timeout is for the
wait time for SMTP responses.

See Qmail's qmail-remote manpage for more information and details on the return value $ret.

=back

=head1 BUGS

Some reports of C<mail> hanging indefinitely during an SMTP session.


=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>


=head1 SEE ALSO

Qmail docs for qmail-remote. Net::SMTP


=head1 COPYRIGHT

Copyright (C) 2002-2004 Reed Sandberg
All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

This package comes with a modified distribution of qmail-1.03 by Dan J. Bernstein. See qmailrem/README for Copyright and further information.

=cut

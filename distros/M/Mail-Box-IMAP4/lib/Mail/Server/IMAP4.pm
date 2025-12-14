# This code is part of Perl distribution Mail-Box-IMAP4 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Server::IMAP4;{
our $VERSION = '4.01';
}

use parent 'Mail::Server';

use strict;
use warnings;

use Log::Report 'mail-box-imap4', import => [];

use Mail::Server::IMAP4::List   ();
use Mail::Server::IMAP4::Fetch  ();
use Mail::Server::IMAP4::Search ();
use Mail::Transport::IMAP4      ();

#--------------------

#--------------------

1;

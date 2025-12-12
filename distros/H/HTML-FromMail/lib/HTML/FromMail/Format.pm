# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Format;{
our $VERSION = '4.00';
}

use base 'Mail::Reporter';

use strict;
use warnings;

use Log::Report 'html-frommail';

#--------------------

#-----------

#-----------


sub containerText($) { $_[0]->notImplemented }


sub processText($$) { $_[0]->notImplemented }


sub lookup($$) { $_[0]->notImplemented }


sub onFinalToken($) { 0 }

1;

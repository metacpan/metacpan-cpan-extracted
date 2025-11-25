# This code is part of Perl distribution Mail-Transport version 3.008.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::Receive;{
our $VERSION = '3.008';
}

use base 'Mail::Transport';

use strict;
use warnings;

#--------------------

sub receive(@) { $_[0]->notImplemented }

#--------------------

1;

# This code is part of Perl distribution Log-Report version 1.42.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Dispatcher::Perl;{
our $VERSION = '1.42';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report';

my $singleton = 0;   # can be only one (per thread)

#--------------------

sub log($$$$)
{	my ($self, $opts, $reason, $message, $domain) = @_;
	print STDERR $self->translate($opts, $reason, $message);
}

1;

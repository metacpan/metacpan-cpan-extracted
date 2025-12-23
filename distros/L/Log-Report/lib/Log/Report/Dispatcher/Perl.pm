# This code is part of Perl distribution Log-Report version 1.44.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Log::Report::Dispatcher::Perl;{
our $VERSION = '1.44';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report', import => [ ];

my $singleton = 0;   # can be only one (per thread)

#--------------------

sub log($$$$)
{	my ($self, $opts, $reason, $message, $domain) = @_;
	print STDERR $self->translate($opts, $reason, $message);
}

1;

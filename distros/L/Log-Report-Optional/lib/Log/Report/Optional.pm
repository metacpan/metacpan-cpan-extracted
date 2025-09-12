# This code is part of Perl distribution Log-Report-Optional version 1.08.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2013-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Optional;{
our $VERSION = '1.08';
}

use base 'Exporter';

use warnings;
use strict;

#--------------------

my ($supported, @used_by);

BEGIN {
	if($INC{'Log/Report.pm'})
	{	$supported  = 'Log::Report';
		my $version = $Log::Report::VERSION;
		die "Log::Report too old for ::Optional, need at least 1.00"
			if $version && $version le '1.00';
	}
	else
	{	require Log::Report::Minimal;
		$supported = 'Log::Report::Minimal';
	}
}

sub import(@)
{	my $class = shift;
	push @used_by, (caller)[0];
	$supported->import('+1', @_);
}

#--------------------

sub usedBy() { @used_by }

1;

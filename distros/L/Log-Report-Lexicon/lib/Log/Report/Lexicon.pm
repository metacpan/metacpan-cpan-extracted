# This code is part of Perl distribution Log-Report-Lexicon version 1.15.
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

package Log::Report::Lexicon;{
our $VERSION = '1.15';
}


use warnings;
use strict;

use Log::Report 'log-report-lexicon';

#--------------------

sub new(@)
{	my $class = shift;
	(bless {}, $class)->init( +{ @_ } );
}

sub init($) { shift }   # $self, $args

#--------------------

1;

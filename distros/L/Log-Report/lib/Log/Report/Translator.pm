# This code is part of Perl distribution Log-Report version 1.44.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Log::Report::Translator;{
our $VERSION = '1.44';
}


use warnings;
use strict;

use Log::Report 'log-report', import => [ ];

#--------------------

sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($) { $_[0] }

#--------------------

#--------------------

# this is called as last resort: if a translator cannot find
# any lexicon or has no matching language.
sub translate($$$)
{	my $msg = $_[1];
	defined $msg->{_count} && $msg->{_count} != 1 ? $msg->{_plural} : $msg->{_msgid};
}


sub load($@) { undef }

1;

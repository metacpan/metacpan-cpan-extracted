# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Page;{
our $VERSION = '4.00';
}

use base 'HTML::FromMail::Object';

use strict;
use warnings;

use Log::Report 'html-frommail';

#--------------------

#-----------

#-----------

sub lookup($$)
{	my ($self, $label, $args) = @_;
	$args->{formatter}->lookup($label, $args);
}

1;

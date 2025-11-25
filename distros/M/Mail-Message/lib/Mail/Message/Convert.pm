# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert;{
our $VERSION = '3.019';
}

use base 'Mail::Reporter';

use strict;
use warnings;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MMC_fields} = $args->{fields} || qr#^(Resent\-)?(To|From|Cc|Bcc|Subject|Date)\b#i;
	$self;
}

#--------------------

sub selectedFields($)
{	my ($self, $head) = @_;
	$head->grepNames($self->{MMC_fields});
}

#--------------------

1;

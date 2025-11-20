# This code is part of Perl distribution HTML-FromMail version 3.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package HTML::FromMail::Default::HTMLifiers;{
our $VERSION = '3.00';
}


use strict;
use warnings;

use HTML::FromText;
use Carp;

#--------------------

our @htmlifiers = (
	'text/plain' => \&htmlifyText,
#	'text/html'  => \&htmlifyHtml,
);


sub htmlifyText($$$$)
{	my ($page, $message, $part, $args) = @_;
	my $main     = $args->{main} or confess;
	my $settings = $main->settings('HTML::FromText')
	  || +{ pre => 1, urls => 1, email => 1, bold => 1, underline => 1};

	my $f = HTML::FromText->new($settings)
		or croak "Cannot create an HTML::FromText object";

	{	image => '',            # this is not an image
		html  => { text => $f->parse($part->decoded->string) },
	}
}


1;

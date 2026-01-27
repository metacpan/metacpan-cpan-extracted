# This code is part of Perl distribution Hash-Case version 1.07.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2002-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Hash::Case::Lower;{
our $VERSION = '1.07';
}

use base 'Hash::Case';

use strict;
use warnings;

use Carp   qw/croak/;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::native_init($args);

	! keys %$args
		or croak "no options possible for ". __PACKAGE__;

	$self;
}

sub FETCH($)  { $_[0]->{lc $_[1]} }
sub STORE($$) { $_[0]->{lc $_[1]} = $_[2] }
sub EXISTS($) { exists $_[0]->{lc $_[1]} }
sub DELETE($) { delete $_[0]->{lc $_[1]} }

1;

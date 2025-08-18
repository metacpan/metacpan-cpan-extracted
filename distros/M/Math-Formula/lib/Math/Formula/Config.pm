# This code is part of Perl distribution Math-Formula version 0.17.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2023-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Math::Formula::Config;{
our $VERSION = '0.17';
}


use warnings;
use strict;

use Log::Report qw/math-formula/;

use File::Spec  ();

#--------------------

sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{	my ($self, $args) = @_;
	my $dir = $self->{MFC_dir} = $args->{directory}
		or error __x"Save directory required";

	-d $dir
		or error __x"Save directory '{dir}' does not exist", dir => $dir;

	$self;
}

#--------------------

sub directory { $_[0]->{MFC_dir} }


sub path_for($$)
{	my ($self, $file) = @_;
	File::Spec->catfile($self->directory, $file);
}

#--------------------

sub save($%) { ... }


sub load($%) { ... }

1;

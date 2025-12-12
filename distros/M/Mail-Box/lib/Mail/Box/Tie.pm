# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Tie;{
our $VERSION = '4.00';
}


use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error/ ];

use Scalar::Util     qw/blessed/;

#--------------------

sub new($$)
{	my ($class, $folder, $type) = @_;

	blessed $folder && $folder->isa('Mail::Box')
        or error __x"no folder specified to tie to.";

	bless +{ MBT_folder => $folder, MBT_type => $type }, $class;
}

#--------------------

sub folder() { $_[0]->{MBT_folder} }
sub type()   { $_[0]->{MBT_type} }

1;

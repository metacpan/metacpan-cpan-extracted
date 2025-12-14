# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Reporter;{
our $VERSION = '4.01';
}


use strict;
use warnings;

use Log::Report     'mail-message', import => [ qw/__x error panic warning/ ];

use Scalar::Util    qw/dualvar blessed/;

#--------------------

sub new(@)
{	my $class = shift;
	(bless +{}, $class)->init( +{@_} );
}

sub init($) { shift }

#--------------------

#--------------------

sub notImplemented(@)
{	my $self    = shift;
	my $package = ref $self || $self;
	my $sub     = (caller 1)[3];

	error __x"class {package} does not implement method {method}.", class => $package, method => $sub;
}


sub AUTOLOAD(@)
{	my $thing   = shift;
	our $AUTOLOAD;
	my $class  = ref $thing || $thing;
	my $method = $AUTOLOAD =~ s/^.*\:\://r;

	panic "method $method() is not defined for a $class.";
}

#--------------------

sub DESTROY { $_[0] }

1;

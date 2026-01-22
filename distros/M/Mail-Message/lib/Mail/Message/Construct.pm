# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.02';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

#--------------------

our %locations = (
	bounce             => 'Bounce',

	build              => 'Build',
	buildFromBody      => 'Build',

	forward            => 'Forward',
	forwardNo          => 'Forward',
	forwardInline      => 'Forward',
	forwardAttach      => 'Forward',
	forwardEncapsulate => 'Forward',
	forwardSubject     => 'Forward',
	forwardPrelude     => 'Forward',
	forwardPostlude    => 'Forward',

	read               => 'Read',

	rebuild            => 'Rebuild',

	reply              => 'Reply',
	replySubject       => 'Reply',
	replyPrelude       => 'Reply',

	string             => 'Text',
	lines              => 'Text',
	file               => 'Text',
	printStructure     => 'Text',
);

sub AUTOLOAD(@)
{	my $self  = shift;
	our $AUTOLOAD;
	my $call = $AUTOLOAD =~ s/.*\:\://gr;

	if(my $mod = $locations{$call})
	{	eval "require Mail::Message::Construct::$mod";
		die $@ if $@;
		return $self->$call(@_);
	}

	our @ISA;                    # produce error via Mail::Reporter
	$call = "${ISA[0]}::$call";
	$self->$call(@_);
}

1;

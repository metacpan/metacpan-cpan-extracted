# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::Delayed;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Head';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error/ ];

use Object::Realize::Later
	becomes        => 'Mail::Message::Head::Complete',
	realize        => 'load',
	believe_caller => 1;

use Scalar::Util   qw/weaken/;

#--------------------

sub build(@) { error __x"cannot build() a delayed header." }

sub init($$)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	if(defined $args->{message})
	{	$self->{MMHD_message} = $args->{message};
		weaken($self->{MMHD_message});
	}

	$self;
}

sub modified(;$)
{	return 0 if @_==1 || !$_[1];
	$_[0]->forceRealize->modified(1);
}

sub isDelayed()  { 1 }
sub isModified() { 0 }
sub isEmpty()    { 0 }

#--------------------

sub get($;$) { shift->load->get(@_) }

#--------------------

sub guessBodySize() { undef }


sub guessTimestamp() { undef }

#--------------------

sub read($)
{	my ($self, $parser, $headtype, $bodytype)  = @_;

#   $parser->skipHeader not implemented... returns where
	$self->{MMH_where}   = 0;
	$self;
}

sub load() { $_[0] = $_[0]->message->loadHead }


sub setNoRealize($) { error __x"attempt to set field on a delayed header." }

1;

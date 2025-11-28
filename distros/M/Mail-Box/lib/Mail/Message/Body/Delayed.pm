# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body::Delayed;{
our $VERSION = '3.012';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Object::Realize::Later
	becomes          => 'Mail::Message::Body',
	realize          => 'load',
	warn_realization => 0,
	believe_caller   => 1;

use Carp;
use Scalar::Util     qw/weaken/;

#--------------------

use overload
	'""'    => 'string_unless_carp',
	bool    => sub {1},
	'@{}'   => sub { $_[0]->load->lines };

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MMB_seqnr}    = -1;  # for overloaded body comparison
	$self->{MMBD_message} = $args->{message}
		or $self->log(INTERNAL => "A message must be specified to a delayed body.");

	weaken($self->{MMBD_message});
	$self;
}

#--------------------

sub message() { $_[0]->{MMBD_message} }

#--------------------

sub modified(;$)
{	return 0 if @_==1 || !$_[1];
	shift->forceRealize(shift);
}


sub isModified()  {0}
sub isDelayed()   {1}
sub isMultipart() { $_[0]->message->head->isMultipart }
sub guessSize()   { $_[0]->{MMBD_size} }


sub nrLines() { $_[0]->{MMBD_lines} // $_[0]->forceRealize->nrLines }

sub string_unless_carp()
{	my $self = shift;
	return $self->load->string if (caller)[0] ne 'Carp';

	my $class = ref $self =~ s/^Mail::Message/MM/gr;
	"$class object";
}

#--------------------

sub read($$;$@)
{	my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
	$self->{MMBD_parser} = $parser;

	@$self{ qw/MMBD_begin MMBD_end MMBD_size MMBD_lines/ } = $parser->bodyDelayed(@_);
	$self;
}


sub fileLocation(;@) {
	my $self = shift;
	@_ ? (@$self{ qw/MMBD_begin MMBD_end/ } = @_) : @$self{ qw/MMBD_begin MMBD_end/ };
}


sub moveLocation($)
{	my ($self, $dist) = @_;
	$self->{MMBD_begin} -= $dist;
	$self->{MMBD_end}   -= $dist;
	$self;
}


sub load() { $_[0] = $_[0]->message->loadBody }

1;

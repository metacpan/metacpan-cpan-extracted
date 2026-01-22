# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body::Lines;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::Body';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x fault/ ];

use Mail::Box::Parser ();
use IO::Lines         ();

#--------------------

sub _data_from_filename(@)
{	my ($self, $filename) = @_;

	open my $in, '<:raw', $filename
		or fault __x"unable to read file {name} for message body lines", name => $filename;

	$self->{MMBL_array} = [ $in->getlines ];
	$in->close;
	$self;
}

sub _data_from_filehandle(@)
{	my ($self, $fh) = @_;
	$self->{MMBL_array} = ref $fh eq 'Mail::Box::FastScalar' ? $fh->getlines : [ $fh->getlines ];
	$self;
}

sub _data_from_lines(@)
{	my ($self, $lines)  = @_;

	$lines = [ split /^/, $lines->[0] ]    # body passed in one string.
		if @$lines==1;

	$self->{MMBL_array} = $lines;
	$self;
}

sub clone()
{	my $self  = shift;
	(ref $self)->new(data => [ $self->lines ], based_on => $self);
}

sub nrLines() { scalar @{ $_[0]->{MMBL_array}} }

# Optimized to be computed only once.

sub size()
{	my $self = shift;
	return $self->{MMBL_size} if exists $self->{MMBL_size};

	my $size = 0;
	$size += length $_ for @{$self->{MMBL_array}};
	$self->{MMBL_size} = $size;
}

sub string() { join '', @{$_[0]->{MMBL_array}} }
sub lines()  { wantarray ? @{$_[0]->{MMBL_array}} : $_[0]->{MMBL_array} }
sub file()   { IO::Lines->new($_[0]->{MMBL_array}) }

sub print(;$)
{	my $self = shift;
	(shift || select)->print(@{$self->{MMBL_array}});
	$self;
}

sub endsOnNewline()
{	my $last = $_[0]->{MMBL_array}[-1];
	!defined $last || $last =~ /[\r\n]$/;
}

sub read($$;$@)
{	my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
	my ($begin, $end, $lines) = $parser->bodyAsList(@_);
	$lines or return undef;

	$self->fileLocation($begin, $end);
	$self->{MMBL_array} = $lines;
	$self;
}

1;

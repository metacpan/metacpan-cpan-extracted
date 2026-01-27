# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body::String;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Body';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x fault/ ];

use Mail::Box::FastScalar ();

#--------------------

# The scalar is stored as reference to avoid a copy during creation of
# a string object.

sub _data_from_filename(@)
{	my ($self, $filename) = @_;

	delete $self->{MMBS_nrlines};
	open my $in, '<:raw', $filename
		or fault __x"unable to read file {name} for message body scalar", name => $filename;

	my @lines = $in->getlines;
	$in->close;

	$self->{MMBS_nrlines} = @lines;
	$self->{MMBS_scalar}  = join '', @lines;
	$self;
}

sub _data_from_filehandle(@)
{	my ($self, $fh) = @_;
	if(ref $fh eq 'Mail::Box::FastScalar')
	{	my $lines = $fh->getlines;
		$self->{MMBS_nrlines} = @$lines;
		$self->{MMBS_scalar}  = join '', @$lines;
	}
	else
	{	my @lines = $fh->getlines;
		$self->{MMBS_nrlines} = @lines;
		$self->{MMBS_scalar}  = join '', @lines;
	}
	$self;
}

sub _data_from_lines(@)
{	my ($self, $lines) = @_;
	$self->{MMBS_nrlines} = @$lines unless @$lines==1;
	$self->{MMBS_scalar}  = @$lines==1 ? shift @$lines : join('', @$lines);
	$self;
}

sub clone()
{	my $self = shift;
	(ref $self)->new(data => $self->string, based_on => $self);
}

sub nrLines()
{	my $self = shift;
	return $self->{MMBS_nrlines} if defined $self->{MMBS_nrlines};

	my $lines = $self->{MMBS_scalar} =~ tr/\n/\n/;
	$lines++ if $self->{MMBS_scalar} !~ m/\n\z/;
	$self->{MMBS_nrlines} = $lines;
}

sub size()   { length $_[0]->{MMBS_scalar} }
sub string() { $_[0]->{MMBS_scalar} }

sub lines()
{	my @lines = split /^/, shift->{MMBS_scalar};
	wantarray ? @lines : \@lines;
}

sub file() { Mail::Box::FastScalar->new(\shift->{MMBS_scalar}) }

sub print(;$)
{	my $self = shift;
	my $fh   = shift || select;
	$fh->print($self->{MMBS_scalar});
	$self;
}

sub read($$;$@)
{	my ($self, $parser, $head, $bodytype) = splice @_, 0, 4;
	delete $self->{MMBS_nrlines};

	(my $begin, my $end, $self->{MMBS_scalar}) = $parser->bodyAsString(@_);
	$self->fileLocation($begin, $end);

	$self;
}

sub endsOnNewline() { $_[0]->{MMBS_scalar} =~ m/\A\z|\n\z/ }

1;

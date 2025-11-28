# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Dir::Message;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use File::Copy qw/move/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->filename($args->{filename})
		if $args->{filename};

	$self->{MBDM_fix_header} = $args->{fix_header};
	$self;
}

#--------------------

sub filename(;$)
{	my $self = shift;
	@_ ? ($self->{MBDM_filename} = shift) : $self->{MBDM_filename};
}


sub fixHeader() { $_[0]->{MBDM_fix_header} }

#--------------------

sub print(;$)
{	my $self     = shift;
	my $out      = shift || select;

	return $self->SUPER::print($out)
		if $self->isModified;

	my $filename = $self->filename;
	if($filename && -r $filename)
	{	if(open my $in, '<:raw', $filename)
		{	local $_;
			print $out $_ while <$in>;
			close $in;
			return $self;
		}
	}

	$self->SUPER::print($out);
	1;
}

BEGIN { *write = \&print }  # simply alias

#--------------------

# Asking the filesystem for the size is faster counting (in
# many situations.  It even may be lazy.

sub size()
{	my $self = shift;

	unless($self->isModified)
	{	my $filename = $self->filename;
		if(defined $filename)
		{	my $size = -s $filename;
			return $size if defined $size;
		}
	}

	$self->SUPER::size;
}

sub diskDelete()
{	my $self = shift;
	$self->SUPER::diskDelete;

	my $filename = $self->filename;
	unlink $filename if $filename;
	$self;
}


sub parser()
{	my $self   = shift;

	my $parser = Mail::Box::Parser->new(
		filename => $self->filename,
		mode     => 'r',
		fix_header_errors => $self->fixHeader,
		$self->logSettings
	) or $self->log(ERROR => "Cannot create parser for $self->{MBDM_filename}."), return;

	$parser;
}


sub loadHead()
{	my $self     = shift;
	my $head     = $self->head;
	$head->isDelayed or return $head;

	my $folder   = $self->folder;
	$folder->lazyPermitted(1);

	my $parser   = $self->parser or return;
	$self->readFromParser($parser);
	$parser->stop;

	$folder->lazyPermitted(0);

	$self->log(PROGRESS => 'Loaded delayed head.');
	$self->head;
}


sub loadBody()
{	my $self     = shift;

	my $body     = $self->body;
	$body->isDelayed or return $body;

	my $head     = $self->head;
	my $parser   = $self->parser or return;

	if($head->isDelayed)
	{	$head = $self->readHead($parser)
			or $self->log(ERROR => 'Unable to read delayed head.'), return;

		$self->log(PROGRESS => 'Loaded delayed head.');
		$self->head($head);
	}
	else
	{	my ($begin, $end) = $body->fileLocation;
		$parser->filePosition($begin);
	}

	my $newbody  = $self->readBody($parser, $head)
		or $self->log(ERROR => 'Unable to read delayed body.'), return;

	$parser->stop;
	$self->log(PROGRESS => 'Loaded delayed body.');
	$self->storeBody($newbody->contentInfoFrom($head));
}


sub create($)
{	my ($self, $filename) = @_;

	my $old = $self->filename || '';
	return $self if $filename eq $old && !$self->isModified;

	# Write the new data to a new file.

	my $new = $filename . '.new';
	open my $newfh, '>:raw', $new
		or $self->log(ERROR => "Cannot write message to $new: $!"), return;

	$self->write($newfh);
	$newfh->close;

	# Accept the new data
# maildir produces warning where not expected...
#   $self->log(WARNING => "Failed to remove $old: $!")
#       if $old && !unlink $old;

	unlink $old if $old;

	move $new, $filename
		or $self->log(ERROR => "Failed to move $new to $filename: $!"), return;

	$self->modified(0);

	# Do not affect flags for Maildir (and some other) which keep it
	# in there.  Flags will be processed later.
	$self->Mail::Box::Dir::Message::filename($filename);
	$self;
}

1;

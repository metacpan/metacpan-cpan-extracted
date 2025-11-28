# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::MH::Index;{
our $VERSION = '3.012';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Mail::Message::Head::Subset ();
use Carp;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBMI_filename}  = $args->{filename}
		or croak "No index filename specified.";

	$self->{MBMI_head_wrap} = $args->{head_wrap} || 72;
	$self->{MBMI_head_type} = $args->{head_type} || 'Mail::Message::Head::Subset';
	$self;
}

#--------------------

sub filename() { $_[0]->{MBMI_filename} }

#--------------------

sub write(@)
{	my ($self, @messages) = @_;
	my $indexfn = $self->filename // return $self;

	# Remove empty index-file.
	unless(@messages)
	{	unlink $indexfn;
		return $self;
	}

	open my $index, '>:raw', $indexfn
		or return $self;

	my $written   = 0;

	foreach my $msg (@messages)
	{	my $head  = $msg->head;
		next if $head->isDelayed && $head->isa('Mail::Message::Head::Subset');

		my $fn    = $msg->filename;
		$index->print(
			"X-MailBox-Filename: $fn\n",
			'X-MailBox-Size: ', (-s $fn), "\n",
		);
		$head->print($index);
		$written++;
	}

	$index->close;
	$written or unlink $indexfn;

	$self;
}


sub append(@)
{	my ($self, @messages) = @_;
	my $indexfn = $self->filename or return $self;

	open my $index, '>>:raw', $indexfn
		or return $self;

	foreach my $msg (@messages)
	{	my $head  = $msg->head;
		next if $head->isDelayed && $head->isa('Mail::Message::Head::Subset');

		my $fn    = $msg->filename;
		$index->print(
			"X-MailBox-Filename: $fn\n",
			'X-MailBox-Size: ', (-s $fn), "\n",
		);
		$head->print($index);
	}
	$index->close;
	$self;
}


sub read(;$)
{	my $self      = shift;
	my $filename  = $self->filename;
	my $parser    = Mail::Box::Parser->new(filename => $filename, mode => 'r') or return;

	my @options   = ($self->logSettings, wrap_length => $self->{MBMI_head_wrap});
	my $type      = $self->{MBMI_head_type};
	my $index_age = -M $filename;
	my %index;

	while(my $head = $type->new(@options)->read($parser))
	{
		# cleanup the index from files which were renamed
		my $msgfile = $head->get('x-mailbox-filename');
		my $size    = int $head->get('x-mailbox-size');
		next unless -f $msgfile && -s _ == $size;
		next if defined $index_age && -M _ < $index_age;

		# keep this one
		$index{$msgfile} = $head;
	}

	$parser->stop;

	$self->{MBMI_index} = \%index;
	$self;
}


sub get($)
{	my ($self, $msgfile) = @_;
	$self->{MBMI_index}{$msgfile};
}

1;

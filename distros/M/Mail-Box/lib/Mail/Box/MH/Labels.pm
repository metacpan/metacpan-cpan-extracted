# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::MH::Labels;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault info/ ];

use Mail::Message::Head::Subset ();

#--------------------

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->{MBML_filename}  = $args->{filename} or error __x"MH labels require a filename.";
	$self;
}

#--------------------

sub filename() { $_[0]->{MBML_filename} }

#--------------------

sub get($)
{	my ($self, $msgnr) = @_;
	$self->{MBML_labels}[$msgnr];
}


sub read()
{	my $self  = shift;
	my $seqfn = $self->filename;

	open my $seq, '<:raw', $seqfn
		or return;

	my @labels;

	local $_;
	while(<$seq>)
	{	s/\s*\#.*$//;
		length or next;

		s/^\s*(\w+)\s*\:\s*// or next;
		my $label = $1;

		my $set   = 1;
		   if($label eq 'cur'   ) { $label = 'current' }
		elsif($label eq 'unseen') { $label = 'seen'; $set = 0 }

		foreach (split /\s+/)
		{	if( /^(\d+)\-(\d+)\s*$/ )
			{	push @{$labels[$_]}, $label, $set foreach $1..$2;
			}
			elsif( /^\d+\s*$/ )
			{	push @{$labels[$_]}, $label, $set;
			}
		}
	}
	$seq->close;
	$self->{MBML_labels} = \@labels;
	$self;
}


sub write(@)
{	my $self     = shift;
	my $filename = $self->filename;

	# Remove when no messages are left.
	unless(@_)
	{	unlink $filename;
		return $self;
	}

	open my $out, '>:raw', $filename
		or fault __x"cannot write MH labels file to {file}", file => $filename;

	$self->print($out, @_);
	close $out
		or fault __x"error while closing MH labels file {file} after write", file => $filename;

	$self;
}


sub append(@)
{	my $self     = shift;
	my $filename = $self->filename;

	open my $out, '>>:raw', $filename
		or fault __x"cannot append to MH labels file {file}", file => $filename;

	$self->print($out, @_);
	close $out
		or fault __x"error while closing MH labels file {file} after append", file => $filename;

	$self;
}


sub print($@)
{	my ($self, $out) = (shift, shift);

	# Collect the labels from the selected messages.
	my %labeled;
	foreach my $message (@_)
	{	my $labels = $message->labels;
		my $seq    = $message->filename =~ s!.*/!!r;

		push @{$labeled{unseen}}, $seq
			unless $labels->{seen};

		foreach (keys %$labels)
		{	push @{$labeled{$_}}, $seq
				if $labels->{$_};
		}
	}
	delete $labeled{seen};

	# Write it out

	local $"     = ' ';
	foreach (sort keys %labeled)
	{
		my @msgs = @{$labeled{$_}};  #they are ordered already.
		$_ = 'cur' if $_ eq 'current';
		print $out "$_:";

		while(@msgs)
		{	my $start = shift @msgs;
			my $end   = $start;
			$end = shift @msgs while @msgs && $msgs[0]==$end+1;

			print $out ($start==$end ? " $start" : " $start-$end");
		}
		print $out "\n";
	}

	$self;
}

1;

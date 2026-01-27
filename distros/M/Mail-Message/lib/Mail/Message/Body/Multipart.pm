# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body::Multipart;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Body';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error panic warning/ ];

use Scalar::Util   qw/blessed/;

use Mail::Message::Body::Lines ();
use Mail::Message::Part        ();
use Mail::Box::FastScalar      ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	my $based = $args->{based_on};
	$args->{mime_type} ||= defined $based ? $based->type : 'multipart/mixed';

	$self->SUPER::init($args);

	my @parts;
	if($args->{parts})
	{	foreach my $raw (@{$args->{parts}})
		{	defined $raw or next;
			my $cooked = Mail::Message::Part->coerce($raw, $self);

			defined $cooked
				or error __x"data not convertible to a message (type is {class})", class => ref $raw;

			push @parts, $cooked;
		}
	}

	my $preamble = $args->{preamble};
	$preamble    = Mail::Message::Body->new(data => $preamble)
		if defined $preamble && ! blessed $preamble;

	my $epilogue = $args->{epilogue};
	$epilogue    = Mail::Message::Body->new(data => $epilogue)
		if defined $epilogue && ! blessed $epilogue;

	if($based)
	{	$self->boundary($args->{boundary} || $based->boundary);
		$self->{MMBM_preamble} = $preamble // $based->preamble;

		$self->{MMBM_parts}
		  = @parts ? \@parts
		  : !$args->{parts} && $based->isMultipart ? [ $based->parts('ACTIVE') ]
		  :    [];

		$self->{MMBM_epilogue} = $epilogue // $based->epilogue;
	}
	else
	{	$self->boundary($args->{boundary} ||$self->type->attribute('boundary'));
		$self->{MMBM_preamble} = $preamble;
		$self->{MMBM_parts}    = \@parts;
		$self->{MMBM_epilogue} = $epilogue;
	}

	$self;
}

sub isMultipart() { 1 }
sub isBinary()    { 0 }   # A multipart body is never binary itself.  The parts may be.

sub clone()
{	my $self     = shift;
	my $preamble = $self->preamble;
	my $epilogue = $self->epilogue;

	my $body     = (ref $self)->new(
		based_on => $self,
		preamble => ($preamble ? $preamble->clone : undef),
		epilogue => ($epilogue ? $epilogue->clone : undef),
		parts    => [ map $_->clone, $self->parts('ACTIVE') ],
	);

}

sub nrLines()
{	my $self = shift;
	my $nr   = 1;  # trailing part-sep

	if(my $preamble = $self->preamble)
	{	$nr += $preamble->nrLines;
		$nr++ if $preamble->endsOnNewline;
	}

	foreach my $part ($self->parts('ACTIVE'))
	{	$nr += 1 + $part->nrLines;
		$nr++ if $part->body->endsOnNewline;
	}

	if(my $epilogue = $self->epilogue)
	{	# nrLines should match mbox counts, which is a bit
		# unclear w.r.t. the \n after a multipart separator
		# line.
		$nr += $epilogue->nrLines -1;
	}

	$nr;
}

sub size()
{	my $self   = shift;
	my $bbytes = length($self->boundary) +4;  # \n--$b\n

	my $bytes  = $bbytes +2;   # last boundary, \n--$b--\n
	if(my $preamble = $self->preamble)
	     { $bytes += $preamble->size }
	else { $bytes -= 1 }      # no leading \n

	$bytes += $bbytes + $_->size foreach $self->parts('ACTIVE');
	if(my $epilogue = $self->epilogue)
	{	$bytes += $epilogue->size;
	}
	$bytes;
}

sub string() { join '', $_[0]->lines }

sub lines()
{	my $self     = shift;
	my $boundary = $self->boundary;
	my $preamble = $self->preamble;

	my @lines;
	push @lines, $preamble->lines if $preamble;

	foreach my $part ($self->parts('ACTIVE'))
	{	# boundaries start with \n
		if(!@lines) { ; }
		elsif($lines[-1] =~ m/\n$/) { push @lines, "\n" }
		else { $lines[-1] .= "\n" }
		push @lines, "--$boundary\n", $part->lines;
	}

	if(!@lines) { ; }
	elsif($lines[-1] =~ m/\n$/) { push @lines, "\n" }
	else { $lines[-1] .= "\n" }
	push @lines, "--$boundary--";

	if(my $epilogue = $self->epilogue)
	{	$lines[-1] .= "\n";
		push @lines, $epilogue->lines;
	}

	wantarray ? @lines : \@lines;
}

sub file()                    # It may be possible to speed-improve the next code, which first
{	my $self   = shift;       # produces a full print of the message in memory...
	my $dump   = Mail::Box::FastScalar->new;
	$self->print($dump);
	$dump->seek(0,0);
	$dump;
}

sub print(;$)
{	my $self = shift;
	my $out  = shift || select;

	my $boundary = $self->boundary;
	my $count    = 0;
	if(my $preamble = $self->preamble)
	{	$preamble->print($out);
		$count++;
	}

	foreach my $part ($self->parts('ACTIVE'))
	{	$out->print("\n") if $count++;
		$out->print("--$boundary\n");
		$part->print($out);
	}
	$out->print("\n") if $count++;
	$out->print("--$boundary--");

	if(my $epilogue = $self->epilogue)
	{	$out->print("\n");
		$epilogue->print($out);
	}

	$self;
}

sub endsOnNewline()
{	my $self = shift;
	my $epilogue = $self->epilogue or return 1;
	$epilogue =~ m/[\r\n]$/;
}


sub foreachLine($)
{	my ($self, $code) = @_;
	error __x"you cannot use foreachLine on a multipart.";
}

sub check()
{	my $self = shift;
	$self->foreachComponent( sub { $_[1]->check } );
}

sub encode(@)
{	my ($self, %args) = @_;
	$self->foreachComponent( sub { $_[1]->encode(%args) } );
}

sub encoded()
{	my $self = shift;
	$self->foreachComponent( sub { $_[1]->encoded } );
}

sub read($$$$)
{	my ($self, $parser, $head, $bodytype) = @_;
	my $boundary   = $self->boundary;

	$parser->pushSeparator("--$boundary");

	my $te;
	$te = lc $1 if +($head->get('Content-Transfer-Encoding') || '') =~ m/(\w+)/;

	my @sloppyopts = (mime_type => 'text/plain', transfer_encoding => $te);

	# Get preamble.
	my $headtype = ref $head;
	my $begin    = $parser->filePosition;
	my $preamble = Mail::Message::Body::Lines->new(@sloppyopts)->read($parser, $head);

	$preamble->nrLines or undef $preamble;
	$self->{MMBM_preamble} = $preamble if defined $preamble;

	# Get the parts.

	my ($has_epilogue, @parts);
	while(my $sep = $parser->readSeparator)
	{	if($sep =~ m/^--\Q$boundary\E--[ \t]*\n?/)
		{	# Per RFC 2046, a CRLF after the close-delimiter marks the presence
			# of an epilogue.  Preserve the epilogue, even if empty, so that the
			# printed multipart body will also have the CRLF.
			# This, however, is complicated w.r.t. mbox folders.
			$has_epilogue = $sep =~ /\n/;
			last;
		}

		my $part = Mail::Message::Part->new(container => $self);
		$part->readFromParser($parser, $bodytype)
			or last;

		push @parts, $part if $part->head->names || $part->body->size;
	}
	$self->{MMBM_parts} = \@parts;

	# Get epilogue

	$parser->popSeparator;
	my $epilogue = Mail::Message::Body::Lines->new(@sloppyopts)
		->read($parser, $head);

	my $end
	  = defined $epilogue ? ($epilogue->fileLocation)[1]
	  : @parts            ? ($parts[-1]->body->fileLocation)[1]
	  : defined $preamble ? ($preamble->fileLocation)[1]
	  :    $begin;

	$self->fileLocation($begin, $end);

	$has_epilogue || $epilogue->nrLines
		or undef $epilogue;

	$self->{MMBM_epilogue} = $epilogue
		if defined $epilogue;

	$self;
}

#--------------------

sub foreachComponent($)
{	my ($self, $code) = @_;
	my $changes  = 0;

	my $new_preamble;
	if(my $preamble = $self->preamble)
	{	$new_preamble = $code->($self, $preamble);
		$changes++ unless $preamble == $new_preamble;
	}

	my $new_epilogue;
	if(my $epilogue = $self->epilogue)
	{	$new_epilogue = $code->($self, $epilogue);
		$changes++ unless $epilogue == $new_epilogue;
	}

	my @new_bodies;
	foreach my $part ($self->parts('ACTIVE'))
	{	my $part_body = $part->body;
		my $new_body  = $code->($self, $part_body);

		$changes++ if $new_body != $part_body;
		push @new_bodies, [$part, $new_body];
	}

	$changes or return $self;

	my @new_parts;
	foreach (@new_bodies)
	{	my ($part, $body) = @$_;
		my $new_part = Mail::Message::Part->new(head => $part->head->clone, container => undef);
		$new_part->body($body);
		push @new_parts, $new_part;
	}

	my $constructed = (ref $self)->new(
		preamble => $new_preamble,
		parts    => \@new_parts,
		epilogue => $new_epilogue,
		based_on => $self,
	);

	$_->container($constructed)
		for @new_parts;

	$constructed;
}


sub attach(@)
{	my $self  = shift;
	(ref $self)->new(based_on => $self, parts => [ $self->parts, @_ ]);
}


sub stripSignature(@)
{	my $self  = shift;

	my @allparts = $self->parts;
	my @parts    = grep ! $_->body->mimeType->isSignature, @allparts;

	@allparts == @parts ? $self : (ref $self)->new(based_on => $self, parts => \@parts);
}

#--------------------

sub preamble() { $_[0]->{MMBM_preamble} }


sub epilogue() { $_[0]->{MMBM_epilogue} }


sub parts(;$)
{	my $self  = shift;
	return @{$self->{MMBM_parts}} unless @_;

	my $what  = shift;
	my @parts = @{$self->{MMBM_parts}};

	  $what eq 'RECURSE' ? (map $_->parts('RECURSE'), @parts)
	: $what eq 'ALL'     ? @parts
	: $what eq 'DELETED' ? (grep  $_->isDeleted, @parts)
	: $what eq 'ACTIVE'  ? (grep !$_->isDeleted, @parts)
	: ref $what eq 'CODE'? (grep $what->($_), @parts)
	:    error __x"unknown criterium {what} to select parts.", what => $what;
}


sub part($) { $_[0]->{MMBM_parts}[$_[1]] }

sub partNumberOf($)
{	my ($self, $part) = @_;
	my $msg   = $self->message or panic "multipart is not connected.";

	my $base  = $msg->isa('Mail::Message::Part') ? $msg->partNumber.'.' : '';

	my @parts = $self->parts('ACTIVE');
	foreach my $partnr (0..@parts)
	{	return $base.($partnr+1)
			if $parts[$partnr] == $part;
	}
	panic "multipart is not found or not active";
}


sub boundary(;$)
{	my $self  = shift;
	my $mime  = $self->type;

	unless(@_)
	{	my $boundary = $mime->attribute('boundary');
		return $boundary if defined $boundary;
	}

	my $boundary = $_[0] // "boundary-".int rand(1000000);
	$self->type->attribute(boundary => $boundary);
}

sub toplevel() { my $msg = $_[0]->message; $msg ? $msg->toplevel : undef}

1;

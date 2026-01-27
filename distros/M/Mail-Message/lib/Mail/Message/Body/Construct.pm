# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body;{
our $VERSION = '4.03';
}

# Mail::Message::Body::Construct adds functionality to Mail::Message::Body

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use Scalar::Util  qw/blessed/;

use Mail::Message::Body::String ();
use Mail::Message::Body::Lines  ();

#--------------------

sub foreachLine($)
{	my ($self, $code) = @_;
	my $changes = 0;
	my @result;

	foreach ($self->lines)
	{	my $becomes = $code->();
		if(defined $becomes)
		{	push @result, $becomes;
			$changes++ if $becomes ne $_;
		}
		else { $changes++ }
	}

	$changes ? (ref $self)->new(based_on => $self, data => \@result) : $self;
}


sub concatenate(@)
{	my $self = shift;
	return $self if @_==1;

	my @unified;
	foreach (grep defined, @_)
	{	push @unified,
			  ! ref $_          ? $_
			: ref $_ eq 'ARRAY' ? @$_
			: $_->isa('Mail::Message')       ? $_->body->decoded
			: $_->isa('Mail::Message::Body') ? $_->decoded
			: 	error(__x"cannot concatenate element {which}", which => $_);
	}

	(ref $self)->new(
		based_on  => $self,
		mime_type => 'text/plain',
		data      => join('', @unified),
	);
}


sub attach(@)
{	my $self  = shift;

	my @parts;
	push @parts, shift while @_ && blessed $_[0];
	@parts or return $self;

	unshift @parts, $self->isNested ? $self->nested : $self->isMultipart ? $self->parts : $self;

	@parts==1 ? $parts[0] : Mail::Message::Body::Multipart->new(parts => \@parts, @_);
}


# tests in t/51stripsig.t

sub stripSignature($@)
{	my ($self, %args) = @_;

	return $self if $self->mimeType->isBinary;

	my $p       = $args{pattern};
	my $pattern = ! defined $p ? qr/^--\s?$/
				: ! ref $p     ? qr/^\Q$p/
				:    $p;

	my $lines   = $self->lines;   # no copy!
	my $stop    = defined $args{max_lines} ? @$lines - $args{max_lines}
				: exists $args{max_lines}  ? 0
				:    @$lines-10;

	$stop = 0 if $stop < 0;
	my ($sigstart, $found);

	if(ref $pattern eq 'CODE')
	{	for($sigstart = $#$lines; $sigstart >= $stop; $sigstart--)
		{	$pattern->($lines->[$sigstart]) or next;
			$found = 1;
			last;
		}
	}
	else
	{	for($sigstart = $#$lines; $sigstart >= $stop; $sigstart--)
		{	$lines->[$sigstart] =~ $pattern or next;
			$found = 1;
			last;
		}
	}

	$found or return $self;

	my $bodytype = $args{result_type} || ref $self;
	my $stripped = $bodytype->new(based_on => $self, data => [ @$lines[0..$sigstart-1] ]);

	wantarray or return $stripped;

	my $sig      = $bodytype->new(based_on => $self, data => [ @$lines[$sigstart..$#$lines] ]);
	($stripped, $sig);
}

1;

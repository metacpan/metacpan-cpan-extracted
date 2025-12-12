# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Search::Grep;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Search';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error info/ ];

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$args->{in} ||= ($args->{field} ? 'HEAD' : 'BODY');

	my $deliver = $args->{deliver} || $args->{details};  # details is old name
	$args->{deliver}
	  = !defined $deliver       ? undef
	  : ref $deliver eq 'CODE'  ? $deliver
	  : $deliver eq 'PRINT'     ? sub { $_[0]->printMatch($_[1]) }
	  : ref $deliver eq 'ARRAY' ? sub { push @$deliver, $_[1] }
	  :    $deliver;

	$self->SUPER::init($args);

	my $take = $args->{field};
	$self->{MBSG_field_check}
	  = !defined $take         ? sub {1}
	  : !ref $take             ? do {$take = lc $take; sub { $_[1] eq $take }}
	  :  ref $take eq 'Regexp' ? sub { $_[1] =~ $take }
	  :  ref $take eq 'CODE'   ? $take
	  :     error __x"unsupported field selector {take UNKNOWN}.", take => $take;

	my $match = $args->{match}
		or error __x"grep requires a match pattern.";

	$self->{MBSG_match_check}
	= !ref $match             ? sub { index("$_[1]", $match) >= $[ }
	:  ref $match eq 'Regexp' ? sub { "$_[1]" =~ $match }
	:  ref $match eq 'CODE'   ? $match
	:     error __x"unsupported match pattern {match UNKNOWN}.", match => $match;

	$self;
}

sub search(@)
{	my ($self, $object, %args) = @_;
	delete $self->{MBSG_last_printed};
	$self->SUPER::search($object, %args);
}

sub inHead(@)
{	my ($self, $part, $head, $args) = @_;

	my @details = (message => $part->toplevel, part => $part);
	my ($field_check, $match_check, $deliver) = @$self{ qw/MBSG_field_check MBSG_match_check MBS_deliver/ };

	my $matched = 0;
LINES:
	foreach my $field ($head->orderedFields)
	{	$field_check->($head, $field->name) && $match_check->($head, $field) or next;
		$matched++;
		$deliver or last LINES;  # no deliver: only one match needed
		$deliver->( {@details, field => $field} );
	}

	$matched;
}

sub inBody(@)
{	my ($self, $part, $body, $args) = @_;

	my @details = (message => $part->toplevel, part => $part);
	my ($field_check, $match_check, $deliver) = @$self{ qw/MBSG_field_check MBSG_match_check MBS_deliver/ };

	my $matched = 0;
	my $linenr  = 0;

  LINES:
	foreach my $line ($body->lines)
	{	$linenr++;
		$match_check->($body, $line) or next;

		$matched++;
		$deliver or last LINES;  # no deliver: only one match needed
		$deliver->( +{ @details, linenr => $linenr, line => $line } );
	}

	$matched;
}

#--------------------

sub printMatch($;$)
{	my $self = shift;
	my ($out, $match) = @_==2 ? @_ : (select, shift);

	  $match->{field}
	? $self->printMatchedHead($out, $match)
	: $self->printMatchedBody($out, $match)
}


sub printMatchedHead($$)
{	my ($self, $out, $match) = @_;
	my $message = $match->{message};
	my $msgnr   = $message->seqnr;
	my $folder  = $message->folder->name;
	my $lp      = $self->{MBSG_last_printed} || '';

	unless($lp eq "$folder $msgnr")  # match in new message
	{	my $subject = $message->subject;
		$out->print("$folder, message $msgnr: $subject\n");
		$self->{MBSG_last_printed} = "$folder $msgnr";
	}

	my @lines   = $match->{field}->string;
	my $inpart  = $match->{part}->isPart ? 'p ' : '  ';
	$out->print($inpart, join $inpart, @lines);
	$self;
}


sub printMatchedBody($$)
{	my ($self, $out, $match) = @_;
	my $message = $match->{message};
	my $msgnr   = $message->seqnr;
	my $folder  = $message->folder->name;
	my $lp      = $self->{MBSG_last_printed} || '';

	unless($lp eq "$folder $msgnr")  # match in new message
	{	my $subject = $message->subject;
		$out->print("$folder, message $msgnr: $subject\n");
		$self->{MBSG_last_printed} = "$folder $msgnr";
	}

	my $inpart  = $match->{part}->isPart ? 'p ' : '  ';
	$out->print(sprintf "$inpart %2d: %s", $match->{linenr}, $match->{line});
	$self;
}

1;

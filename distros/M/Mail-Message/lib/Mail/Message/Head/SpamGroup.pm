# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::SpamGroup;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Head::FieldGroup';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/panic/ ];

#--------------------

my %fighters;
my $fighterfields;    # one regexp for all fields

sub knownFighters() { keys %fighters }


sub fighter($;@)
{	my ($thing, $name) = (shift, shift);

	if(@_)
	{	my %args   = @_;
		defined $args{fields} or panic "requires fields";
		defined $args{isspam} or panic "requires isspam";
		$fighters{$name} = \%args;

		my @fields = map $_->{fields}, values %fighters;
		local $" = '|';
		$fighterfields = qr/@fields/;
	}

	%{$fighters{$name}};
}


BEGIN
{	__PACKAGE__->fighter( SpamAssassin =>
		fields  => qr/^X-Spam-/i,
		isspam  => sub {
			my ($sg, $head) = @_;
			my $f = $head->get('X-Spam-Flag') || $head->get('X-Spam-Status');
			$f ? $f =~ m/^yes\b/i : 0;
		},
		version => sub {
			my ($sg, $head) = @_;
			my $assin = $head->get('X-Spam-Checker-Version') or return ();
			my ($software, $version) = $assin =~ m/^(.*)\s+(.*?)\s*$/;
			($software, $version);
		},
	);

	__PACKAGE__->fighter( 'Habeas-SWE' =>
		fields  => qr/^X-Habeas-SWE/i,
		isspam  => sub {
			my ($sg, $head) = @_;
			not $sg->habeasSweFieldsCorrect;
		},
	);

	__PACKAGE__->fighter( MailScanner  =>
		fields  => qr/^X-MailScanner/i,
		isspam  => sub {
			my ($sg, $head) = @_;
			my $subject = $head->get('subject');
			$subject =~ m/^\{ (?:spam|virus)/xi;
		},
	);
}


sub from($@)
{	my ($class, $from, %args) = @_;
	my $head  = $from->isa('Mail::Message::Head') ? $from : $from->head;
	my ($self, @detected);

	my @types = defined $args{types} ? @{$args{types}} : $class->knownFighters;

	foreach my $type (@types)
	{	$self = $class->new(head => $head) unless defined $self;
		$self->collectFields($type) or next;

		my %fighter = $self->fighter($type);
		my ($software, $version) = defined $fighter{version} ? $fighter{version}->($self, $head) : ();

		$self->detected($type, $software, $version);
		$self->spamDetected( $fighter{isspam}->($self, $head) );

		push @detected, $self;
		undef $self;             # create a new one
	}

	@detected;
}

sub collectFields($)
{	my ($self, $set) = @_;
	my %fighter = $self->fighter($set) or panic "no spam set $set";

	my @names = map $_->name, $self->head->grepNames($fighter{fields});
	$self->addFields(@names) if @names;
	@names;
}


sub isSpamGroupFieldName($) { $_[1] =~ $fighterfields }


my @habeas_lines = (
	'winter into spring', 'brightly anticipated', 'like Habeas SWE (tm)',
	'Copyright 2002 Habeas (tm)',
	'Sender Warranted Email (SWE) (tm). The sender of this',
	'email in exchange for a license for this Habeas',
	'warrant mark warrants that this is a Habeas Compliant',
	'Message (HCM) and not spam. Please report use of this',
	'mark in spam to <http://www.habeas.com/report/>.',
);

sub habeasSweFieldsCorrect(;$)
{	my $self;

	if(@_ > 1)
	{	my ($class, $thing) = @_;
		my $head = $thing->isa('Mail::Message::Head') ? $thing : $thing->head;
		$self    = $head->spamGroups('Habeas-SWE') or return;
	}
	else
	{	$self = shift;
		my $type = $self->type;
		defined $type && $type eq 'Habeas-SWE' or return;
	}

	my $head     = $self->head;
	$self->fields == @habeas_lines or return;

	for(my $nr=1; $nr <= $#habeas_lines; $nr++)
	{	my $f = $head->get("X-Habeas-SWE-$nr") or return;
		$f->unfoldedBody eq $habeas_lines[$nr-1] or return;
	}

	1;
}


sub spamDetected(;$)
{	my $self = shift;
	@_? ($self->{MMFS_spam} = shift) : $self->{MMFS_spam};
}

1;

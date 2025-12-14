# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::ResentGroup;{
our $VERSION = '4.01';
}

use parent 'Mail::Message::Head::FieldGroup';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use Scalar::Util  qw/weaken/;
use Sys::Hostname qw/hostname/;
use Mail::Address ();

use Mail::Message::Field::Fast ();

#--------------------

# all lower cased!
my @ordered_field_names = (
	'return-path', 'delivered-to' , 'received', 'resent-date',
	'resent-from', 'resent-sender', , 'resent-to', 'resent-cc',
	'resent-bcc', 'resent-message-id'
);

my %resent_field_names = map +($_ => 1), @ordered_field_names;

sub init($$)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);

	$self->{MMHR_real}  = $args->{message_head};

	$self->set(Received => $self->createReceived)
		if $self->orderedFields && ! $self->received;

	$self;
}


sub from($@)
{	@_==1 and return $_[0]->resentFrom;   # backwards compat

	my ($class, $from, %args) = @_;
	my $head = $from->isa('Mail::Message::Head') ? $from : $from->head;

	my (@groups, $group, $return_path, $delivered_to);

	foreach my $field ($head->orderedFields)
	{	my $name = $field->name;
		$resent_field_names{$name} or next;

		if($name eq 'return-path')              { $return_path  = $field }
		elsif($name eq 'delivered-to')          { $delivered_to = $field }
		elsif(substr($name, 0, 7) eq 'resent-')
		{	$group->add($field) if defined $group;
		}
		elsif($name eq 'received')
		{
			$group = Mail::Message::Head::ResentGroup ->new($field, message_head => $head);
			push @groups, $group;

			$group->add($delivered_to) if defined $delivered_to;
			undef $delivered_to;

			$group->add($return_path) if defined $return_path;
			undef $return_path;
		}
	}

	@groups;
}

#--------------------

sub messageHead(;$)
{	my $self = shift;
	@_ ? $self->{MMHR_real} = shift : $self->{MMHR_real};
}


sub orderedFields()
{	my $head = shift->head;
	map { $head->get($_) || () } @ordered_field_names;
}


sub set($;$)
{	my $self  = shift;
	my $field;

	if(@_==1) { $field = shift }
	else
	{	my ($fn, $value) = @_;
		my $name  = $resent_field_names{lc $fn} ? $fn : "Resent-$fn";
		$field = Mail::Message::Field::Fast->new($name, $value);
	}

	$self->head->set($field);
	$field;
}

sub fields()     { $_[0]->orderedFields }
sub fieldNames() { map $_->Name, $_[0]->orderedFields }

sub delete()
{	my $self   = shift;
	my $head   = $self->messageHead;
	$head->removeField($_) for $self->fields;
	$self;
}


sub add(@) { shift->set(@_) }


sub addFields(@) { $_[0]->notImplemented }

#--------------------

sub returnPath() { $_[0]->{MMHR_return_path} }


sub deliveredTo() { $_[0]->head->get('Delivered-To') }


sub received() { $_[0]->head->get('Received') }


sub receivedTimestamp()
{	my $received = $_[0]->received or return;
	my $comment  = $received->comment or return;
	Mail::Message::Field->dateToTimestamp($comment);
}


sub date($) { $_[0]->head->get('resent-date') }


sub dateTimestamp()
{	my $date = $_[0]->date or return;
	Mail::Message::Field->dateToTimestamp($date->unfoldedBody);
}


sub resentFrom()
{	my $from = $_[0]->head->get('resent-from') or return ();
	wantarray ? $from->addresses : $from;
}


sub sender()
{	my $sender = $_[0]->head->get('resent-sender') or return ();
	wantarray ? $sender->addresses : $sender;
}


sub to()
{	my $to = $_[0]->head->get('resent-to') or return ();
	wantarray ? $to->addresses : $to;
}


sub cc()
{	my $cc = $_[0]->head->get('resent-cc') or return ();
	wantarray ? $cc->addresses : $cc;
}


sub bcc()
{	my $bcc = $_[0]->head->get('resent-bcc') or return ();
	wantarray ? $bcc->addresses : $bcc;
}


sub destinations()
{	my $self = shift;
	($self->to, $self->cc, $self->bcc);
}


sub messageId() { $_[0]->head->get('resent-message-id') }


sub isResentGroupFieldName($) { $resent_field_names{lc $_[1]} }

#--------------------

my $unique_received_id = 'rc'.time;

sub createReceived(;$)
{	my ($self, $domain) = @_;

	unless(defined $domain)
	{	my $sender = ($self->sender)[0] || ($self->resentFrom)[0];
		$domain    = $sender->host if defined $sender;
	}

	my $received
	  = "from $domain by ". hostname . ' with SMTP id ' . $unique_received_id++
	  . ' for ' . $self->head->get('Resent-To')  # may be wrong
	  . '; '. Mail::Message::Field->toDate;

	$received;
}

#--------------------

1;

# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Wrapper::SpamAssassin;{
our $VERSION = '3.012';
}

use parent 'Mail::SpamAssassin::Message';

use strict;
use warnings;

use Carp;
use Mail::Message::Body;

BEGIN
{	my $v = $Mail::SpamAssassin::VERSION;
	die "ERROR: spam-assassin version $v is not supported (only versions 2.x)\n"
		if $v >= 3.0;
}

#--------------------

sub new(@)    # fix missing infra-structure of base element
{	my ($class, $message, %args) = @_;

	$_->delete for $message->head->spamGroups('SpamAssassin');
	$class->SUPER::new( +{ message => $message } )->init(\%args);
}

sub init($) { $_[0] }

sub create_new() {croak "Should not be used"}

sub get($) { $_[0]->get_header($_[1]) }

sub get_header($)
{	my ($self, $name) = @_;
	my $head = $self->get_mail_object->head;

	# Return all fields unfolded in list context
	return map $_->unfoldedBody, $head->get($name)
		if wantarray;

	# Only one field is expected
	my $field = $head->get($name);
	defined $field ? $field->unfoldedBody : undef;
}

sub get_pristine_header($)
{	my ($self, $name) = @_;
	my $field = $self->get_mail_object->head->get($name);
	defined $field ? $field->foldedBody : undef;
}

sub put_header($$)
{	my ($self, $name, $value) = @_;
	my $head = $self->get_mail_object->head;
	$value =~ s/\s{2,}/ /g;
	$value =~ s/\s*$//;      # will cause a refold as well
	length $value ? $head->add($name => $value) : ();
}

sub get_all_headers($)
{	my $head = shift->get_mail_object->head;
	"$head";
}

sub replace_header($$)
{	my $head = shift->get_mail_object->head;
	my ($name, $value) = @_;
	$head->set($name, $value);
}

sub delete_header($)
{	my $head = shift->get_mail_object->head;
	my $name = shift;
	$head->delete($name);
}

sub get_body() { $_[0]->get_mail_object->body->lines }

sub get_pristine() { $_[0]->get_mail_object->head->string }

sub replace_body($)
{	my ($self, $data) = @_;
	my $body = Mail::Message::Body->new(data => $data);
	$self->get_mail_object->storeBody($body);
}

sub replace_original_message($)
{	my ($self, $lines) = @_;
	die "We will not replace the message.  Use report_safe = 0\n";
}

1;

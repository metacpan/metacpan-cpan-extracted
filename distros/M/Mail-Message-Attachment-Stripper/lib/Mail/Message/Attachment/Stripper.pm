package Mail::Message::Attachment::Stripper;

use strict;
use warnings;

our $VERSION = '1.01';

use Carp;

=head1 NAME

Mail::Message::Attachment::Stripper - Strip the attachments from a mail

=head1 SYNOPSIS

	my $stripper = Mail::Message::Attachment::Stripper->new($mail);

	my Mail::Message $msg = $stripper->message;
	my @attachments       = $stripper->attachments;

=head1 DESCRIPTION

Given a Mail::Message object, detach all attachments from the
message. These are then available separately.

=head1 METHODS

=head2 new 

	my $stripper = Mail::Message::Attachment::Stripper->new($mail);

This should be instantiated with a Mail::Message object.

=head2 message

	my Mail::Message $msg = $stripper->message;

This returns the message with all the attachments detached. This will
alter both the body and the header of the message.

=head2 attachments

	my @attachments = $stripper->attachments;

This returns a list of all the attachments we found in the message,
as a hash of { filename, content_type, payload }.

=cut

sub new {
	my ($class, $msg) = @_;
	croak "Need a message" unless eval { $msg->isa("Mail::Message") };
	bless { _msg => $msg }, $class;
}

sub message {
	my $self = shift;
	$self->_detach_all unless exists $self->{_atts};
	return $self->{_msg};
}

sub attachments {
	my $self = shift;
	$self->_detach_all unless exists $self->{_atts};
	return $self->{_atts} ? @{ $self->{_atts} } : ();
}

sub _detach_all {
	my $self = shift;
	my $mm   = $self->{_msg};

	$self->{_atts} = [];
	$self->{_body} = [];

	$self->_handle_part($mm);
	$mm->body(Mail::Message::Body->new(data => $self->{_body}));
	$self;
}

sub _handle_part {
	my ($self, $mm) = @_;

	# According to Mail::Message docs, this ternary is not required. However,
	# $Mail_Message->parts calls $Mail_Message->deleted which is
	# unimplemented
	foreach my $part ($mm->isMultipart ? $mm->parts : $mm) {
		if ($self->_is_inline_text($part)) {
			$self->_gather_body($part);
		} elsif ($self->_should_recurse($part)) {
			$self->_handle_part($part);
		} else {
			$self->_gather_att($part);
		}
	}
}

sub _gather_body {    # Gen 25:8
	my ($self, $part) = @_;
	push @{ $self->{_body} }, $part->decoded->lines;
}

sub _gather_att {
	my ($self, $part) = @_;

	# stringification is required for safety
	push @{ $self->{_atts} },
		{
		content_type => $part->body->mimeType . "",
		payload      => $part->decoded . "",
		filename     => $self->_filename_for($part),
		};
}

sub _should_recurse {
	my ($self, $part) = @_;
	return 0 if lc($part->body->mimeType) eq "message/rfc822";
	return 1 if $part->isMultipart;
	return 0;
}

sub _is_inline_text {
	my ($self, $part) = @_;
	if ($part->body->mimeType eq "text/plain") {
		my $disp = $part->head->get("Content-Disposition");
		return 1 if $disp && $disp =~ /inline/;
		return 0 if $self->_filename_for($part);
		return 1;
	}
	return 0;
}

sub _filename_for {
	my ($self, $part) = @_;
	my $disp = $part->head->get("Content-Disposition");
	my $type = $part->head->get("Content-Type");
	return ($disp && $disp->attribute("filename"))
		|| ($type && $type->attribute("name"))
		|| "";
}

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Mail-Message-Attachment-Stripper@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2002-2005 Kasei

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut


1;

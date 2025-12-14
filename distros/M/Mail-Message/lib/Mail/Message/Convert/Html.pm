# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::Html;{
our $VERSION = '4.01';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

#--------------------

sub init($)
{	my ($self, $args)  = @_;

	$self->SUPER::init($args);

	my $produce = $args->{produce} || 'HTML';

	$self->{MMCH_tail}
	  = $produce eq 'HTML'  ?   '>'
	  : $produce eq 'XHTML' ? ' />'
	  :    error __x"produce XHTML or HTML, not {what UNKNOWN}.", what => $produce;

	$self;
}

#--------------------

sub textToHtml(@)
{	my $self  = shift;

	my @lines = @_;    # copy is required
	foreach (@lines)
	{	s/\&/&amp;/gs; s/\</&lt;/gs;
		s/\>/&gt;/gs;  s/\"/&quot;/gs;
	}
	wantarray ? @lines : join('', @lines);
}


sub fieldToHtml($;$)
{	my ($self, $field, $subject) = @_;
	   '<strong>'. $self->textToHtml($field->wellformedName) .  ': </strong>' . $self->fieldContentsToHtml($field, $subject);
}


sub headToHtmlTable($;$)
{	my ($self, $head) = (shift, shift);
	my $tp      = @_ ? ' '.shift : '';

	my $subject;
	if($self->{MMHC_mailto_subject})
	{	my $s = $head->get('subject');

		use Mail::Message::Construct;
		$subject = Mail::Message::Construct->replySubject($s) if defined $s;
	}

	my @lines = "<table $tp>\n";
	foreach my $f ($self->selectedFields($head))
	{	my $name_html = $self->textToHtml($f->wellformedName);
		my $cont_html = $self->fieldContentsToHtml($f, $subject);

		push @lines,
			qq(<tr><th valign="top" align="left">$name_html:</th>\n),
			qq(    <td valign="top">$cont_html</td></tr>\n);
	}

	push @lines, "</table>\n";
	wantarray ? @lines : join('',@lines);
}


sub headToHtmlHead($@)
{	my ($self, $head) = (shift,shift);
	my %meta;
	while(@_) { my $k = shift; $meta{lc $k} = shift }

	my $title = delete $meta{title} || $head->get('subject') || '<no subject>';

	my @lines = (
		"<head>\n",
		"<title>".$self->textToHtml($title) . "</title>\n",
	);

	my $author = delete $meta{author};
	unless(defined $author)
	{	my $from = $head->get('from');
		my @addr = defined $from ? $from->addresses : ();
		$author  = @addr ? $addr[0]->format : undef;
	}

	push @lines, '<meta name="Author" content="' . $self->textToHtml($author) . "\"$self->{MMCH_tail}\n"
		if defined $author;

	foreach my $f (map {lc} keys %meta)
	{	next if $meta{$f} eq '';     # empty is skipped.
		push @lines,
			  '<meta name="'. ucfirst lc $self->textToHtml($f)
			. '" content="'. $self->textToHtml($meta{$f})
			."\"$self->{MMCH_tail}\n";
	}

	foreach my $f ($self->selectedFields($head))
	{	next if exists $meta{$f->name};
		push @lines,
			  '<meta name="' . $self->textToHtml($f->wellformedName)
			. '" content="'  . $self->textToHtml($f->content)
			. "\"$self->{MMCH_tail}\n";
	}

	push @lines, "</head>\n";
	wantarray ? @lines : join('',@lines);
}


my $atom          = qr/[^()<>@,;:\\".\[\]\s[:cntrl:]]+/;
my $email_address = qr/(($atom(?:\.$atom)*)\@($atom(?:\.$atom)+))/o;

sub fieldContentsToHtml($;$)
{	my ($self, $field, $subj) = @_;

	my $subject = defined $subj ? '?subject='.$self->textToHtml($subj) : '';
	my $body    = $self->textToHtml($field->body);
	my $comment = $field->comment;

	$body =~ s#$email_address#<a href="mailto:$1$subject">$1</a>#gx
		if $field->name =~ m/^(resent-)?(to|from|cc|bcc|reply\-to)$/;

	$body . ($comment ? '; '.$self->textToHtml($comment) : '');
}

1;

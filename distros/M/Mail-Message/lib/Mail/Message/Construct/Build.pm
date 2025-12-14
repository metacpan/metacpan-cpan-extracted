# This code is part of Perl distribution Mail-Message version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.01';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error info warning/ ];

use Mail::Message::Head::Complete  ();
use Mail::Message::Body::Lines     ();
use Mail::Message::Body::Multipart ();
use Mail::Message::Body::Nested    ();
use Mail::Message::Field           ();

use Mail::Address  ();
use Scalar::Util   qw/blessed/;

#--------------------

sub build(@)
{	my $class = shift;

	! $class->isa('Mail::Box::Message')
		or error __x"only build() Mail::Message's; they are not in a folder yet.";

	my @parts
	  = ! blessed $_[0] ? ()
	  : $_[0]->isa('Mail::Message')       ? shift
	  : $_[0]->isa('Mail::Message::Body') ? shift
	  :    ();

	my ($head, @headerlines);
	my ($type, $transfenc, $dispose, $descr, $cid, $lang);
	while(@_)
	{	my $key = shift;

		if(blessed $key && $key->isa('Mail::Message::Field'))
		{	my $name = $key->name;
			   if($name eq 'content-type')        { $type    = $key }
			elsif($name eq 'content-transfer-encoding') { $transfenc = $key }
			elsif($name eq 'content-disposition') { $dispose = $key }
			elsif($name eq 'content-description') { $descr   = $key }
			elsif($name eq 'content-language')    { $lang    = $key }
			elsif($name eq 'content-id')          { $cid     = $key }
			else { push @headerlines, $key }
			next;
		}

		my $value = shift // next;

		my @data;

		if($key eq 'head')
		{	$head = $value }
		elsif($key eq 'data')
		{	@data = Mail::Message::Body->new(data => $value) }
		elsif($key eq 'file' || $key eq 'files')
		{	@data = map Mail::Message::Body->new(file => $_), ref $value eq 'ARRAY' ? @$value : $value;
		}
		elsif($key eq 'attach')
		{	foreach my $c (ref $value eq 'ARRAY' ? @$value : $value)
			{	defined $c or next;
				push @data, blessed $c && $c->isa('Mail::Message') ? Mail::Message::Body::Nested->new(nested => $c) : $c;
			}
		}
		elsif($key =~ m/^content\-(type|transfer\-encoding|disposition|language|description|id)$/i )
		{	my $k     = lc $1;
			my $field = Mail::Message::Field->new($key, $value);
			   if($k eq 'type')        { $type    = $field }
			elsif($k eq 'disposition') { $dispose = $field }
			elsif($k eq 'description') { $descr   = $field }
			elsif($k eq 'language')    { $lang    = $field }
			elsif($k eq 'id')          { $cid     = $field }
			else                     { $transfenc = $field }
		}
		elsif($key =~ m/^[A-Z]/)
		{	push @headerlines, $key, $value }
		else
		{	warning __x"skipped unknown key '{key}' in build.", key => $key;
		}

		push @parts, grep defined, @data;
	}

	my $body
	  = @parts==0 ? Mail::Message::Body::Lines->new
	  : @parts==1 ? $parts[0]
	  :    Mail::Message::Body::Multipart->new(parts => \@parts);

	# Setting the type explicitly, only after the body object is finalized
	$body->type($type)           if defined $type;
	$body->disposition($dispose) if defined $dispose;
	$body->description($descr)   if defined $descr;
	$body->language($lang)       if defined $lang;
	$body->contentId($cid)       if defined $cid;
	$body->transferEncoding($transfenc) if defined $transfenc;

	$class->buildFromBody($body, $head, @headerlines);
}


sub buildFromBody(@)
{	my ($class, $body) = (shift, shift);

	my $head;
	if(blessed $_[0] && $_[0]->isa('Mail::Message::Head')) { $head = shift }
	else
	{	defined $_[0] or shift;   # explicit undef as head
		$head = Mail::Message::Head::Complete->new;
	}

	while(@_)
	{	if(blessed $_[0]) { $head->add(shift) }
		else              { $head->add(shift, shift) }
	}

	my $message = $class->new(head => $head);
	$message->body($body);

	# be sure the message-id is actually stored in the header.
	defined $head->get('message-id')   or $head->add('Message-Id' => '<'.$message->messageId.'>');
	defined $head->get('Date')         or $head->add(Date => Mail::Message::Field->toDate);
	defined $head->get('MIME-Version') or $head->add('MIME-Version' => '1.0'); # required by rfc2045

	$message;
}

#--------------------

1;

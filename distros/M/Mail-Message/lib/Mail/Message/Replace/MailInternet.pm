# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Replace::MailInternet;{
our $VERSION = '3.020';
}

use base 'Mail::Message';

use strict;
use warnings;

use Mail::Box::FastScalar        ();
use Mail::Box::Parser::Perl      ();
use Mail::Message::Body::Lines   ();

use IO::Handle       ();
use File::Spec       ();

use Scalar::Util     qw/blessed/;

#--------------------

sub new(@)
{	my $class = shift;
	my $data  = @_ % 2 ? shift : undef;
	$class = __PACKAGE__ if $class eq 'Mail::Internet';
	$class->SUPER::new(@_, raw_data => $data);
}

sub init($)
{	my ($self, $args) = @_;
	$args->{head_type} ||= 'Mail::Message::Replace::MailHeader';
	$args->{head}      ||= $args->{Header};
	$args->{body}      ||= $args->{Body};

	defined $self->SUPER::init($args) or return;

	$self->{MI_wrap}      = $args->{FoldLength} || 79;
	$self->{MI_mail_from} = $args->{MailFrom};
	$self->{MI_modify}    = exists $args->{Modify} ? $args->{Modify} : 1;

	$self->processRawData($self->{raw_data}, !defined $args->{Header},
		!defined $args->{Body}) if defined $self->{raw_data};

	$self;
}

sub processRawData($$$)
{	my ($self, $data, $get_head, $get_body) = @_;
	$get_head || $get_body or return $self;

	my ($filename, $lines);
	if(ref $data eq 'ARRAY')
	{	$filename = 'array of lines';
		$lines    = $data;
	}
	elsif(ref $data eq 'GLOB' || (blessed $data && $data->isa('IO::Handle')))
	{	$filename = 'file (' . (ref $data) . ')';
		$lines    = [ $data->getlines ];
	}
	else
	{	$self->log(ERROR=> "Mail::Internet does not support this kind of data");
		return undef;
	}

	@$lines or return;

	my $buffer = join '', @$lines;
	my $file   = Mail::Box::FastScalar->new(\$buffer);
	my $parser = Mail::Box::Parser::Perl->new(filename => $filename, file => $file, trusted => 1);

	my $head;
	if($get_head)
	{	my $from = $lines->[0] =~ m/^From / ? shift @$lines : undef;

		my $head = $self->{MM_head_type}->new(
			MailFrom   => $self->{MI_mail_from},
			Modify     => $self->{MI_modify},
			FoldLength => $self->{MI_wrap}
		);
		$head->read($parser);
		$head->mail_from($from) if defined $from;
		$self->head($head);
	}
	else
	{	$head = $self->head;
	}

	$self->storeBody($self->readBody($parser, $head)) if $get_body;
	$self->addReport($parser);
	$parser->stop;
	$self;
}


sub dup()
{	my $self = shift;
	(ref $self)->coerce($self->clone);
}


sub empty() { $_[0]->DESTROY }

#--------------------

sub MailFrom(;$)
{	my $self = shift;
	@_ ? ($self->{MI_mail_from} = shift) : $self->{MU_mail_from};
}

#--------------------

sub read($@)
{	my $thing = shift;

	blessed $thing
		or return $thing->SUPER::read(@_);  # Mail::Message behavior

	# Mail::Header emulation
	my $data = shift;
	$thing->processRawData($data, 1, 1);
}


sub read_body($)
{	my ($self, $data) = @_;
	$self->processRawData($data, 0, 1);
}


sub read_header($)
{	my ($self, $data) = @_;
	$self->processRawData($data, 1, 0);
}


sub extract($)
{	my ($self, $data) = @_;
	$self->processRawData($data, 1, 1);
}


sub reply(@)
{	my ($self, %args) = @_;

	my $reply_head = $self->{MM_head_type}->new;
	my $home       = $ENV{HOME} || File::Spec->curdir;
	my $headtemp   = File::Spec->catfile($home, '.mailhdr');

	if(open my $head, '<:raw', $headtemp)
	{	my $parser = Mail::Box::Parser::Perl->new(filename => $headtemp, file => $head, trusted => 1);
		$reply_head->read($parser);
		$parser->close;
	}

	$args{quote}       ||= delete $args{Inline}   || '>';
	$args{group_reply} ||= delete $args{ReplyAll} || 0;
	my $keep             = delete $args{Keep}     || [];
	my $exclude          = delete $args{Exclude}  || [];

	my $reply = $self->SUPER::reply(%args);
	my $head  = $self->head;

	$reply_head->add($_->clone) for map $head->get($_), @$keep;
	$reply_head->reset($_)      for @$exclude;

	(ref $self)->coerce($reply);
}


sub add_signature(;$)
{	my $self = shift;
	my $fn   = shift // File::Spec->catfile($ENV{HOME} || File::Spec->curdir, '.signature');
	$self->sign(File => $fn);
}


sub sign(@)
{	my ($self, $args) = @_;
	my $sig;

	if(my $filename = delete $self->{File})
	{	$sig = Mail::Message::Body->new(file => $filename);
	}
	elsif(my $sign  = delete $self->{Signature})
	{	$sig = Mail::Message::Body->new(data => $sign);
	}

	defined $sig or return;

	my $body = $self->decoded->stripSignature;
	my $set  = $body->concatenate($body, "-- \n", $sig);
	$self->body($set) if defined $set;
	$set;
}

#--------------------

sub send($@)
{	my ($self, $type, %args) = @_;
	$self->send(via => $type);
}


#--------------------

sub head(;$)
{	my $self = shift;
	return $self->SUPER::head(@_) if @_;
	$self->SUPER::head || $self->{MM_head_type}->new(message => $self);
}


sub header(;$) { shift->head->header(@_) }


sub fold(;$) { shift->head->fold(@_) }


sub fold_length(;$$) { shift->head->fold_length(@_) }


sub combine($;$) { shift->head->combine(@_) }


sub print_header(@) { shift->head->print(@_) }


sub clean_header() { $_[0]->header }


sub tidy_headers() { }


sub add(@) { shift->head->add(@_) }


sub replace(@) { shift->head->replace(@_) }


sub get(@) { shift->head->get(@_) }


sub delete(@)
{	my $self = shift;
	@_ ? $self->head->delete(@_) : $self->SUPER::delete;
}

#--------------------

sub body(@)
{	my $self = shift;

	unless(@_)
	{	my $body = $self->body;
		return defined $body ? scalar($body->lines) : [];
	}

	my $data = ref $_[0] eq 'ARRAY' ? shift : \@_;
	my $body = Mail::Message::Body::Lines->new(data => $data);
	$self->body($body);

	$body;
}


sub print_body(@) { shift->SUPER::body->print(@_) }


sub bodyObject(;$) { shift->SUPER::body(@_) }


sub remove_sig(;$)
{	my $self  = shift;
	my $lines = shift || 10;
	my $stripped = $self->decoded->stripSignature(max_lines => $lines);
	$self->body($stripped) if defined $stripped;
	$stripped;
}


sub tidy_body(;$)
{	my $self  = shift;

	my $body  = $self->body or return;
	my @body  = $body->lines;

	shift @body while @body && $body[ 0] =~ m/^\s*$/;
	pop   @body while @body && $body[-1] =~ m/^\s*$/;

	return $body if $body->nrLines == @body;
	my $new = Mail::Message::Body::Lines->new(based_on => $body, data=>\@body);
	$self->body($new);
}


sub smtpsend(@)
{	my ($self, %args) = @_;
	my $from = $args{MailFrom} || $ENV{MAILADDRESS} || $ENV{USER} || 'unknown';
	$args{helo}       ||= delete $args{Hello};
	$args{port}       ||= delete $args{Port};
	$args{smtp_debug} ||= delete $args{Debug};

	my $host  = $args{Host};
	unless(defined $host)
	{	my $hosts = $ENV{SMTPHOSTS};
		$host = (split /\:/, $hosts)[0] if defined $hosts;
	}
	$args{host} = $host;

	$self->send(via => 'smtp', %args);
}

#--------------------

sub as_mbox_string()
{	my $self    = shift;
	my $mboxmsg = Mail::Box::Mbox->coerce($self);

	my $buffer  = '';
	my $file    = Mail::Box::FastScalar->new(\$buffer);
	$mboxmsg->print($file);
	$buffer;
}

#--------------------

BEGIN {
	no warnings;
	*Mail::Internet::new = sub (@) {
		my $class = shift;
		Mail::Message::Replace::MailInternet->new(@_);
	};
}


sub isa($)
{	my ($thing, $class) = @_;
	$class eq 'Mail::Internet' ? 1 : $thing->SUPER::isa($class);
}

#--------------------

sub coerce() { confess }

1;

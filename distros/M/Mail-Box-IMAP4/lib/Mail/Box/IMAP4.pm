# This code is part of Perl distribution Mail-Box-IMAP4 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::IMAP4;{
our $VERSION = '4.01';
}

use base 'Mail::Box::Net';

use strict;
use warnings;

use Log::Report 'mail-box-imap4', import => [ qw/__x error notice trace warning/ ];

use Mail::Box::IMAP4::Head        ();
use Mail::Box::IMAP4::Message     ();
use Mail::Box::Parser::Perl       ();
use Mail::Message::Head::Complete ();
use Mail::Message::Head::Delayed  ();
use Mail::Transport::IMAP4        ();

use Scalar::Util   qw/weaken blessed/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	my $folder = $args->{folder} // '/';

	# MailBox names top folder directory '=', but IMAP needs '/'
	$folder    = '/' if $folder eq '=';

	# There's a disconnect between the URL parser and this code.
	# The URL parser always produces a full path (beginning with /)
	# while this code expects to NOT get a full path.  So, we'll
	# trim the / from the front of the path.
	# Also, this code can't handle a trailing slash and there's
	# no reason to ever offer one.  Strip that too.
	if($folder ne '/')
	{	$folder =~ s,^/+,,g;
		$folder =~ s,/+$,,g;
	}

	$args->{folder} = $folder;

	my $access    = $args->{access} ||= 'r';
	my $writeable = $access =~ m/w|a/;
	my $ch        = $self->{MBI_c_head} = $args->{cache_head} || ($writeable ? 'NO' : 'DELAY');

	$args->{head_type}    ||= 'Mail::Box::IMAP4::Head'
		if $ch eq 'NO' || $ch eq 'PARTIAL';

	$args->{body_type}    ||= 'Mail::Message::Body::Lines';
	$args->{message_type} ||= 'Mail::Box::IMAP4::Message';

	if(my $client = $args->{imap_client}) {
		$args->{server_name} = $client->Socket->peerhost();
		$args->{server_port} = $client->Socket->peerport();
		$args->{username}    = $client->User;
	}

	$self->SUPER::init($args);

	$self->{MBI_domain}   = $args->{domain};
	$self->{MBI_c_labels} = $args->{cache_labels} || ($writeable ? 'NO' : 'DELAY');
	$self->{MBI_c_body}   = $args->{cache_body}   || ($writeable ? 'NO' : 'DELAY');

	my $transport = $args->{transporter} || 'Mail::Transport::IMAP4';
	blessed $transport or $transport = $self->createTransporter($transport, %$args);

	$self->transporter($transport);
	defined $transport or return;

	$args->{create} ? $self->create($transport, $args) : $self;
}

sub create($@)
{	my($self, $name, $args) =  @_;

	if($args->{access} !~ /w|a/)
	{	error __x"you must have write access to create folder {name}.", name => $name;
		return undef;
	}

	$self->transporter->createFolder($name);
}

sub foundIn(@)
{	my $self = shift;
	unshift @_, 'folder' if @_ % 2;
	my %args = @_;

	   (exists $args{type}   && $args{type}   =~ m/^imap/i)
	|| (exists $args{folder} && $args{folder} =~ m/^imap/);
}

sub type() {'imap4'}



sub close(@)
{	my $self = shift;
	$self->SUPER::close(@_) or return ();
	$self->transporter(undef);
	$self;
}

sub listSubFolders(@)
{	my ($thing, %args) = @_;
	my $self = $thing;

	$self = $thing->new(%args) or return ()  # list toplevel
		unless ref $thing;

	my $imap = $self->transporter;
	defined $imap ? $imap->folders($self) : ();
}

sub nameOfSubfolder($;$) { $_[1] }

#--------------------

sub readMessages(@)
{	my ($self, %args) = @_;

	my $name  = $self->name;
	return $self if $name eq '/';

	my $imap  = $self->transporter // return;
	my $seqnr = 0;

	my $cl    = $self->{MBI_c_labels} ne 'NO';
	my $wl    = $self->{MBI_c_labels} ne 'DELAY';

	my $ch    = $self->{MBI_c_head};
	my $ht    = $ch eq 'DELAY' ? $args{head_delayed_type} : $args{head_type};
	my @ho    = $ch eq 'PARTIAL' ? (cache_fields => 1) : ();

	$self->{MBI_selectable}
		or return $self;

	foreach my $id ($imap->ids)
	{	my $head    = $ht->new(@ho);
		my $message = $args{message_type}->new(
			head      => $head,
			unique    => $id,
			folder    => $self,
			seqnr     => $seqnr++,

			cache_labels => $cl,
			write_labels => $wl,
			cache_head   => ($ch eq 'DELAY'),
			cache_body   => ($ch ne 'NO'),
		);

		my $body    = $args{body_delayed_type}->new(message => $message);
		$message->storeBody($body);
		$self->storeMessage($message);
	}

	$self;
}


sub getHead($)
{	my ($self, $message) = @_;
	my $imap   = $self->transporter or return;
	my $uidl   = $message->unique;
	my @fields = $imap->getFields($uidl, 'ALL');

	unless(@fields)
	{	warning __x"message {id} disappeared from {folder}.", id => $uidl, folder => "$self";
		return;
	}

	my $head = $self->{MB_head_type}->new;
	$head->addNoRealize($_) for @fields;

	trace "Loaded head of $uidl.";
	$head;
}



sub getHeadAndBody($)
{	my ($self, $message) = @_;
	my $imap  = $self->transporter or return;
	my $uid   = $message->unique;
	my $lines = $imap->getMessageAsString($uid);

	unless(defined $lines)
	{	warning __x"message {id} disappeared from {folder}.", id => $uid, folder => $self->name;
		return ();
	}

	my $parser = Mail::Box::Parser::Perl->new(   # not parseable by C parser
		filename  => "$imap",
		file      => Mail::Box::FastScalar->new(\$lines)
	);

	my $head = $message->readHead($parser);
	unless(defined $head)
	{	warning __x"cannot find head back for {id} in {folder}.", id => $uid, folder => $self;
		$parser->stop;
		return ();
	}

	my $body = $message->readBody($parser, $head);
	unless(defined $body)
	{	warning __x"cannot read body for {id} in {folder}.", id => $uid, folder => $self->name;
		$parser->stop;
		return ();
	}

	$parser->stop;

	trace "loaded message $uid.";
	($head, $body->contentInfoFrom($head));
}



sub body(;$)
{	my $self = shift;
	@_ or return $self->{MBI_cache_body} ? $self->SUPER::body : undef;

	$self->unique();
	$self->SUPER::body(@_);
}



sub write(@)
{	my ($self, %args) = @_;
	my $imap  = $self->transporter or return;

	$self->SUPER::write(%args, transporter => $imap);

	if($args{save_deleted})
	{	notice __x"impossible to keep deleted messages in IMAP folder {name}.", name => $self->name;
	}
	else { $imap->destroyDeleted($self->name) }

	$self;
}

sub delete(@)
{	my $self   = shift;
	my $transp = $self->transporter;
	$self->SUPER::delete(@_);   # subfolders
	$transp->deleteFolder($self->name);
}



sub writeMessages($@)
{	my ($self, $args) = @_;

	my $imap = $args->{transporter};
	my $fn   = $self->name;

	$_->writeDelayed($fn, $imap) for @{$args->{messages}};

	$self;
}



my %transporters;
sub createTransporter($@)
{	my ($self, $class, %args) = @_;

	my $hostname = $self->{MBN_hostname} || 'localhost';
	my $port     = $self->{MBN_port}     || '143';
	my $username = $self->{MBN_username} || $ENV{USER};

	my $join     = exists $args{join_connection} ? $args{join_connection} : 1;

	my $linkid;
	if($join)
	{	$linkid  = "$hostname:$port:$username";
		return $transporters{$linkid} if defined $transporters{$linkid};
	}

	my $transporter = $class->new(
		%args,
		hostname => $hostname, port     => $port,
		username => $username, password => $self->{MBN_password},
		domain   => $self->{MBI_domain},
	) or return undef;

	if(defined $linkid)
	{	$transporters{$linkid} = $transporter;
		weaken($transporters{$linkid});
	}

	$transporter;
}



sub transporter(;$)
{	my $self = shift;

	my $imap;
	if(@_)
	{	$imap = $self->{MBI_transport} = shift // return;
	}
	else
	{	$imap = $self->{MBI_transport};
	}

	defined $imap
		or error __x"no IMAP4 transporter configured.";

	my $name = $self->name;

	$self->{MBI_selectable} = $imap->currentFolder($name)
		or error "couldn't select IMAP4 folder {name}.", name => $name;

	$imap;
}



sub fetch($@)
{	my ($self, $what, @info) = @_;
	my $imap = $self->transporter or return [];
	$what = $self->messages($what) unless ref $what eq 'ARRAY';
	$imap->fetch($what, @info);
}

#--------------------

1;

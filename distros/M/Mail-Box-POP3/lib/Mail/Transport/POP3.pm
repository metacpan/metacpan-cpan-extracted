# This code is part of Perl distribution Mail-Box-POP3 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::POP3;{
our $VERSION = '4.01';
}

use parent 'Mail::Transport::Receive';

use strict;
use warnings;

use Log::Report  'mail-box-pop3', import => [ qw/error fault __x/ ];

use IO::Socket       ();
use IO::Socket::IP   ();
use IO::Socket::SSL  qw/SSL_VERIFY_NONE/;
use Socket           qw/$CRLF/;
use Digest::MD5      qw/md5_hex/;
use MIME::Base64     qw/encode_base64/;

#--------------------

sub _OK($) { substr(shift // '', 0, 3) eq '+OK' }

sub init($)
{	my ($self, $args) = @_;
	$args->{via}    = 'pop3';
	$args->{port} ||= 110;

	$self->SUPER::init($args) or return;

	$self->{MTP_auth}     = $args->{authenticate} || 'AUTO';
	$self->{MTP_ssl}      = $args->{use_ssl};

	my $opts = $self->{MTP_ssl_opts} = $args->{ssl_options} || {};
	$opts->{verify_hostname} ||= 0;
	$opts->{SSL_verify_mode} ||= SSL_VERIFY_NONE;

	$self->socket or return;   # establish connection
	$self;
}

#--------------------

sub useSSL() { $_[0]->{MTP_ssl} }


sub SSLOptions() { $_[0]->{MTP_ssl_opts} }

#--------------------

sub ids(;@)
{	my $self = shift;
	$self->socket or return;
	wantarray ? @{$self->{MTP_n2uidl}} : $self->{MTP_n2uidl};
}


sub messages()
{	my $self = shift;

	wantarray
		or error __x"cannot get all messages of pop3 at once via messages().";

	$self->{MTP_messages};
}


sub folderSize() { $_[0]->{MTP_folder_size} }


sub header($;$)
{	my ($self, $uidl, $bodylines) = @_;
	$uidl or return;

	$bodylines //= 0;;
	my $socket   = $self->socket      or return;
	my $n        = $self->id2n($uidl) or return;

	$self->sendList($socket, "TOP $n $bodylines$CRLF");
}


sub message($;$)
{	my ($self, $uidl) = @_;
	$uidl or return;

	my $socket  = $self->socket      or return;
	my $n       = $self->id2n($uidl) or return;
	my $message = $self->sendList($socket, "RETR $n$CRLF") or return;

	# Some POP3 servers add a trailing empty line
	pop @$message if @$message && $message->[-1] =~ m/^[\012\015]*$/;

	$self->{MTP_fetched}{$uidl} = undef   # mark this ID as fetched
		unless exists $self->{MTP_nouidl};

	$message;
}


sub messageSize($)
{	my ($self, $uidl) = @_;
	$uidl or return;

	my $list;
	unless($list = $self->{MTP_n2length})
	{	my $socket = $self->socket or return;
		my $raw = $self->sendList($socket, "LIST$CRLF") or return;
		my @n2length;
		foreach (@$raw)
		{	m#^(\d+) (\d+)#;
			$n2length[$1] = $2;
		}
		$self->{MTP_n2length} = $list = \@n2length;
	}

	my $n = $self->id2n($uidl) or return;
	$list->[$n];
}


sub deleted($@)
{	my $dele = shift->{MTP_dele} ||= {};
	(shift) ? @$dele{ @_ } = () : delete @$dele{ @_ };
}


sub deleteFetched()
{	my $self = shift;
	$self->deleted(1, keys %{$self->{MTP_fetched}});
}


sub disconnect()
{	my $self = shift;

	my $quit;
	if($self->{MTP_socket}) # can only disconnect once
	{	if(my $socket = $self->socket)
		{	my $dele  = $self->{MTP_dele} || {};
			while(my $uidl = each %$dele)
			{	my $n = $self->id2n($uidl) or next;
				$self->send($socket, "DELE $n$CRLF") or last;
			}

			$quit = $self->send($socket, "QUIT$CRLF");
			close $socket;
		}
	}

	delete @$self{ qw(MTP_socket MTP_dele MTP_uidl2n MTP_n2uidl MTP_n2length MTP_fetched) };
	_OK $quit;
}


sub fetched(;$)
{	my $self = shift;
	return if exists $self->{MTP_nouidl};
	$self->{MTP_fetched};
}


sub id2n($$) { $_[0]->{MTP_uidl2n}{$_[1]} }

#--------------------

sub socket()
{	my $self = shift;

	# Do we (still) have a working connection which accepts commands?
	my $socket = $self->_connection;
	return $socket if defined $socket;

	exists $self->{MTP_nouidl}
		or error __x"can not re-connect reliably to server which doesn't support UIDL";

	# (Re-)establish the connection
	$socket = $self->login or return;
	$self->status($socket) or return;
	$self->{MTP_socket} = $socket;
}



sub send($$)
{	my $self = shift;
	my $socket = shift;
	my $response;

	if(eval { print $socket @_} )
	{	$response = <$socket>;
		defined $response or fault __x"cannot read POP3 from socket";
	}
	else
	{	error __x"cannot write POP3 to socket: {error}", error => $@;
	}
	$response;
}


sub sendList($$)
{	my ($self, $socket) = (shift, shift);
	my $response = $self->send($socket, @_);
	$response && _OK $response or return;

	my @list;
	while(my $line = <$socket>)
	{	last if $line =~ m#^\.\r?\n#s;
		$line =~ s#^\.##;
		push @list, $line;
	}

	\@list;
}

sub DESTROY()
{	my $self = shift;
	$self->SUPER::DESTROY;
	$self->disconnect if $self->{MTP_socket}; # only when open
}

sub _connection()
{	my $self   = shift;
	my $socket = $self->{MTP_socket} // return;

	# Check if we (still) got a connection
	eval { print $socket "NOOP$CRLF" };
	if($@ || ! <$socket> )
	{	delete $self->{MTP_socket};
		return undef;
	}

	$socket;
}



sub login(;$)
{	my $self = shift;

	# Check if we can make a connection

	my ($host, $port, $username, $password) = $self->remoteHost;
	$username && $password
		or error __x"POP3 requires a username and password.";

	my $socket;
	if($self->useSSL)
	{	my $opts = $self->SSLOptions;
		$socket  = eval { IO::Socket::SSL->new(PeerAddr => "$host:$port", %$opts) };
	}
	else
	{	$socket  = eval { IO::Socket::IP->new("$host:$port") };
	}

	$socket
		or fault __x"cannot connect to {service} for POP3", service => "$host:$port";

	# Check if it looks like a POP server

	my $connected;
	my $authenticate = $self->{MTP_auth};
	my $welcome      = <$socket>;
	_OK $welcome
		or error __x"server at {service} does not seem to be talking POP3.", service => "$host:$port";

	# Check APOP login if automatic or APOP specifically requested
	if($authenticate eq 'AUTO' || $authenticate eq 'APOP')
	{	if($welcome =~ m#^\+OK .*(<\d+\.\d+\@[^>]+>)#)
		{	my $md5      = md5_hex $1.$password;
			my $response = $self->send($socket, "APOP $username $md5$CRLF");
			$connected   = _OK $response;
		}
	}

	# Check USER/PASS login if automatic and failed or LOGIN specifically
	# requested.
	unless($connected)
	{	if($authenticate eq 'AUTO' || $authenticate eq 'LOGIN')
		{	my $response = $self->send($socket, "USER $username$CRLF") or return;

			if(_OK $response)
			{	my $response2 = $self->send($socket, "PASS $password$CRLF") or return;
				$connected = _OK $response2;
			}
		}
	}

	# Try OAUTH2 login
	if(! $connected && $authenticate =~ /^OAUTH2/)
	{	# Borrowed from Net::POP3::XOAuth2 0.0.2 by Kizashi Nagata (also Perl license)
		my $token = encode_base64 "user=$username\001auth=Bearer $password\001\001";
		$token    =~ s/[\r\n]//g;    # no base64 newlines, anywhere

		if($authenticate eq 'OAUTH2_SEP')
		{	# Microsofts way
			# https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth
			my $response = $self->send($socket, "AUTH XOAUTH2$CRLF") or return;

			if($response =~ /^\+/)   # Office365 sends + here, not +OK
			{	my $response2 = $self->send($socket, "$token$CRLF") or return;
				$connected = _OK $response2;
			}
		}
		else
		{	my $response = $self->send($socket, "AUTH XOAUTH2 $token$CRLF") or return;
			$connected = _OK $response;
		}
	}

	# If we're still not connected now, we have an error
	unless($connected)
	{	$authenticate eq 'AUTO'
		  ? (error __x"could not authenticate using any login method.")
		  : (error __x"could not authenticate using '{type}' method", type => $authenticate);
	}

	$socket;
}



sub status($;$)
{	my ($self, $socket) = @_;

	# Check if we can do a STAT

	my $stat = $self->send($socket, "STAT$CRLF") or return;
	if($stat !~ m#^\+OK (\d+) (\d+)#)
	{	delete $self->{MTP_messages};
		delete $self->{MTP_size};
		error __x"POP3 Could not do a STAT";
		return;
	}
	$self->{MTP_messages}    = my $nr_msgs = $1;
	$self->{MTP_folder_size} = $2;

	# Check if we can do a UIDL

	my $uidl = $self->send($socket, "UIDL$CRLF") or return;
	$self->{MTP_nouidl} = undef;
	delete $self->{MTP_uidl2n}; # drop the reverse lookup: UIDL -> number

	if(_OK $uidl)
	{	my @n2uidl;
		$n2uidl[$nr_msgs] = undef; # pre-alloc

		while(my $line = <$socket>)
		{	last if substr($line, 0, 1) eq '.';
			$line =~ m#^(\d+) (.+?)\r?\n# or next;
			$n2uidl[$1] = $2;
		}

		shift @n2uidl; # make message 1 into index 0
		$self->{MTP_n2uidl} = \@n2uidl;
		delete $self->{MTP_n2length};
		delete $self->{MTP_nouidl};
	}
	else
	{	# We can't do UIDL, we need to fake it
		my $list = $self->send($socket, "LIST$CRLF") or return;
		my (@n2length, @n2uidl);

		if(_OK $list)
		{	$n2length[$nr_msgs] = $n2uidl[$nr_msgs] = undef; # alloc all

			my ($host, $port)    = $self->remoteHost;
			while(my $line = <$socket>)
			{	last if substr($line, 0, 1) eq '.';
				$line =~ m#^(\d+) (\d+)# or next;
				$n2length[$1] = $2;
				$n2uidl[$1]   = "$host:$port:$1"; # fake UIDL, for id only
			}
			shift @n2length; shift @n2uidl; # make 1st message in index 0
		}
		$self->{MTP_n2length} = \@n2length;
		$self->{MTP_n2uidl}   = \@n2uidl;
	}

	my $i = 1;
	my %uidl2n = map +($_ => $i++), @{$self->{MTP_n2uidl}};
	$self->{MTP_uidl2n} = \%uidl2n;

	1;
}

#--------------------

sub url(;$)
{	my $self = shift;
	my ($host, $port, $user, $pwd) = $self->remoteHost;
	my $proto = $self->useSSL ? 'pop3s' : 'pop3';
	"$proto://$user:$pwd\@$host:$port";
}

#--------------------

1;

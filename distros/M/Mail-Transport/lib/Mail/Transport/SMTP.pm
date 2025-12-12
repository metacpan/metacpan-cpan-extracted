# This code is part of Perl distribution Mail-Transport version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Transport::SMTP;{
our $VERSION = '4.00';
}

use parent 'Mail::Transport::Send';

use strict;
use warnings;

use Log::Report   'mail-transport', import => [ qw/__x error notice warning/ ];

use Net::SMTP     ();

use constant CMD_OK      => 2;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{via}  ||= 'smtp';
	$args->{port} ||= '25';

	my $hosts   = $args->{hostname};
	unless($hosts)
	{	require Net::Config;
		$hosts  = $Net::Config::NetConfig{smtp_hosts};
		undef $hosts unless @$hosts;
		$args->{hostname} = $hosts;
	}

	$self->SUPER::init($args) or return;

	my $helo = $args->{helo}
		|| eval { require Net::Config; $Net::Config::NetConfig{inet_domain} }
		|| eval { require Net::Domain; Net::Domain::hostfqdn() };

	$self->{MTS_net_smtp_opts} = +{ Hello => $helo, Debug => ($args->{smtp_debug} || 0) };
	$self->{MTS_esmtp_options} = $args->{esmtp_options};
	$self->{MTS_from}          = $args->{from};
	$self;
}


sub trySend($@)
{	my ($self, $message, %args) = @_;
	my %send_options = ( %{$self->{MTS_esmtp_options} || {}}, %{$args{esmtp_options} || {}} );

	# From whom is this message.
	my $from = $args{from} || $self->{MTS_from} || $message->sender || '<>';
	$from = $from->address if ref $from && $from->isa('Mail::Address');

	# Which are the destinations.
	! defined $args{To}
		or warning __x"use option `to' to overrule the destination: `To' refers to a field.";

	my @to = map $_->address, $self->destinations($message, $args{to});
	@to or notice(__x"no addresses found to send the message to, no connection made."), return 1;

	#### Prepare the message.

	my $out = '';
	open my $fh, '>:raw', \$out;
	$self->putContent($message, $fh, undisclosed => 0);
	$out =~ m![\r\n]\z! or $out .= "\r\n";
	close $fh;

	#### Send

	my $server;
	if(wantarray)
	{	# In LIST context
		$server = $self->contactAnyServer
			or return (0, 500, "Connection Failed", "CONNECT", 0);

		$server->mail($from, %send_options)
			or return (0, $server->code, $server->message, 'FROM', $server->quit);

		foreach (@to)
		{	 next if $server->to($_);
			#???  must we be able to disable this?  f.i:
			#???     next if $args{ignore_erroneous_destinations}
			return (0, $server->code, $server->message, "To $_", $server->quit);
		}

		my $bodydata = $message->body->file;

		$server->datafast(\$out)  #!! destroys $out
			or return (0, $server->code, $server->message, 'DATA', $server->quit);

		my $accept = ($server->message)[-1];
		chomp $accept;

		my $rc     = $server->quit;
		return ($rc, $server->code, $server->message, 'QUIT', $rc, $accept);
	}

	# in SCALAR context
	$server = $self->contactAnyServer
		or return 0;

	$server->mail($from, %send_options)
		or ($server->quit, return 0);

	foreach (@to)
	{	next if $server->to($_);
		$server->quit;
		return 0;
	}

	$server->datafast(\$out)  #!! destroys $out
		or ($server->quit, return 0);

	$server->quit;
}

# Improvement on Net::CMD::datasend(), mainly bulk adding dots and avoiding copying
# About 79% performance gain on huge messages.
# Be warned: this method destructs the content of $data!
sub Net::SMTP::datafast($)
{	my ($self, $data) = @_;
	$self->_DATA or return 0;

	$$data =~ tr/\r\n/\015\012/ if "\r" ne "\015";  # mac
	$$data =~ s/(?<!\015)\012/\015\012/g;  # \n -> crlf as sep.  Needed?
	$$data =~ s/^\./../;                   # data starts with a dot, escape it
	$$data =~ s/\012\./\012../g;           # other lines which start with a dot

	$self->_syswrite_with_timeout($$data . ".\015\012");
	$self->response == CMD_OK;
}

#--------------------

sub contactAnyServer()
{	my $self = shift;

	my ($enterval, $count, $timeout) = $self->retry;
	my ($host, $port, $username, $password) = $self->remoteHost;
	my @hosts = ref $host ? @$host : $host;
	my $opts  = $self->{MTS_net_smtp_opts};

	foreach my $host (@hosts)
	{	my $server = $self->tryConnectTo($host, Port => $port, %$opts, Timeout => $timeout)
			or next;

		$self->log(PROGRESS => "Opened SMTP connection to $host.");

		if(defined $username)
		{	unless($server->auth($username, $password))
			{	$self->log(ERROR => "Authentication failed.");
				return undef;
			}
			$self->log(PROGRESS => "$host: Authentication succeeded.");
		}

		return $server;
	}

	undef;
}


sub tryConnectTo($@)
{	my ($self, $host) = (shift, shift);
	Net::SMTP->new($host, @_);
}

1;

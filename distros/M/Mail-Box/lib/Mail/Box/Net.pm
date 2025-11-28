# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Net;{
our $VERSION = '3.012';
}

use parent 'Mail::Box';

use strict;
use warnings;

use Mail::Box::Net::Message        ();
use Mail::Message::Body::Lines     ();
use Mail::Message::Body::File      ();
use Mail::Message::Body::Delayed   ();
use Mail::Message::Body::Multipart ();
use Mail::Message::Head            ();
use Mail::Message::Head::Delayed   ();

use Carp;

#--------------------

sub init($)
{	my ($self, $args)     = @_;

	$args->{lock_type}  ||= 'NONE';
	$args->{body_type}  ||= 'Mail::Message::Body::Lines';
	$args->{trusted}    ||= 0;

	my ($scheme, $s, $port, $u, $pwd, $f);
	if(my $d = $args->{folderdir})
	{	# cannot use URI, because some scheme's are fake
		($scheme, $u, $pwd, $s, $port, $f) = $d =~ m!
			^ (\w+) \://                # scheme
			  (?: ( [^:\@/]+ )          # username
			      (?:  \: ( [^\@/]+ ))? # password
			   \@ )?
			  ( [a-zA-Z0-9.-]+ )?       # hostname
			  (?: \: ([0-9]+)  )?       # port
			  ( / .* )?                 # path
		!x;

		defined && s/%([0-9a-fA-F]{2})/hex $1/ge
			for $u, $pwd, $s, $port, $f;

		$args->{folderdir} =~ s!/$!!;
	}

	$args->{folder}     ||= $f || '/';

	$self->SUPER::init($args);

	$self->{MBN_hostname} = $args->{server_name}  || $s;
	$self->{MBN_port}     = $args->{server_port}  || $port;
	$self->{MBN_username} = $args->{username}     || $u;
	$self->{MBN_password} = $args->{password}     || $pwd;

	! exists $args->{hostname}
		or $self->log(WARNING => "The term 'hostname' is confusing wrt folder. You probably need 'server_name'");

	$self;
}


sub create(@) { $_[0]->notImplemented }
sub organization() { 'REMOTE' }

sub url()
{	my $self = shift;
	my ($user, $pass, $host, $port) = @$self{ qw/MBN_username MBN_password MBN_hostname MBN_port/ };

	my $perm = '';
	$perm    = $user if defined $user;
	if(defined $pass)
	{	$pass  =~ s/(\W)/sprintf "%%%02X", ord $1/ge;
		$perm .= ':'.$pass;
	}

	$perm   .= '@'       if length $perm;

	my $loc  = $host;
	$loc    .= ':'.$port if length $port;

	my $name = $self->name;
	$loc    .= '/'.$name if $name ne '/';

	$self->type . '://' . $perm . $loc;
}

1;

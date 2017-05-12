#!/bin/echo This is a perl module and should not be run

package Meta::Comm::Socket::Client;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::System qw();
use IO::Socket::INET qw();

our($VERSION,@ISA);
$VERSION="0.10";
@ISA=qw();

#sub new($);
#sub send($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	$self->{CLIENT}=IO::Socket::INET->new(
		PeerAddr=>"localhost",
		PeerPort=>9000,
		Proto=>"tcp",
		Reuse=>1,
		Type=>IO::Socket::SOCK_STREAM
	);
	if(!$self->{CLIENT}) {
		throw Meta::Error::Simple("unable to init client [".$!."]");
	}
	$self->{CLIENT}->autoflush(1);
#	my($kidpid)=CORE::fork();
#	if(!defined($kidpid)) {
#		throw Meta::Error::Simple("unable to fork");
#	}
#	if(!$kidpid) {
#		Meta::Utils::Output::print("in client in fork\n");
#		my($line);
#		while($line=<$self> || 0) {
#			Meta::Utils::Output::print("got line [".$line."]\n");
#		}
#		CORE::kill("TERM"=>$kidpid);
#		Meta::Utils::System::Sexo(1);
#	}
#	Meta::Utils::Output::print("in client out fork\n");
	bless($self,$class);
	return($self);
}

sub send($$) {
	my($self,$mess)=@_;
	my($client)=$self->{CLIENT};
#	print $client $mess;
	if(!$self->send($mess)) {
		throw Meta::Error::Simple("unable to send");
	}
	Meta::Utils::Output::print("message sent");
	my($retu)=<$client>;
	return($retu);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Comm::Socket::Client - TCP/IP client.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Client.pm
	PROJECT: meta
	VERSION: 0.10

=head1 SYNOPSIS

	package foo;
	use Meta::Comm::Socket::Client qw();
	my($object)=Meta::Comm::Socket::Client->new();
	my($result)=$object->send("hello");

=head1 DESCRIPTION

This class eases your job of creating TCP/IP clients.
Override methods in this to create what you want.

=head1 FUNCTIONS

	new($)
	send($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Comm::Socket::Client object.

=item B<send($$)>

This method will send data to the server and will return the servers
answer.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging again
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV movies and small fixes
	0.05 MV thumbnail user interface
	0.06 MV more thumbnail issues
	0.07 MV website construction
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV md5 issues

=head1 SEE ALSO

IO::Socket::INET(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Comm::Frontier::Server;

use strict qw(vars refs subs);
use Frontier::Daemon qw();
use Meta::Lang::Perl::Interface qw();
use Meta::Utils::Output qw();
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw(Frontier::Daemon);

#sub new($);
#sub set_obje($$);
#sub run($);
#sub quit($);
#sub test($);
#sub print($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Frontier::Daemon->new(
		LocalPort=>1080,
		methods=>{
			'quit'=>\&quit,
			'test'=>\&test,
			'print'=>\&print,
		},
	);
	if(!$self) {
		throw Meta::Error::Simple("cannot create server");
	}
	#bless($self,$class);
	return($self);
}

sub set_obje($$) {
	my($self,$obje)=@_;
	$self->{OBJE}=$obje;
}

sub run($) {
	my($self)=@_;
	my($hash)=Meta::Lang::Perl::Interface::get_method_hash($self->{OBJE});
	my($methods)={};
	while(my($key,$val)=each(%$hash)) {
		Meta::Utils::Output::print("in here with key [".$key."] val [".$val."]\n");
		$methods->{$key}=\&quit;
#		sub
#		{
#			my(@args)=@_;
#			my($object)=Meta::Comm::Frontier::Server::get_object();
#			$object->$key(@args);
#		};
	}
	$methods->{"quit"}=\&quit;
	my($xmlrpc_protocol)="http";
	my($xmlrpc_host)="localhost";
	my($xmlrpc_port)=1080;
	my($xmlrpc_subdir)="RPC2";
	my($server)=Frontier::Daemon->new(
		methods=>$methods,
#		LocalAddr=>$xmlrpc_host,
		LocalPort=>$xmlrpc_port,
	);
}

sub quit($) {
	my($self)=@_;
	CORE::exit(1);
	return(1);
}

sub test($) {
	return(1972);
}

sub print($) {
	Meta::Utils::Output::print("in print\n");
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Comm::Frontier::Server - a Frontier::Daemon server extension.

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

	MANIFEST: Server.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Comm::Frontier::Server qw();
	my($object)=Meta::Comm::Frontier::Server->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is an extension of the Frontier::Daemon class that does
a server communication class.

=head1 FUNCTIONS

	new($)
	set_obje($$)
	run($)
	quit($)
	test($)
	print($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Comm::Frontier::Server object.

=item B<set_obje($$)>

This method will set the object specified.

=item B<run($)>

This method will run the server.

=item B<quit($)>

This method quits the server.

=item B<test($)>

This method tests the server.

=item B<print($)>

This method prints a small message on the server.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Frontier::Daemon(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging again
	0.01 MV stuff
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV move tests into modules
	0.12 MV md5 issues

=head1 SEE ALSO

Frontier::Daemon(3), Meta::Lang::Perl::Interface(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-make the actuall dispatching of methods according to object but make it in a derived class.

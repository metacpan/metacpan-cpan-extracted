#!/bin/echo This is a perl module and should not be run

package Meta::Comm::Xmlrpc::Client;

use strict qw(vars refs subs);
use XMLRPC::Lite qw();

our($VERSION,@ISA);
$VERSION="0.10";
@ISA=qw(XMLRPC::Lite);

#sub new($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=XMLRPC::Lite->new();
	$self->proxy('http://localhost/RPC2:10001');
	bless($self,$class);
	return($self);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Comm::Xmlrpc::Client - XML/RPC client.

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
	use Meta::Comm::Xmlrpc::Client qw();
	my($object)=Meta::Comm::Xmlrpc::Client->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class handles client XML/RPC communication.

=head1 FUNCTIONS

	new($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Comm::Xmlrpc::Client object.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

XMLRPC::Lite(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV stuff
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

XMLRPC::Lite(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Listen;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub new($);
#sub listen($);
#sub cb($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	$self->port(9000);
	$self->callback(\&cb);
	$self->mode("forking");
	$self->hostname("localhost");
	bless($self,$class);
	return($self);
}

sub listen($) {
	my($self)=@_;
	Meta::Utils::Output::print("in here\n");
	$self->run();
}

sub cb($) {
	my($self)=@_;
	$self->quit();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Listen - Pdmt module which listen to commands.

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

	MANIFEST: Listen.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Listen qw();
	my($object)=Meta::Pdmt::Listen->new();

=head1 DESCRIPTION

This object listens for TCP/IP communications and activates the Pdmt object
on any request.

=head1 FUNCTIONS

	new($)
	listen($)
	cb($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Pdmt::Listen object.

=item B<listen($)>

This method activates the listener.

=item B<cb($)>

This method is the one which responds to requests.
Currently is just quits.
these lines were removed from the code:
my($temp)=*STDIN;
Meta::Utils::Output::print("got [".$temp."]\n");

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

	0.00 MV misc fixes
	0.01 MV perl packaging
	0.02 MV more movies
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

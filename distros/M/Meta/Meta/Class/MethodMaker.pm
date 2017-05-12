#!/bin/echo This is a perl module and should not be run

package Meta::Class::MethodMaker;

use strict qw(vars refs subs);
use Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.07";
@ISA=qw(Class::MethodMaker);

#sub print($$);
#sub TEST($);

#__DATA__

sub print($$) {
	my($class,$arra)=@_;
	my($code)='sub { my($self,$file)=@_;';
	for(my($i)=0;$i<=$#$arra;$i++) {
		my($curr)=$arra->[$i];
		$code.='print $file "'.$curr.' is [".$self->get_'.$curr.'()."]\n";';
	}
	$code.="}";
#	Meta::Utils::Output::print("code is [".$code."]\n");
	my(%methods);
	$methods{"print"}=eval($code);
#		sub {
#			my($self,$file)=@_;
#			print $file $self->get_$arra[0]()."\n";
#		};
	$class->install_methods(%methods);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Class::MethodMaker - add capabilities to Class::MethodMaker.

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

	MANIFEST: MethodMaker.pm
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	package foo;
	use Meta::Class::MethodMaker qw();
	my($object)=Meta::Class::MethodMaker->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends Class::MethodMaker (see that classes documentation)
and adds some capabilities to it.

=head1 FUNCTIONS

	print($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<print($$)>

This method will auto-generate a print method.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Class::MethodMaker(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV import tests
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV web site development
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV finish papers
	0.07 MV md5 issues

=head1 SEE ALSO

Class::MethodMaker(3), strict(3)

=head1 TODO

-make an option to make a class out of a DTD definition.

-make a new get_set method (to override the parent) where I don't need to pass -java and the underscore.

-add method which dumps the object in XML.

-add method which reads the object from XML.

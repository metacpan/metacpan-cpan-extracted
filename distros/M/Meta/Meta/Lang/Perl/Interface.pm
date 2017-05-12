#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Interface;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub get_data_hash($);
#sub get_method_hash($);
#sub TEST($);

#__DATA__

sub get_data_hash($) {
	my($obje)=@_;
#	Meta::Utils::Output::print("object is [".$obje."]\n");
	my($hash)={};
	while(my($key,$val)=each(%$obje)) {
#		Meta::Utils::Output::print("key is [".$key."]\n");
		$hash->{$key}=defined;
	}
	return($hash);
}

sub get_method_hash($) {
	my($obje)=@_;
#	Meta::Utils::Output::print("object is [".$obje."]\n");
#	Meta::Utils::Output::print("object is [".ref($obje)."]\n");
	my($type)=ref($obje);
	my($glob_hash)=$type."::";
	no strict qw(refs);
	my($ret)=\%$glob_hash;
	use strict qw(vars refs subs);
	return($ret);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Interface - module to help with dynamically working with perl interfaces.

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

	MANIFEST: Interface.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Interface qw();
	my($hash)=Meta::Lang::Perl::Interface::get_hash($my_object);

=head1 DESCRIPTION

This module will help you dynamically discover what is an objects
interface.

=head1 FUNCTIONS

	get_data_hash($)
	get_method_hash($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_data_hash($)>

This method receives a perl object, analyzes it and
returns a hash with its data memebers in it.

=item B<get_method_hash($)>

This method receives a perl object, analyzes it and
returns a hash with its method interface in it.
On problem here is that I'm turning a string to a hash
reference (as needed as far as I can tell) to get
to the hash with all the methods in it. This is forbidden
by use strict and so I have to relax stuff and put restrictions
back in after I do the ugly deed.

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

	0.00 MV object self introspection
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

Nothing.

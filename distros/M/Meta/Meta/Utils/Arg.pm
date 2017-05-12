#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Arg;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub check_arg_num($$);
#sub check_arg($$);
#sub TEST($);

#__DATA__

sub check_arg_num($$) {
	my($arra,$numx)=@_;
	my($size)=$#$arra+1;
	if($size!=$numx) {
		throw Meta::Error::Simple("number of arguments is wrong [".$size."] and not [".$numx."]");
	}
}

sub check_arg($$) {
	my($varx,$type)=@_;
	if(!defined($varx)) {
		throw Meta::Error::Simple("undefined variable");
	}
	if(defined($type)) {
		if($type eq "ANY") {
			return(1);
		}
		if($type eq "SCALAR") {
			my($ref)=CORE::ref($varx);
			if($ref eq "") {
				return(1);
			} else {
				throw Meta::Error::Simple("what kind of SCALAR is [".$ref."]");
			}
		}
		if($type eq "SCALARref") {
			my($ref)=CORE::ref($varx);
			if($ref eq "SCALAR") {
				return(1);
			} else {
				throw Meta::Error::Simple("what kind of SCALARref is [".$ref."]");
			}
		}
		if($type eq "ARRAYref") {
			my($ref)=CORE::ref($varx);
			if($ref eq "ARRAY") {
				return(1);
			} else {
				throw Meta::Error::Simple("what kind of ARRAYref is [".$ref."]");
			}
		}
		if($type eq "HASHref") {
			my($ref)=CORE::ref($varx);
			if($ref eq "HASH") {
				return(1);
			} else {
				throw Meta::Error::Simple("what kind of HASHref is [".$ref."]");
			}
		}
		if(UNIVERSAL::isa($varx,$type)) {
			return(1);
		} else {
			throw Meta::Error::Simple("variable [".$varx."] is not of type [".$type."]");
		}
	} else {
		throw Meta::Error::Simple("why is type undef ?");
		return(0);
	}
#	my($resu)=ref($varx);
#	if(defined($resu)) {
#		if($resu ne $type) {
#			throw Meta::Error::Simple("variable is not of type [".$varx."] but of type [".$resu."]");
#		}
#	} else {
#		throw Meta::Error::Simple("ref didn't return defined value");
#	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Arg - module to help you checking argument types to methods/functions.

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

	MANIFEST: Arg.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Arg qw();
	Meta::Utils::Arg::check_arg_num(\@_,3);

=head1 DESCRIPTION

This is a general utility module for either miscelleneous commands which are hard to calssify or for routines which are just starting to form a module and have not yet been given a module and moved there.

=head1 FUNCTIONS

	check_arg_num($$)
	check_arg($$)
	TEST($);

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<check_arg_num($$)>

This method will check that the number of arguments is the correct one.

=item B<check_arg($$)>

This checks that the type of argument given to it has the type give to it
using the ref routine (very useful for when receiving lists,hashes etc..).

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

	0.00 MV PDMT/SWIG support
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

Error(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Swig;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Baseline::Utils qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($);
#sub c2chec($);
#sub c2pmxx($);
#sub c2ccpm($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2chec($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2pmxx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2ccpm($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^swig\/.*\.i$/) {#actual dtd files
		return(1);
	}
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Swig - handle SWIG in the project.

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

	MANIFEST: Swig.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Swig qw();
	my($resu)=Meta::Baseline::Lang::Swig::env();

=head1 DESCRIPTION

This package contains stuff specific to Swig in the baseline.
It will authorize SWIG files in the baseline.
It will convert SWIG files to interfaces of many languages.

=head1 FUNCTIONS

	c2deps($)
	c2chec($)
	c2pmxx($)
	c2ccpm($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This will convert dtd files to dependencies.

=item B<c2chec($)>

This will check the SWIG interface file for errors.
Currently this does nothing.

=item B<c2pmxx($)>

This will assume that you want to create a perl module interface
from the swig file and will convert the SWIG interface to a perl
module which will be the perl side interface to the C/C++ library.

=item B<c2ccpm($)>

This will assume that you want to create a perl module interface
from the swig file and will convert the SWIG interface to a C
source file which sould be compiled to produce an .so library that
will be in your PERL5LIB which will enable you to interface the
module.

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Baseline::Lang(3)

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
	0.02 MV BuildInfo object change
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

Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), strict(3)

=head1 TODO

Nothing.

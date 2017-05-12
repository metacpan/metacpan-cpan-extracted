#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Dslx;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Baseline::Utils qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($$$$);
#sub c2chec($$$$);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($$$$) {
	my($modu,$srcx,$targ,$path)=@_;
	Meta::Baseline::Utils::file_emblem($targ);
	return(1);
}

sub c2chec($$$$) {
	my($modu,$srcx,$targ,$path)=@_;
	Meta::Baseline::Utils::file_emblem($targ);
	return(1);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^dslx\/.*\.dsl$/) {
		return(1);
	}
	if($file eq "dslx/CATALOG") {
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

Meta::Baseline::Lang::Dslx - handle Dsls in the project.

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

	MANIFEST: Dslx.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Dslx qw();
	my($resu)=Meta::Baseline::Lang::Dslx::env();

=head1 DESCRIPTION

This package contains stuff specific to Dslx in the baseline:
It's mainly here to authorize entries of DSL files to the baseline.
It also authorises the DSL catalogs entry.
Maybe someday I'll do syntax checks on those also...:)

=head1 FUNCTIONS

	c2deps($$$$)
	c2chec($$$$)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($$$$)>

This will convert Conn files to dependencies.

=item B<c2chec($$$$)>

This will check a Conn file.

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

	0.00 MV bring back sgml to working condition
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

Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), strict(3)

=head1 TODO

Nothing.

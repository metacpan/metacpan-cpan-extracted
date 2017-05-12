#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Dvix;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Tool::Dvi qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw(Meta::Baseline::Lang);

#sub c2chec($);
#sub c2psxx($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2chec($) {
	my($buil)=@_;
	my($resu)=Meta::Tool::Dvi::chec($buil);
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub c2psxx($) {
	my($buil)=@_;
	return(Meta::Tool::Dvi::c2psxx($buil));
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^dvix\/.*\.dvi$/) {
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

Meta::Baseline::Lang::Dvix - language for DVI files.

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

	MANIFEST: Dvix.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Dvix qw();
	my($resu)=Meta::Baseline::Lang::Dvix::env();

=head1 DESCRIPTION

This package contains stuff specific to Dvix in the baseline:
Its mainly here to authorize entries of dvi files to the baseline.
Maybe someday I'll do syntax checks on those also...:)

=head1 FUNCTIONS

	c2chec($)
	c2psxx($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2chec($)>

This routine verifies dvi sources using the dvitype utility.

=item B<c2psxx($)>

This routine will convert DVI files to Postscript.

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

	0.00 MV revision for perl files and better sanity checks
	0.01 MV languages.pl test online
	0.02 MV spelling and papers
	0.03 MV add zipping subsystem
	0.04 MV perl packaging
	0.05 MV BuildInfo object change
	0.06 MV md5 project
	0.07 MV database
	0.08 MV perl module versions in files
	0.09 MV movies and small fixes
	0.10 MV thumbnail user interface
	0.11 MV more thumbnail issues
	0.12 MV website construction
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Lang(3), Meta::Tool::Dvi(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Ps2Pdf;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();
use Meta::Utils::System qw();
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub BEGIN();
#sub c2pdfx($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("ps2pdf");
}

sub c2pdfx($) {
	my($buil)=@_;
	my(@args);
	push(@args,"-dCompatibility=1.3");# 1.3 pdf compatibility
	push(@args,$buil->get_srcx());
	push(@args,$buil->get_targ());
	return(Meta::Utils::System::system_err_silent_nodie($tool_path,\@args));
	#Meta::Baseline::Utils::file_emblem($buil->get_targ());
	#return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Ps2Pdf - convert post script to pdf.

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

	MANIFEST: Ps2Pdf.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Ps2Pdf qw();
	my($res)=Meta::Tool::Ps2Pdf::c2pdfx($build_info);

=head1 DESCRIPTION

This module is here to run ps2pdf tool for you.

=head1 FUNCTIONS

	BEGIN()
	c2pdfx($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find the path to ps2pdf.

=item B<c2pdfx($)>

This method receives a build info object.
This method will actually run the ps2pdf tool.

=item B<TEST($)>

This is a testing suite for the Meta::Tool::Ps2Pdf module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

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

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Utils(3), Meta::Utils::File::Patho(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

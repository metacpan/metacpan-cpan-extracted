#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Html;

use strict qw(vars refs subs);
use Meta::Baseline::Lang qw();
use Meta::Tool::Onsgmls qw();
use Meta::Lang::Html::Html qw();
use Meta::Tool::Aspell qw();

our($VERSION,@ISA);
$VERSION="0.25";
@ISA=qw(Meta::Baseline::Lang);

#sub c2deps($);
#sub c2chec($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($deps)=Meta::Lang::Html::Html::c2deps($buil);
	if(defined($deps)) {
		Meta::Baseline::Cook::print_deps($deps,$buil->get_targ());
		return(1);
	} else {
		return(0);
	}
}

sub c2chec($) {
	my($buil)=@_;
	my($resu)=1;
	if(!Meta::Tool::Onsgmls::dochec($buil)) {
		$resu=0;
	}
	if(!Meta::Tool::Aspell::checkhtml($buil)) {
		$resu=0;
	}
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^html\/.*\.html$/) {
		return(1);
	}
	if($file eq "html/java/lib/stylesheet.css") {
		return(1);
	}
	if($file eq "html/java/lib/package-list") {
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

Meta::Baseline::Lang::Html - doing data specific stuff in the baseline.

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

	MANIFEST: Html.pm
	PROJECT: meta
	VERSION: 0.25

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Html qw();
	my($obje)=Meta::Baseline::Lang::Html->new();
	my($result)=$obje->myfile("data/myfile.txt");

=head1 DESCRIPTION

This package is the data package of the baseline.
It currently does nothing and authorises all files to be placed in data.

=head1 FUNCTIONS

	c2deps($)
	c2chec($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This method creates HTML dependencies by looking at the HTML text and seeing
which other baseline documents it refers too.

=item B<c2chec($)>

This method will check an HTML file for various stuff.

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

	0.00 MV get basic Simul up and running
	0.01 MV perl documentation
	0.02 MV more perl quality
	0.03 MV perl qulity code
	0.04 MV more perl code quality
	0.05 MV revision change
	0.06 MV revision for perl files and better sanity checks
	0.07 MV languages.pl test online
	0.08 MV history change
	0.09 MV db stuff
	0.10 MV html site update
	0.11 MV fix docbook and other various stuff
	0.12 MV fix up cook files
	0.13 MV perl packaging
	0.14 MV BuildInfo object change
	0.15 MV md5 project
	0.16 MV database
	0.17 MV perl module versions in files
	0.18 MV movies and small fixes
	0.19 MV more Class method generation
	0.20 MV thumbnail user interface
	0.21 MV more thumbnail issues
	0.22 MV website construction
	0.23 MV web site automation
	0.24 MV SEE ALSO section fix
	0.25 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Lang(3), Meta::Lang::Html::Html(3), Meta::Tool::Aspell(3), Meta::Tool::Onsgmls(3), strict(3)

=head1 TODO

Nothing.

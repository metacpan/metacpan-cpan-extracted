#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Cxxx;

use strict qw(vars refs subs);
use Meta::Utils::File::Path qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Lang qw();

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw(Meta::Baseline::Lang);

#sub env();
#sub my_file($$);
#sub TEST($);

#__DATA__

sub env() {
	my(%hash);
	my($class)="";
	my($sear)=Meta::Baseline::Aegis::search_path_list();
	for(my($i)=0;$i<=$#$sear;$i++) {
		my($curr)=$sear->[$i];
		$class=Meta::Utils::File::Path::add_path($class,
			$curr."/java/lib",":");
		$class=Meta::Utils::File::Path::add_path($class,
			$curr."/java/import/lib",":");
	}
	$hash{"CLASSPATH"}=$class;
	return(\%hash);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^cxxx\/.*\.c$/) {
		return(1);
	}
	if($file=~/^cxxx\/.*\.h$/) {
		return(1);
	}
	if($file=~/^cxxx\/.*\.i$/) {
		return(1);
	}
	if($file=~/^cxxx\/.*\.t$/) {
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

Meta::Baseline::Lang::Cxxx - doing Cxxx specific stuff in the baseline.

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

	MANIFEST: Cxxx.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Cxxx qw();
	my($resu)=Meta::Baseline::Lang::Cxxx::env();

=head1 DESCRIPTION

This package contains stuff specific to Cxxx in the baseline:
0. produce code to set Cxxx specific vars in the baseline.
1. check Cxxx files for correct Cxxx syntax in the baseline.
	0. produce minimal java usage.
	1. check no numbers are in the code.
	2. check correct includes for c sources.
	etc...


=head1 FUNCTIONS

	env()
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<env()>

This routie returns a hash of environment variables which are essential for
running Cxxx binaries.

=item B<my_file($$)>

This method will return true if the file receives should be handelded by this
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

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV perl quality change
	0.07 MV perl code quality
	0.08 MV more perl quality
	0.09 MV more perl quality
	0.10 MV perl documentation
	0.11 MV more perl quality
	0.12 MV perl qulity code
	0.13 MV more perl code quality
	0.14 MV revision change
	0.15 MV revision for perl files and better sanity checks
	0.16 MV languages.pl test online
	0.17 MV web site and docbook style sheets
	0.18 MV perl packaging
	0.19 MV md5 project
	0.20 MV database
	0.21 MV perl module versions in files
	0.22 MV movies and small fixes
	0.23 MV thumbnail user interface
	0.24 MV more thumbnail issues
	0.25 MV website construction
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Lang(3), Meta::Utils::File::Path(3), strict(3)

=head1 TODO

Nothing.

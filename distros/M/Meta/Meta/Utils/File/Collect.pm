#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Collect;

use strict qw(vars refs subs);
use Meta::Utils::Utils qw();
use Meta::Utils::Hash qw();
use File::Find qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.27";
@ISA=qw();

#sub doit();
#sub hash($$);
#sub list($$);
#sub TEST($);

#__DATA__

my($hash);

sub doit() {
	my($name)=$File::Find::name;
	my($dirx)=$File::Find::dir;
#	Meta::Utils::Output::print("in here with name [".$name."]\n");
#	Meta::Utils::Output::print("in here with dirx [".$dirx."]\n");
	if(-f $name) {
		$hash->{$name}=defined;
	}
}

sub hash($$) {
	my($dire,$abso)=@_;
	$hash={};
	File::Find::find({wanted=>\&doit,no_chdir=>1},$dire);
	if(!$abso) {
		my($other)={};
		$dire.="/";
		while(my($key,$val)=each(%$hash)) {
			my($curr)=Meta::Utils::Utils::minus($key,$dire);
			$other->{$curr}=defined;
		}
		$hash=$other;
	}
	return($hash);
}

sub list($$) {
	my($dire,$abso)=@_;
	my($hash)=hash($dire,$abso);
	my($list)=Meta::Utils::Hash::to_list($hash);
	return($list);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Collect - utility for generate a list of all the files under a certain dir.

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

	MANIFEST: Collect.pm
	PROJECT: meta
	VERSION: 0.27

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Collect qw();
	my($hash)=Meta::Utils::File::Collect::hash($directory,0);
	my($list)=Meta::Utils::File::Collect::list($directory,0);

=head1 DESCRIPTION

This is a library providing functions to generate a list or a hash of
all the files under a certain dir.

=head1 FUNCTIONS

	doit()
	hash($$)
	list($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<$hash>

This variable stores all the files found so far.

=item B<doit()>

This function actually does the purging by checking if the handle at
hand is a regular file and if os adding it to a hash.

=item B<hash($$)>

This function receives a directory and scans it using File::Find and
fills up a hash with all the files found there.
The function also receives whether the file names requested should be
with full path or not.

=item B<list($$)>

This does the same as hash but returns a list as a result.

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

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV check that all uses have qw
	0.04 MV fix todo items look in pod documentation
	0.05 MV more on tests/more checks to perl
	0.06 MV perl code quality
	0.07 MV more perl quality
	0.08 MV more perl quality
	0.09 MV perl documentation
	0.10 MV more perl quality
	0.11 MV perl qulity code
	0.12 MV more perl code quality
	0.13 MV revision change
	0.14 MV revision in files
	0.15 MV languages.pl test online
	0.16 MV perl packaging
	0.17 MV PDMT
	0.18 MV md5 project
	0.19 MV database
	0.20 MV perl module versions in files
	0.21 MV movies and small fixes
	0.22 MV thumbnail user interface
	0.23 MV more thumbnail issues
	0.24 MV website construction
	0.25 MV web site automation
	0.26 MV SEE ALSO section fix
	0.27 MV md5 issues

=head1 SEE ALSO

File::Find(3), Meta::Utils::Hash(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-clean up the code (absolute path wise...).

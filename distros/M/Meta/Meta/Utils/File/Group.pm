#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Group;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub group2gid($);
#sub gid2gourp($);
#sub get_gid($);
#sub get_group($);
#sub check_gid($$);
#sub check_group($$);
#sub check_hash_gid($$);
#sub check_hash_group($$);
#sub TEST($);

#__DATA__

sub group2gid($) {
	my($group)=@_;
	my($gid)=(CORE::getgrnam($group))[2];
	return($gid);
}

sub gid2group($) {
	my($gid)=@_;
	#need to do this
}

sub get_gid($) {
	my($file)=@_;
	my(@list)=stat($file);
	if($list[0]) {
		my($gid)=$list[5];
		return($gid);
	} else {
		throw Meta::Error::Simple("unable to stat file [".$file."]");
		return(0);
	}
}

sub get_group($) {
	my($file)=@_;
	#need to do this
}

sub check_gid($$) {
	my($file,$gid)=@_;
	my($curr)=get_gid($file);
	Meta::Development::Assert::assert_eq($gid,$curr,"bad group on file [".$file."]");
}

sub check_group($$) {
	my($file,$group)=@_;
	my($curr)=get_group($file);
	Meta::Development::Assert::assert_eq($group,$curr,"bad group on file [".$file."]");
}

sub check_hash_gid($$) {
	my($hash,$gid)=@_;
	while(my($key,$val)=each(%$hash)) {
		check_gid($key,$gid);
	}
}

sub check_hash_group($$) {
	my($hash,$group)=@_;
	my($gid)=group2gid($group);
	check_hash_gid($hash,$gid);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Group - library to handle group possessions.

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

	MANIFEST: Group.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Group qw();
	my($group)=Meta::Utils::File::Group::get_group("/etc/passwd");
	# $group should now be "root"

=head1 DESCRIPTION

This package can check and fix the group settings on files within your change.

=head1 FUNCTIONS

	group2gid($)
	gid2group($)
	get_gid($)
	get_group($)
	check_gid($$)
	check_group($$)
	check_hash_gid($$)
	check_hash_group($$)
	TEST($);

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<grou2gid($)>

This function receives a group name and converts it to the group id.

=item B<gid2group($)>

This function receives a group id and returns the group name associated with that id.

=item B<get_gid($)>

This routine receives a file name and returns the group id ownership of that
file. The function dies if the file does not exist.
The function uses the standard "stat" function to get the relevant
information.

=item B<get_group($)>

This routine receives a file name and returns the group name of that file.
The function throws an exception if anything goes wrong.

=item B<check_gid($$)>

This routine receives a file and a group id.
It makes sure that the file is of the appointed group.
It will throw an exception if it is not.

=item B<check_group($$)>

This method receives a file and a group name.
It makes sure that the file is of the appointed group.
It will throw an exception if it is not.

=item B<check_hash_gid($$$)>

The function receives a hash reference, a group id and a verbose flag.
This routine runs a check on all the files in the hash that they are
indeed of the designated group received.

=item B<check_hash_group($$$)>

This does exactly as the above function check_hash_gid except it receives
a group name and not an absolute id, and then translates it to an absolute
id in order to make the check and simple calls: check_hash_gid.

=item B<TEST($)>

Test suite for this module.
The test suite could be called individually or by a higher level script to perform
regression testing for this class as part of a bigger class collection.
This test suite currently does nothing.

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

	0.00 MV perl reorganization
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

#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Tar;

use strict qw(vars refs subs);
use Meta::Utils::File::Patho qw();
#use Meta::Utils::Chdir qw();
use Meta::Utils::System qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub BEGIN();
#sub unpack($$);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("tar");
}

sub unpack($$) {
	my($package,$target_dir)=@_;
	my($abs_package)=Meta::Utils::Utils::to_absolute($package);
#	Meta::Utils::Chdir::chdir($target_dir);
	Meta::Utils::System::system($tool_path,["--extract","--bzip2","--directory=".$target_dir,"--file",$abs_package]);
#	Meta::Utils::Chdir::popd();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Tar - library to run tar for archiving.

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

	MANIFEST: Tar.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Tar qw();
	Meta::Tool::Tar::unpack("myfile.tar.gz","/tmp");

=head1 DESCRIPTION

This object will tar up - you can create tar archives, add, remove and
do whatever you want with them.

=head1 FUNCTIONS

	BEGIN()
	unpack($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find your tar executable.

=item B<unpack($$)>

Give this method a package name (file name) and a destination directory and the
package will unpack the package into that directory.

=item B<TEST($)>

Test suite for this module.
This method should be called by some higher level to perform full regression
testing for the entire software package this class comes with.
This method can also be call by the user to make sure that this package
functions properly.

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

	0.00 MV perl order in packages
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

Meta::Utils::File::Patho(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

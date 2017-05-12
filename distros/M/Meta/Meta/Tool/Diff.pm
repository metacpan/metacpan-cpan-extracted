#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Diff;

use strict qw(vars refs subs);
use Error qw(:try);
use Meta::Utils::File::Patho qw();
use Meta::Utils::System qw();
use Meta::Utils::Chdir qw();
use Meta::Utils::Output qw();
use Meta::Utils::Env qw();

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub BEGIN();
#sub diff_dir($$$$);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("diff");
}

sub diff_dir($$$$) {
	my($one,$two,$out,$rel_dir)=@_;
	Meta::Utils::Chdir::chdir($rel_dir);
	Meta::Utils::Output::print("rel_dir is [".$rel_dir."]\n");
	Meta::Utils::System::system_shell("ls");
	Meta::Utils::Output::print("PWD is [".Meta::Utils::Env::get("PWD")."]\n");
	#we disregard errors since diff returns error codes when there was a diff
	#between the files
	try {
		my($cmd)=$tool_path." -urN ".$one." ".$two." > ".$out;
		Meta::Utils::Output::print("cmd is [".$cmd."]\n");
		Meta::Utils::System::system_shell($cmd);
	}
	catch Error::Simple with {
	}
	Meta::Utils::Chdir::popd();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Diff - run diff in a controlled manner for you.

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

	MANIFEST: Diff.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Diff qw();
	my($object)=Meta::Tool::Diff->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module knows about diff options and will run diff for you.

=head1 FUNCTIONS

	BEGIN()
	diff_dir($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootstrap method for location your installed version of diff.

=item B<diff_dir($$$$)>

This method receives:
1. Directory to diff from.
2. Directory to diff to.
3. File name for output patch.
4. Relative directory for the comparison.
This method will run diff and produce the requested patch.

=item B<TEST($)>

This is a testing suite for the Meta::Tool::Diff module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
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

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Utils::Chdir(3), Meta::Utils::Env(3), Meta::Utils::File::Patho(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.

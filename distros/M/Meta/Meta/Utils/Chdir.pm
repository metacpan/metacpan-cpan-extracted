#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Chdir;

use strict qw(vars refs subs);
use Meta::Ds::Stack qw();
use Meta::Utils::Output qw();
use Cwd qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub BEGIN();
#sub get_cwd();
#sub get_system_cwd();
#sub chdir($);
#sub system_chdir($);
#sub topd();
#sub popd();
#sub popup($);
#sub TEST($);

#__DATA__

our($stack);

sub BEGIN() {
	$stack=Meta::Ds::Stack->new();
	# put current directory on stack
	$stack->push(Cwd::cwd());
}

sub get_cwd() {
	return($stack->top());
}

sub get_system_cwd() {
	# this is how we access the real systems CWD
	return(Cwd::cwd());
}

sub chdir($) {
	my($directory)=@_;
	if($directory ne get_cwd()) {
		system_chdir($directory);
		$stack->push($directory);
	}
}

sub system_chdir($) {
	my($directory)=@_;
	# this is how we really change the working directory
	if(!Cwd::chdir($directory)) {
		throw Meta::Error::Simple("unable to change directory to [".$directory."]");
	}
}

sub topd() {
	my($directory)=$stack->top();
	system_chdir($directory);
}

sub popd() {
	$stack->pop();
	topd();
}

sub popup($) {
	my($num)=@_;
	$stack->popup($num);
	topd();
}

sub TEST($) {
	my($context)=@_;
	Meta::Utils::Output::print("cwd is [".get_cwd()."]\n");
	Meta::Utils::Output::print("system_cwd is [".get_system_cwd()."]\n");
	&chdir("/tmp");
	Meta::Utils::Output::print("cwd is [".get_cwd()."]\n");
	Meta::Utils::Output::print("system_cwd is [".get_system_cwd()."]\n");
	&popd();
	Meta::Utils::Output::print("cwd is [".get_cwd()."]\n");
	Meta::Utils::Output::print("system_cwd is [".get_system_cwd()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Chdir - change current working directories.

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

	MANIFEST: Chdir.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Chdir qw();
	# get the current working directory
	my($cwd)=Meta::Utils::Chdir::get_cwd();
	# change to some directory
	Meta::Utils::Chdir::chdir("/tmp/foo");
	# now return to the place where you were
	Meta::Utils::Chdir::popd();

=head1 DESCRIPTION

This package aids you in finding out and changing the current working directory.
The package also enables you to return to directories you were in without the
need to save them. The package stores a stack of the visited directories and you
can pop up as many directories as you like.

=head1 FUNCTIONS

	BEGIN()
	get_cwd()
	get_system_cwd()
	chdir($)
	system_chdir($)
	topd()
	popd()
	popup($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method which initializes the stack and puts the current working directory
on top of it.

=item B<get_cwd()>

Get the current working directory based on package knowledge (no system interaction).
This method simply looks at the top of the stack.

=item B<get_system_cwd()>

Get the system working directory. No implementation details yet.

=item B<chdir($)>

Change working directory using the package.
It will add the directory to the top of the stack (pushing it). This way
you can pop back without remembering where you were.
This method will throw an exception if the directory is not valid.

=item B<system_chdir($)>

Perform a system level chdir without the knowledge of the package.
This means that the stack remains oblivious of the directory you're going
to.
This method will throw an exception if the directory is not valid.

=item B<topd()>

This method will chdir to the top of the stack. You should use it in case
you wander off.

=item B<popd()>

This method will return to last directory you were in.
The method will raise an exception if you try to popd before going anywhere.

=item B<popup($)>

This method receives the number of levels to go up in the stack.
This means that popup(1) and popd() are equivalent calls.
This method, much like the popd method, will raise an exception if you try
to pop up too many levels.

=item B<TEST($)>

This is a testing suite for the Meta::Utils::Chdir module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
Currently this method prints the current directory data, chdirs, prints again,
pops and print again.

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

Cwd(3), Error(3), Meta::Ds::Stack(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Env;

use strict qw(vars refs subs);
#use Meta::Utils::Hash qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.31";
@ISA=qw();

#sub get($);
#sub has($);
#sub check_in($);
#sub check_out($);
#sub remove($);
#sub set($$);
#sub set_in($$);
#sub set_out($$);
#sub save($);
#sub load($);
#sub bash($);
#sub bash_cat($);
#sub TEST($);

#__DATA__

sub get($) {
	my($key)=@_;
	if(exists($ENV{$key})) {
		return($ENV{$key});
	} else {
		throw Meta::Error::Simple("unable to find [".$key."] in environment");
	}
}

sub has($) {
	my($key)=@_;
	return(exists($ENV{$key}));
}

sub check_in($) {
	my($key)=@_;
	if(!has($key)) {
		throw Meta::Error::Simple("cant find [".$key."] in the environment");
	}
}

sub check_out($) {
	my($key)=@_;
	if(has($key)) {
		throw Meta::Error::Simple("cant find [".$key."] in the environment");
	}
}

sub remove($) {
	my($key)=@_;
	if(has($key)) {
		delete $ENV{$key};
	} else {
		throw Meta::Error::Simple("environment does not have [".$key."] in environment");
	}
}

sub set($$) {
	my($key,$val)=@_;
	$ENV{$key}=$val;
}

sub set_in($$) {
	my($key,$val)=@_;
	check_in($key);
	set($key,$val);
}

sub set_out($$) {
	my($key,$val)=@_;
	check_out($key);
	set($key,$val);
}

sub save($) {
	my($file)=@_;
#	Meta::Utils::Hash::save(\%ENV,$file);
}

sub load($) {
	my($file)=@_;
#	Meta::Utils::Hash::load(\%ENV,$file);
}

sub TEST($) {
	my($context)=@_;
	my($scod);
	try {
		Meta::Utils::Env::get("FOO");
		$scod=0;
	}
	catch Error with {
		$scod=1;
	};
	return($scod);
}

1;

__END__

=head1 NAME

Meta::Utils::Env - utilities to let you access the environment variables.

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

	MANIFEST: Env.pm
	PROJECT: meta
	VERSION: 0.31

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Env qw();
	my($home)=Meta::Utils::Env::get("HOME");

=head1 DESCRIPTION

This is a library to let you get,set query,save and load environment
variables.
It has a few advanced services also - like giving you pieces of bash code
to run from your environment and autoset environment variables etc...
You may rightly ask - "why should you have such a library ? Perl already
has a global hash variable called ENV which IS the environment". True, true,
but the access to it is not object oriented and is arcane to people who are
used to working in a clean object orient environment. Why should they learn
about the ENV variable ? the $? variable ? are you kidding ? these are old
style stuff. For every subject there need be a namespace which descirbes
the subject accordingly and all the routines that have to do with that
subject will be under that name-space. This approach is much more extendible,
uniform, modern and lends itself to building larger software systems since
you do not mess up your namespace by default but rather use a library on a
need to basis.

=head1 FUNCTIONS

	get($)
	has($)
	check_in($)
	check_out($)
	remove($)
	set($$)
	set_in($$)
	set_out($$)
	save($)
	load($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get($)>

This gives you an element of the environment and dies if it cannot find
it in the environment.
The implementation just gets the value from the "ENV" hash table (perl builtin).

=item B<has($)>

This routine returns a boolean variable according to whether a variable
is in the environment or not.
The implementation just consults the ENV hash table.

=item B<check_in($)>

This routine receives an environment variables name and dies if it isnt
in the environment.

=item B<check_out($)>

This dies if the environment variable is already in the environment.

=item B<remove($)>

This will remove an environment variable (this is different from setting
it to "").

=item B<set($$)>

This sets an element in the environment.
The implementation just adds the variable and its value to the ENV hash.

=item B<set_in($$)>

This does a set but dies if the envrionment values in question did not
already exist in the environment.

=item B<set_out($$)>

This does a set but dies if the environment key in question was already in
the environment.

=item B<save($)>

This routine saves all environment variables into a file. The idea is to
be able to save and load the entire environment so as to keep an exact
copy of the working conditions for a certain process or to clear the
environment to supply a sterile environment to run some process and then
restore it back. You may find other uses.

=item B<load($)>

This routine loads the entire environment from a disk. See the save routine
for more details.

=item B<TEST($)>

Test suite for this module.
Currently it just tries to get a bogus environment variable and make sure
that it fails doing that.

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
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV more perl code quality
	0.08 MV correct die usage
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV more perl quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV history change
	0.20 MV perl packaging
	0.21 MV some chess work
	0.22 MV md5 project
	0.23 MV database
	0.24 MV perl module versions in files
	0.25 MV movies and small fixes
	0.26 MV thumbnail user interface
	0.27 MV more thumbnail issues
	0.28 MV website construction
	0.29 MV web site automation
	0.30 MV SEE ALSO section fix
	0.31 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

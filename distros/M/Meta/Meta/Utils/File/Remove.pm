#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Remove;

use strict qw(vars refs subs);
use File::Find qw();
use Meta::Utils::Output qw();
use Error qw(:try);
use Meta::Error::FileNotFound qw();

our($VERSION,@ISA);
$VERSION="0.30";
@ISA=qw();

#sub rm($);
#sub rmdir($);
#sub rmall($);
#sub rmrmdir($);
#sub rmrecursive($);
#sub rmhash($);
#sub rmlist($);
#sub rmmult($);
#sub TEST($);

#__DATA__

sub rm($) {
	my($file)=@_;
	if(!-f $file) {
		throw Meta::Error::FileNotFound($file);
	}
	my($resu)=CORE::unlink($file);
	if($resu!=1) {
		throw Meta::Error::Simple("unable to remove [".$file."]");
	}
}

sub rmdir($) {
	my($directory)=@_;
	if(!-d $directory) {
		throw Meta::Error::FileNotFound($directory);
	}
	my($resu)=CORE::rmdir($directory);
	if(!$resu) {
		throw Meta::Error::Simple("unable to remove directory [".$directory."]");
	}
}

sub rmall($) {
#	my($unkn)=@_;
	my($unkn)=$File::Find::name;
	if(-f $unkn) {
		&rm($unkn);
		return;
	}
	if(-d $unkn) {
		&rmdir($unkn);
		return;
	}
	throw Meta::Error::FileNotFound($unkn);
}

sub rmrmdir($) {
	my($file)=@_;
	&rm($file);
	my($dire)=dirname($file);
	if(dir_empty($dire)) {
		&rmdir($dire);
	}
}

sub rmrecursive($) {
	my($dir)=@_;
	File::Find::find({wanted=>\&rmall,nochdir=>1,bydepth=>1},$dir);
}

sub rmhash($) {
	my($hash)=@_;
	my($resu)=1;
	while(my($key,$val)=each(%$hash)) {
		my($curr_resu)=&rm($key);
		$resu=$resu && $curr_resu;
	}
	return($resu);
}

sub rmlist($) {
	my($list)=@_;
	my($resu)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr_resu)=&rm($list->[$i]);
		$resu=$resu && $curr_resu;
	}
	return($resu);
}

sub rmmult($) {
	my($file)=@_;
	my($line);
	my($resu)=1;
	while($line=<$file> || 0) {
		chop($line);
		my($curr_resu)=&rm($line);
		$resu=$resu && $curr_resu;
	}
	return($resu);
}

sub TEST($) {
	my($context)=@_;
	my($scod)=0;
	try {
		&rm("/tmp/dgfgdfg");
	}
	catch Meta::Error::FileNotFound with {
		$scod=1;
	};
	return($scod);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Remove - package that eases removal of files and directories.

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

	MANIFEST: Remove.pm
	PROJECT: meta
	VERSION: 0.30

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Remove qw();
	Meta::Utils::File::Remove::rm($filename);
	Meta::Utils::File::Remove::rmdir($dirname);

=head1 DESCRIPTION

This module eases the use of rm. Instead of checking for errors all of the
time just let this module remove a file or directory for you (it has all
the options including a recursive one...). If something happens wrong
it dies on you but hey - thats the price you got to pay...

=head1 FUNCTIONS

	rm($)
	rmdir($)
	rmall($)
	rmrmdir($)
	rmrecusrive($)
	rmhash($)
	rmlist($)
	rmmult($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<rm($)>

This function removes a single file and throws an exception if it cannot do so.
This function does not return a value.

=item B<rmdir($)>

This function removes a directory and throws an exception if it cannot do so.
This function does not return a value.

=item B<rmall($)>

This function assumes that you dont know if what you're looking to remove
is a file or a directory and removes whichever this is...
It dies if it cannot perform.
The function tries to test if the unknown is a file first since it assumes
that most stuff that will need delting is files (I hope I'm right here...:).
If the unknown is neither a file nor a directory then the function will
throw an exception.

=item B<rmrmdir($)>

This function removes a file and then removes the directory in which it is
located if it remains empty.
Actually this function should continues going higher....:) up the directory
tree.

=item B<rmrecusive($)>

This function removes a directory in a recursive fashion.
It uses the File::Find function to achieve this (unlinking dirs is not
good...:)
It also uses the rmall function to achieve this (nice trick...).

=item B<rmhash($)>

This routine removes a whole hash. As expected, demo and verbose arguments
are also allowed.

=item B<rmlist($)>

This routine removes a whole list. As expected, demo and verbose arguments
are also allowed.

=item B<rmmult($)>

This function receives the regular demo and verbose variables and treats the
standard input as a source for lines, each representing a file to be removed.
The function removes all the files refered as such.
The function returns whether all the removals were successful or not.

=item B<TEST($)>

Test suite for this module.
This suite should be called by a higher level to test the functionality of
this module.
Currently this test suite tries to remove a non existant file and catches
the error.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None

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
	0.07 MV make lilypond work
	0.08 MV correct die usage
	0.09 MV lilypond stuff
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV more perl quality
	0.13 MV perl documentation
	0.14 MV more perl quality
	0.15 MV perl qulity code
	0.16 MV more perl code quality
	0.17 MV revision change
	0.18 MV languages.pl test online
	0.19 MV perl packaging
	0.20 MV fix database problems
	0.21 MV md5 project
	0.22 MV database
	0.23 MV perl module versions in files
	0.24 MV movies and small fixes
	0.25 MV thumbnail user interface
	0.26 MV more thumbnail issues
	0.27 MV website construction
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV md5 issues

=head1 SEE ALSO

Error(3), File::Find(3), Meta::Error::FileNotFound(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-rm_rmdir should climb higher and keep removing dirs (its not doing that right now...).

-start using a parameter module to determine things like verbosity and demo mode (where we dont really do the removing but rather just climb back on top).

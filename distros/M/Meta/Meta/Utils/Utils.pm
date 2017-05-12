#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Utils;

use strict qw(vars refs subs);
use Meta::Utils::Env qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Chdir qw();
use Meta::IO::File qw();
use POSIX qw();
use Cwd qw();
use Error qw(:try);
use File::Basename qw();

our($VERSION,@ISA);
$VERSION="0.45";
@ISA=qw();

#sub bnot($);
#sub minus($$);
#sub get_temp_dir();
#sub get_temp_dire();
#sub get_temp_file();
#sub replace_suffix($$);
#sub remove_suffix($);
#sub remove_suf($$);
#sub basename($);
#sub is_prefix($$);
#sub is_suffix($$);
#sub cuid();
#sub cuname();
#sub cgid();
#sub get_home_dir();
#sub get_user_home_dir($);
#sub remove_comments($);
#sub cat($$$);
#sub is_absolute($);
#sub is_relative($);
#sub to_absolute($);
#sub TEST($);

#__DATA__

sub bnot($) {
	my($val)=@_;
	if($val==0) {
		return(1);
	} else {
		return(0);
	}
}

sub minus($$) {
	my($full,$partial)=@_;
	if(substr($full,0,length($partial)) eq $partial) {
		return(substr($full,length($partial),length($full)));
	} else {
		throw Meta::Error::Simple("partial is [".$partial."] and full is [".$full."]\n");
	}
}

sub get_temp_dir() {
	return("/tmp");
}

sub get_temp_dire() {
	my($base)="/tmp/temp_dir";
	my($i)=0;
	while(!CORE::mkdir($base."_".$i,0755)) {
		$i++;
	}
	return($base."_".$i);
}

sub get_temp_file() {
	return(POSIX::tmpnam());
#	This call actually creates the file and this is unneccessary because
#	this is not the intention of the routine. Watch out for a race
#	condition where the routine calling this one will get the name and cant
#	create the file.
#	my($name,$fh);
#	do {
#		$name=POSIX::tmpnam();
#	}
#	until($fh=Meta::IO::File->new($name,Meta::IO::File::O_RDWR|Meta::IO::File::O_CREAT|Meta::IO::File::O_EXCL));
#	return($name);
}

sub replace_suffix($$) {
	my($file,$suff)=@_;
	my($base)=File::Basename::basename($file);
	my($dir)=File::Basename::dirname($file);
	$base=~s/\..*/$suff/;
	return($dir."/".$base);
	#the old code which is bad since it does not handle files
	#which have "." in the directory part.
	#$file=~s/\..*/$suff/;
}

sub remove_suffix($) {
	my($file)=@_;
	return(replace_suffix($file,""));
}

sub remove_suf($$) {
	my($full,$partial)=@_;
	if(substr($full,length($full)-length($partial),length($partial)) eq $partial) {
		return(substr($full,0,length($full)-length($partial)));
	} else {
		throw Meta::Error::Simple("partial is [".$partial."] and full is [".$full."]\n");
	}
}

sub basename($) {
	my($file)=@_;
	my(@arra)=split('/',$file);
	my($last)=$arra[$#arra];
	return(remove_suffix($last));
#	my($basename)=($file=~/\/([.-\/]*)\.[.-\/]*$/);
#	return($basename);
}

sub get_suffix($) {
	my($file)=@_;
	my($suff)=($file=~/^.*\.(.*)$/);
	return($suff);
}

sub is_prefix($$) {
	my($stri,$pref)=@_;
	#$pref=quotemeta($pref);
	#Meta::Utils::Output::print("pref is [".$pref."]\n");
	#return($stri=~/^$pref/);
	my($sub)=substr($stri,0,length($pref));
	return($sub eq $pref);
}

sub is_suffix($$) {
	my($stri,$suff)=@_;
	#$suff=quotemeta($suff);
	#Meta::Utils::Output::print("suff is [".$suff."]\n");
	#return($stri=~/$suff$/);
	my($sub)=substr($stri,-length($suff));
	return($sub eq $suff);
}

sub cuid() {
	return(POSIX::getuid());
#	return($>);
}

sub cuname() {
	my($uid)=POSIX::getuid();
	return((POSIX::getpwuid($uid))[0]);
}

sub cgid() {
	return(POSIX::getegid());
}

sub get_home_dir() {
	my($uid)=POSIX::getuid();
	return((POSIX::getpwuid($uid))[7]);
	#my($user)=POSIX::getpwnam();
	#return(get_user_home_dir($user));
#	return(Meta::Utils::Env::get("HOME"));
}

sub get_user_home_dir($) {
	my($user)=@_;
	my($resu)=((POSIX::getpwnam($user))[7]);
	if(!defined($resu)) {
		throw Meta::Error::Simple("user [".$user."] unknown");
	}
	return($resu);
}

sub remove_comments($) {
	my($text)=@_;
	$text=~s/\/\/*.*\*\///;
	return($text);
}

sub cat($$$) {
	my($f1,$f2,$out)=@_;
	if($f1 eq $out || $f2 eq $out) {
		throw Meta::Error::Simple("bad files given");
	}
	my($io_out)=Meta::IO::File->new_writer($out);
	my($io_f1)=Meta::IO::File->new_reader($f1);
	while(!$io_f1->eof()) {
		my($line)=$io_f1->getline();
		print $io_out $line;
	}
	$io_f1->close();
	my($io_f2)=Meta::IO::File->new_reader($f2);
	while(!$io_f2->eof()) {
		my($line)=$io_f2->getline();
		print $io_out $line;
	}
	$io_f2->close();
	$io_out->close();
	#older implementation which is much less efficient
	#my($text_f1,$text_f2);
	#Meta::Utils::File::File::load($f1,\$text_f1);
	#Meta::Utils::File::File::load($f2,\$text_f2);
	#my($text_out)=$text_f1.$text_f2;
	#Meta::Utils::File::File::save($out,$text_out);
}

sub is_absolute($) {
	my($fn)=@_;
	return($fn=~/^\//);
}

sub is_relative($) {
	my($fn)=@_;
	return($fn!~/^\//);
}

sub to_absolute($) {
	my($fn)=@_;
	if(is_absolute($fn)) {
		return($fn);
	} else {
		return(Meta::Utils::Chdir::get_cwd()."/".$fn);
	}
}

sub TEST($) {
	my($context)=@_;
	Meta::Utils::Output::print(get_home_dir()."\n");
	Meta::Utils::Output::print(get_user_home_dir("root")."\n");
	Meta::Utils::Output::print(remove_comments("kuku /* mark */ fufu")."\n");
	Meta::Utils::Output::print(get_suffix("foo.bar")."\n");
	Meta::Utils::Output::print(basename("/etc/passwd.txt")."\n");
	Meta::Utils::Output::print(remove_suf("/etc/passwd.txt",".txt")."\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Utils - misc utility library for many functions.

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

	MANIFEST: Utils.pm
	PROJECT: meta
	VERSION: 0.45

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Utils qw();
	my($get_home_dir)=Meta::Utils::Utils::get_home_dir();

=head1 DESCRIPTION

This is a general utility module for either miscelleneous commands which are hard to calssify or for routines which are just starting to form a module and have not yet been given a module and moved there.

=head1 FUNCTIONS

	bnot($)
	minus($$)
	get_temp_dir()
	get_temp_dire()
	get_temp_file()
	replace_suffix($$)
	remove_suffix($)
	remove_suf($$)
	is_prefix($$)
	is_suffix($$)
	cuid()
	cuname()
	cgid()
	get_home_dir()
	get_user_home_dir($)
	remove_comments($)
	cat($$$)
	is_absolute($)
	is_relative($)
	to_absolute($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<bnot($)>

This does a binary "not" operation which (suprisingly) is not enough to
do using the "!" operator.

=item B<minus($$)>

This subtracts one string from another under the assumbtions that the second
is a prefix of the first. This is useful for paths (and hence the names of the
local variables in this function).

=item B<get_temp_dir()>

This gives you a temporary directory where you can store temporary files
to your hearts content. Currently this just returns "/tmp" which is ok for
UNIX type systems.

=item B<get_temp_dire()>

This method will give you a directory it created in a temporary location.
Currently it iterates on names until it manages to create the directory.

=item B<get_temp_file()>

This gives you a temporary file name using the POSIX tmpnam function.

=item B<replace_suffix($$)>

This replaces the strings suffix with another one.

=item B<remove_suffix($)>

This removes a suffix from the string argument given it.
This just substitues the suffix of the string with nothing...:)

=item B<remove_suf($$)>

This method removes a suffix from a string.
The suffix is an explicit string passed to it.

=item B<is_prefix($$)>

This routine receives a string and a prefix and returns whether the
prefix is a prefix for that string

=item B<is_suffix($$)>

This routine receives a string and a suffix and returns whether the
suffix is a suffix for that string

=item B<cuid()>

This routine returns the numerical value of the current user (uid).

=item B<cuname()>

This routine returns the current user name (uname).

=item B<cgid()>

This routine returns the numerical value of the current group (gid).
I don't think there is a cleaner way to do this.

=item B<get_home_dir()>

This routine returns the current users home directory.
The implementation used to work with the environment and getting the
HOME variable but this is very unrobust and works for less platforms
and situations. Currently this uses POSIX which is much more robust
to find the uid of the current user and then the home directory from
the password file using getpwuid. The reason that this does not use
the get_user_home_dir method from this same module is that there is
no convinient way to get the current user name (it would take
another function to convert uid to uname). The implementation marked
out using POSIX::getpwnam does not work.

=item B<get_user_home_dir($)>

This routine returns the home dir of the user that is given to it as the
argument.

=item B<remove_comments($)>

This routine will receive a text and will remove all comments from it.
The idea here is C/C++ style comments : /* sdfdaf */

=item B<cat($$$)>

This function receives the names of two files and write the content of the
two fles into the third one. If one of the input files is the output file
then this function will throw an exception. In the future the function may
be able to deal with such cases by moving the info through an intermediate
file.

=item B<is_absolute($)>

This function will return whether the file name it received is an absolute file name.

=item B<is_relative($)>

This function will return whether the file name it received is a relative file name.

=item B<to_absolute($)>

This function will convert a relative file name to an absolute one. It use
Meta::Utils::Chdir::pwd to do it's thing.

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
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV more perl code quality
	0.09 MV put ALL tests back and light the tree
	0.10 MV make options a lot better
	0.11 MV introduce docbook into the baseline
	0.12 MV make lilypond work
	0.13 MV correct die usage
	0.14 MV lilypond stuff
	0.15 MV perl quality change
	0.16 MV perl code quality
	0.17 MV more perl quality
	0.18 MV more perl quality
	0.19 MV get basic Simul up and running
	0.20 MV perl documentation
	0.21 MV more perl quality
	0.22 MV perl qulity code
	0.23 MV more perl code quality
	0.24 MV revision change
	0.25 MV languages.pl test online
	0.26 MV more on images
	0.27 MV PDMT/SWIG support
	0.28 MV perl packaging
	0.29 MV perl packaging again
	0.30 MV db inheritance
	0.31 MV more database issues
	0.32 MV md5 project
	0.33 MV database
	0.34 MV perl module versions in files
	0.35 MV movies and small fixes
	0.36 MV thumbnail user interface
	0.37 MV more thumbnail issues
	0.38 MV website construction
	0.39 MV more web page stuff
	0.40 MV web site automation
	0.41 MV SEE ALSO section fix
	0.42 MV move tests to modules
	0.43 MV web site development
	0.44 MV finish papers
	0.45 MV md5 issues

=head1 SEE ALSO

Cwd(3), Error(3), File::Basename(3), Meta::IO::File(3), Meta::Utils::Chdir(3), Meta::Utils::Env(3), Meta::Utils::File::File(3), POSIX(3), strict(3)

=head1 TODO

-implement the get_temp_dir routine better... (is there a way of officialy getting such a directory ?).

-is there a better way to implement the get_temp_dire routine ?

-move the get_home_dir and related functions into some library.

-The is suffix routine and is prefix routines should be fixed for cases where the string they match has special (regexp type) characters in it. Watch the example in cook_touch.

-more routines should be moved to their own modules...

-the remove_suffix function is a little slow (uses replace suffix). Make it just do it's thing.

-do the basename more efficiently using regexps. (experimental code is there but doesnt work)

-improve the cat method to deal with the case where the one of the input files is also the output.

-improve the cat method to check for cannonical file names and not just the ones given.

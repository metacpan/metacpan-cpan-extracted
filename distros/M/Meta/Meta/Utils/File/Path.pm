#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Path;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::Utils::Utils qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.32";
@ISA=qw();

#sub add_path($$$);
#sub add_path_min($$$);
#sub min_path($$);
#sub exists($$$);
#sub exists_dir($$$);
#sub resolve_nodie($$$);
#sub resolve($$$);
#sub resolve_dir_nodie($$$);
#sub resolve_dir($$$);
#sub append($$$);
#sub remove_path($$$);
#sub remove_nonexist($$);
#sub check($$);
#sub check_flst($$);
#sub TEST($);

#__DATA__

sub add_path($$$) {
	my($onex,$twox,$sepa)=@_;
	if($onex eq "") {
		if($twox eq "") {
			return("");
		} else {
			return($twox);
		}
	} else {
		if($twox eq "") {
			return($onex);
		} else {
			return($onex.$sepa.$twox);
		}
	}
}

sub add_path_min($$$) {
	my($onex,$twox,$sepa)=@_;
	my($resu)=add_path($onex,$twox,$sepa);
	return(min_path($resu,$sepa));
}

sub min_path($$) {
	my($path,$sepa)=@_;
	my(%hash,@retu);
	my(@fiel)=split($sepa,$path);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i];
		if(!exists($hash{$curr})) {
			push(@retu,$curr);
			$hash{$curr}=defined;
		}
	}
	return(join($sepa,@retu));
}

sub exists($$$) {
	my($path,$file,$sepa)=@_;
	my(@part)=split($sepa,$path);
	for(my($i)=0;$i<=$#part;$i++) {
		my($cpth)=$part[$i];
		my($curr)=$cpth."/".$file;
		if(-f $curr) {
			return(1);
		}
	}
	return(0);
}

sub exists_dir($$$) {
	my($path,$file,$sepa)=@_;
	my(@part)=split($sepa,$path);
	for(my($i)=0;$i<=$#part;$i++) {
		my($cpth)=$part[$i];
		my($curr)=$cpth."/".$file;
		if(-d $curr) {
			return(1);
		}
	}
	return(0);
}

sub resolve_nodie($$$) {
	my($path,$file,$sepa)=@_;
#	Meta::Utils::Output::print("got path [".$path."] and file [".$file."]\n");
	my(@part)=split($sepa,$path);
	for(my($i)=0;$i<=$#part;$i++) {
		my($cpth)=$part[$i];
		my($curr)=$cpth."/".$file;
#		Meta::Utils::Output::print("curr is [".$curr."]\n");
		if(-f $curr) {
			return($curr);
		}
	}
	return(undef);
}

sub resolve($$$) {
	my($path,$file,$sepa)=@_;
	my($resu)=resolve_nodie($path,$file,$sepa);
	if(!defined($resu)) {
		throw Meta::Error::Simple("unable to find file [".$file."] in path [".$path."]");
	}
	return($resu);
}

sub resolve_dir_nodie($$$) {
	my($path,$dire,$sepa)=@_;
#	Meta::Utils::Output::print("got path [".$path."] and file [".$file."]\n");
	my(@part)=split($sepa,$path);
	for(my($i)=0;$i<=$#part;$i++) {
		my($cpth)=$part[$i];
		my($curr)=$cpth."/".$dire;
#		Meta::Utils::Output::print("curr is [".$curr."]\n");
		if(-d $curr) {
			return($curr);
		}
	}
	return(undef);
}

sub resolve_dir($$$) {
	my($path,$dire,$sepa)=@_;
	my($resu)=resolve_dir_nodie($path,$dire,$sepa);
	if(!defined($resu)) {
		throw Meta::Error::Simple("unable to find directory [".$dire."] in path [".$path."]");
	}
	return($resu);
}

sub append($$$) {
	my($path,$suff,$sepa)=@_;
	my(@fiel)=split($sepa,$path);
	my(@list);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i];
		push(@list,$curr.$suff);
	}
	return(join($sepa,@list));
}

sub remove_path($$$) {
	my($path,$sepa,$file)=@_;
	my(@fiel)=split($sepa,$path);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i]."/";
		#Meta::Utils::Output::print("checking [".$file."] vs [".$curr."]\n");
		if(Meta::Utils::Utils::is_prefix($file,$curr)) {
			return(Meta::Utils::Utils::minus($file,$curr));
		}
	}
	throw Meta::Error::Simple("is not a prefix of any [".$path."] [".$sepa."] [".$file."]");
}

sub remove_nonexist($$) {
	my($path,$sepa)=@_;
	my(@retu);
	my(@fiel)=split($sepa,$path);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i];
		if(-d $curr) {
			push(@retu,$curr);
		}
	}
	return(join($sepa,@retu));
}

sub check($$) {
	my($path,$sepa)=@_;
	my($scod)=1;
	my(@fiel)=split($sepa,$path);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i];
		if(!(-d $curr)) {
			$scod=0;
		}
	}
	return($scod);
}

sub check_flst($$) {
	my($path,$sepa)=@_;
	my($scod)=1;
	my(@fiel)=split($sepa,$path);
	for(my($i)=0;$i<=$#fiel;$i++) {
		my($curr)=$fiel[$i];
		if(!(-f $curr)) {
			throw Meta::Error::Simple("file [".$curr."] bad");
		}
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Path - module to handle path names.

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

	MANIFEST: Path.pm
	PROJECT: meta
	VERSION: 0.32

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Path qw();
	my($full)=Meta::Utils::File::Path::add_path("/usr/bin:/bin","/sbin:/usr/sbin",":");

=head1 DESCRIPTION

This package is intended to help you handle paths. For example - remove
automounted parts from your path, get cannonic paths, get absolute paths,
get paths with as few ".." as possible, reduce paths to a minimum etc...

=head1 FUNCTIONS

	add_path($$$)
	add_path_min($$$)
	min_path($$)
	exists($$$)
	exists_dir($$$)
	resolve_nodie($$$)
	resolve($$$)
	resolve_dir_nodie($$$)
	resolve_dir($$$)
	append($$$)
	remove_path($$$)
	remove_nonexist($$)
	check($$)
	check_flst($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<add_path($$$)>

This functions receives:
1. A first path component.
2. A second path component.
3. A separator used for those paths.
And returns a path which is the catenation of those two paths.
If one of them is nothing then the extra separator will be
ommited.

=item B<add_path_min($$$)>

This method does exactly as add_path except it also minimizes the path
of the catenation if indeed catenation takes place (if no catenation
takes place the path is kept the same as the first or second element
which must be already minimized if you with the result ot be minimized).

=item B<min_path($$)>

This function receives:
0. A string which is a path name.
1. A separator.
This function assumes that the string is a path name with the second argument
is the separator and returns a string which is in effect the same path but has
no two entries which are the same.
The algorithm is to construct a new path and remember the old parts as not
to repeat them.

=item B<exists($$$)>

This method returns true iff the file exists in the path.

=item B<exists_dir($$$)>

This method returns true iff the directory exists in the path.

=item B<resolve_nodie($$$)>

This method receives a path and a file and returns the resolution of them:
meaning the abosolute file name of the first file in the path that matches
the file.

=item B<resolve($$$)>

This method is the same as resolve_nodie expect it dies if it cannot find
the file.

=item B<append($$$)>

This will append a suffix to the path. This means all elements in the path.

=item B<remove_path($$$)>

This method reveices a path (and a separator) and a path name.
The method assumes that file is in one of the elements in the
path and returns the relative part of the file name.

=item B<remove_nonexist($$)>

This method return a path which is like the original given to
it except it removes the parts of the path which are not
real directories.

=item B<check($$)>

This method will return whether the path passed is indeed valid path
(every component is a real directory).

=item B<check_flst($$)>

This method will return whether the path passed is indeed valid file
list (every component is a real file).

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
	0.08 MV chess and code quality
	0.09 MV more perl quality
	0.10 MV perl documentation
	0.11 MV more perl quality
	0.12 MV perl qulity code
	0.13 MV more perl code quality
	0.14 MV revision change
	0.15 MV languages.pl test online
	0.16 MV web site and docbook style sheets
	0.17 MV perl packaging
	0.18 MV perl packaging again
	0.19 MV tree type organization in databases
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV paper writing
	0.27 MV website construction
	0.28 MV web site automation
	0.29 MV SEE ALSO section fix
	0.30 MV move tests to modules
	0.31 MV download scripts
	0.32 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.

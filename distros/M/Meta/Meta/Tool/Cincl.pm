#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Cincl;

use strict qw(vars refs subs);
use Meta::Utils::List qw();
use Meta::Utils::File::Remove qw();
use Meta::Baseline::Utils qw();
use Meta::Utils::Output qw();
use Meta::Utils::Options qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw();

#sub BEGIN();
#sub run($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("c_incl");
}

sub run($) {
	my($buil)=@_;
	my($modu)=$buil->get_modu();
	my($srcx)=$buil->get_srcx();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my(@dirx)=split(":",$path);
	my($file)=Meta::Baseline::Aegis::which("data/baseline/cook/ccxx.txt");
	my($options)=Meta::Utils::Options->new();
	$options->read($file);
	my($einc)=join(':',
		$options->get("base_cook_lang_ccxx_incl"),
		$options->get("base_cook_lang_ccxx_incl_base")
	);
	my($elib)=$options->get("base_cook_lang_ccxx_link");
	#extract epth
	my(@edir)=split(":",$einc);

	my(@args)=(
		$srcx
	);

# see (1)

	if(0) {
		push(@args,"--No_System");
	} else {
# Actualy,there is no such flags
# push(@args,"--System");
	}

# see (2)

	if(0) {
		push(@args,"--Absent_System_Ignore");
	} else {
		push(@args,"--Absent_System_Error");
	}

# see (3)

	if(0) {
		push(@args,"--Absent_Local_Ignore");
	} else {
		push(@args,"--Absent_Local_Error");
	}

	push(@args,(
		"--Language=C",
		"--No_Cache",
		"--No_Source_Relative_Includes",
		"--No_Recursion",
		"--No_Absolute_Paths",
		"--Output",$targ,
		"--PREfix=".Meta::Baseline::Utils::get_cook_emblem()."cascade ".$modu."=",
		"--SUFfix=;",
		"--Absent_Program_Error",
		"-I-"
	));

# see (4)

	for(my($i)=0;$i<=$#edir;$i++) {
		push(@args,"-I");
		push(@args,$edir[$i]);
	}

# see (5)

	for(my($i)=0;$i<=$#dirx;$i++) {
		push(@args,"-I");
		push(@args,$dirx[$i]."/ccxx");
		push(@args,"-Remove_Leading_Path");
		push(@args,$dirx[$i]);
	}
#	Meta::Utils::Output::print("this is the list of args:\n");
#	Meta::Utils::List::print(Meta::Utils::Output::get_file(),\@args);
#	Meta::Utils::Output::print("this is the end of the argument list\n");
	my($scod)=Meta::Utils::System::system_nodie($tool_path,\@args);
	if(!$scod) {
#		Meta::Utils::Output::print("failed - removing target [".$targ."]\n");
		Meta::Utils::File::Remove::rm($targ);
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Cincl - handle running Peter Millers c_incl tool.

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

	MANIFEST: Cincl.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Cincl qw();
	my($object)=Meta::Tool::Cincl->new();
	my($result)=Meta::Tool::Cincl::run([param]);

=head1 DESCRIPTION

This module will run cincl which is a utility which is supplied with Peter
Millers cook for you. It knows how to run cincl well and has a lot of options
you could use.

=head1 FUNCTIONS

	BEGIN()
	run($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

A bootstrap method to find where your c_incl is.

=item B<run($)>

This method does most of the work. A lot of documentation will now follow. 

If you do not know what is the cascade method for dependency managment
and calculation in cook I hereby refer you to the cook manual to that
chapter.
If you do not know what the cc,hh,ii,tt suffixes stand for in C++ development
please read about it in the C++ sections.

parameters to this utility:
0. modu - source file that the dependencies are for without prefixes.
1. srcx - source file to generate dependencies for.
2. targ - file to be the output file.
3. path - orderd search path for in project include files.
	(this may contain !!!more!!! than two directories if were using
	the Aegis branch features...:).

Additional parameters are extracted from an option file which are:
0. einc - extra path to look for includes in. This should not point into the
	baseline or change as it is referenced only to enable you to link
	with libraries which store header files not in the standard directories
	searched by the compiler.
1. elib - extra path to look for libraries in. This should not point into the
	baseline or change as it is referenced only to enable you to link
	with libraries which stroe dll files not in the standard directories
	searched by the compiler.

Here are the explanations for all the parameters that are give to c_incl:
0. $srcx - this is the C++ file that we wish to analyze dependencies for.
1. C<--Language=C> - we are working with C. If you dont like it - go home.
2. C<--No_Cache> - do not use c_incl caching (we are using the cascade
	dependency method and caching is useless in this method).
3. C<--No_Source_Relative_Includes> - this is a must in a source control
	environment so people wont do "include "../that.h" (they dont
	actually know if that.h is in their change or in the baseline).
4. C<--No_Recursion> - do not recurse - print only the direct includes for
	this file (scan only this file). This is an integral part of the
	cascade method for dependency handling - consult the cook
	manual if you do not understand this.
5. C<--No_Absolute_Paths> - do not put absolute paths in the output.
6. C<--Output $targ> - what file is the output of this process.
7. C<--PREfix> - this is to make the syntax for the cook work.
	notice the $modu parameter which is the name of the source file
	without the baseline or change prefix.
8. C<--SUFfix> - this is to make the syntax for the cook work.
9. C<--Absent_Program_Error> - we want c_incl to go crazy if it cannot find
	the source file.
10. B<-I-> - to prevent any misconceptions of c_incl about where our include
	files are - we will tell it where they are (/usr/include is not
	allowed).

In addition there are a few conditional flags that we use:
0. C<--No_System> - do not allow system include files to be used (people
	are not supposed to include system files in their files).
	There is not --System as this is the regular behaviour. We issue this
	flag for every source that cook tells us too.
1. C<--Absent_System_Error>/C<--Absent_System_Ignore>
	Issue an error and stop if there is an absent system file or (for the
	ignore case) ignore such cases. This is given according to whether
	cook thinks this is relevant. In theory, this should be given to
	any file which is allowed to include system files and is compiled
	on the current platform since there should be no problem in finding
	its include files. If the file is from a different platform then that
	is another beezwax.
2. C<--Absent_Local_Error>/C<--Absent_Local_Ignore>
	Same as the above but for local includes (includes in double quotes instead of ge signs).
	As a policy, we should not allow local includes (they are bad shit).
	But this script does not do that job. In any case we issue this flag
	according to what cook says and I can not think of a reason why
	cook will let a file off for having an absent local include so it
	should be C<--Absent_Local_Error> on all files...

In addition, we issue actual include directives according to two source of
information:
0. The epth which is an external path (already configured to point at the
	include locations exactly). This is for external libraries which
	we are dependant upon. We do not remove any leading paths in
	the dependencies generated for those since they are absolute as
	far as we are concerned (they are certainly not part of the baseline).
1. The path which is the Aegis search path that tells c_incl where to find
	our own include files (we get this from Aegis and it has the regular
	change/branch/baseline format...). We remove the leading paths for
	thosie includes using the C<--Remove_Leading_Path> directive bacause
	we want dependency information to be independant of whether the files
	involved are in the change/branch/baseline...

Yes - definately a lot of parameters - but we squeeze c_incl for all its
worth in this usage.

Notice that this script will fail (and also cleanup after itself - i.e -
will not create any target file) if any file is included out of the baseline -
this is very good in preventing people from including stuff directly
and thus making us a little higher above the system...
Another feature is the exclusion list.
The cook modules knows about a list of files which are on something we
call the exclusion list. That list is stored somewhere in the baseline as
data (lookup the cook module documentation for this). All files on that
list are allowed to directly include system headers. Please do not add
files to that list to accomodate your immediate needs (I know it is hard).
I know that you do not want to compile the entire baseline for a singe
system include files - but life is tough....

(1)
This handles the exclusion list.
First we init the exclusion list (I.E. tell cook to read it...).
Then we ask it if our source file is in it (mind you we use the source
without prefixes as that will be types of files stored in the exception list).
We use the "--No_System" if the file is on the exclusion list.
That is because we could have includes for source files not on our system
(on Windoze NT for instance...). Therefore we dont c_incl to complain about
thouse. It is true that it means that it will not chech for correct includes
in our file (gcc.h or something) but that is tough...
In any case - if this is the case we allow system include by using the
"--System" directive.
If the file is not on the exclusion list the task is simpler - we just declare
that no system include files are allowed using the "--No_System" construct.

(2)
This handles foreigh files (for foreign systems).
Cook has a list of those (fore_exis([filename]) and if this is the case
we simply ignore those files.

(3)
This handles local includes ignores.

(4)
Here we add include directives for external h files. Note that we do not
do any modifications to the external path elements as it is supposed that
they were modified in the appropriate way for inclusiong.

(5)
Here we add the development include directives. Note that we add the type
prefix to the directives so that people in the baseline will not need to
explicitly write it in their sources. Also note that we removing these leading
paths because we want the dependency information to be independant of whether
the files involved are in the development, branch or baseline directories.

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

	0.00 MV perl order in packages
	0.01 MV remove old c++ files
	0.02 MV convert dtd to html
	0.03 MV perl packaging
	0.04 MV BuildInfo object change
	0.05 MV xml encoding
	0.06 MV md5 project
	0.07 MV database
	0.08 MV perl module versions in files
	0.09 MV movies and small fixes
	0.10 MV thumbnail user interface
	0.11 MV more thumbnail issues
	0.12 MV website construction
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Utils(3), Meta::Utils::File::Patho(3), Meta::Utils::File::Remove(3), Meta::Utils::List(3), Meta::Utils::Options(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-fix the actual descision making about the three flags (currently there is no descision making and no special lists...)

-each time the module is run it re-reads the params file. Do the reading in a begin block or use a general parameter passing scheme.

-this module is dependant on a binary for its installation. Make it explicit. Also don't hardcode the binary path here.

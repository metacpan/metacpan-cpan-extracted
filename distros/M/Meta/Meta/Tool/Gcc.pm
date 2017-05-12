#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Gcc;

use strict qw(vars refs subs);
use XML::DOM qw();
use Meta::Utils::System qw();
use Meta::Baseline::Arch qw();
use Meta::Utils::Unix qw();
use Meta::Utils::Output qw();
use Meta::Tool::Gcc qw();
use Meta::Utils::Options qw();
use Meta::Lang::Cpp::Libs qw();
use Meta::Utils::File::Patho qw();
use Meta::Development::Module qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw();

#sub BEGIN();
#sub get_path();
#sub get_version();
#sub get_dom($);
#sub link($$$$$$$$$$$$$$$$);
#sub your_proc($);
#sub compile($);
#sub TEST($);

#__DATA__

our($gcc_compiler,$gcc_path,$gpp_compiler,$gpp_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$gcc_compiler=$patho->resolve("gcc");
	$gcc_path=$patho->path_to("gcc");
	$gpp_compiler=$patho->resolve("g++");
	$gpp_path=$patho->path_to("g++");
	#$gcc_path="/usr/bin";
}

sub get_path() {
	return($gcc_path);
}

sub get_version() {
	my($output)=Meta::Utils::System::system_out($gcc_compiler,["--version"]);
	chop($$output);
	return($$output);
}

sub get_dom($) {
	my($errors)=@_;
	Meta::Utils::Output::print($errors);
	my($retu)=XML::DOM::Document->new();
	my($el_errors)=$retu->createElement("errors");
	$retu->appendChild($el_errors);
	my(@lines)=split('\n',$errors);
	for(my($i)=0;$i<=$#lines;$i++) {
		my($curr)=$lines[$i];
		# skip stupid message by the compiler
		if($curr eq "cc1plus: warnings being treated as errors") {
			next;
		}
		# skip source files (actually I do need to do something about
		# that...).
		if($curr=~/^In file included from /) {
			next;
		}
		my($el_error)=$retu->createElement("error");
		$el_errors->appendChild($el_error);
		my($el_file)=$retu->createElement("file");
		$el_error->appendChild($el_file);
		my($el_line)=$retu->createElement("line");
		$el_error->appendChild($el_line);
		my($el_char)=$retu->createElement("char");
		$el_error->appendChild($el_char);
		my($el_text)=$retu->createElement("text");
		$el_error->appendChild($el_text);
		my(@fields)=split(':',$curr);
		if($#fields!=2) {
#			throw Meta::Error::Simple("what line is [".$curr."]\n");
			next;
#			throw Meta::Error::Simple("what kind of gcc output is [".$curr."]");
		}
		my($file)=$fields[0];
		my($line)=$fields[1];
		my($char)="unknown";
		my($text)=$fields[2];
		my($text_file)=$retu->createTextNode($file);
		$el_file->appendChild($text_file);
		my($text_line)=$retu->createTextNode($line);
		$el_line->appendChild($text_line);
		my($text_char)=$retu->createTextNode($char);
		$el_char->appendChild($text_char);
		my($text_text)=$retu->createTextNode($text);
		$el_text->appendChild($text_text);
	}
	return($retu);
}

sub link($$$$$$$$$$$$$$$$) {
	my($verb,$demo,$proc,$trg0,$trg1,$trg2,$trg3,$src0,$src1,$src2,$src3,$prm0,$prm1,$prm2,$prm3,$path)=@_;
	my($module)=Meta::Development::Module->new_name("data/baseline/cook/ccxx.txt");
	my($options)=Meta::Utils::Options->new_modu($module);
	my($einc)=$options->get("base_cook_lang_ccxx_incl");
	my($elib)=$options->get("base_cook_lang_ccxx_link");

	my($targ)=$trg0;
	my(@objs)=split(":",$src0);
	my(@libs)=split(":",$src1);
	my(@rlib)=split(":",$prm0);
	my(@rpth)=split(":",$prm1);
	my(@pths)=split(":",$path);
	my(@args);

	#$verb=1;

	if($verb) {
		Meta::Utils::Output::print("verb is [".$verb."]\n");
		Meta::Utils::Output::print("demo is [".$demo."]\n");
		Meta::Utils::Output::print("proc is [".$proc."]\n");
		Meta::Utils::Output::print("trg0 is [".$trg0."]\n");
		Meta::Utils::Output::print("trg1 is [".$trg1."]\n");
		Meta::Utils::Output::print("trg2 is [".$trg2."]\n");
		Meta::Utils::Output::print("trg3 is [".$trg3."]\n");
		Meta::Utils::Output::print("src0 is [".$src0."]\n");
		Meta::Utils::Output::print("src1 is [".$src1."]\n");
		Meta::Utils::Output::print("src2 is [".$src2."]\n");
		Meta::Utils::Output::print("src3 is [".$src3."]\n");
		Meta::Utils::Output::print("prm0 is [".$prm0."]\n");
		Meta::Utils::Output::print("prm1 is [".$prm1."]\n");
		Meta::Utils::Output::print("prm2 is [".$prm2."]\n");
		Meta::Utils::Output::print("prm3 is [".$prm3."]\n");
		Meta::Utils::Output::print("path is [".$path."]\n");
		Meta::Utils::Output::print("number of objs is [".$#objs."]\n");
		Meta::Utils::Output::print("number of libs is [".$#libs."]\n");
		Meta::Utils::Output::print("number of rlib is [".$#rlib."]\n");
		Meta::Utils::Output::print("number of rpth is [".$#rpth."]\n");
		Meta::Utils::Output::print("number of pths is [".$#pths."]\n");
		Meta::Utils::Output::print("objs is [".join(":",@objs)."]\n");
		Meta::Utils::Output::print("libs is [".join(":",@libs)."]\n");
		Meta::Utils::Output::print("rlib is [".join(":",@rlib)."]\n");
		Meta::Utils::Output::print("rpth is [".join(":",@rpth)."]\n");
		Meta::Utils::Output::print("pths is [".join(":",@pths)."]\n");
	}
	my($arch)=Meta::Baseline::Arch->new();
	$arch->analyze($proc);
	my($cpu)=$arch->get_cpu();
	my($os)=$arch->get_os();
	my($os_version)=$arch->get_os_version();
	my($compiler)=$arch->get_compiler();
	#Meta::Utils::Output::print("compiler is [".$compiler."]\n");
	my($compiler_version)=$arch->get_compiler_version();
	my($flagset_primary)=$arch->get_flagset_primary();
	my($flagset_secondary)=$arch->get_flagset_secondary();
	my($dire)=$arch->get_dire();
	my($ldir)=$arch->get_dll_directory();

	# Put type specific flags here

	if($flagset_primary eq "bin") {
	}
	if($flagset_primary eq "dll") {
		push(@args,"-shared");
	}
	if($flagset_primary eq "lib") {
	}

	# lets set the program to run for the compiler wanted

	my($prog)=$compiler;

	# Put flagset specifics here

	if($flagset_secondary eq "opt") {
		push(@args,"-s");
	}
	if($flagset_secondary eq "dbg") {
	}
	if($flagset_secondary eq "prf") {
	}

	push(@args,"-o");
	push(@args,$targ);
	push(@args,@objs);
	for(my($i)=0;$i<=$#pths;$i++) {
		push(@args,"-L".$pths[$i]."/".$ldir);
		#push(@args,"-Xlinker","-rpath","-Xlinker",$pths[$i]."/".$ldir);
	}
	for(my($i)=0;$i<=$#libs;$i++) {
		my($clib)=$libs[$i];
		my($name)=Meta::Utils::Unix::file_to_libname($clib);
		push(@args,"-l".$name);
	}

=begin COMMENT

#	this is more complex code to push the "-lbaseline lib" flags
#	which does an exact matching according to the search path.
#	this is the code we are supposed to use but it has to be ported
#	to use the utilities provided by Meta::Utils::Unix
	for(my($i)=0;$i<=$#libs;$i++) {
		my($clib)=$libs[$i];
		# handle relative and absolute libs paths
		my($stri)=$dire."\/lib(.*)\.so";
		if($clib=~/^$stri$/) {
			my($curr)=($clib=~/^$stri$/);
			push(@args,"-l".$curr);
		} else {
			my($found)=0;
			for(my($j)=0;$j<=$#pths && !$found;$j++) {
				my($cpth)=$pths[$j];
				my($stri)=$cpth."\/".$dire."\/lib(.*)\.so";
				if($clib=~/^$stri$/) {
					my($curr)=($clib=~/^$stri$/);
					push(@args,"-l".$curr);
					$found=1;
				}
			}
			if(!$found) {
				throw Meta::Error::Simple("cant match library [".$clib."]");
			}
		}
	}

=cut

	for(my($i)=0;$i<=$#rpth;$i++) {
		push(@args,"-L".$rpth[$i]);
	}
	my(@elib)=split(':',$elib);
	for(my($i)=0;$i<=$#elib;$i++) {
		push(@args,"-L".$elib[$i]);
	}
	my($obje)=Meta::Lang::Cpp::Libs->new();
	for(my($i)=0;$i<=$#rlib;$i++) {
		my($curr)=$rlib[$i];
		push(@args,"-l".$rlib[$i]);
		if($obje->node_has($curr)) {
			my($edges)=$obje->edge_ou($curr);
			for(my($j)=0;$j<$edges->size();$j++) {
				my($clib)=$edges->elem($j);
		#		Meta::Utils::Output::print("pushing [".$clib."]\n");
				push(@args,"-l".$clib);
			}
		} else {
			Meta::Utils::Output::print("node [".$curr."] does not exist in lib graph\n");
			return(0);
		}
	}
	if($verb) {
		Meta::Utils::Output::print("prog is [".$prog."]\n");
		for(my($i)=0;$i<=$#args;$i++) {
			Meta::Utils::Output::print("arg [".$i."] is ".$args[$i]."\n");
		}
	}
	my($scod)=Meta::Utils::System::system_nodie($gcc_path."/".$prog,\@args);
	return($scod);
}

sub your_proc($) {
	my($proc)=@_;
	return(1);
}

sub compile($) {
	my($buil)=@_;
	my($modu)=$buil->get_modu();
	my($srcx)=$buil->get_srcx();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my(@comps)=split('/',$targ);
	my($dire)=join('/',$comps[0],$comps[1]);
#	Meta::Utils::Output::print("dire is [".$dire."]\n");
	my($module)=Meta::Development::Module->new_name("data/baseline/cook/ccxx.txt");
	my($options)=Meta::Utils::Options->new_modu($module);
	my($einc)=$options->get("base_cook_lang_ccxx_incl");
	my($elib)=$options->get("base_cook_lang_ccxx_link");
#	Meta::Utils::Output::print("ccxx is [".$srcx."]\n");
#	Meta::Utils::Output::print("objx is [".$targ."]\n");
#	Meta::Utils::Output::print("dire is [".$dire."]\n");
#	Meta::Utils::Output::print("path is [".$path."]\n");
#	Meta::Utils::Output::print("einc is [".$einc."]\n");
#	Meta::Utils::Output::print("elib is [".$elib."]\n");
	my($arch_o)=Meta::Baseline::Arch->new();
	$arch_o->from_dire($dire);
	my($prog)=$arch_o->get_compiler();
	my($pref);
	my($foun)=0;
	if(!$foun) {
		if($prog eq "gcc") {
			$pref="cxxx";
			$foun=1;
		}
	}
	if(!$foun) {
		if($prog eq "g++") {
			$pref="ccxx";
			$foun=1;
		}
	}
	if(!$foun) {
		throw Meta::Error::Simple("what exactly do you want me to compile ?");
	}

	my($os)=$arch_o->get_os();
	my($cpu)=$arch_o->get_cpu();
	my($compiler)=$arch_o->get_compiler();
	my($compiler_version)=$arch_o->get_compiler_version();
	my($type)=$arch_o->get_flagset_primary();
	my($flag)=$arch_o->get_flagset_secondary();

	my(@args);
	push(@args,$srcx);
	push(@args,"-o");
	push(@args,$targ);
	if($type eq "pre") {
		if($prog eq "g++") {
			push(@args,"-E");
			if($flag eq "dbg") {
				push(@args,"-DDBG_ON=1");
			}
			if($flag eq "opt") {
				push(@args,"-DDBG_ON=0");
			}
			if($flag eq "prf") {
				push(@args,"-DDBG_ON=0");
			}
		}
		if($prog eq "gcc") {
			push(@args,"-E");
			if($flag eq "dbg") {
				push(@args,"-DDBG_ON=1");
			}
			if($flag eq "opt") {
				push(@args,"-DDBG_ON=0");
			}
			if($flag eq "prf") {
				push(@args,"-DDBG_ON=0");
			}
		}
	}
	if($type eq "obj") {
		if($prog eq "g++") {
			push(@args,"-c");
			push(@args,"-pipe");
			push(@args,"-fPIC");
			push(@args,"-fno-implicit-templates");
			push(@args,"-Wall");
			push(@args,"-Wpointer-arith");
			push(@args,"-Wmissing-declarations");
			push(@args,"-Wmissing-prototypes");
#	no longer supported by gcc (as of 3.2)
#			push(@args,"-Wid-clash-16");
			push(@args,"-Wstrict-prototypes");
			push(@args,"-Wnested-externs");
			push(@args,"-Wwrite-strings");
			push(@args,"-Werror");
			push(@args,"-Wunknown-pragmas");
			push(@args,"-ansi");
#	was removed because gnomemm headers do that
#			push(@args,"-Woverloaded-virtual");
#	was removed bacause mysql++ headers request inlines of stuff which
#	the compiler cant do (that is the meaning of the warning).
#			push(@args,"-Winline");
#	was removed because the Cwd library wanted rtti
#			push(@args,"-fno-rtti");
#	was removed bacause of the mysql++ library
#			push(@args,"-fno-exceptions");
#	was removed because that mysql.h has problems with it
#			push(@args,"-pedantic-errors");
#	was removed because it does not allow '#if [name]' when the name name
#	is not defined and LEDA headers are full of those
#			push(@args,"-Wundef");
#	was removed bacause system headers are full of those (declaring the
#	same function twice or more...).
#			push(@args,"-Wredundant-decls");
			if($flag eq "dbg") {
				push(@args,"-DDBG_ON=1");
				push(@args,"-ggdb3");
			}
			if($flag eq "opt") {
				push(@args,"-DDBG_ON=0");
				push(@args,"-O3");
				push(@args,"-march=".$cpu);
			}
			if($flag eq "prf") {
				push(@args,"-DDBG_ON=0");
				push(@args,"-pg");
			}
		}
		if($prog eq "gcc") {
			push(@args,"-c");
			push(@args,"-pipe");
			push(@args,"-fPIC");
			push(@args,"-Wall");
			push(@args,"-Wstrict-prototypes");
			push(@args,"-Wnested-externs");
			push(@args,"-Wwrite-strings");
			push(@args,"-Werror");
			push(@args,"-Wunknown-pragmas");
			push(@args,"-ansi");
			if($flag eq "dbg") {
				push(@args,"-DDBG_ON=1");
				push(@args,"-ggdb3");
			}
			if($flag eq "opt") {
				push(@args,"-DDBG_ON=0");
				push(@args,"-O3");
				push(@args,"-march=".$cpu);
			}
			if($flag eq "prf") {
				push(@args,"-DDBG_ON=0");
				push(@args,"-pg");
			}
		}
	}
#	now handle the include paths
	my(@path)=split(':',$path);
	for(my($i)=0;$i<=$#path;$i++) {
		push(@args,"-I");
		push(@args,$path[$i]."/".$pref);
	}
	my(@einc)=split(':',$einc);
	for(my($i)=0;$i<=$#einc;$i++) {
		push(@args,"-I");
		push(@args,$einc[$i]);
	}
#	Meta::Utils::Output::print("ccxx is [".$srcx."]\n");
#	Meta::Utils::Output::print("objx is [".$targ."]\n");
#	Meta::Utils::Output::print("type is [".$type."]\n");
#	Meta::Utils::Output::print("dire is [".$dire."]\n");
#	Meta::Utils::Output::print("path is [".$path."]\n");
#	Meta::Utils::Output::print("einc is [".$einc."]\n");
#	Meta::Utils::Output::print("elib is [".$elib."]\n");
	my($exe)=$gcc_path."/".$prog;
#	Meta::Utils::Output::print("exe is [".$exe."]\n");
#	for(my($i)=0;$i<=$#args;$i++) {
#		Meta::Utils::Output::print("arg [".$i."] is [".$args[$i]."]\n");
#	}
	my($text);
	my($scod)=Meta::Utils::System::system_err_nodie(\$text,$exe,\@args);
	if(!$scod) {
		Meta::Utils::Output::print("errors are [".$text."]\n");
		#my($dom)=Meta::Tool::Gcc::get_dom($text);
		#Meta::Utils::Output::print($dom->toString());
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	Meta::Utils::Output::print("path is [".&get_path()."]\n");
	Meta::Utils::Output::print("version is [".&get_version()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Gcc - tool for running gcc.

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

	MANIFEST: Gcc.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Gcc qw();
	my($object)=Meta::Tool::Gcc->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This tool will run gcc for you, analyze errors etc...
This is a library to help call the gcc compiler,linker,preprocessor etc...
The most interesting thing about it is the link routine.

The idea is to have a robust object oriented module to call gcc for you
and to know which flags gcc has so you won't have to know all the weird
gcc command line interface. If gcc ever supply a library which does
compilations it will be even better but I may be dreaming here.

This module will also analyze the errors coming out of gcc and deduce
the erroneous lines and will give you a dom object with all the errors.
You could use this object in an IDE environment for instance to place
them in a box and move the cursor to the location of the error...
Other uses may be colorizing the output on the console screen.

=head1 FUNCTIONS

	BEGIN()
	get_path()
	get_version()
	get_dom($)
	link($$$$$$$$$$$$$$$$)
	your_proc($)
	compile($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Setup method for this class which sets up the path to gcc.

=item B<get_path()>

This method will return the absolute path of the compiler.

=item B<get_version()>

This method will return the version of Gcc currently in use.

=item B<get_dom($)>

This method gets output from gcc and creates a DOM object which represents
the errors.

=item B<link($$$$$$$$$$$$$$$$)>

Link a gcc executable. This method has too many arguments to describe.

=item B<your_proc($)>

This routine will return a true answer only if the procedure described is
one which is handled by the linker.

=item B<compile($)>

This is the actual compilation process using Gcc.

Guideline about C++ compiler flags:
In general we should try to turn off all warning for public headers
and use as much as possible once the compiler gets in our code
oren also used "-fshort-enums" here - I'm not sure we should use it and
I've taken it off. The compiler knows best about -f flags is my
strategy. The reason for this is that 32 bit enums might be the best in
terms of speed performance and making them short will make structures
not 32 bit aligned which will slow things up. The only -f flags Im
using are the ones for major feature that we do not use like exceptions
and rtti (real time type information which is another big pimple on
the butt of C++...).

There are a lot of warnings which I turned off mainly because of system or
library headers which we use which violate those. We should find a way to
make these flags apply only for our code and not for the external code.
As far as I know gcc does not have this option yet so these are removed
for now.

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

	0.00 MV get imdb ids of directors and movies
	0.01 MV perl order in packages
	0.02 MV remove old c++ files
	0.03 MV c++ stuff
	0.04 MV xml/rpc client/server
	0.05 MV pics with db support
	0.06 MV publish gz on the internet
	0.07 MV convert dtd to html
	0.08 MV add sdl and sdl sample
	0.09 MV more examples
	0.10 MV c++ framework stuff
	0.11 MV writing papers
	0.12 MV perl packaging
	0.13 MV BuildInfo object change
	0.14 MV md5 project
	0.15 MV database
	0.16 MV perl module versions in files
	0.17 MV movies and small fixes
	0.18 MV thumbnail project basics
	0.19 MV thumbnail user interface
	0.20 MV import tests
	0.21 MV dbman package creation
	0.22 MV more thumbnail issues
	0.23 MV website construction
	0.24 MV web site automation
	0.25 MV SEE ALSO section fix
	0.26 MV bring movie data
	0.27 MV teachers project
	0.28 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Arch(3), Meta::Development::Module(3), Meta::Lang::Cpp::Libs(3), Meta::Tool::Gcc(3), Meta::Utils::File::Patho(3), Meta::Utils::Options(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Unix(3), XML::DOM(3), strict(3)

=head1 TODO

-add coloring of '` messages

-add stripping

-add generating preprocessed h files.

-add generating dependencies for cc and hh files using gcc.

-fix the fact that Im matching libraries against a prototype of (somethig)/gcc/dbg/lib(something).so It should be against the change or the baseline (actually the path according to order...).

-get the path for the compiler out of here and into some options file.

-get a lot of other things into option files.

-the dep graph just looks one level deep - it needs to look at all levels.

-library versions!!!

-add it so this module will know which flags gcc has and will check that you are using the right ones.

-add it so this module could give a caption of the command line used to generate an object so that this command line could be saved so if it changes the object could be regenerated.

-stop reading the options every time!!! read it on startup.

-use enumerations for the types here (dbg,opt etc...).

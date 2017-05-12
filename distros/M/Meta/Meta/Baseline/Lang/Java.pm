#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Java;

use strict qw(vars refs subs);
use Meta::Utils::File::Path qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Utils qw();
use Meta::Utils::File::Mkdir qw();
use Meta::Utils::File::Move qw();
use Meta::Baseline::Lang qw();
use Meta::Utils::Output qw();
use Meta::Utils::Env qw();

our($VERSION,@ISA);
$VERSION="0.40";
@ISA=qw(Meta::Baseline::Lang);

#sub get_jars();
#sub env();
#sub c2deps($);
#sub c2clas($);
#sub c2html($);
#sub c2chec($);
#sub class2file($);
#sub my_file($$);
#sub TEST($);

#__DATA__

sub get_jars() {
	my($jar0)=Meta::Baseline::Aegis::which("java/jars/classes12.jar");
	my($jar1)=Meta::Baseline::Aegis::which("java/jars/jaxp.jar");
	my($jar2)=Meta::Baseline::Aegis::which("java/jars/parser.jar");
	my($jar3)=Meta::Baseline::Aegis::which("java/jars/servlet.jar");
	return(join(':',$jar0,$jar1,$jar2,$jar3));
}

sub env() {
	my(%hash);
	my($class)="";
	my($sear)=Meta::Baseline::Aegis::search_path_list();
	for(my($i)=0;$i<=$#$sear;$i++) {
		my($curr)=$sear->[$i];
		$class=Meta::Utils::File::Path::add_path($class,
			$curr."/java/lib",":");
		$class=Meta::Utils::File::Path::add_path($class,
			$curr."/java/import/lib",":");
	}
	$hash{"CLASSPATH"}=$class;
	return(\%hash);
}

sub c2deps($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	open(FILE,"> ".$targ) || throw Meta::Error::Simple("unable to open file [".$targ."]");
	Meta::Baseline::Utils::cook_emblem_print(*FILE);
	print FILE "cascade ".$srcx."=\n";
	my($obje)=Meta::Utils::Parse::Text->new();
	$obje->init_file($srcx);
	while(!$obje->get_over()) {
		my($line)=$obje->get_line();
		if($line=~/^import meta\..*;$/) {
#			Meta::Utils::Output::print("line is [".$line."]\n");
			my($class)=($line=~/^import (.*);$/);
			my($file)=class2file($class);
			print FILE $file."\n";
		}
		$obje->next();
	}
	$obje->fini();
	print FILE ";\n";
	close(FILE) || throw Meta::Error::Simple("unable to close file [".$targ."]");
	return(1);
}

sub c2clas($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($jarx)=get_jars();
	my(@lptc)=split(":",$path);
	my(@lpts)=split(":",$path);
	for(my($i)=0;$i<=$#lptc;$i++) {
		$lptc[$i].="/clas/java/lib";
		$lpts[$i].="/java/lib";
#		Meta::Utils::File::Mkdir::mkdir_check($lptc[$i]);
	}
	my($pthc)=join(":",$jarx,@lptc);
	my($pths)=join(":",$jarx,@lpts);
	my($prog)="/local/tools/j2sdk1.4.1_01/bin/javac";
	my(@args);
	push(@args,"-O");
	# Add this if you want errors about deprecated features.
	# push(@args,"-deprecation");
	push(@args,"-nowarn");
	push(@args,"-classpath");
	push(@args,$pthc);
	push(@args,"-sourcepath");
	push(@args,$pths);
	push(@args,"-d");
	push(@args,"clas/java/lib");
	push(@args,$srcx);
	if(0) {
		for(my($i)=0;$i<=$#args;$i++) {
			Meta::Utils::Output::print("arg [".$i."] is [".$args[$i]."]\n");
		}
	}
	my($scod)=Meta::Utils::System::system_nodie($prog,\@args);
#	if($scod) {
#		my($name,$path,$suff)=File::Basename::fileparse($srcx,"\.java");
#		my($crea)=$path.$name.".class";
#		Meta::Utils::File::Move::mv($crea,$targ);
#	}
	return($scod);
#	open(FILE,"> ".$targ) || throw Meta::Error::Simple("unable to open file [".$targ."]");
#	Meta::Baseline::Utils::cook_emblem_print(*FILE);
#	close(FILE) || throw Meta::Error::Simple("unable to close file [".$targ."]");
#	return(1);
}

sub c2html($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($targ)=$buil->get_targ();
	my($path)=$buil->get_path();
	my($dire)=File::Basename::dirname($targ);
	my($scod)=Meta::Utils::System::system_err_silent_nodie("javadoc",[$srcx,"-d","html/java/lib","-classpath",$path,"-noindex"]);
	#if(!(-f $targ)) {
	#	Meta::Baseline::Utils::file_emblem($targ);
	#}
	return($scod);
}

sub c2chec($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub class2file($) {
	my($class)=@_;
#	Meta::Utils::Output::print("class is [".$class."]\n");
	$class=~s/\./\//g;
	$class="java/lib/".$class.".java";
	return($class);
}

sub my_file($$) {
	my($self,$file)=@_;
	if($file=~/^java\/.*\.java$/) {
		return(1);
	}
	if($file=~/^java\/.*\.jar$/) {
		return(1);
	}
	return(0);
}

sub TEST($) {
	my($context)=@_;
	my($hash)=Meta::Baseline::Lang::Java::env();
	Meta::Utils::Env::bash_cat($hash);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Java - doing Java specific stuff in the baseline.

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

	MANIFEST: Java.pm
	PROJECT: meta
	VERSION: 0.40

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Java qw();
	my($resu)=Meta::Baseline::Lang::Java::env();

=head1 DESCRIPTION

This package contains stuff specific to Java in the baseline:
0. produce code to set Java specific vars in the baseline.
1. check Java files for correct Java syntax in the baseline.
	0. produce minimal java usage.
	1. check no numbers are in the code.
	2. check correct customs for package names (all lower letter alpha
		caracters and numbers with no special chars separatered
		by ".").
	etc...


=head1 FUNCTIONS

	get_jars()
	env()
	c2deps($)
	c2clas($)
	c2html($)
	c2chec($)
	class2file($)
	my_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_jars()>

This routine return a path segment to be added to java tool running in order
for all baseline jars to be considered.

=item B<env()>

This routine returns a hash of environment variables which are essential for
running Java binaries.

=item B<c2deps($)>

This routine will produce a file desribing the dependencies of the java source
file to the cook mechanism.
This method returns an error code.

=item B<c2clas($)>

This routine will compile the java file.
This method returns an error code.

=item B<c2html($)>

This routine will create an html document from the java source file using
java doc.
This method returns an error code.

=item B<c2chec($)>

This routine will apply different validataion methods on the source code which
the compiler does not apply.
This method returns an error code.

=item B<class2file($)>

This method will convert a java class name to a file.

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

=item B<TEST($)>

Test suite for this module.
This currently just runs the Env stuff and checks whats the output bash script.

=back

=begin COMMENT

old code from old compilation of java:

This is the call to our Java compiler.
Other options include:
	Kaffe - kjc (this is implemented).
	gcc java front end - gcj.
	sun 1.2 standard - javac.
	jikes - jikes.
	blackdown.
	IBM.
This receives:
0. .java source files to compile.
1. path to put classes in (relative to root package).
2. class path to use for compilation.

This should activate the compiler with maximum errors turned on.
This should !!!not!!! compile anything except the source ".java" required.
This should !!!not!!! generate any dependency information.
This should !!!not!!! generate any javadoc information.

Notes on the Kaffe compiler:
The documentation for it on the usage command line is a bit off:
	B<--strict> is not an option (although it says so...)
	B<--dest> should be used for the destination directory (altough
		it says that B<-d> should do the trick...).
	B<--warning> seems nice but doesnt work. for instance, if you
		do not use an argument passed on to you in a function,
		kjc will compain about it. On the other hand, it doesnt
		allow you to remove the name of the argument!!
		Thats why I'm not using it.

-This script needs to receive a target directory and not a target class since
a single java source can produce many .class files in the same directory.

-Move all the code here to some module and create a module for each compiler.

-Add optimized vs non-optimized modes.

C<
my($pthc)=join
(
	":",
	"/usr/share/kaffe/Klasses.jar",
	$path
);
my($code)=Meta::Utils::System::system_nodie("kjc",["--dest",$dest,"--classpath",$pthc,"--deprecation","-O2",$srcx]);
>

=cut

=head1 SUPER CLASSES

Meta::Baseline::Lang(3)

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
	0.06 MV fix small problems and update java
	0.07 MV correct die usage
	0.08 MV text change
	0.09 MV make java compilation real
	0.10 MV Java compilation
	0.11 MV finish Simul documentation
	0.12 MV perl quality change
	0.13 MV perl code quality
	0.14 MV more perl quality
	0.15 MV more perl quality
	0.16 MV perl documentation
	0.17 MV more perl quality
	0.18 MV perl qulity code
	0.19 MV more perl code quality
	0.20 MV revision change
	0.21 MV better general cook schemes
	0.22 MV revision in files
	0.23 MV revision for perl files and better sanity checks
	0.24 MV languages.pl test online
	0.25 MV web site and docbook style sheets
	0.26 MV perl packaging
	0.27 MV BuildInfo object change
	0.28 MV xml encoding
	0.29 MV md5 project
	0.30 MV database
	0.31 MV perl module versions in files
	0.32 MV movies and small fixes
	0.33 MV thumbnail user interface
	0.34 MV more thumbnail issues
	0.35 MV website construction
	0.36 MV web site development
	0.37 MV web site automation
	0.38 MV SEE ALSO section fix
	0.39 MV put all tests in modules
	0.40 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::Utils::Env(3), Meta::Utils::File::Mkdir(3), Meta::Utils::File::Move(3), Meta::Utils::File::Path(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-actually do the dependency calculations (they are not done now).

-any other types of java documentation we can support ?

-methods to do the dependency calculation could be: use jikes that knows how to
produce them, use the SUN compiler, use a perl parser, use the java builtin parser.

-stop hardcoding the java jars here !!!

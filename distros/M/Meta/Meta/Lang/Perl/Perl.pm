#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Perl;

use strict qw(vars refs subs);
use Meta::Utils::Utils qw();
use Meta::Utils::System qw();
use ExtUtils::MakeMaker qw();
use ExtUtils::MM_Unix qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::Progname qw();
use Meta::Utils::File::File qw();
use Pod::POM qw();
use Symbol qw();
use Meta::Module::Info qw();
use Meta::Utils::File::Patho qw();
use Error qw(:try);
#use Pod::POM::View::Pod qw();

our($VERSION,@ISA);
$VERSION="0.17";
@ISA=qw();

#sub BEGIN();
#sub is_perl($);
#sub is_lib($);
#sub is_bin($);
#sub is_test($);
#sub get_prefix_lib();
#sub get_prefix_bin();
#sub remove_prefix_lib($);
#sub remove_prefix_bin($);
#sub remove_prefix($);
#sub get_version_mm($);
#sub get_version_mm_unix($);
#sub get_version($);
#sub load_module($);
#sub unload_module($);
#sub call_method($$$);
#sub get_module_isa($);
#sub get_module_see($);
#sub get_file_isa($);
#sub get_file_see($);
#sub get_module_pod_isa($);
#sub get_module_pod_see($);
#sub get_file_pod_isa($);
#sub get_file_pod_see($);
#sub run($);
#sub profile($);
#sub man($);
#sub man_file($);
#sub man_deve($);
#sub module_to_file($);
#sub module_to_search_file($);
#sub file_to_module($);
#sub module_to_link($);
#sub get_pods($);
#sub get_pods_new($);
#sub get_name($);
#sub get_my_pod($);
#sub get_my_name($);
#sub get_use_text($);
#sub get_use($);
#sub TEST($);

#__DATA__

my($tool_path,$perldoc_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("perl");
	$perldoc_path=$patho->resolve("perldoc");
}

sub is_perl($) {
	my($file)=@_;
	return(is_lib($file) || is_bin($file));
}

sub is_lib($) {
	my($file)=@_;
	return($file=~/\.pm$/);
}

sub is_bin($) {
	my($file)=@_;
	return($file=~/\.pl$/);
}

sub is_test($) {
	my($file)=@_;
	return($file=~/perl\/bin\/Meta\/Tests\//);
}

sub get_prefix_lib() {
	return("perl/lib/");
}

sub get_prefix_bin() {
	return("perl/bin/");
}

sub remove_prefix_lib($) {
	my($modu)=@_;
	return(Meta::Utils::Utils::minus($modu,&get_prefix_lib()));
}

sub remove_prefix_bin($) {
	my($modu)=@_;
	return(Meta::Utils::Utils::minus($modu,&get_prefix_bin()));
}

sub remove_prefix($) {
	my($modu)=@_;
	if(&is_lib($modu)) {
		return(&remove_prefix_lib($modu));
	}
	if(&is_bin($modu)) {
		return(&remove_prefix_bin($modu));
	}
	throw Meta::Error::Simple("what the hell is [".$modu."]");
}

sub get_version_mm($) {
	my($file)=@_;
	#we build an object every time. Yes. It's wasteful.
	my($mm)=ExtUtils::MakeMaker->new();
	my($version)=$mm->parse_version($file);
	#this commented method doesnt work since parse_version isnt
	#realy a method of ExtUtils::MakeMaker.
	#my($version)=ExtUtils::MakeMaker->parse_version($file);
	if(!defined($version)) {
		return(0);
		#throw Meta::Error::Simple('what version is [".$file."]");
	} else {
		#Meta::Utils::Output::print("got version [".$version."] for module [".$file."]\n");
	}
	return($version);
}

sub get_version_mm_unix($) {
	my($file)=@_;
	my($version)=ExtUtils::MM_Unix->parse_version($file);
	if(!defined($version)) {
		return(0);
		#throw Meta::Error::Simple("what version is [".$file."]");
	} else {
		#Meta::Utils::Output::print("got version [".$version."] for module [".$file."]\n");
	}
	return($version);
}

sub get_version($) {
	my($file)=@_;
	my($module)=file_to_module($file);
	return(get_version_module($module));
}

sub get_version_module($) {
	my($module)=@_;
	no strict 'refs';
	load_module($module);
	my($versionref)=*{$module."::VERSION"}{SCALAR};
	my($version)=$$versionref;
	#use strict 'refs';
	return($version);
}

sub load_module($) {
	my($module)=@_;
	eval "require ".$module;
	if($@) {
		throw Meta::Error::Simple("unable to load module [".$module."] with error [".$@."]");
	}
}

sub unload_module($) {
	my($module)=@_;
	my($res)=Symbol::delete_package($module);
	return($res);
}

sub call_method($$$) {
	my($module,$method,$args)=@_;
	my($method)=$module."::".$method;
	my($ref)=\&{$method};
	#Meta::Utils::Output::print("ref is [".$ref."]\n");
	my($res)=&$ref($args);
	return($res);
}

sub get_module_isa($) {
	my($module)=@_;
	load_module($module);
	no strict 'refs';
	#my($isa)=*{$modu."::ISA"}{ARRAY};
	my($isa)=*{$module."::ISA"};
	#use strict 'refs';
	return($isa);
}

sub get_module_see($) {
	my($module)=@_;
	my($mod)=Meta::Module::Info->new_from_module($module);
	my(@used)=$mod->modules_used_sorted();
	return(\@used);
}

sub get_file_isa($) {
	my($file)=@_;
	my($module)=file_to_module($file);
	return(get_module_isa($module));
}

sub get_file_see($) {
	my($file)=@_;
	my($mod)=Meta::Module::Info->new_from_file($file);
	my(@used)=$mod->modules_used_sorted();
	return(\@used);
}

sub get_module_pod_isa($) {
	my($module)=@_;
	my($isa)=get_module_isa($module);
	my(@pods);
	for(my($i)=0;$i<=$#$isa;$i++) {
		my($curr)=$isa->[$i];
		push(@pods,module_to_link($curr));
	}
	my($res)=join(",\ ",@pods);
	if($res eq "") {
		return("None.");
	} else {
		return($res);
	}
}

sub get_module_pod_see($) {
	my($module)=@_;
	my($see)=get_module_see($module);
	my(@pods);
	for(my($i)=0;$i<=$#$see;$i++) {
		my($curr)=$see->[$i];
		push(@pods,module_to_link($curr));
	}
	my($res)=join(",\ ",@pods);
	if($res eq "") {
		return("None.");
	} else {
		return($res);
	}
}

sub get_file_pod_isa($) {
	my($file)=@_;
	my($module)=file_to_module($file);
	return(get_module_pod_isa($module));
}

sub get_file_pod_see($) {
	my($file)=@_;
	my($see)=get_file_see($file);
	my(@pods);
	for(my($i)=0;$i<=$#$see;$i++) {
		my($curr)=$see->[$i];
		push(@pods,module_to_link($curr));
	}
	my($res)=join(",\ ",@pods);
	if($res eq "") {
		return("None.");
	} else {
		return($res);
	}
}

sub run($) {
	my($modu)=@_;
	return(Meta::Utils::System::system_nodie($tool_path,[$modu]));
}

sub profile($) {
	my($modu)=@_;
	Meta::Utils::System::system_nodie($tool_path,["-d:DProf",$modu]);
	Meta::Utils::System::system_nodie("dprofpp",[]);
	Meta::Utils::File::Remove::rm("tmon.out");
}

sub man($) {
	my($modu)=@_;
	return(Meta::Utils::System::system_nodie($perldoc_path,[$modu]));
}

sub man_file($) {
	my($file)=@_;
	return(Meta::Utils::System::system_nodie($perldoc_path,["-F",$file]));
}

sub man_deve($) {
	my($deve)=@_;
	my($file)=Meta::Baseline::Aegis::which($deve);
	return(Meta::Utils::System::system_nodie($perldoc_path,["-F",$file]));
}

sub module_to_file($) {
	my($modu)=@_;
	$modu=~s/::/\//g;
	$modu="perl/lib/".$modu.".pm";
	return($modu);
}

sub module_to_search_file($) {
	my($modu)=@_;
	$modu=~s/::/\//g;
	$modu.=".pm";
	return($modu);
}

sub file_to_module($) {
	my($file)=@_;
	my($modu)=($file=~/^.*perl\/lib\/(.*)\.pm$/);
	$modu=~s/\//::/g;
	return($modu);
}

sub module_to_link($) {
	my($module)=@_;
	return($module."(3)");
}

sub get_pods($) {
	my($text)=@_;
	my(@lines)=split('\n',$text);
	my($size)=$#lines+1;
	my($inde)=undef;#init the variable
	my(%hash);
	for(my($i)=0;$i<$size;$i++) {
		my($curr)=$lines[$i];
		if($curr=~/^=head1 /) {
			($inde)=($curr=~/^=head1 (.*)$/);
		} else {
			if(defined($inde)) {
#				Meta::Utils::Output::print("adding [".$curr."] to [".$inde."]\n");
				if(exists($hash{$inde})) {
					$hash{$inde}.="\n".$curr;
				} else {
					$hash{$inde}=$curr;
				}
			}
		}
	}
	return(\%hash);
}

sub get_pods_new($) {
	my($text)=@_;
	my($parser)=Pod::POM->new();
	my($pom)=$parser->parse_text($text);
	if(!$pom) {
		die $parser->error();
	}
#	Meta::Utils::Output::print("pom is [".$pom->head1()."]\n");
	my($head1);
	my(%hash);
	foreach $head1 ($pom->head1()) {
		my($title)=$head1->title();
		#my($content);
		#$content=$head1->text();
		# The reason we use this Pod::POM::View::Pod module is that if
		# we use the regular ->content method as described in the Pod::POM
		# documentation the result is not a string but rather an object and
		# I see no way in the documentation to turn the object to a string.
		# The content turns itself into a string (automagically) when printed
		# and I HATE THIS!!! I HATE MAGICAL FEATURES WHICH REMOVE MY ABILITY TO
		# CONTROL THINGS!!! I want the content in a string and I can't get it...
		# that's why I use this view thingy.
		my($content)=$head1->content()->present();
		#my($content)=Pod::POM::View::Pod->print($head1);
#		Meta::Utils::Output::print("title is [".\$title."]\n");
#		Meta::Utils::Output::print("content is [".\$content."]\n");
		$hash{$title}=$content;
#		print $head1->title(),"\n";
#		print $head1->content();
	}
	return(\%hash);
}

sub get_name($) {
	my($text)=@_;
	if($text!~/^\n.* - .*\.\n$/) {
		throw Meta::Error::Simple("bad NAME pod found [".$text."]");
	}
	my($out)=($text=~/^\n.* - (.*)\.\n$/);
	return($out);
}

sub get_my_pod($) {
	my($pod_name)=@_;
	my($prog)=Meta::Utils::Progname::fullname();
	my($text);
	Meta::Utils::File::File::load($prog,\$text);
	my($pods)=Meta::Lang::Perl::Perl::get_pods($text);
	my($pod)=$pods->{$pod_name};
	return($pod);
}

sub get_my_name() {
	my($name_pod)=Meta::Lang::Perl::Perl::get_my_pod("NAME");
	my($name)=Meta::Lang::Perl::Perl::get_name($name_pod);
	return($name);
}

sub get_use_text($) {
	my($text)=@_;
	my(@lines)=split('\n',$text);
	my($size)=$#lines+1;
	my(@arra);
	for(my($i)=0;$i<$size;$i++) {
		my($line)=$lines[$i];
		if($line=~/^\s*use .*\s+qw\(.*\)\s*;\s*$/) {
			my($modu)=($line=~/^\s*use (.*)\s+qw\(.*\)\s*;\s*$/);
			push(@arra,$modu);
		}
	}
	return(\@arra);
}

sub get_use($) {
	my($file)=@_;
	my($text);
	Meta::Utils::File::File::load($file,\$text);
	return(&get_use_text($text));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Perl - tool to ease interaction with Perl.

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

	MANIFEST: Perl.pm
	PROJECT: meta
	VERSION: 0.17

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Perl qw();
	my($object)=Meta::Lang::Perl::Perl->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module eases interaction with the Perl language interpreter.

=head1 FUNCTIONS

	BEGIN()
	is_perl($)
	is_lib($)
	is_bin($)
	is_test($)
	get_prefix_lib()
	get_prefix_bin()
	remove_prefix_lib($)
	remove_prefix_bin($)
	remove_prefix($)
	get_version_mm($)
	get_version_mm_unix($)
	get_version($)
	load_module($)
	unload_module($)
	call_method($$$)
	get_module_isa($)
	get_module_see($)
	get_file_isa($);
	get_file_see($);
	get_module_pod_isa($);
	get_module_pod_see($);
	get_file_pod_isa($);
	get_file_pod_see($);
	run($)
	profile($)
	man($)
	man_file($)
	man_deve($)
	module_to_file($)
	module_to_search_file($)
	file_to_module($)
	module_to_link($)
	get_pods($)
	get_pods_new($)
	get_name($)
	get_my_name($)
	get_use_text($)
	get_use($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find the perl interpreter for you.

=item B<is_perl($)>

This method will return true iff the file in question is a perl file
(script or library).

=item B<is_lib($)>

This method receives a file name and return true if the file
is a perl library.

=item B<is_bin($)>

This method receives a file name and return true if the file
is a perl binary.

=item B<is_test($)>

This method receives a file name and returns true if the file
is a perl test file.

=item B<get_prefix_lib()>

This returns the prefix for perl modules stored in the baseline.

=item B<get_prefix_bin()>

This returns the prefix for perl binaries stored in the baseline.

=item B<remove_prefix_lib($)>

This method removes a prefix from a baseline related module.

=item B<remove_prefix_bin($)>

This method removes a prefix from a baseline related script.

=item B<remove_prefix($)>

This method receives a perl file (script or lib) and removes its prefix.

=item B<get_version_mm($)>

This method gets a filename of a perl module and returns it's version number.
This method uses ExtUtils::MakeMaker.
The actual code that ExtUtils::MakeMaker uses in from MM_Unix.
There is a problem with this method that emits strange warning.
This method returns 0 in case the version cannot be established.

=item B<get_version_mm_unix($)>

This method gets a filename of a perl module and returns it's version number.
This method calls ExtUtils::MM_Unix directly to avoid the MakeMaker warnings.
The method does not create an ExtUtils::MM_Unix object since it's method
makes no use of the object passed. This may cause problems in the future.
This method returns 0 in case the version cannot be established.

=item B<get_version($)>

This method gets a filename of a perl module and returns it's version number.
This is my own version. Unlike the MM code which parses the modules actual
text (opens the file etc...) my code loads the module (which is at least
as long) but them proceeds to get the $VERSION variable from the package using
perl reference techniques.

=item B<load_module($)>

This method will load a module.

=item B<unload_module($)>

This method will unload a module. It uses the Symbol package to do it's thing.

=item B<call_method($$$)>

This method will call the method for the package received with the arguments
received.

=item B<get_module_isa($)>

This will get the ISA part of the module which is supplied by module name.
The code loads the modules and uses references to achieve this.
The code is pretty unefficient as it loads the module and the just looks
up the ISA variable.

=item B<get_module_see($)>

This will get the use part of the module which is supplied by module name.

=item B<get_file_isa($)>

Pass this method a file name and it will return the ISA part of the module.
It just uses the get_module_isa method.

=item B<get_file_see($)>

Pass this method a file name and it will return the use part of the module.
It just uses the get_module_see method.

=item B<get_module_pod_isa($)>

This method will return the isa part of a module in a manner fitting
to be included in a POD document. You can use various automated tools
to put this automatically in your "SUPER CLASSES" section.

=item B<get_module_pod_see($)>

This method will return the usage part of a module in a mannger fitting
to be included in a POD document. You can use various automated tools
to put this automatically in your "SEE ALSO" section.

=item B<get_file_pod_isa($)>

This does exactly as get_pod_isa but for a file name only.

=item B<get_file_pod_see($)>

This does exactly as get_pod_see but for a file name only.

=item B<run($)>

Routine to run the perl script it receives as input.

=item B<profile($)>

Routine to run the perl profile on the script it receives as input.

=item B<man($)>

Routine to show a manual page of a perl module (the parameter).
The parameter is passed directly to perldoc.

=item B<man_file($)>

Routine to show a manual page of a file. The perldoc is told that
the argument is a file.

=item B<man_deve($)>

This routine will show a manual page of a development module.

=item B<module_to_file($)>

This will translate a module name to a baseline relative file name.

=item B<module_to_search_file($)>

This will translate a module name to a module file to search for (without
the perl/lib prefix...

=item B<file_to_module($)>

This will translate a file name to a module name.

=item B<module_to_link($)>

This method will translate a module name to a link which
could be put in a pod section. Currently it just adds the
"(3)" suffix to the name which could be problematic if
things change too much.

=item B<get_pods($)>

This method will extract pods from a perl source and will return them as a hash.

=item B<get_pods_new($)>

This method will extract pods from a perl text and will return them as a hash.
Intead of doing the parsing myself (which I don't like doing since I want to
make someone else do the work) I use Pod::POM.

=item B<get_name($)>

This will return the name of the executable.
Input is the NAME pod paragraph.

=item B<get_my_pod($)>

This method will retrieve the text of the pod section which has the name passed
from the current scripts source code.

=item B<get_my_name()>

This method is suitable for use by scripts who want to extract their name from their
own source. No input is reqiured since current script is assumed.

=item B<get_use_text($)>

This method receives a piece of perl code and returns an array with all modules
used by that code. The implementation currently consists of a simple parser and
is probably incorrect but good enought for what I want for now. You are welcome
to improve the implementation.

=item B<get_use($)>

This method receives a perl file name and returns an array with all the modules
used by that perl file. The implementation simply loads the file into a string
and calls the above get_use_text.

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

	0.00 MV more perl packaging
	0.01 MV perl packaging again
	0.02 MV more Perl packaging
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV graph visualization
	0.08 MV md5 progress
	0.09 MV thumbnail user interface
	0.10 MV import tests
	0.11 MV dbman package creation
	0.12 MV more thumbnail issues
	0.13 MV website construction
	0.14 MV improve the movie db xml
	0.15 MV web site automation
	0.16 MV SEE ALSO section fix
	0.17 MV md5 issues

=head1 SEE ALSO

Error(3), ExtUtils::MM_Unix(3), ExtUtils::MakeMaker(3), Meta::Module::Info(3), Meta::Utils::File::File(3), Meta::Utils::File::Patho(3), Meta::Utils::File::Remove(3), Meta::Utils::Progname(3), Meta::Utils::System(3), Meta::Utils::Utils(3), Pod::POM(3), Symbol(3), strict(3)

=head1 TODO

-write my own get_version code (simple parsing with no eval suitable for internal modules).

-the unload module function does not work well (you cannot reload the model after that). find better solutions.

-chage the _see methods to _use.

#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Deps;

use strict qw(vars refs subs);
use Meta::Development::Deps qw();
use Meta::Utils::Utils qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Meta::IO::File qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.15";
@ISA=qw();

#sub is_internal($);
#sub add_graph($);
#sub c2deps($);
#sub module_to_search_file($);
#sub module_to_file($);
#sub file_to_module($);
#sub module_to_deps($);
#sub extfile_to_module($);
#sub deps_to_module($);
#sub add_deps($$$$$);
#sub add_deps_rec($$$$$$);
#sub TEST($);

#__DATA__

sub is_internal($) {
	my($modu)=@_;
	if($modu=~/^\//) {
		return(0);
	} else {
		return(1);
	}
}

sub add_graph($$) {
	my($buil,$grap)=@_;
	my($modu)=$buil->get_modu();
	my($srcx)=$buil->get_srcx();
	my($show_internal)=1;
	my($show_external)=1;
	my($path)=join(":",@INC);
	$grap->node_insert($modu);
	my($io)=Meta::IO::File->new_reader($srcx);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
		if($line=~/^use .* qw\(.*\);$/) {
			my($cmod)=($line=~/^use (.*) qw\(.*\);$/);
			if($cmod=~/^Meta/) {#this is an internal file
				if($show_internal) {
					my($file)=module_to_file($cmod);
					$grap->node_insert($file);
					$grap->edge_insert($modu,$file);
				}
			} else {#this is an external file
				if($show_external) {
					my($search_file)=module_to_search_file($cmod);
					my($file)=Meta::Utils::File::Path::resolve($path,$search_file,":");
					$grap->node_insert($file);
					$grap->edge_insert($modu,$file);
				}
			}
		}
	}
	$io->close();
}

sub c2deps($) {
	my($buil)=@_;
	my($grap)=Meta::Development::Deps->new();
	&add_graph($buil,$grap);
	return($grap);
}

sub module_to_search_file($) {
	my($modu)=@_;
	$modu=~s/::/\//g;
	$modu.=".pm";
	return($modu);
}

sub module_to_file($) {
	my($modu)=@_;
	$modu=~s/::/\//g;
	$modu="perl/lib/".$modu.".pm";
	return($modu);
}

sub file_to_module($) {
	my($file)=@_;
	$file=~s/\//::/g;
	my($resu)=($file=~/(.*)\.pm$/);
	return($resu);
}

sub module_to_deps($) {
	my($modu)=@_;
	return("deps/".Meta::Utils::Utils::replace_suffix($modu,".deps"));
}

sub extfile_to_module($) {
	my($file)=@_;
	my($path)=join(':',@INC);
	my($remove)=Meta::Utils::File::Path::remove_path($path,':',$file);
	return(&file_to_module($remove));
}

sub deps_to_module($) {
	my($deps)=@_;
	my($module)=($deps=~/deps\/(.*)\.deps$/);
	if($module eq "") {
		throw Meta::Error::Simple("module is nothing from deps [".$deps."]");
	}
	my($suff);
	if($module=~/^perl\/bin/) {
		$suff=".pl";
	}
	if($module=~/^perl\/lib/) {
		$suff=".pm";
	}
	return($module.$suff);
}

sub deps_file_to_module($) {
	my($file)=@_;
}

sub add_deps($$$$$) {
	my($grap,$modu,$inte,$exte,$path)=@_;
	$grap->node_insert($modu);
	my($fdep)=&module_to_deps($modu);
	my($deps)=Meta::Utils::File::Path::resolve($path,$fdep,":");
	my($io)=Meta::IO::File->new_reader($deps);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
		if($line=~/^\/\*/) {#skip comment lines
			next;
		}
		if($line=~/^cascade .*=$/) {#read name of module and make sure it's the one we got
			my($node)=($line=~/^cascade (.*)=$/);
			if($node ne $modu) {
				throw Meta::Error::Simple("node [".$node."] ne modu [".$modu."]");
			}
			next;
		}
		if($line eq ";") {#skip the end line
			next;
		}
		#otherwise - its an edge-find out if we want to add it
		my($addx);
		if(&is_internal($line)) {
			$addx=$inte;
		} else {
			$addx=$exte;
		}
		if($addx) {#this is the actual addition
			$grap->node_insert($line);
			$grap->edge_insert($modu,$line);
		}
	}
	$io->close();
}

sub add_deps_rec($$$$$) {
	my($grap,$modu,$inte,$exte,$visi)=@_;
	if(!(exists($visi->{$modu}))) {
		$visi->{$modu}=defined;
		#Meta::Utils::Output::print("visiting [".$modu."]\n");
		my($path)=Meta::Baseline::Aegis::search_path();
		&add_deps($grap,$modu,$inte,$exte,$path);
		my($edge)=$grap->edge_ou($modu);
		for(my($i)=0;$i<$edge->size();$i++) {
			my($curr)=$edge->elem($i);
			#Meta::Utils::Output::print("curr is [".$curr."]\n");
			if(&is_internal($curr)) {
				add_deps_rec($grap,$curr,$inte,$exte,$visi);
			}
		}
	}
}

sub TEST($) {
	my($context)=@_;
	my($modu)="perl/lib/Meta/Utils/File/File.pm";
	my($grap)=Meta::Development::Deps->new();
	Meta::Lang::Perl::Deps::add_deps_rec($grap,$modu,1,1,{});
	Meta::Utils::Output::print("number of nodes is [".$grap->node_size()."]\n");
	Meta::Utils::Output::print("number of edges is [".$grap->edge_size()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Deps - module to help you handle perl dependency information.

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

	MANIFEST: Deps.pm
	PROJECT: meta
	VERSION: 0.15

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Deps qw();
	my($object)=Meta::Lang::Perl::Deps->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will help you extract, manipulate and print perl dependency
from actual perl source files.

=head1 FUNCTIONS

	is_internal($)
	add_graph($)
	c2deps($)
	module_to_search_file($)
	module_to_file($)
	file_to_module($)
	module_to_deps($)
	extfile_to_module($)
	deps_to_module($)
	add_deps($$$$$)
	add_deps_rec($$$$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<is_internal($)>

This method receives a module name from the DEPENDENCY files
and tells you if it is internal or not (by checking if it
is absolute or not).

=item B<add_graph($$)>

This method will add the dependency information in a single perl
file (script or module) to a graph dependency object you give it.

=item B<c2deps($)>

This method will extract a dependency graph from a perl source file.

=item B<module_to_search_file($)>

This will translate a module name to a module file to search for (without
the perl/lib prefix...

=item B<file_to_module($)>

Convert a filename for a module to its perl notation (with ::).

=item B<module_to_deps($)>

This method receives a module name and returns the deps file that
holds the dependency information for it.

=item B<extfile_to_module($)>

Convert an expternal perl module filename perl module notation.

=item B<deps_to_module($)>

This method does the reverse of module_to_deps.

=item B<deps_file_to_module($)>

This method recevies a deps file, and returns the module which it represents.

=item B<add_deps($$$$$)>

This method reads a dep file and adds it's information to a graph.

=item B<add_deps_rec($$$$$$)>

This module will create a dep graph to describe the module
and all the modules that it depends on.

=item B<TEST($)>

Test suite for this module.
Currenlty it tries to check the recursive dependencies
of a certain module.

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

	0.00 MV fix up cook files
	0.01 MV perl packaging
	0.02 MV more perl packaging
	0.03 MV perl packaging again
	0.04 MV fix database problems
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV teachers project
	0.15 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Development::Deps(3), Meta::Error::Simple(3), Meta::IO::File(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-in the c2deps method check that the source configuration management tool knows about the files
	were adding.

-were always calling Aegis::Search_path here. Optimize this (either at the aegis or this level).

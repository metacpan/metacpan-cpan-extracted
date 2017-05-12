#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Perlpkg;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Meta::Info::Author qw();
use Meta::Development::Deps qw();
use Meta::Lang::Perl::Deps qw();
use Meta::Ds::Oset qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.20";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub add_deps($$$);
#sub get_pack($);
#sub get_pack_name($);
#sub get_pack_file_name($);
#sub get_modules_dep_list($$$);
#sub get_scripts_dep_list($$$);
#sub get_tests_dep_list($$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_name",
		-java=>"_description",
		-java=>"_longdescription",
		-java=>"_license",
		-java=>"_version",
		-java=>"_uname",
		-java=>"_gname",
		-java=>"_author",
		-java=>"_modules",
		-java=>"_scripts",
		-java=>"_tests",
		-java=>"_files",
		-java=>"_credits",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_author(Meta::Info::Author->new());
	$self->set_modules(Meta::Ds::Array->new());
	$self->set_scripts(Meta::Ds::Array->new());
	$self->set_tests(Meta::Ds::Array->new());
	$self->set_files(Meta::Ds::Array->new());
	$self->set_credits(Meta::Ds::Array->new());
}

sub add_deps($$$) {
	my($self,$modu,$deps)=@_;
	my($modules)=$self->get_modules();
	for(my($i)=0;$i<$modules->size();$i++) {
		my($curr)=$modules->getx($i)->get_source();
		$deps->node_insert($curr);
		$deps->edge_insert($modu,$curr);
	}
	my($scripts)=$self->get_scripts();
	for(my($i)=0;$i<$scripts->size();$i++) {
		my($curr)=$scripts->getx($i)->get_source();
		$deps->node_insert($curr);
		$deps->edge_insert($modu,$curr);
	}
	my($tests)=$self->get_tests();
	for(my($i)=0;$i<$tests->size();$i++) {
		my($curr)=$tests->getx($i)->get_source();
		$deps->node_insert($curr);
		$deps->edge_insert($modu,$curr);
	}
	my($files)=$self->get_files();
	for(my($i)=0;$i<$files->size();$i++) {
		my($curr)=$files->getx($i)->get_source();
		$deps->node_insert($curr);
		$deps->edge_insert($modu,$curr);
	}
}

sub get_pack($) {
	my($self)=@_;
	my($retu)=$self->get_name()."-".$self->get_version();
	return($retu);
}

sub get_pack_name($) {
	my($self)=@_;
	my($retu)=$self->get_pack().".tar.gz";
	return($retu);
}

sub get_pack_file_name($) {
	my($self)=@_;
	return("pack/".$self->get_pack_name());
}

sub get_modules_dep_list($$$) {
	my($self,$inte,$exte)=@_;
	my($grap)=Meta::Development::Deps->new();
	my($list)=$self->get_modules();
	my($hash)={};
	for(my($i)=0;$i<$list->size();$i++) {
		my($curr)=$list->getx($i)->get_source();
		Meta::Lang::Perl::Deps::add_deps_rec($grap,$curr,1,1,$hash);
	}
	#collect all graph nodes into an oset
	my($oset)=Meta::Ds::Oset->new();
	my($resu)=$grap->nodes();
	for(my($i)=0;$i<$resu->size();$i++) {
		my($curr)=$resu->elem($i);
		my($addx);
		if(Meta::Lang::Perl::Deps::is_internal($curr)) {
			$addx=$inte;
		} else {
			$addx=$exte;
		}
		if($addx) {
			$oset->insert($curr);
		}
	}
	return($oset);
}

sub get_scripts_dep_list($$$) {
	my($self,$inte,$exte)=@_;
	my($grap)=Meta::Development::Deps->new();
	my($list)=$self->get_scripts();
	my($hash)={};
	for(my($i)=0;$i<$list->size();$i++) {
		my($curr)=$list->getx($i)->get_source();
		Meta::Lang::Perl::Deps::add_deps_rec($grap,$curr,1,1,$hash);
	}
	my($oset)=Meta::Ds::Oset->new();
	my($resu)=$grap->nodes();
	for(my($i)=0;$i<$resu->size();$i++) {
		my($curr)=$resu->elem($i);
		my($addx);
		if(Meta::Lang::Perl::Deps::is_internal($curr)) {
			$addx=$inte;
		} else {
			$addx=$exte;
		}
		if($addx) {
			$oset->insert($curr);
		}
	}
	return($oset);
}

sub get_tests_dep_list($$$) {
	my($self,$inte,$exte)=@_;
	my($grap)=Meta::Development::Deps->new();
	my($list)=$self->get_tests();
	my($hash)={};
	for(my($i)=0;$i<$list->size();$i++) {
		my($curr)=$list->getx($i)->get_source();
		Meta::Lang::Perl::Deps::add_deps_rec($grap,$curr,1,1,$hash);
	}
	my($oset)=Meta::Ds::Oset->new();
	my($resu)=$grap->nodes();
	for(my($i)=0;$i<$resu->size();$i++) {
		my($curr)=$resu->elem($i);
		my($addx);
		if(Meta::Lang::Perl::Deps::is_internal($curr)) {
			$addx=$inte;
		} else {
			$addx=$exte;
		}
		if($addx) {
			$oset->insert($curr);
		}
	}
	return($oset);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Perlpkg - store information for a perl package.

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

	MANIFEST: Perlpkg.pm
	PROJECT: meta
	VERSION: 0.20

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Perlpkg qw();
	my($object)=Meta::Lang::Perl::Perlpkg->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module stores information needed to create a single perl
package. Supplies such services as creating a perl package
and other services.

=head1 FUNCTIONS

	BEGIN()
	init($)
	add_deps($$$)
	get_pack($)
	get_pack_name($)
	get_pack_file_name($)
	get_modules_dep_list($$$)
	get_scripts_dep_list($$$)
	get_tests_dep_list($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

A setup routine for this module which creates get/set methods for the
following attributes:
name - name of this package.
description - short description of what the package does.
longdescription - long description of what the package does.
license - license for this package.
version - version number for the distribution archive.
uname - user name for the distribution archive.
gname - group name for the distribution archive.
author - author information for this package.
modules - modules distributed in this package.
scripts - script files in this package.
tests - test files in this package.
files - regular files in this package.
credits - credit information for this package.

=item B<init($)>

Post construction internal method.

=item B<add_deps($$$)>

This method will add dependency information to a deps
object it receives.

=item B<get_pack($)>

This method returns the basic package name (just name
and version).

=item B<get_pack_name($)>

This method returns the package name that this package
should have (a CPAN name).

=item B<get_pack_file_name($)>

This method gets a module name (baseline relative) for the package file.

=item B<get_modules_dep_list($$$)>

This method returns the list of modules which are dependant on the modules
in the package.

A few notes on the algorithm:
1. A new dep graph is created. The deps are collected but care is given not
to revisit same nodes by use of a hash table which stores which nodes
were visited.
2. When collecting deps both internal and external nodes are followed. I'm
still not sure about this.
3. After all of this a set is created and all the elements which are wanted
are collected into it.
4. If the hash mentioned above is not used and nodes are revisited performance
drops at a quadratic rate (for 250 modules it goes from 10 seconds to 130
seconds).

=item B<get_scripts_dep_list($$$)>

This method returns the list of scripts which are dependant on the scripts
in the package.

=item B<get_tests_dep_list($$$)>

This method returns the list of tests which are dependant on the tests 
in the package.

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

	0.00 MV perl packaging
	0.01 MV more perl packaging
	0.02 MV perl packaging again
	0.03 MV perl packaging again
	0.04 MV validate writing
	0.05 MV PDMT
	0.06 MV some chess work
	0.07 MV fix database problems
	0.08 MV more database issues
	0.09 MV md5 project
	0.10 MV database
	0.11 MV perl module versions in files
	0.12 MV movies and small fixes
	0.13 MV thumbnail user interface
	0.14 MV import tests
	0.15 MV more thumbnail issues
	0.16 MV website construction
	0.17 MV web site development
	0.18 MV web site automation
	0.19 MV SEE ALSO section fix
	0.20 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Development::Deps(3), Meta::Ds::Array(3), Meta::Ds::Oset(3), Meta::Info::Author(3), Meta::Lang::Perl::Deps(3), strict(3)

=head1 TODO

-unite the 3 dep routines here which are almost the same.

-add a misc files section for the license etc... (this way these files won't be hardcoded here).

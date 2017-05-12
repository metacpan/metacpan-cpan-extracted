#!/bin/echo This is a perl module and should not be run

package Meta::Archive::Tar;

use strict qw(vars refs subs);
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::File qw();
use Archive::Tar qw();
use Meta::Utils::File::Remove qw();
use Meta::Class::MethodMaker qw();
use Meta::Utils::Output qw();
use Meta::Utils::Utils qw();
use Meta::Utils::System qw();
use Meta::Ds::Set qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Archive::Tar);

#sub BEGIN();
#sub new($);
#sub add_data($$$);
#sub add_file($$$);
#sub add_deve($$$);
#sub add_modu($$$);
#sub write($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_type",
		-java=>"_use_uname",
		-java=>"_uname",
		-java=>"_use_gname",
		-java=>"_gname",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Archive::Tar->new();
	bless($self,$class);
	$self->{SET}=Meta::Ds::Set->new();
	$self->set_type("gzip");
	$self->set_use_uname(0);
	$self->set_use_gname(0);
	return($self);
}

sub add_data($$$) {
	my($self,$name,$data)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		# the next paragraph is a bug work around
		if($data eq "") {#make the data have something so It will go into the archive
			$data=" ";
			#add data with specified length - does not work
			#$self->SUPER::add_data($name,$data,{ "size"=>0 });
			#this is plain insertion which does not work
			#$self->SUPER::add_data($name,$data);
		}
		my($hash)={};
		if($self->get_use_uname()) {
			$hash->{"uname"}=$self->get_uname();
		}
		if($self->get_use_gname()) {
			$hash->{"gname"}=$self->get_gname();
		}
		$self->SUPER::add_data($name,$data,$hash);
		$set->insert($name);
	}
}

sub add_file($$$) {
	my($self,$name,$file)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		my($data);
		Meta::Utils::File::File::load($file,\$data);
		$self->add_data($name,$data);
	}
}

sub add_deve($$$) {
	my($self,$name,$file)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		my($abso)=Meta::Baseline::Aegis::which($file);
		$self->add_file($name,$abso);
	}
}

sub add_modu($$$) {
	my($self,$name,$modu)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		my($abso)=$modu->get_abs_path();
		$self->add_file($name,$abso);
	}
}

sub write($$) {
	my($self,$targ)=@_;
	my($type)=$self->get_type();
	if($type eq "gzip") {
		$self->SUPER::write($targ,9);
	}
	if($type eq "bz2") {
		my($temp)="/tmp/tmpi";
		$self->SUPER::write($temp);
		# now compress $temp to $targ using bz2
	}
}

sub TEST($) {
	my($context)=@_;
	my($tar)=Meta::Archive::Tar->new();
	$tar->add_data("foo.c","");
	$tar->add_deve("movies.xml","xmlx/movie/movie.xml");
	my(@list)=$tar->list_files();
	Meta::Utils::Output::print(join("\n",@list)."\n");
	my($temp)=Meta::Utils::Utils::get_temp_file();
	$tar->write($temp);
	my($out)=Meta::Utils::System::system_out("tar",["ztvf",$temp]);
	Meta::Utils::Output::print("out is [".$$out."]\n");
	Meta::Utils::File::Remove::rm($temp);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Archive::Tar - extended Archive::Tar class.

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

	MANIFEST: Tar.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Archive::Tar qw();
	my($object)=Meta::Archive::Tar->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends the Archive::Tar class.
It adds services like adding a file under a different name,
and adding a baseline relative file.

It also guards the user from adding the same file several times.

Currently, because of the underlying Archive::Tar
implementation, only the gzip mode is supported.

=head1 FUNCTIONS

	BEGIN()
	new($)
	add_data($$$)
	add_file($$$)
	add_deve($$$)
	add_modu($$$)
	write($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Setup method for this class which sets up get/set methods for
the following attributes:
type - type of archive (gzip,zip,bzip2).
uname - user name under which the archive will be created.
gname - group name under which the archive will be created.

=item B<new($)>

This is a constructor for the Meta::Archive::Tar object.

=item B<add_data($$$)>

This method overrides the default add_data since the default
method does not handle empty data well (it does not put them
in the archive and I written that as a bug to mail the author).

=item B<add_file($$$)>

This method will add a file you specify under the name you specify.

=item B<add_deve($$$)>

This method will add a file relative to the baseline.
Parameters are:
0. Meta::Archive::Tar object handle.
1. name under which to store the file.
2. file name relative to the baseline root.

=item B<add_modu($$$)>

This method will add a module to the baseline.
Parameters are:
0. Meta::Archive::Tar object handle.
1. name under which to store the file.
2. Meta::Development::Module module.

=item B<write($$)>

This method will write the archive. This method overrides the Archive::Tar
method by the same name because that method passes the gzip compression factor
in the activation too (which I think is bad practice).

=item B<TEST($)>

This is a test suite for the Meta::Archive::Tar package.
Currently it just creates an archive with some data.

=back

=head1 SUPER CLASSES

Archive::Tar(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging
	0.01 MV validate writing
	0.02 MV PDMT
	0.03 MV fix database problems
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV thumbnail user interface
	0.09 MV import tests
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site development
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV move tests to modules
	0.16 MV finish papers
	0.17 MV teachers project
	0.18 MV md5 issues

=head1 SEE ALSO

Archive::Tar(3), Meta::Baseline::Aegis(3), Meta::Class::MethodMaker(3), Meta::Ds::Set(3), Meta::Utils::File::File(3), Meta::Utils::File::Remove(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-once the author of Archive::Tar gets ridd of the bug where empty data files could not be created then fix the code here.

-add method to add a files under the same name as the addition (bypass the load mechanism).

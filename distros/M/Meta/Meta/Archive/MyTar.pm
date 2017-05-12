#!/bin/echo This is a perl module and should not be run

package Meta::Archive::MyTar;

use strict qw(vars refs subs);
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::Copy qw();
use Meta::Utils::Utils qw();
use Meta::Utils::System qw();
use Meta::Utils::File::Remove qw();
use Meta::Ds::Array qw();
use Meta::Ds::Set qw();
use Meta::Class::MethodMaker qw();
use Meta::Info::Enum qw();

our($VERSION,@ISA);
$VERSION="0.14";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub add_file($$$);
#sub add_deve($$$);
#sub add_data($$$);
#sub list_files($);
#sub write($$);
#sub TEST($);

#__DATA__

our($compress_type_enum);

sub BEGIN() {
	$compress_type_enum=Meta::Info::Enum->new();
	$compress_type_enum->insert("bzip2");
	$compress_type_enum->insert("gzip");
	$compress_type_enum->insert("compress");
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_type",
		-java=>"_uname",
		-java=>"_gname",
		-java=>"_uid",
		-java=>"_gid",
		-java=>"_temp",
	)
}

sub init($) {
	my($self)=@_;
	#create a temp directory and record it's name
	$self->set_temp(Meta::Utils::Utils::get_temp_dire());
	#list of files to be stored
	$self->{LIST}=Meta::Ds::Array->new();
	$self->{SET}=Meta::Ds::Set->new();
}

sub add_file($$$) {
	my($self,$name,$file)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		Meta::Utils::File::Copy::copy_mkdir($file,$self->get_temp()."/".$name);
		$self->{LIST}->push($name);
		$self->{SET}->insert($name);
	}
}

sub add_deve($$$) {
	my($self,$name,$deve)=@_;
	my($file)=Meta::Baseline::Aegis::which($deve);
	$self->add_file($name,$file);
}

sub add_data($$$) {
	my($self,$name,$data)=@_;
	my($set)=$self->{SET};
	if($set->hasnt($name)) {
		Meta::Utils::File::File::save($self->get_temp()."/".$name,$data);
		$self->{LIST}->push($name);
		$self->{SET}->insert($name);
	}
}

sub list_files($) {
	my($self)=@_;
	my(@out_list);
	my($list)=$self->{LIST};
	for(my($i)=0;$i<$list->size();$i++) {
		my($curr)=$list->getx($i);
		push(@out_list,$curr);
	}
	return(@out_list);
}

sub write($$) {
	my($self,$targ)=@_;
	my($type)=$self->get_type();
	my($temp)=Meta::Utils::Utils::get_temp_file();
	my(@args);
	push(@args,"--create");
	push(@args,"--file=".$temp);
	#push(@args,"--remove-files");
	push(@args,"--directory=".$self->get_temp());#change directory before activating
	my($list)=$self->{LIST};
	for(my($i)=0;$i<$list->size();$i++) {
		my($curr)=$list->getx($i);
		push(@args,$curr);
	}
	#if($type eq "bzip2") {
	#	push(@args,"--bzip2");
	#}
	#if($type eq "gzip") {
	#	push(@args,"--gzip");
	#}
	#if($type eq "compress") {
	#	push(@args,"--compress");
	#}
	my($verbose)=0;
	if($verbose) {
		push(@args,"--verbose");
	}
	if($self->get_uname() ne defined) {
	#	push(@args,"--owner=".$self->get_uname());
	}
	if($self->get_gname() ne defined) {
	#	push(@args,"--group=".$self->get_gname());
	}
	#if($self->get_uid() ne defined) {
	#}
	#if($self->get_gid() ne defined) {
	#}
	#tar it up
	#Meta::Utils::Output::print("args are [".join(",",@args)."]\n");
	Meta::Utils::System::system("tar",\@args);
	#remove the directory used as temp
	Meta::Utils::File::Remove::rmrecursive($self->get_temp());
	#use tardy to set user and group
	my($temp_tardy)=Meta::Utils::Utils::get_temp_file();
	#Meta::Utils::Output::print("temp_tardy is [".$temp_tardy."]\n");
	Meta::Utils::System::system("tardy",["-Group_NAme",$self->get_gname(),"-User_Name",$self->get_uname(),$temp,$temp_tardy]);
	#remove the temp file used before tardy
	Meta::Utils::File::Remove::rm($temp);
	#compress the file
	if($type eq "bzip2") {
		Meta::Utils::System::system_shell("bzip2 ".$temp_tardy." --stdout > ".$targ);
	}
	if($type eq "gzip") {
		Meta::Utils::System::system_shell("gzip ".$temp_tardy." --stdout > ".$targ);
	}
	if($type eq "compress") {
		Meta::Utils::System::system_shell("compress ".$temp_tardy." -c > ".$targ);
	}
	#remove the temp file used after tardy
	Meta::Utils::File::Remove::rm($temp_tardy);
}

sub TEST($) {
	my($context)=@_;
	my($mytar)=Meta::Archive::MyTar->new();
	$mytar->set_type("gzip");
	$mytar->set_uname("me");
	$mytar->set_gname("mine");
	$mytar->add_deve("xmlx/movie/movie.xml","xmlx/movie/movie.xml");
	my($temp)=Meta::Utils::Utils::get_temp_file();
	$mytar->write($temp);
	my($out)=Meta::Utils::System::system_out("tar",["ztvf",$temp]);
	Meta::Utils::Output::print("out is [".$$out."]\n");
	Meta::Utils::File::Remove::rm($temp);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Archive::MyTar - Tar archive module.

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

	MANIFEST: MyTar.pm
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	package foo;
	use Meta::Archive::MyTar qw();
	my($object)=Meta::Archive::MyTar->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module allows you to create tar archives much line the CPAN
Archive::Tar module. The difference is that this module stores
the archive on the disk and not in RAM and therefore is supposed
to have more performance. It also supports more operations.

I would rather follow a different path than the code here and do
one of the following:
1. use some kind of libtar.so which provides tar functionality.
Unfortunately, this type of thing is not currently available.
2. write the target tar file from the beginging and add files to
it using the tar command line. But unfortunately the tar command
line interface does not support some of the features that I need
(the main one being "here is a file but I want you to put it in
the archive under a completely different name).
Therefore the algorithm I'm following here is much more naive -
I open a temp directory and do all thw work there.

This method also allows me to support these types of compressions:
1. bzip2 with extension .bz2 (--bzip2 flag to tar).
2. gzip with extension .gz (--gzip flag to tar).
3. zip with extension .zip (--compress flag to tar).
4. none no compression.

The module works with GNU tar so your mileage with other tar
implementations will vary.

This module also uses the tardy program by Peter Miller to
set uname and gname after the fact.

This module also maintains a set with all files that currently went
into the archive so that files won't be added more than once.

=head1 FUNCTIONS

	BEGIN()
	init($)
	add_file($$$)
	add_deve($$$)
	add_data($$$)
	list_files($)
	write($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a constructor for the Meta::Archive::MyTar object.
It builds accessor methods for the following attributes:
type,uname,gname,uid,gid.

=item B<init($)>

This method does further initialization of the class.

=item B<add_file($$$)>

This method will add a file to the archive. The file in question
is read and copied to the temp directory we are working with
under the required name. Maybe we could symlink here instead of copying ?
It could be faster (or even hardlink...).

=item B<add_deve($$$)>

This method will add a development file to the archive under a
different name. This method just tranlates the development
module name to a file name and uses the add_file method.

=item B<add_data($$$)>

This method will add some explicit data to the archive under a certain
file name.

=item B<list_files($)>

Get a list of all files in the archive.

=item B<write($$)>

This method will write the archive to the specified file.
The format is tar.gz. This method calls the tar executable
to perform the work.

=item B<TEST($)>

This is a test suite for the Meta::Archive::MyTar package.
Currently it just creates an archive with some data and then lists
it's content.

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

	0.00 MV fix database problems
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV movies and small fixes
	0.05 MV thumbnail project basics
	0.06 MV thumbnail user interface
	0.07 MV import tests
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site development
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV teachers project
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Class::MethodMaker(3), Meta::Ds::Array(3), Meta::Ds::Set(3), Meta::Info::Enum(3), Meta::Utils::File::Copy(3), Meta::Utils::File::Remove(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-support compression parameters for each compression algorithm (for instance 1..9, best compression level for gzip etc...).

-use links (hard ?, soft?) instead of copying the files.

-why am I using tardy and not just using the owner and group parameters to tar ? (the code is already here and remarked). Is it because tar will leave them numeric and not symbolic ? If so then document this.

#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Fs;

use strict qw(vars refs subs);
use Meta::Ds::Ohash qw();
use Meta::Utils::System qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.14";
@ISA=qw(Meta::Ds::Ohash);

#sub new($);
#sub get_type($);
#sub set_type($$);
#sub get_modi($);
#sub set_modi($$);
#sub get_md5x($);
#sub set_md5x($$);
#sub get_data($);
#sub set_data($$);
#sub is_file($);
#sub is_dire($);
#sub has_single_dir($$);
#sub has_dir($$);
#sub has_single_file($$);
#sub has_file($$);
#sub check_single_dir($$);
#sub check_dir($$);
#sub check_single_file($$);
#sub check_file($$);
#sub check_empty_single_dir($$);
#sub check_empty_dir($$);
#sub create_single_dir($$);
#sub create_dir($$);
#sub create_single_file($$);
#sub create_file($$);
#sub get_single_dir($$);
#sub get_dir($$);
#sub get_single_file($$);
#sub get_file($$);
#sub get_dir_of_file($$);
#sub remove_single_dir($$);
#sub remove_dir($$);
#sub remove_single_file($$);
#sub remove_file($$);
#sub remove_last_dir($$);
#sub get_all_files_list($$$);
#sub get_all_files_hash($$$);
#sub get_all_empty_dirs($$$);
#sub print($$);
#sub xml($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Ohash->new();
	$self->{MODI}=defined;
	$self->{TYPE}=defined;
	$self->{MD5X}=defined;
	$self->{DATA}=defined;
	bless($self,$class);
	return($self);
}

sub get_type($) {
	my($self)=@_;
	return($self->{TYPE});
}

sub set_type($$) {
	my($self,$val)=@_;
	if($val ne "file" && $val ne "directory") {
		throw Meta::Error::Simple("type [".$val."] is not a recognized type");
	}
	$self->{TYPE}=$val;
}

sub get_modi($) {
	my($self)=@_;
	return($self->{MODI});
}

sub set_modi($$) {
	my($self,$val)=@_;
	$self->{MODI}=$val;
}

sub get_md5x($) {
	my($self)=@_;
	return($self->{MD5X});
}

sub set_md5x($$) {
	my($self,$val)=@_;
	$self->{MD5X}=$val;
}

sub get_data($) {
	my($self)=@_;
	return($self->{DATA});
}

sub set_data($$) {
	my($self,$val)=@_;
	$self->{DATA}=$val;
}

sub is_file($) {
	my($self)=@_;
	return($self->{TYPE} eq "file");
}

sub is_dire($) {
	my($self)=@_;
	return($self->{TYPE} eq "directory");
}

sub has_single_dir($$) {
	my($self,$name)=@_;
	if($self->has($name)) {
		my($val)=$self->get($name);
		return($val->is_dire());
	} else {
		return(0);
	}
}

sub has_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<=$#fields;$i++) {
		my($curr)=$fields[$i];
		if(!$cfs->has_single_dir($curr)) {
			return(0);
		}
		$cfs=$cfs->get_dir($curr);
	}
	return(1);
}

sub has_single_file($$) {
	my($self,$name)=@_;
	if($self->has($name)) {
		my($val)=$self->get($name);
		return($val->is_file());
	} else {
		return(0);
	}
}

sub has_file($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		if(!$cfs->has_single_dir($curr)) {
			return(0);
		}
		$cfs=$cfs->get_dir($curr);
	}
	return($cfs->has_single_file($fields[$#fields]));
}

sub check_single_dir($$) {
	my($self,$name)=@_;
	my($val)=$self->get($name);
	if(!$val->is_dire()) {
		throw Meta::Error::Simple("name [".$name."] is not a directory");
	}
	return($val);
}

sub check_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<=$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_dir($curr);
	}
}

sub check_single_file($$) {
	my($self,$name)=@_;
	my($val)=$self->get($name);
	if(!$val->is_file()) {
		throw Meta::Error::Simple("name [".$name."] is not a file");
	}
}

sub check_file($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_dir($curr);
	}
	$cfs->check_single_file($fields[$#fields]);
}

sub check_empty_single_dir($$) {
	my($self,$name)=@_;
	my($fs)=$self->get_single_dir($name);
	if($fs->size() ne 0) {
		throw Meta::Error::Simple("name [".$name."] is not empty");
	}
	return($fs);
}

sub check_empty_single_dir($$) {
	my($self,$name)=@_;
	my($fs)=$self->get_dir($name);
	if($fs->size() ne 0) {
		throw Meta::Error::Simple("name [".$name."] is not empty");
	}
	return($fs);
}

sub create_single_dir($$) {
	my($self,$name)=@_;
	if($name=~/\//) {
		throw Meta::Error::Simple("name [".$name."] has a slash in it");
	}
	if($self->has($name)) {
		throw Meta::Error::Simple("name [".$name."] already exists");
	}
	my($new)=Meta::Utils::File::Fs->new();
	$new->set_type("directory");
	$self->insert($name,$new);
	return($new);
}

sub create_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<=$#fields;$i++) {
		my($curr)=$fields[$i];
		if($cfs->has_single_dir($curr)) {
			$cfs=$cfs->get_single_dir($curr);
		} else {
			$cfs=$cfs->create_single_dir($curr);
		}
	}
	return($cfs);
}

sub create_single_file($$) {
	my($self,$name)=@_;
	if($name=~/\//) {
		throw Meta::Error::Simple("name [".$name."] has a slash in it");
	}
	if($self->has($name)) {
		throw Meta::Error::Simple("name [".$name."] already exists");
	}
	my($new)=Meta::Utils::File::Fs->new();
	$new->set_type("file");
	$self->insert($name,$new);
	return($new);
}

sub create_file($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		if($cfs->has_single_dir($curr)) {
			$cfs->get_single_dir($curr);
		} else {
			$cfs=$cfs->create_single_dir($curr);
		}
	}
	my($curr)=$fields[$#fields];
	$cfs->create_single_file($curr);
}

sub remove_single_dir($$) {
	my($self,$name)=@_;
	$self->check_empty_single_dir($name);
	$self->remove($name);
}

sub remove_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	my(@list,@name);
	for(my($i)=0;$i<=$#fields;$i++) {
		my($curr)=$fields[$i];
		push(@list,$cfs);
		push(@name,$curr);
		$cfs=$cfs->get_single_dir($curr);
	}
	for(my($i)=$#fields;$i>0;$i--) {
		my($remove)=$name[$i];
		my($from)=$list[$i-1];
		$from->remove_single_dir($remove);
	}
}

sub remove_single_file($$) {
	my($self,$name)=@_;
	$self->check_single_file($name);
	$self->remove($name);
}

sub remove_file($$) {
	my($self,$name)=@_;
	my($dir)=$self->get_dir_of_file($name);
	my($fn)=get_name_of_file($name);
	$dir->remove_single_file($fn);
}

sub remove_last_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_single_dir($curr);
	}
	$cfs->remove_single_dir($fields[$#fields]);
	return($cfs);
}

sub get_single_dir($$) {
	my($self,$name)=@_;
	my($retu)=$self->get($name);
	if(!$retu->is_dire()) {
		throw Meta::Error::Simple("name [".$name."] is not a directory");
	}
	return($retu);
}

sub get_dir($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<=$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_single_dir($curr);
	}
	return($cfs);
}

sub get_single_file($$) {
	my($self,$name)=@_;
	my($retu)=$self->get($name);
	if(!$retu->is_file()) {
		throw Meta::Error::Simple("name [".$name."] is not a directory");
	}
	return($retu);
}

sub get_file($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_single_dir($curr);
	}
	return($cfs->get_single_file($fields[$#fields]));
}

sub get_dir_of_file($$) {
	my($self,$name)=@_;
	my(@fields)=split('\/',$name);
	my($cfs)=$self;
	for(my($i)=0;$i<$#fields;$i++) {
		my($curr)=$fields[$i];
		$cfs=$cfs->get_single_dir($curr);
	}
	return($cfs);
}

sub get_all_files_list($$$) {
	my($self,$list,$pref)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		my($curr);
		if($pref ne "") {
			$curr=$pref."/".$key;
		} else {
			$curr=$key;
		}
		if($val->is_file()) {#this is a file
			push(@$list,$curr);
		}
		if($val->is_dire()) {#this is a directory - recurse
			$val->get_all_files_list($list,$curr);
		}
	}
}

sub get_all_files_hash($$$) {
	my($self,$hash,$pref)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		my($curr);
		if($pref ne "") {
			$curr=$pref."/".$key;
		} else {
			$curr=$key;
		}
		if($val->is_file()) {#this is a file
			$hash->{$curr}=defined;
		}
		if($val->is_dire()) {#this is a directory - recurse
			$val->get_all_files_hash($hash,$curr);
		}
	}
}

sub get_all_empty_dirs($$$) {
	my($self,$list,$pref)=@_;
	my($remove)=1;
	for(my($i)=0;$i<$self->size();$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		my($curr);
		if($pref ne "") {
			$curr=$pref."/".$key;
		} else {
			$curr=$key;
		}
		if($val->is_dire()) {#this is a directory 
			my($res)=$val->get_all_empty_dirs($list,$curr);
			if(!$res) {
				$remove=0;
			}
		} else {
			$remove=0;
		}
	}
	if($remove) {
		push(@$list,$pref);
	}
	return($remove);
}

sub get_name_of_file($) {
	my($name)=@_;
	my(@fields)=split('\/',$name);
	return($fields[$#fields]);
}

sub print($$) {
	my($self,$inde)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($key)=$self->key($i);
		my($val)=$self->val($i);
		for(my($j)=0;$j<$inde;$j++) {
			Meta::Utils::Output::print("\t");
		}
		Meta::Utils::Output::print($key."(".$val->get_modi().")\n");
		if($val->is_dire()) {
			$val->print($inde+1);
		}
	}
}

sub xml($$$) {
	my($self,$writ,$name)=@_;
	$writ->startTag("fs");
	$writ->dataElement("name",$name);
	$writ->dataElement("type",$self->get_type());
	$writ->dataElement("modi",$self->get_modi());
	$writ->dataElement("md5x",$self->get_md5x());
	$writ->dataElement("data",$self->get_data());
	if($self->is_dire()) {
		for(my($i)=0;$i<$self->size();$i++) {
			my($key)=$self->key($i);
			my($val)=$self->val($i);
			$val->xml($writ,$key);
		}
	}
	$writ->endTag("fs");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Fs - object to encapsulate a file system.

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

	MANIFEST: Fs.pm
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Fs qw();
	my($object)=Meta::Utils::File::Fs->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object provides the services of a file system. You can create
files, remove files, create symlinks and query its condition.
You may rightfuly ask: "why the fuck should I want such an object ?"
Well, some processes, for example building software and updating
a remote mirror/ftp site acquire a knowledge of a file heirarchy
(a file system) when they start off, and then assume that no one
alters the file system (or at least tell them when they do) and
proceed to execute operations on the file system. They still want
to remmember what the status of the file system is. This is where
this object comes into play. Using this object to store the
file system information they retrieve upon startup and updating
this object whenever they perform operations on the file system
enables them to have knowledge of the underlying file system
without resorting to re-query the actual file system which is
expensive when querying a disk but even more so when querying
a remote ftp server or the like...

=head1 FUNCTIONS

	new($)
	get_type($)
	set_type($$)
	get_modi($)
	set_modi($$)
	get_md5x($)
	set_md5x($$)
	get_data($)
	set_data($$)
	is_file($)
	is_dire($)
	has_single_dir($$)
	has_dir($$)
	has_single_file($$)
	has_file($$)
	check_single_dir($$)
	check_dir($$)
	check_single_file($$)
	check_file($$)
	check_empty_single_dir($$)
	check_empty_dir($$)
	create_single_dir($$)
	create_dir($$)
	create_single_file($$)
	create_file($$)
	get_single_dir($$)
	get_dir($$)
	get_single_file($$)
	get_file($$)
	get_dir_of_file($$)
	remove_single_dir($$)
	remove_dir($$)
	remove_single_file($$)
	remove_file($$)
	remove_last_dir($$)
	get_all_files_list($$$)
	get_all_files_hash($$$)
	get_all_empty_dirs($$$)
	print($$)
	xml($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Utils::File::Fs object.

=item B<get_type($)>

This method will return the type of this node.

=item B<set_type($$)>

This method will set the type for the current node.

=item B<get_modi($)>

This method will retrieve the modification time for the current node.

=item B<set_modi($$)>

This method will set the modification time for the current node.

=item B<get_md5x($)>

This method will retrieve the md5 sum of the current file.

=item B<set_md5x($$)>

This method will set the md5 sum for the current file.

=item B<get_data($)>

This method will retrieve the data for the current file.

=item B<set_data($$)>

This method will set the data for the current file.

=item B<is_file($)>

This method will return a boolean value which will be true if
the current node is of type file.

=item B<is_dire($)>

This method will return a boolean value which will be true if
the current node is of type directory.

=item B<has_single_dir($$)>

This method returns true if the Fs object given to it has
a certain subdir.

=item B<has_dir($$)>

This method returns true if the Fs object given to it has
a certain directory (of any nesting level).

=item B<has_single_file($$)>

This method returns true if the Fs object given to it has
a certain file.

=item B<has_file($$)>

This method returns true if the Fs object given to it has
a certain file (of any nesting level).

=item B<check_single_dir($$)>

This method receives an Fs type object and checks that the name
given to it is indeed a directory in that filesystem.
The method returns the directory involved.
The reason that this method is using the !is_file method is
because in the future we may support other things like sym
links, hard links etc...

=item B<check_dir($$)>

This method receives an Fs type object and checks that the name
given to it is indeed a directory (of any depth) in that filesystem.
It uses consecutive calls to check_single_dir.
The method doesnt return anything.

=item B<check_single_file($$)>

This method receives an Fs type object and checks that the name
given to it is indeed a file in that filesystem.
The method doesnt return anything.
The reason that this method is using the !is_file method is
because in the future we may support other things like sym
links, hard links etc...

=item B<check_file($$)>

This method receives an Fs type object and checks that the
name given to it is indeed a file (of any depth) in that filesystem.
The method doesnt return anything.

=item B<check_empty_single_dir($$)>

This method receives an Fs type object and checks that the name
given to it is indeed a directory in that file system and it is
empty.
The method returns the directory involved.

=item B<check_empty_dir($$)>

This method receives an Fs type object and checks that the name
given to it is indeed a directory in that file system and it is
empty.
The method returns the directory involved.

=item B<create_single_dir($$)>

This method creates a single directory under the current one.
The method returns the directory created.

=item B<create_dir($$)>

This creates a new directory with parent directories.
The method returns the directory created.

=item B<create_single_file($$)>

This creates a single file under the current directory.
The method returns the file type created.

=item B<create_file($$)>

This method creates a file with parent directories.
This method doesnt return anything.

=item B<remove_single_dir($$)>

This method removes a single direcotry from the current fs.
The method doesnt return anything.

=item B<remove_dir($$)>

This method removes a directory with all of its ancestors
from the current file system.

=item B<remove_single_file($$)>

This method removes a single file from the current fs.
The method doesnt return anything.

=item B<remove_file($$)>

This method receives an Fs type object and removes a file
named from it.
The method returns the directory of the file.

=item B<remove_last_dir($$)>

This method removes the last component of a directory.
The method returns the directory handle of the directory
from which it was removed.

=item B<get_single_dir($$)>

This method returns a directory within the current fs.

=item B<get_dir($$)>

This method returns a directory within the current fs (of any depth).

=item B<get_single_file($$)>

This method returns a specific file within the current fs.

=item B<get_file($$)>

This method returns a file within the current fs (of any depth).

=item B<get_dir_of_file($$)>

This method receives an Fs type object and returns the directory
entry in which the file given to it resides.

=item B<get_all_files_list($$$)>

This method receives an fs object and a list pointer and fills
the list with all the files under the current fs. All the files
will be given the prefix that you specify. If you do not wish
to have a prefix then "" will do.

=item B<get_all_files_hash($$$)>

This method receives an fs object a hash pointer and fills
the hash with all the files unders the current fs. All the files
will be given the prefix that you specify. If you do not wish
to have a prefix then "" will do.

=item B<get_all_empty_dirs($$$)>

This method gets an fs object and a list and fills the list
with all the empty directories it could find. The prefixe that
is supplied will be given to all files ("" should do if you
do not want any prefix).
The method returns whether the current dir is empty or not.

=item B<get_name_of_file($)>

This function receives a file name (with directory) and returns just
the file name part.
NOTE: this is not a method but a function (no object is neccessary).

=item B<print($$)>

This method will print the current fs (mostly for debug
purposes). You could put 0 in the indent parameter if you
don't want the print indented.

=item B<xml($$$)>

This method receives an XML writer object and writer the file system into the XML
writer object.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Ohash(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV upload system revamp
	0.01 MV do some book work
	0.02 MV perl packaging
	0.03 MV xml
	0.04 MV data sets
	0.05 MV md5 project
	0.06 MV database
	0.07 MV perl module versions in files
	0.08 MV movies and small fixes
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Ds::Ohash(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-there are no current checks that makes sure that files and directories are not created inside files!!!

-make the print routine have the same logic as the xml routine (it's better logic). That would require that routine to get 3 parameters too.

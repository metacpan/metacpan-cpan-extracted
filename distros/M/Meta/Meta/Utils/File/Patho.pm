#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Patho;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();
use Meta::Utils::Env qw();

our($VERSION,@ISA);
$VERSION="0.08";
@ISA=qw(Meta::Ds::Array);

#sub new($);
#sub new_data($$$);
#sub new_env($$$);
#sub new_path($);
#sub minimize($$$);
#sub exists($$);
#sub resolve($$);
#sub path_to($$);
#sub mtime($$);
#sub append_data($$$);
#sub append($$);
#sub check($);
#sub compose($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Ds::Array->new();
	bless($self,$class);
	return($self);
}

sub new_data($$$) {
	my($class,$path,$sepa)=@_;
	my($object)=&new($class);
	$object->append_data($path,$sepa);
	return($object);
}

sub new_env($$$) {
	my($class,$var,$sepa)=@_;
	return(&new_data($class,Meta::Utils::Env::get($var),$sepa));
}

sub new_path($) {
	my($class)=@_;
	return(&new_env($class,"PATH",':'));
}

sub minimize($) {
	my($self)=@_;
}

sub exists($$) {
	my($self,$file)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->getx($i);
		my($test)=$curr."/".$file;
		if(-f $test) {
			return(1);
		}
	}
	return(0);
}

sub resolve($$) {
	my($self,$file)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->getx($i);
		my($test)=$curr."/".$file;
		if(-x $test) {
			return($test);
		}
	}
	throw Meta::Error::Simple("path to [".$file."] not found");
}

sub path_to($$) {
	my($self,$file)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->getx($i);
		my($test)=$curr."/".$file;
		if(-x $test) {
			return($curr);
		}
	}
	throw Meta::Error::Simple("path to [".$file."] not found");
}

sub mtime($$) {
	my($self,$file)=@_;
	my($resolved)=$self->resolve($file);
	if(defined($resolved)) {
		return(Meta::Utils::File::Time::mtime($resolved));
	} else {
		return(undef);
	}
}

sub append_data($$$) {
	my($self,$path,$sepa)=@_;
	my(@arra)=split($sepa,$path);
	for(my($i)=0;$i<=$#arra;$i++) {
		$self->push($arra[$i]);
	}
}

sub append($$) {
	my($self,$data)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->setx($i,$self->getx($i).$data);
	}
}

sub check($) {
	my($self)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		my($curr)=$self->getx($i);
		if(!(-d $curr)) {
			throw Meta::Error::Simple("component [".$curr."] is not a directory");
		}
		if($curr=~/^\//) {
			throw Meta::Error::Simple("component [".$curr."] is not absolute");
		}
	}
}

sub compose($$) {
	my($self,$sepa)=@_;
	return($self->join($sepa));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Patho - Path object.

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

	MANIFEST: Patho.pm
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Patho qw();
	my($object)=Meta::Utils::File::Patho->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module gives you an object which encapsulates a path.

A Path is an ordered set of directories used to enable hierarchical
search for files (executables, source files etc). This path object
is exactly that - an ordered set of directories. You can initialize
the object from a string and a separator, from an environment
variable or by adding the components yourself. After that you can
resolve a file name according to the path and perform other
operations.

=head1 FUNCTIONS

	new($)
	new_data($$$)
	new_env($$$)
	new_path($)
	minimize($)
	exists($$)
	resolve($$)
	path_to($$)
	mtime($$)
	append_data($$$)
	append($$)
	check($)
	compose($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Utils::File::Patho object.

=item B<new_data($$$)>

Give this constructor a path and a separator and you'll get
a path object initialized for that path.

=item B<new_env($$$)>

This method will create a new instance from data taken from an
environment variable. You have to supply the separator yourself.

=item B<new_path($)>

This method will create a new instance from the envrionment PATH
variable.

=item B<minimize($)>

This method will remove redundant componets in the path. Redundant
components in the path are components which repeat them selves.
The paths structure (the order of resolution) will remain the same.

=item B<exists($$)>

This method will returns whether a file given exists according to
the path. The file can have directory components in it and must
be relative to the path.

=item B<resolve($$)>

This method will return a file resolved according to a path.

=item B<path_to($$)>

This method will return the path to a certain executable according to the current
path object.

=item B<mtime($$)>

This method will return the files resolved modification time.

=item B<append_data($$$)>

This method will append a path to the end of the current one.

=item B<append($$)>

This method appends a piece of data to every element of the path.

=item B<check($)>

This method will check that each component in the path is indeed a directory.

=item B<compose($$)>

This method will return a string describing the path using the separator specified.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Array(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV md5 progress
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV web site development
	0.07 MV teachers project
	0.08 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Array(3), Meta::Utils::Env(3), strict(3)

=head1 TODO

-in the check method also check that the components are ABSOLUTE directory names.

-write the minimize method.

-in the minimize method convert the elements into some kind of cannonical representation so I'll know that two directory names are not the same name for the same directory.

-write a method to find files in paths which are not executables.

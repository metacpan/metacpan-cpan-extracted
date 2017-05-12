#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Set;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use Meta::IO::File qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.38";
@ISA=qw();

#sub new($);
#sub clear($);
#sub insert($$);
#sub write($$);
#sub remove($$);
#sub has($$);
#sub hasnt($$);
#sub check_has($$);
#sub check_hasnt($$);
#sub read($$);
#sub size($);
#sub contained($$);
#sub set_add($$);
#sub set_remove($$);
#sub foreach($$);
#sub get_hash($);
#sub filter_regexp($$);
#sub filter($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{HASH}={};
	$self->{SIZE}=0;
	return($self);
}

sub clear($) {
	my($self)=@_;
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$self->remove($key);
	}
}

sub insert($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is a set element");
	} else {
		$self->{HASH}->{$elem}=defined;
		$self->{SIZE}++;
	}
}

sub write($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->hasnt($elem)) {
		$self->{HASH}->{$elem}=defined;
		$self->{SIZE}++;
	}
}

sub remove($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		delete($self->{HASH}->{$elem});
		$self->{SIZE}--;
	} else {
		throw Meta::Error::Simple("elem [".$elem."] is not a set element");
	}
}

sub has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if(exists($self->{HASH}->{$elem})) {
		return(1);
	} else {
		return(0);
	}
}

sub hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if(exists($self->{HASH}->{$elem})) {
		return(0);
	} else {
		return(1);
	}
}

sub check_has($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->hasnt($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is not an element of the set");
	}
}

sub check_hasnt($$) {
	my($self,$elem)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if($self->has($elem)) {
		throw Meta::Error::Simple("elem [".$elem."] is an element of the set");
	}
}

sub read($$) {
	my($self,$file)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
#	Meta::Utils::Arg::check_arg($file,"ANY");
	my($io)=Meta::IO::File->new_reader($file);
	while(!$io->eof()) {
		my($line)=$io->getline();
		chop($line);
		$self->insert($line);
	}
	$io->close();
}

sub size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Set");
	return($self->{SIZE});
}

sub contained($$) {
	my($self,$other_set)=@_;
	my($res)=1;
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
# The next line which is more efficient isn't used cause
# it wont put the internal hash iterator into starting position.
# If there is a way to do that then we should bring this back
# and do it at the end of the method
#	while((my($key,$val)=each(%$hash)) && $res) {
		#Meta::Utils::Output::print("key is [".$key."]\n");
		if($other_set->hasnt($key)) {
			$res=0;
		}
	}
	return($res);
}

sub set_add($$) {
	my($self,$other_set)=@_;
	my($hash)=$other_set->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$self->add($key);
	}
}

sub set_remove($$) {
	my($self,$other_set)=@_;
	my($hash)=$other_set->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$self->remove($key);
	}
}

sub foreach($$) {
	my($self,$code)=@_;
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		&$code($key);
	}
}

sub get_hash($) {
	my($self)=@_;
	return($self->{HASH});
}

sub filter_regexp($$) {
	my($self,$re)=@_;
	my($hash)=$self->{HASH};
	my($ret)=ref($self)->new();
	while(my($key,$val)=each(%$hash)) {
		if($key=~/$re/) {
			$ret->insert($key);
		}
	}
	return($ret);
}

sub filter($$) {
	my($self,$code)=@_;
	my($hash)=$self->{HASH};
	my($ret)=ref($self)->new();
	while(my($key,$val)=each(%$hash)) {
		if(\&code($key)) {
			$ret->insert($key);
		}
	}
	return($ret);
}

sub TEST($) {
	my($context)=@_;
	my($set)=Meta::Ds::Set->new();
	$set->read("/etc/passwd");
	Meta::Utils::Output::dump($set);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Set - data structure that represents a set.

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

	MANIFEST: Set.pm
	PROJECT: meta
	VERSION: 0.38

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Set qw();
	my($set)=Meta::Ds::Set->new();
	$set->insert("mark");

=head1 DESCRIPTION

This is a library to let you create a set like data structure.
The set data structure is akin to the mathematical object of a set.
A set is a collection of items where duplicates are not allowed (if
you insert an item which is already in the set the set does not
change).
The sets operations are mainly insert, remove and testing whether
elements are memebers of it or not.
The set here is not ordered so you CANT iterate it's elements.
If you do want to iterate them use the Oset object. If you don't -
use this object and same time and memory. Don't worry - if you don't
know if you do or you don't - use this object for starters - if you
wind up needing iteration just switch to using the Oset - they have
the same interface so you will only need to change your code in the use
and object construction points.
The implementation is simply based on a perl hash table and does not
use the capability of the hash table to store value items beside the
keys in the table.

=head1 FUNCTIONS

	new($)
	clear($)
	insert($$)
	write($$)
	remove($$)
	has($$)
	hasnt($$)
	check_has($$)
	check_hasnt($$)
	read($$)
	size($)
	contained($$)
	set_add($$)
	set_remove($$)
	foreach($$)
	get_hash($)
	filter_regexp($$)
	filter($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Set object.

=item B<clear($)>

This will clear the set (make it the empty set).

=item B<insert($$)>

Inserts a new element into the set. If the element is already in the set then this method
throws an exception.

=item B<write($$)>

Inserts a new element into the set. If the element is already in the set then this method
does nothing.

=item B<remove($$)>

Removes an element from the set.

=item B<has($$)>

Returns whether the current element is a member of the set.

=item B<hasnt($$)>

Returns whether the current element is not a member of the set.

=item B<check_has($$)>

Check that the element received is in the set and die if it is not.
This method receives:
0. The object handle.
1. The element to check for.
This method does not return anything.

=item B<check_hasnt($$)>

Check that the element received is in not the set and die if it is.
This method receives:
0. The object handle.
1. The element to check for.
This method does not return anything.

=item B<read($$)>

This method reads a file into the current set object. It does not
remove previously stored elements in the set.
This method receives:
0. The object handle.
1. The file name to read from.
This method returns nothing.

=item B<size($)>

Return the size of the set. The real size (not size-1).
This method receives:
0. The object handle.
This method returns the size of the set object in question.

=item B<contained($$)>

This method will return a boolean value according to whether the current set
is contained in another one supplied.

=item B<set_add($$)>

This method will add the elements of a set given to it to the current set.

=item B<set_remove($$)>

This method will remove from the current set any elements found in a set given
to it.

=item B<foreach($$)>

This method will iterate over all elements of the set and will feed them to
a user supplied function. The function should receive a single arguement
and should do whatever it wants with it.

=item B<get_hash($)>

This method provides access to the underlying hash. Take heed. Use this for read
only purposes.

=item B<filter_regexp($$)>

This method receives a regular expression and returns a set will all members of
the original set which match the regular expression.

=item B<filter($$)>

This method receives a piece of code which gets a single argument. The method will
run this code on each element of the set and will return only elements for which
the code returned a value evaluated to true.

=item B<TEST($)>

Test suite for this module.
Currently this just reads a set and prints it.

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

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV ok. This is for real
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV make Meta::Utils::Opts object oriented
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV silense all tests
	0.10 MV correct die usage
	0.11 MV finish Simul documentation
	0.12 MV perl code quality
	0.13 MV more perl quality
	0.14 MV more perl quality
	0.15 MV get basic Simul up and running
	0.16 MV perl documentation
	0.17 MV more perl quality
	0.18 MV perl qulity code
	0.19 MV more perl code quality
	0.20 MV revision change
	0.21 MV languages.pl test online
	0.22 MV PDMT/SWIG support
	0.23 MV Pdmt stuff
	0.24 MV perl packaging
	0.25 MV some chess work
	0.26 MV md5 project
	0.27 MV database
	0.28 MV perl module versions in files
	0.29 MV movies and small fixes
	0.30 MV more thumbnail code
	0.31 MV thumbnail user interface
	0.32 MV more thumbnail issues
	0.33 MV website construction
	0.34 MV web site automation
	0.35 MV SEE ALSO section fix
	0.36 MV finish papers
	0.37 MV teachers project
	0.38 MV md5 issues

=head1 SEE ALSO

Meta::Error::Simple(3), Meta::IO::File(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.

#!/bin/echo This is a perl module and should not be run

package Meta::Ds::Hash;

use strict qw(vars refs subs);
use Meta::IO::File qw();
use Meta::Error::Simple qw();
use Meta::Error::NoSuchElement qw();

our($VERSION,@ISA);
$VERSION="0.41";
@ISA=qw();

#sub new($);
#sub insert($$$);
#sub put($$$);
#sub overwrite($$$);
#sub remove($$);
#sub size($);
#sub has($$);
#sub hasnt($$);
#sub check_has($$);
#sub check_hasnt($$);
#sub get($$);
#sub load($$);
#sub save($$);
#sub clear($);
#sub filter($$);
#sub foreach($$);
#sub add_hash($$);
#sub remove_hash($$);
#sub add_key_prefix($$);
#sub internal_hash($);
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

sub insert($$$) {
	my($self,$key,$val)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
#	Meta::Utils::Arg::check_arg($key,"ANY");
#	Meta::Utils::Arg::check_arg($val,"ANY");
	if($self->has($key)) {
		$self->overwrite($key,$val);
		return(0);
	} else {
		$self->put($key,$val);
		return(1);
	}
}

sub put($$$) {
	my($self,$key,$val)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
#	Meta::Utils::Arg::check_arg($key,"ANY");
#	Meta::Utils::Arg::check_arg($val,"ANY");
	my($hash)=$self->{HASH};
	if(exists($hash->{$key})) {
		throw Meta::Error::Simple("already have element [".$key."]");
	}
	$hash->{$key}=$val;
	$self->{SIZE}++;
}

sub overwrite($$$) {
	my($self,$key,$val)=@_;
#	Meta::Utils::Arg::check_arg_num(\@_,3);
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
#	Meta::Utils::Arg::check_arg($key,"ANY");
#	Meta::Utils::Arg::check_arg($val,"ANY");
	my($hash)=$self->{HASH};
	if(!exists($hash->{$key})) {
		throw Meta::Error::Simple("dont have element [".$key."]");
	}
	$hash->{$key}=$val;
}

sub remove($$) {
	my($self,$key)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
	my($hash)=$self->{HASH};
	if($self->has($key)) {
		delete($hash->{$key});
		$self->{SIZE}--;
	} else {
		throw Meta::Error::Simple("unable to remove element [".$key."] from hash");
	}
}

sub size($) {
	my($self)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
	return($self->{SIZE});
}

sub has($$) {
	my($self,$key)=@_;
#	Meta::Utils::Arg::check_arg($self,"Meta::Ds::Hash");
	my($hash)=$self->{HASH};
	if(exists($hash->{$key})) {
		return(1);
	} else {
		return(0);
	}
}

sub hasnt($$) {
	my($self,$key)=@_;
	return(!$self->has($key));
}

sub check_has($$) {
	my($self,$key)=@_;
	if($self->hasnt($key)) {
		throw Meta::Error::Simple("hash doesnt have key [".$key."]");
	}
}

sub check_hasnt($$) {
	my($self,$key)=@_;
	if($self->has($key)) {
		throw Meta::Error::Simple("hash has key [".$key."]");
	}
}

sub get($$) {
	my($self,$key)=@_;
	if(!$self->has($key)) {
		throw Meta::Error::NoSuchElement("I dont have an elem [".$key."]");
	}
	return($self->{HASH}->{$key});
}

sub load($$) {
	my($self,$file)=@_;
	my($io)=Meta::IO::File->new_reader($file);
	while(!$io->eof()) {
		my($line)=$io->getline();
		chop($line);
		my(@fiel)=split(' ',$line);
		Meta::Develop::Assert::assert_eq($#fiel+1,2);
		$self->insert($fiel[0],$fiel[1]);
	}
	$io->close();
}

sub save($$) {
	my($self,$file)=@_;
	my($io)=Meta::IO::File->new_writer($file);
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		print $io join(' ',$key,$val)."\n";
	}
	$io->close();
}

sub clear($) {
	my($self)=@_;
	$self->{HASH}={};
	$self->{SIZE}=0;
}

sub filter($$) {
	my($self,$code)=@_;
	my($ret)=Meta::Ds::Hash->new();
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		try {
			&$code($key,$val);
			$ret->insert($key,$val);
		}
	}
	return($ret);
}

sub foreach($$) {
	my($self,$code)=@_;
	my($hash)=$self->{HASH};
	while(my($key,$val)=each(%$hash)) {
		&$code($key,$val);
	}
}

sub add_hash($$) {
	my($self,$hash)=@_;
	my($hash)=$hash->{HASH};
	while(my($key,$val)=each(%$hash)) {
		$self->insert($key,$val);
	}
}

sub remove_hash($$) {
	my($self,$hash)=@_;
	my($hash)=$hash->{HASH};
	while(my($key,$val)=each(%$hash)) {
		# we do not care if the elements are not in the hash
		try {
			$self->remove($key);
		}
	}
}

sub add_key_prefix($$) {
	my($self,$pref)=@_;
	my($hash)=$self->{HASH};
	my($other)=Meta::Ds::Hash->new();#FIXME this needs to be a clone of the current object
	while(my($key,$val)=each(%$hash)) {
		$other->insert($pref.$key,$val);
	}
	return($other);
}

sub internal_hash($) {
	my($self)=@_;
	return($self->{HASH});
}

sub TEST($) {
	my($context)=@_;
	my($hash)=Meta::Ds::Hash->new();
	$hash->insert("mark","veltzer");
	$hash->insert("linus","torvalds");
	Meta::Utils::Output::dump($hash);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Ds::Hash - data structure that represents a hash table.

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

	MANIFEST: Hash.pm
	PROJECT: meta
	VERSION: 0.41

=head1 SYNOPSIS

	package foo;
	use Meta::Ds::Hash qw();
	use Error qw(:try);
	my($hash)=Meta::Ds::Hash->new();
	$hash->insert("mark","veltzer");
	$hash->insert("linus","torvals");
	$hash->remove("mark");
	if($hash->has("mark")) {
		throw Meta::Error::Simple("error");
	}

=head1 DESCRIPTION

This is a library to let you create a hash like data structure.
"Why should I have such a data strcuture ?" you rightly ask...
Perl already supports hashes as built in structures, but these dont
have a size method (for one...)... This encapsulates hash as a object
and is much better (built over the builtin implementation).
This is a value less hash (no values for the inserted ones...),
so it effectivly acts as a set.

=head1 FUNCTIONS

	new($)
	insert($$$)
	put($$$)
	overwrite($$$)
	remove($$)
	size($)
	has($$)
	hasnt($$)
	check_has($$)
	check_hasnt($$)
	get($$)
	load($$)
	save($$)
	clear($)
	filter($$)
	foreach($$)
	add_hash($$)
	remove_hash($$)
	add_key_prefix($$)
	internal_hash($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Hash object.

=item B<insert($$$)>

Inserts an element into the hash. If the element already exists this DOES NOTHING.
This receives:
0. Hash object.
1. Element to insert.
2. Value to insert.
This returns whether the value was actually inserted.

=item B<put($$$)>

This will put a new element in the hash.
If the element is already a part of the hash it will throw an exception.
Arguments:
0. Hash object.
1. Element to insert.
2. Value to insert.

=item B<overwrite($$$)>

This will overwrite an element in the hash.
If the element is not already in the hash it will throw an exception.
Arguments:
0. Hash object.
1. Element to insert.
2. Value to insert.

=item B<remove($$)>

Remove an element from the hash.
This receives:
0. Hash object.
1. Element to remove.
The method will throw an exception if the element does not exist
in the current hash.

=item B<size($)>

Return the number of elements in the hash.
This receives:
0. Hash object.

=item B<has($$)>

Returns a boolean value according to whether the specified element is
in the hash.
This receives:
0. Hash object.
1. Element to check for.

=item B<hasnt($$)>

Returns a boolean value according to whether the specified element is
not in the hash.
This receives:
0. Hash object.
1. Element to check for.

=item B<check_has($$)>

This method will throw an exception if the key passed to it does not
exist in the hash.
The method receives:
0. Hash object.
1. Element to check for.

=item B<check_hasnt($$)>

This method does the exact opposite of check_has.

=item B<get($$)>

This returns a certain element from the hash.

=item B<load($$)>

This will read a hash from a file assuming that file has an entry for the
hash as two string separated by a space on each line until the end of the
file.

=item B<save($$)>

This will write a hash table as in the read method. See that methods
documentation for details.

=item B<clear($)>

This method will clear all elements in the hash. It is fast.

=item B<filter($$)>

This method receives a hash table and some code reference.
The method will return a hash which has all the elements in the
original hash for which the code did not throw any exceptions.

=item B<foreach($$)>

This method will iterate over all elements of the hash and will
run a user given function on everyone of them. The function should
receive two inputs: a key and a value. The function can do just about
anything you like.

=item B<add_hash($$)>

This method adds a hash to the current one by iterating over
it's elements and adding them one by one.

=item B<remove_hash($$)>

This method removes a give hash from the current one.
It does so by iterating over the given hashs elements and removing
them one by one from the current hash.
This method receives:
0. Hash object.
1. Hash object which contains elements to be removed.

=item B<add_key_prefix($$)>

This method will return a new hash which will be exactly like the original
except every key will be prefixed by the prefix you give.

=item B<internal_hash($)>

This method will give you the internal hash that this data structure uses.
Be careful and use it read only or you risk rendering this data structure
unusable.

=item B<TEST($)>

Test suite for this module.
This test suite is can be called directly to test very basic functionality of
this class or by a higher level test code to test the entire functionality of
a class library this class is provided with.
Currently this test only creates a small hash and dumps it.

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
	0.02 MV handle architectures better
	0.03 MV get the databases to work
	0.04 MV ok. This is for real
	0.05 MV ok - this time I realy mean it
	0.06 MV make quality checks on perl code
	0.07 MV more perl checks
	0.08 MV make Meta::Utils::Opts object oriented
	0.09 MV check that all uses have qw
	0.10 MV fix todo items look in pod documentation
	0.11 MV add enumerated types to options
	0.12 MV more on tests/more checks to perl
	0.13 MV change new methods to have prototypes
	0.14 MV correct die usage
	0.15 MV finish Simul documentation
	0.16 MV perl code quality
	0.17 MV more perl quality
	0.18 MV more perl quality
	0.19 MV perl documentation
	0.20 MV more perl quality
	0.21 MV perl qulity code
	0.22 MV more perl code quality
	0.23 MV revision change
	0.24 MV languages.pl test online
	0.25 MV PDMT/SWIG support
	0.26 MV Pdmt stuff
	0.27 MV perl packaging
	0.28 MV md5 project
	0.29 MV database
	0.30 MV perl module versions in files
	0.31 MV movies and small fixes
	0.32 MV more thumbnail stuff
	0.33 MV thumbnail user interface
	0.34 MV more thumbnail issues
	0.35 MV website construction
	0.36 MV web site automation
	0.37 MV SEE ALSO section fix
	0.38 MV move tests to modules
	0.39 MV weblog issues
	0.40 MV teachers project
	0.41 MV md5 issues

=head1 SEE ALSO

Meta::Error::NoSuchElement(3), Meta::Error::Simple(3), Meta::IO::File(3), strict(3)

=head1 TODO

-Add many more routines: 1. add/subtract a hash. 2. get a list from a hash. 3. get a set from a hash. 4. get a hash from a list. 5. get a hash from a set. 6. insert an element and make sure that he wasnt there. 7. remove an element and make sure that he was there.

-add a limitation on the types of objects going into the hash (they must be inheritors from some kind of object).

-make option for hash to be strict (that insert twice will yell).

-make all methods here return the hash object so more ops could be performed.

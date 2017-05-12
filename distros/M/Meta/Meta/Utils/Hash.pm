#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Hash;

use strict qw(vars refs subs);
use Meta::Utils::Utils qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Output qw();
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.35";
@ISA=qw();

#sub size($);
#sub empty($);
#sub notempty($);
#sub read($);
#sub read_exe($);
#sub cmp($$$$$);
#sub to_list($);
#sub add_hash($$);
#sub remove_hash($$$);
#sub add_prefix($$);
#sub add_suffix($$);
#sub system($$$$);
#sub dup($);

#sub add_key_prefix($$);
#sub add_key_suffix($$);

#sub filter_prefix($$$);
#sub filter_prefix_add($$$$);
#sub filter_multi($$$$);
#sub filter_suffix($$$);
#sub filter_regexp($$$);
#sub filter_regexp_add($$$$);
#sub filter_file_sing_regexp($$$);
#sub filter_which($$$);
#sub filter_exists($);
#sub filter_notexists($);

#sub save($$);
#sub load($$);

#sub TEST($);

#__DATA__

sub cmp($$$$$) {
	my($has1,$nam1,$has2,$nam2,$verb)=@_;
#	Meta::Utils::Arg::check_arg($has1,"HASH");
#	Meta::Utils::Arg::check_arg($nam1,"SCALAR");
#	Meta::Utils::Arg::check_arg($has2,"HASH");
#	Meta::Utils::Arg::check_arg($nam2,"SCALAR");
	my($name,$val);
	my($stat)=0;
	while(($name,$val)=each(%$has1)) {
		if(!exists($has2->{$name})) {
			Meta::Utils::Output::verbose($verb,"[".$name."] in [".$nam1."] and not in [".$nam2."]\n");
			$stat=1;
		}
	}
	while(($name,$val)=each(%$has2)) {
		if(!exists($has1->{$name})) {
			Meta::Utils::Output::verbose($verb,"[".$name."] in [".$nam2."] and not in [".$nam1."]\n");
			$stat=1;
		}
	}
	return(!$stat);
}

sub to_list($) {
	my($hash)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	my(@list);
	while(my($key,$val)=each(%$hash)) {
		push(@list,$key);
	}
	return(\@list);
}

sub add_hash($$) {
	my($from,$hash)=@_;
#	Meta::Utils::Arg::check_arg($from,"HASH");
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	while(my($key,$val)=each(%$hash)) {
		$from->{$key}=$val;
	}
}

sub remove_hash($$$) {
	my($from,$hash,$stri)=@_;
#	Meta::Utils::Arg::check_arg($from,"HASH");
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	while(my($key,$val)=each(%$hash)) {
		if(exists($from->{$key})) {
			delete($from->{$key});
		} else {
			if($stri) {
				throw Meta::Error::Simple("elem [".$key."] is a bad value");
			}
		}
	}
}

sub add_prefix($$) {
	my($hash,$pref)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($pref,"SCALAR");
	my(%resu);
	while(my($key,$val)=each(%$hash)) {
		$resu{$key}=$pref.$hash->{$key};
	}
	return(\%resu);
}

sub add_suffix($$) {
	my($hash,$suff)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($suff,"SCALAR");
	my(%resu);
	while(my($key,$val)=each(%$hash)) {
		$resu{$key}=$hash->{$key}.$suff;
	}
	return(\%resu);
}

sub add_key_prefix($$) {
	my($hash,$pref)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($pref,"SCALAR");
	my(%resu);
	while(my($key,$val)=each(%$hash)) {
		$resu{$pref.$key}=$val;
	}
	return(\%resu);
}

sub add_key_suffix($$) {
	my($hash,$suff)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($suff,"SCALAR");
	my(%resu);
	while(my($key,$val)=each(%$hash)) {
		$resu{$key.$suff}=$val;
	}
	return(\%resu);
}

sub read($) {
	my($file)=@_;
	my(%hash);
	my($io)=Meta::IO::File->new_reader($file);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
		$hash{$line}=defined;
	}
	$io->close();
	return(\%hash);
}

sub read_exe($) {
	my($exe)=@_;
	return(&read("$exe |"));
}

sub filter_prefix($$$) {
	my($hash,$pref,$posi)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($pref,"SCALAR");
#	Meta::Utils::Arg::check_arg($posi,"SCALAR");
	my(%retu);
	filter_prefix_add($hash,$pref,$posi,\%retu);
	return(\%retu);
}

sub filter_prefix_add($$$$) {
	my($hash,$pref,$posi,$retu)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($pref,"SCALAR");
#	Meta::Utils::Arg::check_arg($posi,"SCALAR");
#	Meta::Utils::Arg::check_arg($retu,"HASH");
	while(my($key,$val)=each(%$hash)) {
		if(Meta::Utils::Utils::is_prefix($key,$pref)) {
			if($posi) {
				$retu->{$key}=$val;
			}
		} else {
			if(!$posi) {
				$retu->{$key}=$val;
			}
		}
	}
}

sub filter_multi($$$$) {
	my($hash,$dmod,$dire,$modu)=@_;
	my(@modu)=split(':',$modu);
	my(%rhas);
	if($dmod) {
		if($dire!=2) {
			for(my($i)=0;$i<=$#modu;$i++) {
				&filter_prefix_add($hash,$modu[$i]."/",$dire,\%rhas);
			}
		}
		return(\%rhas);
	} else {
		return($hash);
	}
}

sub filter_suffix($$$) {
	my($hash,$filt,$posi)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($filt,"SCALAR");
#	Meta::Utils::Arg::check_arg($posi,"SCALAR");
	my(%retu);
	while(my($key,$val)=each(%$hash)) {
		if(Meta::Utils::Utils::is_suffix($key,$filt)) {
			if($posi) {
				$retu{$key}=$val;
			}
		} else {
			if(!$posi) {
				$retu{$key}=$val;
			}
		}
	}
	return(\%retu);
}

sub filter_regexp($$$) {
	my($hash,$rege,$posi)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($rege,"SCALAR");
#	Meta::Utils::Arg::check_arg($posi,"SCALAR");
	my(%retu);
	filter_regexp_add($hash,$rege,$posi,\%retu);
	return(\%retu);
}

sub filter_regexp_add($$$$)
{
	my($hash,$rege,$posi,$retu)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($rege,"SCALAR");
#	Meta::Utils::Arg::check_arg($posi,"SCALAR");
#	Meta::Utils::Arg::check_arg($retu,"HASH");
	while(my($key,$val)=each(%$hash)) {
		if($key=~/$rege/) {
			if($posi) {
				$retu->{$key}=$val;
			}
		} else {
			if(!$posi) {
				$retu->{$key}=$val;
			}
		}
	}
}

sub empty($) {
	my($hash)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	return(size($hash)==0);
}

sub notempty($) {
	my($hash)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	return(size($hash)>0);
}

sub system($$$$) {
	my($hash,$syst,$demo,$verb)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	while(my($key,$val)=each(%$hash)) {
		Meta::Utils::Output::verbose($verb,"doing [".$syst."] [".$key."]\n");
		if(!$demo) {
			Meta::Utils::System::system($syst,[$key]);
		}
	}
}

sub dup($) {
	my($hash)=@_;
	my($res_hash)={};
	while(my($key,$val)=each(%$hash)) {
		$res_hash->{$key}=$val;
	}
	return($res_hash);
}

sub size($) {
	my($hash)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	my(@list)=keys(%$hash);
	my($retu)=$#list;
	$retu++;
	return($retu);
}

sub filter_file_sing_regexp($$$) {
	my($hash,$rege,$prin)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
#	Meta::Utils::Arg::check_arg($rege,"SCALAR");
#	Meta::Utils::Arg::check_arg($prin,"SCALAR");
	my(%retu);
	while(my($key,$val)=each(%$hash)) {
		if(Meta::Utils::File::File::check_sing_regexp($key,$rege,$prin)) {
			$retu{$key}=$val;
		}
	}
	return(\%retu);
}

sub filter_which() {
}

sub filter_notexists($) {
	my($hash)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
	my(%inte);
	while(my($key,$val)=each(%$hash)) {
		my($curr)=$key;
		if(!(-e $curr)) {
			$inte{$curr}=defined;
		}
	}
	return(\%inte);
}

sub save($$) {
	my($hash,$file)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
}

sub load($$) {
	my($hash,$file)=@_;
#	Meta::Utils::Arg::check_arg($hash,"HASH");
}

sub TEST($) {
	my($context)=@_;
	my(%hash);
	$hash{"mark"}="veltzer";
	$hash{"linus"}="torvalds";
	my($size)=Meta::Utils::Hash::size(\%hash);
	Meta::Utils::Output::print("size is [".$size."]\n");
	if($size eq 2) {
		return(1);
	} else {
		return(0);
	}
}

1;

__END__

=head1 NAME

Meta::Utils::Hash - general base utility library for many hash functions.

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
	VERSION: 0.35

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Hash qw();
	my(%hash);
	my($size)=Meta::Utils::Hash::size(\%hash);
	# $size should now be 0

=head1 DESCRIPTION

This is a general utility perl library for all kinds of hash routines.
This mainly iterates hashes using the each builtin which is the fastest
to do the job and like the list library uses refernces to avoid duplication
whereever possible.

=head1 FUNCTIONS

	size($)
	empty($)
	notempty($)
	read($)
	read_exe($)
	cmp($$$$$)
	to_list($)
	add_hash($$)
	remove_hash($$$)
	add_prefix($$)
	add_suffix($$)
	system($$$$)
	dup($)
	add_key_prefix($$)
	add_key_suffix($$)
	filter_prefix($$$)
	filter_prefix_add($$$$)
	filter_multi($$$$)
	filter_suffix($$$)
	filter_regexp($$$)
	filter_regexp_add($$$$)
	filter_file_sing_regexp($$$)
	filter_which($$$)
	filter_exists($)
	filter_notexists($)
	save($$)
	load($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<cmp($$$$$)>

This functions compares two hashes according to keys and prints the values
which exists in any of them but not in the other
The return value is a boolean which is true iff the two hashes are equal.
The routine also receives a boolean value telling it to be verbose or not.

=item B<to_list($)>

This takes a hash reference as input and produces a list which has all the
keys in the hash in it. since the keys in the hash are unique the list is
unique also...:)

=item B<add_hash($$)>

This function receives two hashes and adds the second one to the first
one the fastest way possible.

=item B<remove_hash($$$)>

This function receives:
0. A source hash.
1. A hash to remove from the source hash.
2. A strict parameter to tell the function whether to die if an element is
	in the subtracted hash but not in the source one.
The function changes the source hash so as not to contain any elements in
the removed hash.
The function doesnt return anything.

=item B<add_prefix($$)>

This routine adds a constant prefix to all the element in a hash.
Traversal (ofcourse) is using the each operator

=item B<add_suffix($$)>

This routine adds a constant suffix to all the element in a hash.
Traversal (ofcourse) is using the each operator

=item B<add_key_prefix($$)>

This routine adds a constant prefix to all the keys in a hash.
Traversal (ofcourse) is using the each operator

=item B<add_key_suffix($$)>

This routine adds a constant suffix to all the keys in a hash.
Traversal (ofcourse) is using the each operator.

=item B<read($)>

This reads a hash table from a file by assuming that every line is
a key and giving all the keys a value of undef.
That means that the key will exist but the value will be undefined.

=item B<read_exe($)>

This routine is the same as read except that the argument is
a command line to run out of which will come the stdout file that we need
to run. Why not just dump the outcome to a temp file and then read it
using the previous routine ? because its stupid and uses the disk which
we do not need to do...
What we do is just pipe the output to a file that we open and execute
the same algorithm as before.
As it turns out we do call the previous routine but we change the file
argument to mean "the stdout stream that comes out of the "$cmd" command"...

=item B<filter_prefix($$$)>

This routines receives a hash and a prefix and returns a hash with only
the elements in the original hash which have such a prefix...
This also receives the a third argument that instructs it to act as a negative
or a positive filter.

=item B<filter_prefix_add($$$$)>

This routine filters according to prefix and instruction a certain hash and
adds the results to a second.

=item B<filter_multi($$$$)>

This one is a full filter. This gets:
0. a hash.
1. whether to do filtering or not.
2. boolean indicating whether filter is negative or positive.
3. list of modules for filtering data.
And does the entire filtering process in an efficient manner.

=item B<filter_suffix($$$)>

This routines receives a hash and a suffix and returns a hash with only
the elements in the original hash which had such a suffix...
This also receives the a third argument that instructs it to act as a negative
or a positive filter.

=item B<filter_regexp($$$)>

This routine filters to the result hash all elements of the hash it
gets which match a regular expression.
There is also a third argument telling the filter to act as positive or
negative.

=item B<filter_regexp_add($$$$)>

This routine adds to the received hash all the elements of the hash that
match/not match (according to the posi argument) elements of the current hash.

=item B<empty($)>

This routine receives a hash reference.
This routine returns a boolean value according to whether the hash is
empty or not

=item B<notempty($)>

This routine receives a hash reference.
This routine returns a boolean value accroding to whether the hash is
not empty or not

=item B<system($$$$)>

This routine runs a system command for all keys of a hash.
The inputs are: the hash,the system command,demo and verbose.

=item B<dup($)>

This function receives a hash reference and duplicates it.

=item B<size($)>

This routine returns the number of elements in the hash (actual elements
and not in the strange convention for perl where the size of the array is
the number of elements minus 1.

=item B<filter_file_sing_regexp($$$)>

This routine receives a hash and a regular expression and returns a hash
containing only the elements in the hash which are pointers to files which
contain a the regular expression.
This also receives as the third variable whether to print the matched lines
or not (this is passes along to Meta::Utils::File::File::check_sing_regexp).

=item B<filter_which()>

This needs to be written.

=item B<filter_notexists($)>

This does the exact opposite of the previous routine.
Should we also have the same routine that actually does the manipulation on
the list itself ? it would be faster...

=item B<save($$)>

This routine saves the entire hash to a disk file.

=item B<load($$)>

This routine loads the entire hash from a disk file.

=item B<TEST($)>

Test suite for this module.
Currently this test creates a small hash table and checks that the size
method of this package works.

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
	0.01 MV this time really make the databases work
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV fix up perl checks
	0.06 MV fix todo items look in pod documentation
	0.07 MV more on tests/more checks to perl
	0.08 MV fix all tests change
	0.09 MV more perl quality
	0.10 MV correct die usage
	0.11 MV perl code quality
	0.12 MV more perl quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV more perl quality
	0.19 MV revision change
	0.20 MV languages.pl test online
	0.21 MV PDMT/SWIG support
	0.22 MV perl packaging
	0.23 MV PDMT
	0.24 MV md5 project
	0.25 MV database
	0.26 MV perl module versions in files
	0.27 MV movies and small fixes
	0.28 MV more thumbnail code
	0.29 MV thumbnail user interface
	0.30 MV more thumbnail issues
	0.31 MV website construction
	0.32 MV web site automation
	0.33 MV SEE ALSO section fix
	0.34 MV bring movie data
	0.35 MV md5 issues

=head1 SEE ALSO

Meta::IO::File(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-cant we do the size more efficiently ?

-do the sub filter_file_mult_regexp($$) routine

-the read_exe routine gets a shell command line and sometimes you dont want that overhead. make a routine that does the same and doesnt pass through the shell and check where the current routine is used and replace where ever possible.

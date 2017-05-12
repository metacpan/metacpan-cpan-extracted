#!/bin/echo This is a perl module and should not be run

package Meta::Utils::List;

use strict qw(vars refs subs);
use Meta::Utils::Arg qw();
use Meta::Utils::Hash qw();
use Meta::Utils::Output qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.39";
@ISA=qw();

#sub size($);
#sub empty($);
#sub notempty($);
#sub cmp($$$$$);
#sub print($$);
#sub add_postfix($$);
#sub to_hash($);
#sub chop($);
#sub add_prefix($$);
#sub add_suffix($$);
#sub add_hash_style($$);
#sub has_elem($$);
#sub add_star($$);
#sub add_endx($$);

#sub filter_prefix($$);
#sub filter_suffix($$);
#sub filter_file_regexp($$);
#sub filter_which($$$);
#sub filter_exists($);
#sub filter_notexists($);

#sub read($);
#sub read_exe($);

#sub equa($$);
#sub is_prefix($$);

#sub TEST($);

#__DATA__

sub size($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	my($resu)=$#$list;
	return($resu+1);
}

sub empty($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	return(size($list)==0);
}

sub notempty($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	return(size($list)>0);
}

sub cmp($$$$$) {
	my($lst1,$nam1,$lst2,$nam2,$verb)=@_;
#	Meta::Utils::Arg::check_arg($lst1,"ARRAY");
#	Meta::Utils::Arg::check_arg($nam1,"SCALAR");
#	Meta::Utils::Arg::check_arg($lst2,"ARRAY");
#	Meta::Utils::Arg::check_arg($nam2,"SCALAR");
	my($has1)=to_hash($lst1);
	my($has2)=to_hash($lst2);
	return(Meta::Utils::Hash::cmp($has1,$nam1,$has2,$nam2,$verb));
}

sub print($$) {
	my($file,$list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	my($size)=$#$list+1;
	for(my($i)=0;$i<$size;$i++) {
		print $file $list->[$i]."\n";
	}
}

sub add_postfix($$) {
	my($list,$post)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($post,"ANY");
	for(my($i)=0;$i<=$#$list;$i++) {
		$list->[$i]=$list->[$i].$post;
	}
}

sub to_hash($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	my(%hash);
	for(my($i)=0;$i<=$#$list;$i++) {
		$hash{$list->[$i]}=defined;
	}
	return(\%hash);
}

sub chop($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	for(my($i)=0;$i<=$#$list;$i++) {
		chop($list->[$i]);
	}
}

sub add_prefix($$) {
	my($list,$pref)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($pref,"ANY");
	for(my($i)=0;$i<=$#$list;$i++) {
		$list->[$i]=$pref.$list->[$i];
	}
}

sub add_suffix($$) {
	my($list,$suff)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($suff,"ANY");
	for(my($i)=0;$i<=$#$list;$i++) {
		$list->[$i]=$list->[$i].$suff;
	}
}

sub add_hash_style($$) {
	my($list,$elem)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	if(!has_elem($list,$elem)) {
		push(@$list,$elem);
	}
}

sub has_elem($$) {
	my($list,$elem)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	my($resu)=0;
	for(my($i)=0;$i<=$#$list;$i++) {
		if($list->[$i] eq $elem) {
			$resu=1;
		}
	}
	return($resu);
}

sub add_star($$) {
	my($list,$elem)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	for(my($i)=$#$list+1;$i>=0;$i--) {
		$list->[$i]=$list->[$i-1];
	}
	$list->[0]=$elem;
}

sub add_endx($$) {
	my($list,$elem)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($elem,"ANY");
	push(@$list,$elem);
}

sub filter_prefix($$) {
	my($list,$reld)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($reld,"ANY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(substr($curr,0,length($reld)) eq $reld) {
			push(@inte,$curr);
		}
	}
	return(\@inte);
}

sub filter_suffix($$) {
	my($list,$reld)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($reld,"ANY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(substr($curr,length($curr)-length($reld),length($reld)) eq $reld) {
			push(@inte,$curr);
		}
	}
	return(\@inte);
}

sub filter_exists($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(-e $curr) {
			push(@inte,$curr);
		}
	}
	return(\@inte);
}

sub filter_notexists($) {
	my($list)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(!(-e $curr)) {
			push(@inte,$curr);
		}
	}
	return(\@inte);
}

sub filter_which($$$) {
	my($list,$chnp,$basp)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($chnp,"ANY");
#	Meta::Utils::Arg::check_arg($basp,"ANY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		my($chnt)=$chnp."/".$curr;
		if(-e $chnt) {
			push(@inte,$chnt);
		} else {
			my($bast)=$basp."/".$curr;
			if(-e $bast) {
				push(@inte,$bast);
			} else {
				throw Meta::Error::Simple("cannot find file in change or baseline [".$curr."]");
			}
		}
	}
	return(\@inte);
}

sub filter_file_regexp($$) {
	my($list,$rege)=@_;
#	Meta::Utils::Arg::check_arg($list,"ARRAY");
#	Meta::Utils::Arg::check_arg($rege,"ANY");
	my(@inte);
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(check_sing_regexp($curr,$rege)) {
			push(@inte,$curr);
		}
	}
	return(\@inte);
}

sub read($) {
	my($file)=@_;
#	Meta::Utils::Arg::check_arg($file,"ANY");
	my(@list);
	my($io)=Meta::IO::File->new_reader($file);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
		push(@list,$line);
	}
	$io->close();
	return(\@list);
}

sub equa($$) {
	my($lst1,$lst2)=@_;
	if(0) {
		Meta::Utils::Output::print("list 1 is\n");
		&print(Meta::Utils::Output::get_file(),$lst1);
		Meta::Utils::Output::print("list 2 is\n");
		&print(Meta::Utils::Output::get_file(),$lst2);
	}
	my($siz1)=$#$lst1+1;
	my($siz2)=$#$lst2+1;
	if($siz1!=$siz2) {
		return(0);
	}
	my($size)=$siz1;# arbitrary
	for(my($i)=0;$i<=$size;$i++) {
		if($lst1->[$i] ne $lst2->[$i]) {
			return(0);
		}
	}
	return(1);
}

sub is_prefix($$) {
	my($lst1,$lst2)=@_;
	my($siz1)=$#$lst1;
	my($siz2)=$#$lst2;
#	Meta::Utils::Output::print("siz1 is [".$siz1."]\n");
#	Meta::Utils::Output::print("siz2 is [".$siz2."]\n");
	if($siz1>$siz2) {
		return(0);
	}
	for(my($i)=0;$i<=$siz1;$i++) {
		if($lst1->[$i] ne $lst2->[$i]) {
#			Meta::Utils::Output::print("one is [".$lst1->[$i]."]\n");
#			Meta::Utils::Output::print("two is [".$lst2->[$i]."]\n");
			return(0);
		}
	}
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::List - general library for list functions.

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

	MANIFEST: List.pm
	PROJECT: meta
	VERSION: 0.39

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::List qw();
	my(@list)=["sunday","monday",...];
	Meta::Utils::List::print(*FILE,\@list);

=head1 DESCRIPTION

This is a general utility perl library for list manipulation in perl.
This library works mostly with list references rather than the list
themselves to avoid extra work when copying them.

=head1 FUNCTIONS

	size($)
	empty($)
	notempty($)
	cmp($$$$$)
	print($$)
	add_postfix($$)
	to_hash($)
	chop($)
	add_prefix($$)
	add_suffix($$)
	add_hash_style($$)
	has_elem($$)
	add_star($$)
	add_endx($$)
	filter_prefix($$)
	filter_suffix($$)
	filter_file_regexp($$)
	filter_which($$$)
	filter_exists($)
	filter_notexists($)
	read($)
	read_exe($)
	equa($$)
	is_prefix($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<size($)>

This routine returns the list size at hand (using the #$ shit...)
The input is a list reference.

=item B<empty($)>

This routine receives a list reference.
This routine returns a boolean value according to whether the list is
empty or not

=item B<notempty($)>

This routine receives a list reference.
This routine returns a boolean value according to whether the list is
not empty or not

=item B<cmp($$$$$)>

This routine compares two lists by printing any value which is in one of them
but not in the other. This uses the Meta::Utils::Hash::cmp routine to chieve this.
The routine also receives a verbose boolean to direct it whether to write the
differences or not.

=item B<print($$)>

This prints out a list.
Currently just receives a list reference as input but could be enriched

=item B<add_postfix()>

This postfixes every element in a list.

=item B<to_hash($)>

This converts a list to a hash receiving a list reference and constructing
a hash which has a key value of undef on every list entry and no other values.

=item B<chop($)>

This chops up a list, meaning activates the chop function on every element.
This receives a list reference to do the work on.

=item B<add_prefix($$)>

This adds a prefix to every element of a list.
The input is a list reference and the prefix to be added.

=item B<add_suffix($$)>

This adds a suffix to every element of a list.
The input is a list reference and the suffix to be added.

=item B<add_hash_style($$)>

This adds an element to the list assuming that the list is a hash in
disguise. i.e. it does not add the element if the element is already in
the list.

=item B<has_elem($$)>

This routine returns a boolean value based on whether the list it got has
a certain element.

=item B<add_star($$)>

This adds an element to the beginging of a list.

=item B<add_endx($$)>

This adds an element to the end of a list.

=item B<filter_prefix($$)>

This gets a list reference as input and produces a list of all the entires
which have a certain prefix in them.
Should we also have the same routine that actually does the manipulation on
the list itself ? it would be faster...

=item B<filter_suffix($$)>

This gets a list reference as input and produces a list of all the entires
which have a certain suffix in them.
Should we also have the same routine that actually does the manipulation on
the list itself ? it would be faster...

=item B<filter_exists($)>

This gets a list reference of file names and generates a list of all the
entries in the original list which were actuall files that exist
Should we also have the same routine that actually does the manipulation on
the list itself ? it would be faster...

=item B<filter_notexists($)>

This does the exact opposite of the previous routine.
Should we also have the same routine that actually does the manipulation on
the list itself ? it would be faster...

=item B<filter_which($$$)>

fileters according to the relative path.

=item B<filter_file_regexp($$)>

This routine gets a list reference and a regular expression.
The routine will return a list reference to a list contraining all the
items in the original list that when taken as file names contain a match
for the regular expression. The routine utilises the check_sing_regexp
routine to actuall check the regular expression match.

=item B<read($)>

This reads a list from a file by storing each line in a list entry.

=item B<equa($$)>

This method will get two lists by reference and will return true off the two
lists are the same.

=item B<is_prefix($$)>

This method will get two lists by references and will return true iff the first is a prefix of the second.

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

	0.00 MV initial code brought in
	0.01 MV this time really make the databases work
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV fix up perl checks
	0.06 MV check that all uses have qw
	0.07 MV fix todo items look in pod documentation
	0.08 MV more on tests/more checks to perl
	0.09 MV more perl code quality
	0.10 MV more quality testing
	0.11 MV more perl code quality
	0.12 MV more perl quality
	0.13 MV correct die usage
	0.14 MV perl quality change
	0.15 MV perl code quality
	0.16 MV more perl quality
	0.17 MV more perl quality
	0.18 MV perl documentation
	0.19 MV more perl quality
	0.20 MV perl qulity code
	0.21 MV more perl code quality
	0.22 MV more perl quality
	0.23 MV revision change
	0.24 MV languages.pl test online
	0.25 MV PDMT/SWIG support
	0.26 MV perl packaging
	0.27 MV PDMT
	0.28 MV some chess work
	0.29 MV md5 project
	0.30 MV database
	0.31 MV perl module versions in files
	0.32 MV movies and small fixes
	0.33 MV more thumbnail code
	0.34 MV thumbnail user interface
	0.35 MV more thumbnail issues
	0.36 MV website construction
	0.37 MV web site automation
	0.38 MV SEE ALSO section fix
	0.39 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Utils::Arg(3), Meta::Utils::Hash(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-do prefix and postfix routines. the add_prefix and add_postfix routines are not good enough since they work on the list at hand. This is the most efficient way, but sometimes I dont want no one to change the current list...

#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Iterator;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Ds::Stack qw();
use Meta::Utils::Utils qw();
use Error qw(:try);
use Meta::IO::Dir qw();
use File::Basename qw();
use Meta::Ds::Oset qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub add_directory($$);
#sub add_directories($$$);
#sub add_file($$);
#sub add_files($$$);
#sub start($);
#sub next($);
#sub fini($);
#sub collect($):
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_want_files",
		-java=>"_want_dirs",
		-java=>"_curr",
		-java=>"_base",
		-java=>"_dire",
		-java=>"_over",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_want_files(1);
	$self->set_want_dirs(0);
	$self->{STACK_DIRE}=Meta::Ds::Stack->new();
	$self->{STACK_IO}=Meta::Ds::Stack->new();
	$self->{STACK_DIR}=Meta::Ds::Stack->new();
	$self->{STACK_FILE}=Meta::Ds::Stack->new();
}

sub add_directory($$) {
	my($self,$val)=@_;
	$self->{STACK_DIR}->push($val);
}

sub add_directories($$$) {
	my($self,$dlst,$sepa)=@_;
	my(@dirs)=CORE::split($sepa,$dlst);
	for(my($i)=0;$i<=$#dirs;$i++) {
		my($curr)=$dirs[$i];
		$self->add_directory($curr);
	}
}

sub add_file($$) {
	my($self,$val)=@_;
	$self->{STACK_FILE}->push($val);
}

sub add_files($$) {
	my($self,$flst,$sepa)=@_;
	my(@files)=CORE::split($sepa,$flst);
	for(my($i)=0;$i<=$#files;$i++) {
		my($curr)=$files[$i];
		$self->add_file($curr);
	}
}

sub start($) {
	my($self)=@_;
	$self->set_over(0);
	$self->next();
}

sub next($) {
	my($self)=@_;
	my($stack_dire)=$self->{STACK_DIRE};
	my($stack_io)=$self->{STACK_IO};
	if($stack_io->empty()) {#there are no more io stacks
		my($stack_dir)=$self->{STACK_DIR};
		if($stack_dir->empty()) {#no more dirs
			my($stack_file)=$self->{STACK_FILE};
			if($stack_file->empty()) {
				$self->set_over(1);
			} else {
				my($file_top)=$stack_file->pop();
				if($self->get_want_files()) {
					$self->set_curr($file_top);
					$self->set_base(File::Basename::basename($file_top));
					$self->set_dire(File::Basename::dirname($file_top));
				} else {
					$self->next();
				}
			}
		} else {
			my($dire_top)=$stack_dir->pop();
			$stack_io->push(Meta::IO::Dir->new($dire_top));
			$stack_dire->push($dire_top);
			if($self->get_want_dirs()) {
				$self->set_curr($dire_top);
				$self->set_base(File::Basename::basename($dire_top));
				$self->set_dire(File::Basename::dirname($dire_top));
			} else {
				$self->next();
			}
		}
	} else {#there are io stacks
		my($io)=$stack_io->top();
		my($dire)=$stack_dire->top();
		if($io->get_over()) {
			$io->close();
			$stack_io->pop();
			$stack_dire->pop();
			$self->next();
		} else {
			my($curr)=$io->get_curr();
			my($full)=$dire."/".$curr;
			if(-d $full) {
				$stack_io->push(Meta::IO::Dir->new($full));
				#Meta::Utils::Output::print("pushing [".$full."]\n");
				$stack_dire->push($full);
				$io->next();
				if($self->get_want_dirs()) {
					$self->set_curr($full);
					$self->set_base($curr);
					$self->set_dire($dire);
				} else {
					$self->next();
				}
			}
			if(-f $full) {
				$io->next();
				if($self->get_want_files()) {
					$self->set_curr($full);
					$self->set_base($curr);
					$self->set_dire($dire);
				} else {
					$self->next();
				}
			}
		}
	}
}

sub fini($) {
	my($self)=@_;
	$self->set_over(0);
	#emtpy the stacks here
}

sub collect($) {
	my($directory)=@_;
	my($iterator)=__PACKAGE__->new();
	$iterator->set_want_dirs(1);
	$iterator->set_want_files(1);
	$iterator->add_directory($directory);
	my($set)=Meta::Ds::Oset->new();
	$iterator->start();
	while(!$iterator->get_over()) {
		$set->insert($iterator->get_curr());
		$iterator->next();
	}
	$iterator->fini();
	return($set);
}

sub TEST($) {
	my($context)=@_;
	my($dire)=Meta::Baseline::Aegis::baseline()."/data";
	my($set)=&collect(Meta::Baseline::Aegis::baseline()."/data");
	$set->foreach(\&Meta::Utils::Output::println);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Iterator - iterate files in directories.

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

	MANIFEST: Iterator.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Iterator qw();
	my($iterator)=Meta::Utils::File::Iterator->new();
	$iterator->add_directory("/home/mark");
	$iterator->start();
	while(!$iterator->get_over()) {
		print $iterator->get_curr()."\n";
		$iterator->next();
	}
	$iterator->fini();

=head1 DESCRIPTION

This is an iterator object which allows you to streamline work which
has to do with recursing subdirs. Give this object a subdir to
recurse and it will give you the next file to work on whenever you
ask it to. The reason this method is more streamlined is that you
dont need to know anything about iterating file systems and still
you dont get all the filenames that you will be working on in RAM
at the same time. Lets say that you're working on 100,000 files
(which is more than the number of arguments that you can give
to a utility program on a UNIX system by default...). How will you
work on it ? If you want to get the filenames on the command line
you have to use something like xargs which is an ugly hack since
it runs your utility way too many times (one time for each file).
If you don't want the xargs overhead then what you want is to
put the iterator in your source. Again, two methods are available.
Either you scan the file system and produce a list of the files
which you will be working on. This means that the RAM that your
program will take will be proportional to the number of files
you will be working on (and since you may not need knowledge
of all of them at the same time and you may even need them
one at a time with no relation to the others) - this is quite
a ram load. The other method is the method presented here:
use this iterator.

This iterator can give you directory names or just the files.
The default behaviour is to iterate just the files.

The interface to this object is quite object oriented. See the
synopsis for an example.

The object may receive several directories to iterate and it
will iterate them in sequence. The object may also receive
file which will take part in the iteration.

The object will throw exceptions if any errors occur. Please
see Error.pm for detail about catching or ignoring those.

=head1 FUNCTIONS

	BEGIN()
	init($)
	add_directory($$)
	add_directories($$$)
	add_file($$)
	add_files($$$)
	start($)
	next($)
	fini($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method creates the accessor methods for the following attributes:
0. "want_files" - do you want to iterate regular file.
1. "want_dirs" - do you want to iterate directories.
2. "curr" - current file/directory of the iterator.
3. "base" - basename (name without directory) of the current file/directory.
4. "dire" - directory of the current file/directory.
5. "over" - is the iterator over ?

=item B<init($)>

This is an internal post-constructor.

=item B<add_directory($$)>

This method will set the directory that this iterator will
scan. Right now, if you add the same directory with different
names, it will get iteraterd twice. This is on the todo list.

=item B<add_directories($$$)>

This method receives:
1. A file iterator object to work on.
2. A string containing a catenated list of directories.
3. A separator string enabling split of directories.
The method will add each of the directories in the list to the
current file iterator. It will simply call add_directory on
each of these.

=item B<add_file($$)>

This method will add a single file to be iterated by the iterator.

=item B<add_files($$$)>

This method adds a file list to be iterated by the iterator. A separator
is also supplied to split them up.

=item B<start($)>

This will initialize the iterator. After that you can
start calling get_over in a loop and in the loop use
get_curr and next.

=item B<next($)>

This method iterates to the next value. You need to check
if there are more entries to iterate using the "get_over"
method after using this one.

=item B<fini($)>

This method wraps the iterator up (does various cleanup).
You're not obliged to call this one but for future purposes
you better...:)

=item B<collect($$)>

This is a static method which uses the current object to provide
you with a set object which has all the files under a certain directory.

=item B<TEST($)>

Test suite for this module.
This test suite can be called to test the functionality of this module on a stand
alone basis or as a part of a high level testing suite for an entire class library
this class is provided with.
Currently this test suite iterates over some directories and prints the results.

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

	0.00 MV more perl packaging
	0.01 MV PDMT
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV movie stuff
	0.07 MV graph visualization
	0.08 MV more thumbnail stuff
	0.09 MV thumbnail user interface
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site development
	0.13 MV web site automation
	0.14 MV SEE ALSO section fix
	0.15 MV move tests to modules
	0.16 MV md5 issues

=head1 SEE ALSO

Error(3), File::Basename(3), Meta::Class::MethodMaker(3), Meta::Ds::Oset(3), Meta::Ds::Stack(3), Meta::IO::Dir(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-enable breadth vs depth first search.

-enable different options for filtering which files get delivered (suffixes, regexps, types etc...).

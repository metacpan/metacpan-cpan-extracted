#!/bin/echo This is a perl module and should not be run

package Meta::Utils::File::Iter;

use strict qw(vars refs subs);
use Meta::Class::MethodMaker qw();
use Meta::Ds::Stack qw();
use Meta::Ds::Hash qw();
use DirHandle qw();
use File::stat qw();
use Meta::Utils::Output qw();
use Meta::Utils::Utils qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub add_directory($$);
#sub start($);
#sub nstart($);
#sub next($);
#sub nnext($);
#sub fini($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_want_files",
		-java=>"_want_dirs",
		-java=>"_over",
		-java=>"_curr",
		-java=>"_curr_base",
		-java=>"_level",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_want_files(1);
	$self->set_want_dirs(1);
	$self->set_over(0);
	$self->{STACK}=Meta::Ds::Stack->new();
	$self->{STACK_NAME}=Meta::Ds::Stack->new();
	$self->{INODE_HASH}=Meta::Ds::Hash->new();
}

sub add_directory($$) {
	my($self,$val)=@_;
	my($handle)=DirHandle->new($val);
	if(defined($handle)) {
		$self->{STACK}->push($handle);
		$self->{STACK_NAME}->push($val);
		my($st)=File::stat::stat($val);
		my($inode)=$st->ino();
		$self->{INODE_HASH}->insert($inode);
	} else {
		throw Meta::Error::Simple("cannot create handle for [".$val."]");
	}
}

sub start($) {
	my($self)=@_;
	$self->set_over(0);
	$self->next();
}

sub nstart($) {
	my($self)=@_;
	$self->set_over(0);
	$self->nnext();
}

sub next($) {
	my($self)=@_;
	#Meta::Utils::Output::print("size is [".$self->{STACK}->size()."]\n");
	my($handle)=$self->{STACK}->top();
	my($name)=$self->{STACK_NAME}->top();
	my($curr);
	$curr=$handle->read();
	if(defined($curr)) {
		#if it is a directory - put it on the stack
		#Meta::Utils::Output::print("got [".$curr."]\n");
		my($full)=$name."/".$curr;
		$self->set_curr($full);
		$self->set_level($self->{STACK}->size());
		if(-d $full) {
			my($st)=File::stat::stat($full);
			my($inode)=$st->ino();
			my($hash)=$self->{INODE_HASH};
			if(!$hash->has($inode) && $curr ne "." && $curr ne "..") {
				$self->add_directory($full);
			}
		}
	} else {
		#Meta::Utils::Output::print("going to pop\n");
		#top directory is over
		$self->{STACK}->pop();
		$self->{STACK_NAME}->pop();
		if($self->{STACK}->empty()) {
			#stack is empty and we are over
			$self->set_over(1);
		} else {
			#stack is not empty - do exactly the same thing
			$self->next();
		}
	}
}

sub nnext($) {
	my($self)=@_;
	my($ok_to_exit)=0;
	while(!$ok_to_exit) {
		$self->next();
		if(!$self->get_over()) {
			if($self->get_want_dirs() && -d $self->get_curr()) {
				$ok_to_exit=1;
			}
			if($self->get_want_files() && -f $self->get_curr()) {
				$ok_to_exit=1;
			}
		} else {
			$ok_to_exit=1;
		}
	}
}

sub fini($) {
	my($self)=@_;
	$self->set_over(0);
	#emtpy the stacks here
}

sub TEST($) {
	my($context)=@_;
	my($dire)=Meta::Utils::Utils::get_home_dir()."/.kde/share/apps";
	my($iter)=Meta::Utils::File::Iter->new();
	$iter->add_directory($dire);
	$iter->set_want_dirs(0);
	$iter->nstart();
	while(!($iter->get_over())) {
		my($curr)=$iter->get_curr();
		Meta::Utils::Output::print("got [".$curr."]\n");
		$iter->nnext();
	}
	$iter->fini();
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::File::Iter - iterate files in directories.

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

	MANIFEST: Iter.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::File::Iter qw();
	my($iterator)=Meta::Utils::File::Iter->new();
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

=head1 FUNCTIONS

	BEGIN()
	init($)
	add_directory($)
	start($)
	nstart($)
	next($)
	nnext($)
	fini($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method will create set/get methods for the following attributes:
"want_files", "want_dirs", "over", "curr", "level".

=item B<init($)>

This is an internal post construction method. Do not use it directly.

=item B<add_directory($$)>

This method will set the directory that this iterator will
scan. Right now, if you add the same directory with different
names, it will get iteraterd twice. This is on the todo list.

=item B<start($)>

This will initialize the iterator. After that you can
start calling get_over in a loop and in the loop use
get_curr and next.

=item B<nstart($)>

Initialize the iterator and take heed of want_dirs and
want_files attributes.

=item B<next($)>

This method iterates to the next value. You need to check
if there are more entries to iterate using the "get_over"
method after using this one.

=item B<nnext($)>

Method which iterates and takes the want_dirs and want_files
attributes into consideration.

=item B<fini($)>

This method wraps the iterator up (does various cleanup).
You're not obliged to call this one but for future purposes
you better...:)

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

	0.00 MV movie stuff
	0.01 MV thumbnail project basics
	0.02 MV more thumbnail stuff
	0.03 MV thumbnail user interface
	0.04 MV import tests
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV web site development
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV finish papers
	0.11 MV md5 issues

=head1 SEE ALSO

DirHandle(3), File::stat(3), Meta::Class::MethodMaker(3), Meta::Ds::Hash(3), Meta::Ds::Stack(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-empty the stacks at finish

-enable breadth vs depth first search.

-enable different options for filtering which files get delivered (suffixes, regexps, types etc...).

-when doing add_directory translate it to cannonical form and add it to a HashStack which will only keep distinct values.

-add support for recursive via non recursive iteration (and even control the depth of the recursion).

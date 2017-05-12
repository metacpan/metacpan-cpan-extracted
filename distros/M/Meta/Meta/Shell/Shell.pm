#!/bin/echo This is a perl module and should not be run

package Meta::Shell::Shell;

use strict qw(vars refs subs);
use Term::ReadLine qw();
use Meta::Class::MethodMaker qw();
use Meta::Utils::System qw();
use Meta::IO::File qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Term::ReadLine);

#sub BEGIN();
#sub new($);
#sub pre($);
#sub run($);
#sub post($);
#sub process($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
#	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_prompt",
		-java=>"_startup",
		-java=>"_startup_file",
		-java=>"_history",
		-java=>"_history_file",
		-java=>"_quit",
		-java=>"_verbose",
		-java=>"_quit_yes_msg",
		-java=>"_quit_yes_msg_string",
		-java=>"_quit_no_msg",
		-java=>"_quit_no_msg_string",
		-java=>"_num",
	);
}

sub new($) {
	my($class)=@_;
	#my($self)=Term::ReadLine::new($class);
	my($self)=Term::ReadLine->new();
	bless($self,$class);
	return($self);
}

sub pre($) {
	my($self)=@_;
}

sub run($) {
	my($self)=@_;
	$self->pre();
	if($self->get_history()) {
		#Meta::Utils::Output::print("reading history to [".$self->get_history_file()."]\n");
		$self->ReadHistory($self->get_history_file());
	}
	if($self->get_startup()) {
		#process startup file.
		my($io)=Meta::IO::File->new($self->get_startup_file());
		if(defined($io)) {
			while(!$io->eof() && !$self->get_quit()) {
				my($line)=$io->getline();
				CORE::chop($line);
				$self->process($line);
			}
			$io->close();
		} else {
			Meta::Utils::Output::verbose($self->get_verbose(),"unable to open startup file [".$self->get_startup_file()."]\n");
		}
	}
	#this is the main loop where all the action takes place
	my($line);
	while(!$self->get_quit() && defined($line=$self->readline($self->get_prompt()))) {
		$self->process($line);
	}
	if($self->get_history()) {
		#Meta::Utils::Output::print("writing history to [".$self->get_history_file()."]\n");
		$self->WriteHistory($self->get_history_file());
	}
	if($self->get_quit()) {
		if($self->get_quit_yes_msg()) {
			Meta::Utils::Output::verbose($self->get_verbose(),
			"\n".$self->get_quit_yes_msg_string());
		}
	} else {
		if($self->get_quit_no_msg()) {
			Meta::Utils::Output::verbose($self->get_verbose(),
			"\n".$self->get_quit_no_msg_string());
		}
	}
	$self->post();
	return($self->get_quit());
}

sub post($) {
	my($self)=@_;
}

sub process($$) {
	my($self,$line)=@_;
	$self->set_num($self->get_num()+1);
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Shell::Shell - expand Term::ReadLine.

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

	MANIFEST: Shell.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Shell::Shell qw();
	my($object)=Meta::Shell::Shell->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is exactly like Term::ReadLine except it has many more attributes
and is able to run full readline loop for you where all you have to do is
subclass it and implement the process method.

=head1 FUNCTIONS

	BEGIN()
	new($)
	pre($)
	run($)
	post($)
	process($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method for the following attributes:
0. prompt - prompt to be used.
1. startup - read startup file ?
2. startup_file - startup file to read.
3. history - use history ?
4. history_file - history file to use.
5. quit - whether to quit mainloop or not.
6. verbose - whether to be verbose or not.
7. quit_yes_msg - print message in case of QUIT ?
8. quit_yes_msg_string - message to print in case of QUIT.
9. quit_no_msg - print message in case of EOF ?
10. quit_no_msg_string - message to print in case of EOF.

=item B<new($)>

This is a constructor for the Meta::Shell::Shell object.
This is not really needed and is present only because the regular
Term::ReadLine constructor is buggy in that it does not bless into
the class passed to it.

=item B<pre($)>

Method to override to perform application specific intialization.
Called from run before anything is done in that method.

=item B<run($)>

This actually runs the shell interface.

=item B<post($)>

Method to override to perform application specific cleanup.
Called from run after the running is done and in case of sudden
killing of the run method.

=item B<process($$)>

This is the method to override and do whatever the commands need
to do. The method receives the current object and the line received
by the user.

=item B<TEST($)>

This is a testing suite for the Meta::Shell::Shell module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

The reason that an explicit new is required here is that the regular Term::ReadLine constructor
doesn't respect the class passed to it and does not bless right.

=back

=head1 SUPER CLASSES

Term::ReadLine(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::IO::File(3), Meta::Utils::Output(3), Meta::Utils::System(3), Term::ReadLine(3), strict(3)

=head1 TODO

-use MethodMaker capabilities to make the virtual functions here virtual instead of coding them.

-add more messages (like in case of errors for instance).

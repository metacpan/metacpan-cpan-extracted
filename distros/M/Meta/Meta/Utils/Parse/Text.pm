#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Parse::Text;

use strict qw(vars refs subs);
use Meta::IO::File qw();
use IO::Pipe qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.31";
@ISA=qw();

#sub BEGIN();
#sub init_file($$);
#sub init_proc($$);
#sub next($);
#sub fini($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_type",
		-java=>"_file",
		-java=>"_over",
		-java=>"_line",
		-java=>"_numb",
		-java=>"_fnam",
		-java=>"_proc",
	);
}

sub init_file($$) {
	my($self,$fnam)=@_;
	my($file)=Meta::IO::File->new($fnam,"r");
	$self->set_type("file");
	$self->set_fnam($fnam);
	$self->set_file($file);
	my($line);
	if($line=<$file> || 0) {
		$self->set_over(0);
	} else {
		$self->set_over(1);
	}
	chop($line);
	$self->set_line($line);
	$self->set_numb(0);
}

sub init_proc($$) {
	my($self,$proc)=@_;
	my($file)=IO::Pipe->new();
	if(!defined($file)) {
		throw Meta::Error::Simple("unable to create object");
	}
	$file->reader(@$proc);
	$self->set_type("proc");
	$self->set_proc($proc);
	$self->set_file($file);
	my($line);
	if($line=<$file> || 0) {
		$self->set_over(0);
	} else {
		$self->set_over(1);
	}
	chop($line);
	$self->set_line($line);
	$self->set_numb(0);
}

sub next($) {
	my($self)=@_;
	my($file)=$self->get_file();
	my($line);
	if($line=<$file> || 0) {
		$self->set_over(0);
	} else {
		$self->set_over(1);
	}
	chop($line);
	$self->set_line($line);
	$self->set_numb($self->get_numb()+1);
}

sub fini($) {
	my($self)=@_;
	my($type)=$self->get_type();
	if($type eq "file") {
		my($file)=$self->get_file();
		if(!$file->close()) {
			throw Meta::Error::Simple("unable to close file [".$self->get_fnam()."]");
		}
	}
	if($type eq "proc") {
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Parse::Text - library to help you parse text files.

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

	MANIFEST: Text.pm
	PROJECT: meta
	VERSION: 0.31

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Parse::Text qw();
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file("/etc/passwd");
	while(!$parser->get_over()) {
		my($current_line)=$parser->get_line();
		# do something with $current_line
		$parser->next();
	}
	$parser->fini();

=head1 DESCRIPTION

This module helps you in parsing text files.
You construct a parser, give it a text file and loop until its over each
time getting the current line from it...
You can also init the parser from a process and so get the process output
in a pipe without having to temporarily store it. This enables you to get the
output of a process much cleaner and to avoid a need to store the output in
an intermediate file.

Why would you want such a parser ? Well - if all you want is to interate
through a text file that's ok but if you are looking to grow then you need
to reprogram the same code again and again in a non object oriented way.
For instance - you have written a perl standard parser using:
C<	while($line=E<lt>FILEE<gt>) {
	}
>
and now you want to do some error message from within the loop and indicate
the line number. Uh uh. Now you need to count the lines. Or, for instance,
you now need to get the input from a process and not a file. Or you need
a different delimiter. If you use this parser these types of changes are
easily done without breaking your code.

=head1 FUNCTIONS

	BEGIN()
	init_file($$)
	init_proc($$)
	next($)
	fini($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This function initializes the object with accessor methods to these attributes:
0. fnam: name of file to read from.
1. type: type of parser (file or proc).
2. over: is the parser over ?
3. line: current line parsed. 
4. file: file handle of the parser.
5. numb: line number the parser is at.
6. proc: procedure to get output from.

=item B<init_file($$)>

This function initializes the parser.
This function receives:
0. A parser object to work with.
1. A file name to work with.

=item B<init_proc($$)>

This function initializes the parser from a process instead of a file.

=item B<next($)>

This moves the parser to the next line.
This function receives:
0. A parser object to work with.

=item B<fini($)>

This methos wraps up the object closing any opened files, processes etc..
This function receives:
0. A parser object to work with.

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
	0.01 MV bring databases on line
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV fix all tests change
	0.08 MV change new methods to have prototypes
	0.09 MV correct die usage
	0.10 MV perl code quality
	0.11 MV more perl quality
	0.12 MV chess and code quality
	0.13 MV more perl quality
	0.14 MV perl documentation
	0.15 MV more perl quality
	0.16 MV perl qulity code
	0.17 MV more perl code quality
	0.18 MV revision change
	0.19 MV languages.pl test online
	0.20 MV perl packaging
	0.21 MV PDMT
	0.22 MV md5 project
	0.23 MV database
	0.24 MV perl module versions in files
	0.25 MV movies and small fixes
	0.26 MV thumbnail user interface
	0.27 MV more thumbnail issues
	0.28 MV website construction
	0.29 MV web site automation
	0.30 MV SEE ALSO section fix
	0.31 MV md5 issues

=head1 SEE ALSO

IO::Pipe(3), Meta::Class::MethodMaker(3), Meta::IO::File(3), strict(3)

=head1 TODO

-move this module to Utils/Text.

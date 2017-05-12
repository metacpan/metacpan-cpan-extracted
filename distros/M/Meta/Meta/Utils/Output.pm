#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Output;

use strict qw(vars refs subs);
use IO::Handle qw();
use Data::Dumper qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw();

#sub BEGIN();
#sub print($);
#sub println($);
#sub verbose($$);
#sub dump($);
#sub verbose_dump($$);
#sub get_file();
#sub get_handle();
#sub get_block();
#sub set_block($);
#sub TEST($);

#__DATA__

our($block)=0;

sub BEGIN() {
	STDOUT->IO::Handle::autoflush(1);
#	STDERR->IO::Handle::autoflush(1);
}

sub print($) {
	my($stri)=@_;
	if(!$block) {
		print STDOUT $stri;
	}
}

sub println($) {
	my($stri)=@_;
	&print($stri."\n");
}

sub verbose($$) {
	my($verb,$stri)=@_;
	if($verb) {
		print STDOUT $stri;
	}
}

sub dump($) {
	my($struct)=@_;
	&print(Data::Dumper::Dumper($struct));
}

sub verbose_dump($$) {
	my($verb,$struct)=@_;
	if($verb) {
		&dump($struct);
	}
}

sub get_file() {
	return(*STDOUT);
}

sub get_handle() {
	return(\*STDOUT);
}

sub get_block() {
	return($block);
}

sub set_block($) {
	my($iblock)=@_;
	$block=$iblock;
}

sub TEST($) {
	my($context)=@_;
	&print("Hello,\ World!\n");
	my(%hash)=("one","two","three","four");
	&dump(\%hash);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Output - write output messages to console.

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

	MANIFEST: Output.pm
	PROJECT: meta
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Output qw();
	my($object)=Meta::Utils::Output->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This is a central controller of output to the console. All output to the
console (i.e. what usually you did using stdout and stderr) you should do
through this.

this is a SPECIAL STDERR FILE

=head1 FUNCTIONS

	BEGIN()
	print($)
	println($)
	verbose($$)
	dump($)
	verbose_dump($$)
	get_file()
	get_handle()
	get_block()
	set_block($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is the BEGIN block for this module.
It is executed when the module is loaded.
Currently it just sets the autoflush on STDOUT which is not so by default.
The reason I don't do this for STDERR bacause by default STDERR is already
so.

=item B<print($)>

This prints out an output message to the console.

=item B<println($)>

This method prints out it's argument with newline attached.

=item B<verbose($$)>

This method prints out an output message to the console only if the first
parameter is true.

=item B<dump($)>

This method will dump to out any structure. It used Data::Dumper to do that.

=item B<verbose_dump($)>

This method will dump a structure only if the verbose flag is turned on. It uses
the dump method to do it's thing.

=item B<get_file()>

This method will return a file handle that other code can write to in order
to get output on the console.

=item B<get_handle()>

This method will return the code handle that other code can write to in order
to get output to the console.

=item B<get_block()>

This will retrieve whether currently printing output is blocked.

=item B<set_block($)>

This method will set the current blocking attribute.

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

	0.00 MV languages.pl test online
	0.01 MV get imdb ids of directors and movies
	0.02 MV perl packaging
	0.03 MV more movies
	0.04 MV md5 project
	0.05 MV database
	0.06 MV perl module versions in files
	0.07 MV movies and small fixes
	0.08 MV thumbnail user interface
	0.09 MV import tests
	0.10 MV more thumbnail issues
	0.11 MV website construction
	0.12 MV web site automation
	0.13 MV SEE ALSO section fix
	0.14 MV finish papers
	0.15 MV teachers project
	0.16 MV md5 issues

=head1 SEE ALSO

Data::Dumper(3), IO::Handle(3), strict(3)

=head1 TODO

-use Text::Wrap here to wrap up lines.

-do colorization.

-do reading of arguments from XML options database and control in here.

-read whether we should do the flushing from the XML options file.

-get rid of the "SPECIAL STDERR FILE" tag here intended to allow using STDERR.

-dont print via STDOUT and therefore don't call autoflush on it. STDOUT is for results and not for messages. Use STDERR which already flushes.

-give out a file handle to /dev/null if it is requested when block is 1.

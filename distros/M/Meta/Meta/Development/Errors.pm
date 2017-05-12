#!/bin/echo This is a perl module and should not be run

package Meta::Development::Errors;

use strict qw(vars refs subs);
use Meta::Tool::Editor qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub print($);
#sub edit($);
#sub TEST($);

#__DATA__

sub print($) {
	my($dom)=@_;
}

sub edit($) {
	my($doc)=@_;
	my($errors)=$doc->getElementsByTagName("error");
	for(my($i)=0;$i<$errors->getLength();$i++) {
		my($error)=$errors->[$i];
		my($el_file)=$error->getElementsByTagName("file")->[0];
		my($el_line)=$error->getElementsByTagName("line")->[0];
		my($el_char)=$error->getElementsByTagName("char")->[0];
		my($el_text)=$error->getElementsByTagName("text")->[0];
		my($file)=$el_file->getFirstChild()->getData();
		my($line)=$el_line->getFirstChild()->getData();
		my($char)=$el_char->getFirstChild()->getData();
		my($text)=$el_text->getFirstChild()->getData();
		Meta::Tool::Editor::edit_line_char($file,$line,$char);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Errors - module to handle errors from tools.

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

	MANIFEST: Errors.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Errors qw();
	my($object)=Meta::Development::Errors->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module will help you handle XML::DOM error objects.
It will print the errors in nice colors on the console.
It will run editors on the errors with positions set to the correct places.

=head1 FUNCTIONS

	print($)
	edit($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<print($)>

This method will print out the errors object.

=item B<edit($)>

This method will run the editor on all the errors in the object received.

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

	0.00 MV get imdb ids of directors and movies
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Tool::Editor(3), strict(3)

=head1 TODO

Nothing.

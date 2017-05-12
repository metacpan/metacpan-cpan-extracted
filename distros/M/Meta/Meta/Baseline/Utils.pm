#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Utils;

use strict qw(vars refs subs);
use XML::Writer qw();
use IO qw();
use Meta::Utils::File::File qw();
use Meta::Utils::File::Mkdir qw();

our($VERSION,@ISA);
$VERSION="0.30";
@ISA=qw();

#sub get_emblem();
#sub get_file_emblem();
#sub get_cook_emblem();
#sub get_script_emblem();
#sub get_xml_emblem();
#sub get_html_emblem();
#sub file_emblem($);
#sub cook_emblem($);
#sub script_emblem($);
#sub xml_emblem($);
#sub html_emblem($);
#sub cook_emblem_print($);
#sub mkdir_emblem($);
#sub TEST($);

#__DATA__

sub get_emblem() {
	return("Base auto generated file - DO NOT EDIT!");
}

sub get_file_emblem() {
	return("/* ".&get_emblem()." */\n");
}

sub get_cook_emblem() {
	return("/* ".&get_emblem()." */\n");
}

sub get_script_emblem() {
	return("# ".&get_emblem()."\n");
}

sub get_xml_emblem() {
	my($output)=IO::String->new();
	my($writer)=XML::Writer->new(OUTPUT=>$output);
	$writer->xmlDecl();
	$writer->comment(&get_emblem());
	$writer->dataElement("empty");
	$writer->end();
	$output->close();
	return($output);
}

sub get_html_emblem() {
	return("/* ".&get_emblem()." */\n");
}

sub file_emblem($) {
	my($file)=@_;
	my($string)=&get_file_emblem();
	Meta::Utils::File::File::save($file,$string);
}

sub cook_emblem($) {
	my($file)=@_;
	my($string)=&get_cook_emblem();
	Meta::Utils::File::File::save($file,$string);
}

sub script_emblem($) {
	my($file)=@_;
	my($string)=&get_script_emblem();
	Meta::Utils::File::File::save($file,$string);
}

sub xml_emblem($) {
	my($file)=@_;
	my($string)=&get_xml_emblem();
	Meta::Utils::File::File::save($file,$string);
}

sub html_emblem($) {
	my($file)=@_;
	my($string)=&get_html_emblem();
	Meta::Utils::File::File::save($file,$string);
}

sub cook_emblem_print($) {
	my($file)=@_;
	my($string)=&get_cook_emblem();
	print $file $string;
}

sub mkdir_emblem($) {
	my($file)=@_;
	Meta::Utils::File::Mkdir::mkdir_p_check_file($file);
	&file_emblem($file);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Utils - library to provide utilities to baseline software.

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

	MANIFEST: Utils.pm
	PROJECT: meta
	VERSION: 0.30

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Utils qw();
	Meta::Baseline::Utils::cook_emblem_print(*FILE);

=head1 DESCRIPTION

This package will provide code sniplets that a lot of scripts in the
baseline need.

=head1 FUNCTIONS

	get_emblem()
	get_file_emblem()
	get_cook_emblem()
	get_script_emblem()
	get_xml_emblem()
	get_html_emblem()
	file_emblem($)
	cook_emblem($)
	script_emblem($)
	xml_emblem($)
	html_emblem($)
	cook_emblem_print($)
	mkdir_emblem($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<get_emblem()>

This will return the emblem that should be put on auto generated files.

=item B<get_file_emblem()>

This method returns the emblem in a general stile (C multi line comment).

=item B<get_cook_emblem()>

This method returns the emblem in a cook style (C multi line comment).

=item B<get_script_emblem()>

This method returns the emblem in a script style (shebang style).

=item B<get_xml_emblem()>

This method returns the emblem in an XML style (small xml doc).

=item B<get_html_emblem()>

This method returns the emblem in an HTML style (small html doc).

=item B<file_emblem($)>

This will create a stub file with the emblem.
This is meant for files in which the /* */ is the form for comments.

=item B<cook_emblem($)>

Cook knows how to handle C++ style comments so we just
call the method for that.

=item B<script_emblem($)>

This method will create a stub file fit for scripts (where the hash (#)
sign is the correct form for comments.

=item B<xml_emblem($)>

This will create a stub XML file.

=item B<html_emblem($)>

This will create a stub HTML file.

=item B<cook_emblem_print($)>

This method gets a file handle and prints a cook emblem into it.

=item B<mkdir_emblem($)>

This method will create an emblem file but will also create the directory in
which it is supposed to reside (if it is not already created).

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

	0.00 MV bring databases on line
	0.01 MV this time really make the databases work
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV spelling change
	0.08 MV correct die usage
	0.09 MV perl code quality
	0.10 MV more perl quality
	0.11 MV more perl quality
	0.12 MV perl documentation
	0.13 MV more perl quality
	0.14 MV perl qulity code
	0.15 MV more perl code quality
	0.16 MV revision change
	0.17 MV languages.pl test online
	0.18 MV perl packaging
	0.19 MV xml encoding
	0.20 MV md5 project
	0.21 MV database
	0.22 MV perl module versions in files
	0.23 MV movies and small fixes
	0.24 MV thumbnail user interface
	0.25 MV more thumbnail issues
	0.26 MV website construction
	0.27 MV web site automation
	0.28 MV SEE ALSO section fix
	0.29 MV teachers project
	0.30 MV md5 issues

=head1 SEE ALSO

IO(3), Meta::Utils::File::File(3), Meta::Utils::File::Mkdir(3), XML::Writer(3), strict(3)

=head1 TODO

-add routine to make a file read only after is created and do it with emblem.

-make the emblem / emblem_simple more natural.

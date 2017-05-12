#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use XML::Handler::YAWriter qw();
use Meta::IO::File qw();
use XML::Driver::HTML qw();

my($file,$PrettyWhiteIndent,$NoWhiteSpace,$NoComments,$AddHiddenNewline,$AddHiddenAttrTab,$CatchEmptyElement,$Encoding);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("file","what file to use ?",undef,\$file);
$opts->def_bool("PrettyWhiteIndent","PrettyWhiteIndent",1,\$PrettyWhiteIndent);
$opts->def_bool("NoWhiteSpace","NoWhiteSpace",1,\$NoWhiteSpace);
$opts->def_bool("NoComments","NoComments",1,\$NoComments);
$opts->def_bool("AddHiddenNewline","AddHiddenNewline",0,\$AddHiddenNewline);
$opts->def_bool("AddHiddenAttrTab","AddHiddenAttrTab",0,\$AddHiddenAttrTab);
$opts->def_bool("CatchEmptyElement","CatchEmptyElement",1,\$CatchEmptyElement);
$opts->def_stri("Encoding","Encoding",'UTF-8',\$Encoding);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($ya)=XML::Handler::YAWriter->new(
	'Output'=>Meta::IO::File->new(">-"),
	'Pretty'=> {
		'PrettyWhiteIndent'=>$PrettyWhiteIndent,
		'NoWhiteSpace'=>$NoWhiteSpace,
		'NoComments'=>$NoComments,
		'AddHiddenNewline'=>$AddHiddenNewline,
		'AddHiddenAttrTab'=>$AddHiddenNewline,
		'CatchEmptyElement'=>$AddHiddenNewline,
	}
);
my($html)=XML::Driver::HTML->new(
	'Handler'=>$ya,
	'Source'=>{
		'ByteStream'=>Meta::IO::File->new($file),
		'Encoding',$Encoding,
	},
);
$html->parse();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xml_html_to_xml.pl - convert HTML to XHTML.

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

	MANIFEST: xml_html_to_xml.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	xml_html_to_xml.pl [options]

=head1 DESCRIPTION

This script converts HTML to XHTML using the SAX driver.

=head1 OPTIONS

=over 4

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=item B<file> (type: file, default: )

what file to use ?

=item B<PrettyWhiteIndent> (type: bool, default: 1)

PrettyWhiteIndent

=item B<NoWhiteSpace> (type: bool, default: 1)

NoWhiteSpace

=item B<NoComments> (type: bool, default: 1)

NoComments

=item B<AddHiddenNewline> (type: bool, default: 0)

AddHiddenNewline

=item B<AddHiddenAttrTab> (type: bool, default: 0)

AddHiddenAttrTab

=item B<CatchEmptyElement> (type: bool, default: 1)

CatchEmptyElement

=item B<Encoding> (type: stri, default: UTF-8)

Encoding

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV move tests to modules
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::IO::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), XML::Driver::HTML(3), XML::Handler::YAWriter(3), strict(3)

=head1 TODO

-enable to write to a specific output file (or to stdout by default).

-enable to get input from stdin by default (this should be handled at the module level).

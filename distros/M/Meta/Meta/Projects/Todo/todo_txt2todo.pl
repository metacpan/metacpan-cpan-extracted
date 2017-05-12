#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use XML::Writer qw();
use Meta::IO::File qw();

my($inpu,$outp,$xmlx,$doct);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_file("input","what file to convert ?",undef,\$inpu);
$opts->def_newf("output","output file",undef,\$outp);
$opts->def_bool("xml","should I put an XML header ?",1,\$xmlx);
$opts->def_bool("doctype","should I put a DOCTYPE header ?",1,\$doct);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($output)=Meta::IO::File->new_writer($outp);
my($writer)=XML::Writer->new(OUTPUT=>$output,DATA_MODE=>1,DATA_INDENT=>8);
if($xmlx) {
	$writer->xmlDecl();
}
if($doct) {
	$writer->doctype("todo","-//META//DTD TODO V1.0//EN","deve/xml/todo.dtd");
}
$writer->startTag("todo");
$writer->startTag("items");
my($io)=Meta::IO::File->new_reader($inpu);
while(!$io->eof()) {
	my($line)=$io->cgetline();
	$writer->startTag("item");
	$writer->dataElement("subject","");
	$writer->dataElement("text",$line);
	$writer->endTag("item");
}
$io->close();
$writer->endTag("items");
$writer->endTag("todo");
$writer->end();
$output->close();

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

todo_txt2todo.pl - convert text lines describing todo/done items to XML/todo.

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

	MANIFEST: todo_txt2todo.pl
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	todo_txt2todo.pl [options]

=head1 DESCRIPTION

This program converts a text file containing todo/done items, one
per line, to the XML/todo dtd defined in this project.

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

=item B<input> (type: file, default: )

what file to convert ?

=item B<output> (type: newf, default: )

output file

=item B<xml> (type: bool, default: 1)

should I put an XML header ?

=item B<doctype> (type: bool, default: 1)

should I put a DOCTYPE header ?

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

	0.00 MV some chess work
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV thumbnail user interface
	0.05 MV more thumbnail issues
	0.06 MV website construction
	0.07 MV improve the movie db xml
	0.08 MV web site automation
	0.09 MV SEE ALSO section fix
	0.10 MV move tests to modules
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::IO::File(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), XML::Writer(3), strict(3)

=head1 TODO

-move to using a validating writer here.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use IO qw();
use Meta::Xml::Writer qw();
use Meta::Digest::MD5 qw();
use Meta::Utils::Output qw();
use Meta::Utils::File::Iterator qw();
use MIME::Base64 qw();
use Meta::Utils::File::Time qw();

my($verb,$outp,$dire);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",1,\$verb);
$opts->def_newf("output","output file name","/tmp/file.xml",\$outp);
$opts->def_dire("directory","directory to scan",".",\$dire);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);


my($output)=IO::File->new("> ".$outp);
my($writer)=Meta::Xml::Writer->new(OUTPUT=>$output,DATA_MODE=>1,DATA_INDENT=>8);
# emit a proper XML header
$writer->xmlDecl();
# emit a DOCTYPE declaration
$writer->doctype("md5","-//META//DTD MD5 V1.0//EN","deve/xml/md5.dtd");
# now start the primary element
$writer->startTag("md5");

my($iterator)=Meta::Utils::File::Iterator->new();
$iterator->add_directory($dire);
$iterator->start();

while(!$iterator->get_over()) {
	my($curr)=$iterator->get_curr();
	if($verb) {
		Meta::Utils::Output::print("working on [".$curr."]\n");
	}
	my($sum)=Meta::Digest::MD5::get_filename_digest($curr);
	my($time)=Meta::Utils::File::Time::time($curr);
	$writer->startTag("stamp");
	$writer->dataElement("filename",$curr);
	$writer->dataElement("moddate",$time);
	$writer->dataElement("md5sum",MIME::Base64::encode($sum,""));
	$writer->endTag("stamp");
	$iterator->next();
}
$iterator->fini();
#close the main element
$writer->endTag("md5");
$writer->end();
$output->close();
Meta::Utils::System::exit_ok();

__END__

=head1 NAME

md5_produce.pl - produce XML/md5 for sets of files.

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

	MANIFEST: md5_produce.pl
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	md5_produce.pl [options]

=head1 DESCRIPTION

This script takes as input a set of files on the command line and
produces an XML file according to the XML/md5 dtd I have defined
which contains information about the files MD5 sum and modification
times.

This type of information could later be used to:
0. Determine if further MD5 calculations are needed according
	to the files modification time (thus only needing to
	stat the file and not read it).
1. Determine if the file really changed just by looking at its
	new MD5 sum compared to its old MD5. This type of check
	could be made by smart build tools etc...
2. Other uses that I didn't think of (best ones).

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

=item B<verbose> (type: bool, default: 1)

noisy or quiet ?

=item B<output> (type: newf, default: /tmp/file.xml)

output file name

=item B<directory> (type: dire, default: .)

directory to scan

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

	0.00 MV books XML into database
	0.01 MV md5 project
	0.02 MV database
	0.03 MV perl module versions in files
	0.04 MV graph visualization
	0.05 MV more thumbnail stuff
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV improve the movie db xml
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV move tests to modules
	0.13 MV md5 issues

=head1 SEE ALSO

IO(3), MIME::Base64(3), Meta::Digest::MD5(3), Meta::Utils::File::Iterator(3), Meta::Utils::File::Time(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Xml::Writer(3), strict(3)

=head1 TODO

Nothing.

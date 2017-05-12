#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use XML::LibXSLT qw();
use XML::LibXML qw();

my($xslt_file,$xml_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("xslt","what xslt file to use ?","xslt/nop.xsl",\$xslt_file);
$opts->def_devf("xml","what xml file to process ?","xmlx/movie/movie.xml",\$xml_file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$xslt_file=Meta::Baseline::Aegis::which($xslt_file);
$xml_file=Meta::Baseline::Aegis::which($xml_file);

my($parser)=XML::LibXML->new();
my($xslt)=XML::LibXSLT->new();
my($source)=$parser->parse_file($xml_file);
my($style_doc)=$parser->parse_file($xslt_file);
my($stylesheet)=$xslt->parse_stylesheet($style_doc);
my($results)=$stylesheet->transform($source);
Meta::Utils::Output::print($stylesheet->output_string($results));

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xslt_libxslt_run.pl - run LibXSLT XSL transformations.

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

	MANIFEST: xslt_libxslt_run.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	xslt_libxslt_run.pl [options]

=head1 DESCRIPTION

This program will run LibXSLT XSL transformations for you.
You need to supply the style sheet and the XML document to work on.
This script will do the rest.

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

=item B<xslt> (type: devf, default: xslt/nop.xsl)

what xslt file to use ?

=item B<xml> (type: devf, default: xmlx/movie/movie.xml)

what xml file to process ?

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

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::LibXML(3), XML::LibXSLT(3), strict(3)

=head1 TODO

Nothing.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use XML::XSLT qw();
use Error qw(:try);

my($xslt_file,$dom,$variables,$base,$debug,$warnings,$indent,$indent_incr,$xml_file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("xslt","what xslt file to use ?","xslt/nop.xsl",\$xslt_file);
$opts->def_stri("DOMparser_args","args to pass to the DOMParser","",\$dom);
$opts->def_stri("variables","variables to pass to XSLT","",\$variables);
$opts->def_stri("base","base URL for parsing","",\$base);
$opts->def_bool("debug","turn debugging on ?",0,\$debug);
$opts->def_bool("warnings","turn warnings on ?",1,\$warnings);
$opts->def_inte("indent","indent amount for debugging",0,\$indent);
$opts->def_inte("indent_incr","indent increment amount for debugging",1,\$indent_incr);
$opts->def_devf("xml","what xml file to process ?","xmlx/movie/movie.xml",\$xml_file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$xslt_file=Meta::Baseline::Aegis::which($xslt_file);
$xml_file=Meta::Baseline::Aegis::which($xml_file);
#Meta::Utils::Output::print("xslt_file is [".$xslt_file."]\n");
#Meta::Utils::Output::print("xml_file is [".$xml_file."]\n");

my($xslt)=XML::XSLT->new(
	Source=>$xslt_file,
# one of the following needs to be a hash and doesn't work
#	DOMparser_args=>$dom,
#	variables=>$variables,
#	base=>$base,
	debug=>$debug,
	warnings=>$warnings,
	indent=>$indent,
	indent_incr=>$indent_incr,
);
if(!$xslt) {
	throw Meta::Error::Simple("unable to create xslt object");
}
my($result)=$xslt->serve(Source=>$xml_file);
Meta::Utils::Output::print($result);

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

xslt_run.pl - run XSLT transformations with lots of options.

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

	MANIFEST: xslt_run.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	xslt_run.pl [options]

=head1 DESCRIPTION

This program will run an XSLT transformation(s) on XML file(s).
The program is very efficient in resource consumption and has
lots of very easy to use command line options.

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

=item B<DOMparser_args> (type: stri, default: )

args to pass to the DOMParser

=item B<variables> (type: stri, default: )

variables to pass to XSLT

=item B<base> (type: stri, default: )

base URL for parsing

=item B<debug> (type: bool, default: 0)

turn debugging on ?

=item B<warnings> (type: bool, default: 1)

turn warnings on ?

=item B<indent> (type: inte, default: 0)

indent amount for debugging

=item B<indent_incr> (type: inte, default: 1)

indent increment amount for debugging

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

	0.00 MV move tests to modules
	0.01 MV web site development
	0.02 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::XSLT(3), strict(3)

=head1 TODO

Nothing.

#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Tool::Xmllint qw();
use Meta::Lang::Xml::Xml qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Xml::LibXML qw();

my($modu,$validation,$pedantic_parser,$load_ext_dtd,$recover);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_modu("file","what file to check ?",undef,\$modu);
$opts->def_bool("validation","should I validate ?",1,\$validation);
$opts->def_bool("pedantic_parser","pedantic parser ?",1,\$pedantic_parser);
$opts->def_bool("load_ext_dtd","load extenal dtds ?",1,\$load_ext_dtd);
$opts->def_bool("recover","recover ?",0,\$recover);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

#my($scod)=Meta::Tool::Xmllint::check_modu($modu);

#my($build)=Meta::Pdmt::BuildInfo->new();
#$build->set_srcx($modu->get_abs_path());
#$build->set_modu($modu->get_name());
#$build->set_path(Meta::Baseline::Aegis::search_path());
#my($scod)=Meta::Lang::Xml::Xml::check($build);

my($parser)=Meta::Xml::LibXML->new_aegis();
#Meta::Utils::Output::print("got parser [".$parser."]\n");
$parser->validation($validation);
$parser->pedantic_parser($pedantic_parser);
$parser->load_ext_dtd($load_ext_dtd);
$parser->recover($recover);
#my($scod)=$parser->parse_file($modu->get_abs_path());
my($scod)=$parser->check_file($modu->get_abs_path());
#Meta::Utils::Output::print("scod is [".$scod."]\n");

Meta::Utils::System::exit($scod);

__END__

=head1 NAME

xml_lint.pl - check XML files for you.

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

	MANIFEST: xml_lint.pl
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	xml_lint.pl [options]

=head1 DESCRIPTION

This script receives a development module name and checks it for you
using the Meta::Tool::Xmllint module.

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

=item B<file> (type: modu, default: )

what file to check ?

=item B<validation> (type: bool, default: 1)

should I validate ?

=item B<pedantic_parser> (type: bool, default: 1)

pedantic parser ?

=item B<load_ext_dtd> (type: bool, default: 1)

load extenal dtds ?

=item B<recover> (type: bool, default: 0)

recover ?

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

	0.00 MV put all tests in modules
	0.01 MV move tests to modules
	0.02 MV teachers project
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Lang::Xml::Xml(3), Meta::Tool::Xmllint(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Xml::LibXML(3), strict(3)

=head1 TODO

-add method to check using LibXML directly and not xmllint extenral executable.

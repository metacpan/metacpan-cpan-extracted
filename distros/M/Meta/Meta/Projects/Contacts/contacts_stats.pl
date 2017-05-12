#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Xml::Dom qw();
use Meta::Lang::Xml::Xml qw();

my($verb,$vali,$file);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_bool("validate","use a validating parser ?",0,\$vali);
$opts->def_stri("file","where is the xml db file ?","xmlx/contacts/contacts.xml",\$file);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

if($verb) {
	Meta::Utils::Output::print("Analyzing...\n");
}
Meta::Lang::Xml::Xml::setup_path();
my($file)=Meta::Baseline::Aegis::which($file);
my($parser)=Meta::Xml::Dom->new_vali($vali);
my($doc)=$parser->parsefile($file);

my($contact_number)=$doc->getElementsByTagName("contact")->getLength();

Meta::Utils::Output::print("number of contact is [".$contact_number."]\n");

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

contacts_stats.pl - show statistics about contacts xml database.

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

	MANIFEST: contacts_stats.pl
	PROJECT: meta
	VERSION: 0.03

=head1 SYNOPSIS

	contacts_stats.pl [options]

=head1 DESCRIPTION

This program prints out some statistics from the contacts xml file.

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

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<validate> (type: bool, default: 0)

use a validating parser ?

=item B<file> (type: stri, default: xmlx/contacts/contacts.xml)

where is the xml db file ?

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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV move tests to modules
	0.03 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Lang::Xml::Xml(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), Meta::Xml::Dom(3), strict(3)

=head1 TODO

Nothing.

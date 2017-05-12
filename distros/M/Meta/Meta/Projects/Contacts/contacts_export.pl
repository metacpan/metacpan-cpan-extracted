#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Meta::Utils::Output qw();
use Meta::Lang::Xml::Xml qw();
use Meta::Baseline::Aegis qw();
use XML::Parser qw();
use XML::XPath qw();
use Meta::IO::File qw();
use Meta::Template::Sub qw();
use Meta::Ds::Set qw();
use Error qw(:try);

my($file,$verb,$outf,$sync,$set_sort,$config);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_devf("file","what contacts file to use ?","xmlx/contacts/contacts.xml",\$file);
$opts->def_bool("verbose","noisy or quiet ?",0,\$verb);
$opts->def_ovwf("outf","what output file to generate ?","[% home_dir %]/.kde/share/apps/kmail/addressbook",\$outf);
$opts->def_bool("sync","read kmail and check before writing ?",1,\$sync);
$opts->def_bool("set_sort","sort output via set sorting ?",1,\$set_sort);
$opts->def_ovwf("config","what config file to modify ?","[% home_dir %]/.kde/share/config/kmailrc",\$config);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

$outf=Meta::Template::Sub::interpolate($outf);

Meta::Utils::Output::verbose($verb,"started reading old file\n");
my($old_set)=Meta::Ds::Set->new();
$old_set->read($outf);
Meta::Utils::Output::verbose($verb,"finished reading old file\n");
#Meta::Utils::Output::dump($old_set);
my($special)="# kmail addressbook file";
$old_set->remove($special);

my($set)=Meta::Ds::Set->new();
#$set->insert("# kmail addressbook file");

Meta::Utils::Output::verbose($verb,"started reading xml file\n");
Meta::Lang::Xml::Xml::setup_path();
my($file)=Meta::Baseline::Aegis::which($file);
my($par)=XML::Parser->new();
if(!defined($par)) {
	throw Meta::Error::Simple("unable to create XML::Parser");
}
my($parser)=XML::XPath::XMLParser->new(filename=>$file,parser=>$par);
if(!defined($parser)) {
	throw Meta::Error::Simple("unable to create XML::XPath::XMLParser");
}
my($root_node)=$parser->parse();
my($nodes)=$root_node->find('/contacts/contact');

my($size)=$nodes->size();
Meta::Utils::Output::verbose($verb,"size is [".$size."]\n");
foreach my $node ($nodes->get_nodelist()) {
	my($emails)=$node->find('emails/email/value');
	Meta::Utils::Output::verbose($verb,"emails is [".$emails."]\n");
	my($use_firstname)=undef;
	my($firstname)=$node->find('firstname');
	if($firstname->size()) {
		$use_firstname=$firstname->get_node(0)->getChildNode(1)->getValue();
	}
	my($use_surname)=undef;
	my($surname)=$node->find('surname');
	if($surname->size()) {
		$use_surname=$surname->get_node(0)->getChildNode(1)->getValue();
	}
	my($use_company)=undef;
	my($company)=$node->find('company');
	if($company->size()) {
		$use_company=$company->get_node(0)->getChildNode(1)->getValue();
	}
	my($use_title)=undef;
	my($title)=$node->find('title');
	if($title->size()) {
		$use_title=$title->get_node(0)->getChildNode(1)->getValue();
	}
	my($name)=undef;
	if(defined($use_firstname) && !defined($use_surname)) {
		$name=$use_firstname;
	}
	if(defined($use_firstname) && defined($use_surname)) {
		$name=join(' ',$use_firstname,$use_surname);
	}
	if(defined($use_company)) {
		$name.=' ('.$use_company.')';
	}
	if(defined($use_title)) {
		$name=$use_title;
	}
	foreach my $email ($emails->get_nodelist()) {
		my($email_text)=$email->getChildNode(1)->getValue();
		my($line)=$name. " <".$email_text.">";
		$set->insert($line);
	}
}
Meta::Utils::Output::verbose($verb,"finished reading xml file\n");
if(!$sync || ($sync && $old_set->contained($set))) {
	Meta::Utils::Output::verbose($verb,"started writing output\n");
	my($io);
	$io=Meta::IO::File->new($outf,"w");
	$io->print($special."\n");
	if($set_sort) {
		my($hash)=$set->get_hash();
		$io->print(join("\n",sort(keys(%$hash))));
	} else {
		my($hash)=$set->get_hash();
		$io->print(join("\n",keys(%$hash)));
	}
	$io->close();
	Meta::Utils::Output::verbose($verb,"finished writing output\n");
} else {# only if sync requested and sets are not contained
	Meta::Utils::Output::verbose($verb,"started subtract\n");
	my($res_set)=$old_set->subtract($set);
	Meta::Utils::Output::print("New info in kmail. Please Sync.\n");
	Meta::Utils::Output::dump($res_set);
	#throw Meta::Error::Simple("cannot write output becuse of sync problems");
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

contacts_export.pl - export contact information in various formats.

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

	MANIFEST: contacts_export.pl
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	contacts_export.pl [options]

=head1 DESCRIPTION

This script will read an XML/contacts file and will export it to a selection
out of the known set of export formats.
Formats which are planned to be supported:
1. kmail - a file that you could use so that you will have all your
	contact information in kmail. This is a text file which only
	has "John Doe john@doe.com\n" type entries.
2. evolution - a file that you could use so that you will have all
	your contact information in evolution. In essense this file
	is a Bekeley DB file and I use perl modules for manipulating
	Berkeley DB files to do that (create the file or add entries
	into your existing file).
3. gnokii - a file fit to be transferred using gnokii to a Nokia cellular
	phone (I still dont know what that format is and this is still
	not implemented).
4. html - a file fit to be put on a web server somewhere so that you
	will always have your contact information. Be sure to put
	this in a protected place (using a password) if you want to
	keep the information private. This is script is NOT responsible
	for such security matters!!!.
5. pdb palm pilot file - there are perl modules which can manipulate
	such files and I plan to use them to export my contacts
	to my palm pilot.

Current script only supports the first option (kmail).

Technical notes:
Ths use of XML::Parser here is mandatory since if you do not supply your
own parser the XML::XPath uses it's own which cannot do Aegis resolution and so
this kills everything.

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

=item B<file> (type: devf, default: xmlx/contacts/contacts.xml)

what contacts file to use ?

=item B<verbose> (type: bool, default: 0)

noisy or quiet ?

=item B<outf> (type: ovwf, default: [% home_dir %]/.kde/share/apps/kmail/addressbook)

what output file to generate ?

=item B<sync> (type: bool, default: 1)

read kmail and check before writing ?

=item B<set_sort> (type: bool, default: 1)

sort output via set sorting ?

=item B<config> (type: ovwf, default: [% home_dir %]/.kde/share/config/kmailrc)

what config file to modify ?

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
	0.02 MV download scripts
	0.03 MV move tests into modules
	0.04 MV finish papers
	0.05 MV teachers project
	0.06 MV more pdmt stuff
	0.07 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Baseline::Aegis(3), Meta::Ds::Set(3), Meta::IO::File(3), Meta::Lang::Xml::Xml(3), Meta::Template::Sub(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), XML::Parser(3), XML::XPath(3), strict(3)

=head1 TODO

-make sure that kmail is not running when running this. use a general class which can make sure that a certain executable is not running.

-create filters too.

#!/bin/echo This is a perl module and should not be run

package Meta::Info::Author;

use strict qw(vars refs subs);
use Meta::Info::Affiliation qw();
use Meta::Xml::Parsers::Author qw();
use Meta::Baseline::Aegis qw();
use Meta::Class::MethodMaker qw();
use XML::Writer qw();
use IO::String qw();
use Data::Dumper qw();
use Meta::Ds::Ohash qw();

our($VERSION,@ISA);
$VERSION="0.22";
@ISA=qw();

#sub BEGIN();
#sub init($);
#sub new_file($$);
#sub new_modu($$);
#sub get_default_passphrase($);
#sub get_default_email($);
#sub get_default_affiliation($);
#sub get_handle($);
#sub get_sourceforge_user($);
#sub get_sourceforge_password($);
#sub get_sourceforge_mail($);
#sub get_sourceforge_ssh($);
#sub get_cpan_user($);
#sub get_cpan_mail($);
#sub get_cpan_password($);
#sub get_cpan_url($);
#sub get_homepage($);
#sub get_perl_makefile($);
#sub get_perl_source($);
#sub get_perl_copyright($);
#sub get_vcard($);
#sub get_html_copyright($);
#sub get_html_info($);
#sub get_full_name($);
#sub get_docbook_author($);
#sub get_docbook_address($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new_with_init("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_honorific",
		-java=>"_firstname",
		-java=>"_surname",
		-java=>"_initials",
		-java=>"_webpages",
		-java=>"_emails",
		-java=>"_accounts",
		-java=>"_affiliations",
		-java=>"_security_keys",
		-java=>"_ims",
	);
}

sub init($) {
	my($self)=@_;
	$self->set_webpages(Meta::Ds::Ohash->new());
	$self->set_emails(Meta::Ds::Ohash->new());
	$self->set_accounts(Meta::Ds::Ohash->new());
	$self->set_affiliations(Meta::Ds::Ohash->new());
	$self->set_security_keys(Meta::Ds::Ohash->new());
	$self->set_ims(Meta::Ds::Ohash->new());
}

sub new_file($$) {
	my($class,$file)=@_;
	my($parser)=Meta::Xml::Parsers::Author->new();
	$parser->parsefile($file);
	return($parser->get_result());
}

sub new_modu($$) {
	my($class,$modu)=@_;
	my($file)=$modu->get_abs_path();
	return(&new_file($class,$file));
}

sub get_default_passphrase($) {
	my($self)=@_;
	return($self->get_security_keys()->get("main")->get_passphrase());
}

sub get_default_email($) {
	my($self)=@_;
	return($self->get_emails()->get("main")->get_value());
}

sub get_default_affiliation($) {
	my($self)=@_;
	return($self->get_affiliations()->get("main"));
}

sub get_handle($) {
	my($self)=@_;
	return($self->get_accounts()->get("local")->get_user());
}

sub get_sourceforge_user($) {
	my($self)=@_;
	return($self->get_accounts()->get("sourceforge")->get_user());
}

sub get_sourceforge_password($) {
	my($self)=@_;
	return($self->get_accounts()->get("sourceforge")->get_password());
}

sub get_sourceforge_mail($) {
	my($self)=@_;
	return($self->get_accounts()->get("sourceforge")->get_mail());
}

sub get_sourceforge_ssh($) {
	my($self)=@_;
	return($self->get_accounts()->get("sourceforge")->get_ssh());
}

sub get_cpan_user($) {
	my($self)=@_;
	return($self->get_accounts()->get("cpan")->get_user());
}

sub get_cpan_mail($) {
	my($self)=@_;
	return($self->get_accounts()->get("cpan")->get_mail());
}

sub get_cpan_password($) {
	my($self)=@_;
	return($self->get_accounts()->get("cpan")->get_password());
}

sub get_cpan_url($) {
	my($self)=@_;
	return($self->get_accounts()->get("cpan")->get_url());
}

sub get_homepage($) {
	my($self)=@_;
	return($self->get_webpages()->get("main")->get_value());
}

sub get_perl_makefile($) {
	my($self)=@_;
	return($self->get_firstname()." ".$self->get_surname()." <".$self->get_cpan_mail().">");
}

sub get_perl_source($) {
	my($self)=@_;
	return(
		"\tName: ".$self->get_firstname()." ".$self->get_surname()."\n".
		"\tEmail: mailto:".$self->get_cpan_mail()."\n".
		"\tWWW: ".$self->get_homepage()."\n".
		"\tCPAN id: ".$self->get_cpan_user()."\n"
	);
}

sub get_perl_copyright($) {
	my($self)=@_;
	return("Copyright (C) ".Meta::Baseline::Aegis::copyright_years()." ".$self->get_firstname()." ".$self->get_surname().";\nAll rights reserved.\n");
}

sub get_vcard($) {
	my($self)=@_;
	return("VCARD");
}

sub get_html_copyright($) {
	my($self)=@_;
	return("Copyright (C) ".Meta::Baseline::Aegis::copyright_years()." ".
		"<a href=\"mailto:".$self->get_default_email()."\">".
		$self->get_firstname()." ".$self->get_surname()."</a>".
		"\;\ All rights reserved."
	);
}

sub get_html_info($) {
	my($self)=@_;
	return(
		"<li><a href=\"".$self->get_homepage()."\">\n".
		"Home page: ".$self->get_homepage()."</a></li>\n".
		"<li><a href=\"mailto: ".$self->get_default_email()."\">\n".
		"Email: ".$self->get_default_email()."</a></li>"
	);
}

sub get_full_name($) {
	my($self)=@_;
	return($self->get_firstname()." ".$self->get_surname());
}

sub get_docbook_author($) {
	my($self)=@_;
	my($string);
	my($io)=IO::String->new($string);
	my($writer)=XML::Writer->new(OUTPUT=>$io);
	$writer->startTag("author");
	$writer->dataElement("honorific",$self->get_honorific());
	$writer->dataElement("firstname",$self->get_firstname());
	$writer->dataElement("surname",$self->get_surname());
	$writer->startTag("affiliation");
	$writer->dataElement("orgname",$self->get_default_affiliation()->get_orgname());
	$writer->startTag("address");
	$writer->dataElement("email",$self->get_default_email());
	$writer->endTag("address");
	$writer->endTag("affiliation");
	$writer->endTag("author");
	$io->close();
	return($string);
}

sub get_docbook_address($) {
	my($self)=@_;
	my($self)=@_;
	my($string);
	my($io)=IO::String->new($string);
	my($writer)=XML::Writer->new(OUTPUT=>$io);
	$writer->startTag("address");
	$writer->dataElement("firstname",$self->get_firstname());
	$writer->dataElement("surname",$self->get_surname());
	$writer->dataElement("country",$self->get_default_affiliation()->get_address()->get_country());
	$writer->dataElement("city",$self->get_default_affiliation()->get_address()->get_city());
	$writer->dataElement("street",$self->get_default_affiliation()->get_address()->get_street());
	$writer->dataElement("email",$self->get_default_affiliation()->get_address()->get_mail());
	$writer->dataElement("phone",$self->get_default_affiliation()->get_address()->get_phone());
	$writer->dataElement("fax",$self->get_default_affiliation()->get_address()->get_fax());
	$writer->dataElement("postcode",$self->get_default_affiliation()->get_address()->get_postcode());
	$writer->endTag("address");
	$io->close();
	return($string);
}

sub TEST($) {
	my($context)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/author/author.xml");
	my($author)=Meta::Info::Author->new_modu($module);
	Meta::Utils::Output::print(Data::Dumper::Dumper($author));
	Meta::Utils::Output::print("default_passphrase is [".$author->get_default_passphrase()."]\n");
	Meta::Utils::Output::print("default_email is [".$author->get_default_email()."]\n");
	Meta::Utils::Output::print("default_affiliation is [".$author->get_default_affiliation()."]\n");
	Meta::Utils::Output::print("sourceforge_user is [".$author->get_sourceforge_user()."]\n");
	Meta::Utils::Output::print("sourceforge_password is [".$author->get_sourceforge_password()."]\n");
	Meta::Utils::Output::print("sourceforge_mail is [".$author->get_sourceforge_mail()."]\n");
	Meta::Utils::Output::print("sourceforge_ssh is [".$author->get_sourceforge_ssh()."]\n");
	Meta::Utils::Output::print("cpan_user is [".$author->get_cpan_user()."]\n");
	Meta::Utils::Output::print("cpan_mail is [".$author->get_cpan_mail()."]\n");
	Meta::Utils::Output::print("cpan_password is [".$author->get_cpan_password()."]\n");
	Meta::Utils::Output::print("homepage is [".$author->get_homepage()."]\n");
	Meta::Utils::Output::print("perl_makefile is [".$author->get_perl_makefile()."]\n");
	Meta::Utils::Output::print("perl_source is [".$author->get_perl_source()."]\n");
	Meta::Utils::Output::print("perl_copyright is [".$author->get_perl_copyright()."]\n");
	Meta::Utils::Output::print("vcard is [".$author->get_vcard()."]\n");
	Meta::Utils::Output::print("html_copyright is [".$author->get_html_copyright()."]\n");
	Meta::Utils::Output::print("html_info is [".$author->get_html_info()."]\n");
	Meta::Utils::Output::print("full_name is [".$author->get_full_name()."]\n");
	Meta::Utils::Output::print("docbook_author is [".$author->get_docbook_author()."]\n");
	Meta::Utils::Output::print("docbook_address is [".$author->get_docbook_address()."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Author - object oriented author personal information.

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

	MANIFEST: Author.pm
	PROJECT: meta
	VERSION: 0.22

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Author qw();
	my($object)=Meta::Info::Author->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class provides author information according to the DocBook DTD.

=head1 FUNCTIONS

	BEGIN()
	init($)
	new_file($$)
	new_modu($$)
	get_default_passphrase($)
	get_default_email($)
	get_default_affiliation($)
	get_sourceforge_user($)
	get_sourceforge_password($)
	get_sourceforge_mail($)
	get_sourceforge_ssh($)
	get_cpan_user($)
	get_cpan_mail($)
	get_cpan_password($)
	get_cpan_url($)
	get_homepage($)
	get_perl_makefile($)
	get_perl_source($)
	get_perl_copyright($)
	get_vcard($)
	get_html_copyright($)
	get_html_info($)
	get_full_name($)
	get_docbook_author($)
	get_docbook_address($)
	TEST($);

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This method builds the attribute access method for this class.
The attributes are:
0. "honorific" - honorific of the person.
1. "firstname" - first name of the person.
2. "surname" - sur name of the person.
3. "initials" - the persons initials.
4. "webpages" - set of web pages for the author (object list).
5. "emails" - set of email for the author (object list).
6. "accounts" - set of accounts for the author (object list).
7. "affiliations" - set of affiliations for the author (object list).
8. "security_keys" - set of security keys for the author (object list).
9. "ims" - set of instant messaging addresses for the author (object list).

For their meaning please consult the author DTD.

=item B<new_file($$)>

This method will create a new instance from an XML/author file.

=item B<new_modu($$)>

This method will create a new instance from an XML/author module
(Meta::Development::Module object).

=item B<get_default_passphrase($)>

This method will retrieve the default passphrase of the author.

=item B<get_default_email($)>

This method will retrieve the default email of the author.

=item B<get_default_affiliation($)>

This method will retrieve the default affiliation of the author.

=item B<get_handle($)>

This method will retrieve the unix user name of the author.

=item B<get_sourceforge_user($)>

This method returns the source forge user name of the author.

=item B<get_sourceforge_password($)>

This method returns the source forge password of the author.

=item B<get_sourceforge_mail($)>

This method returns the source forge email of the author.

=item B<get_sourceforge_ssh($)>

This method returns the ssh url where ssh interaction is possible with source forge.

=item B<get_cpan_user($)>

This method returns the CPAN id of the author.

=item B<get_cpan_mail($)>

This method returns the CPAN email of the author.

=item B<get_cpan_password($)>

This method returns the CPAN password of the author.

=item B<get_cpan_url($)>

This method returns the CPAN url of the author.

=item B<get_homepage($)>

This method returns the defualt homepage of the author.

=item B<get_perl_makefile($)>

This method will return the name of the author suitable for inclusion in
a perl makefile (Makefile.PL).

=item B<get_perl_source($)>

This method will return the name of the author suitable for inclusion
in a perl source file under a POD AUTHOR section.

=item B<get_perl_copyright($)>

This method will return the perl copyright notice for this author.
in a perl source file under a POD COPYRIGHT section.
The copyright years are taken from Aegis.

=item B<get_vcard($)>

This method will provide you with a string which contains VCARD information
that could be sent (for instance) as an email attachment so the recipient will
automatically have your details in his contacts software.

Here is a sample VCARD:
-----------------------
BEGIN:VCARD
X-EVOLUTION-FILE-AS:Falk, Rachel
FN:Rachel Falk
N:Falk;Rachel
TEL;WORK;VOICE:02-5892301
TEL;CELL:050-256655
EMAIL;INTERNET:rachel.falk@intel.com
ORG:Intel
NOTE;QUOTED-PRINTABLE:Cvish Begin=0ATake light to right=0AUp the ramp=0AFirst light Left=0AReach=
industrial zone=0AFirst right=0AFirst Left=0APass 500 meters=0AIntel buil=
ding on right
CATEGORIES:Business
UID:file:///local/home/mark/evolution/local/Contacts/addressbook.db/pas-id-3B73B04400000015
END:VCARD
-----------------------

=item B<get_html_copyright($)>

Get a copyright suitable for inserting into an HTML page.

=item B<get_html_info($)>

Get info suitable for inclusing in an HTML page.

=item B<get_full_name($)>

This method will return the full name of the Author.

=item B<get_docbook_author($)>

Return XML snipplet fit to be fitted in a Docbook document as author information.

=item B<get_docbook_address($)>

Return XML snipplet fit to be fitted in a Docbook document as address information.

=item B<TEST($)>

Test suite for this module.

The test currently creates an author object and prints it out. It also runs various
shortcut accessor method and prints the results of those too.

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

	0.00 MV perl packaging
	0.01 MV perl packaging again
	0.02 MV PDMT
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV more Class method generation
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV md5 project
	0.11 MV website construction
	0.12 MV improve the movie db xml
	0.13 MV web site development
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV bring movie data
	0.17 MV move tests into modules
	0.18 MV web site development
	0.19 MV weblog issues
	0.20 MV finish papers
	0.21 MV teachers project
	0.22 MV md5 issues

=head1 SEE ALSO

Data::Dumper(3), IO::String(3), Meta::Baseline::Aegis(3), Meta::Class::MethodMaker(3), Meta::Ds::Ohash(3), Meta::Info::Affiliation(3), Meta::Xml::Parsers::Author(3), XML::Writer(3), strict(3)

=head1 TODO

-make the signature routine produce a better signature.

-make the VCARD method do its thing.

-add more info.

-fix the constructor methods here (first argument in constructor should always be class type or blessing to right class wont be possible).

-add the following methods:
get_default_security_key()
get_advogato_user(),
get_advogato_email().

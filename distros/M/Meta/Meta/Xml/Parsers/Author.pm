#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Author;

use strict qw(vars refs subs);
use Meta::Info::Author qw();
use Meta::Xml::Parsers::Collector qw();
use Meta::Info::Webpage qw();
use Meta::Info::Email qw();
use Meta::Info::Account qw();
use Meta::Info::Affiliation qw();
use Meta::Info::SecurityKey qw();
use Meta::Info::Im qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.16";
@ISA=qw(Meta::Xml::Parsers::Collector);

#sub new($);
#sub get_result($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_endchar($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Collector::new($class);
	$self->setHandlers(
		'Start'=>\&handle_start,
		'End'=>\&handle_end,
	);
	#bless($self,$class);
	$self->{TEMP_AUTHOR}=defined;
	return($self);
}

sub get_result($) {
	my($self)=@_;
	return($self->{TEMP_AUTHOR});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_start($elem);
	#Meta::Utils::Output::print("in handle_start with elem [".$elem."]\n");
	if($elem eq "author") {
		$self->{TEMP_AUTHOR}=Meta::Info::Author->new();
	}
	if($elem eq "webpage") {
		$self->{TEMP_WEBPAGE}=Meta::Info::Webpage->new();
	}
	if($elem eq "email") {
		$self->{TEMP_EMAIL}=Meta::Info::Email->new();
	}
	if($elem eq "account") {
		$self->{TEMP_ACCOUNT}=Meta::Info::Account->new();
	}
	if($elem eq "affiliation") {
		$self->{TEMP_AFFILIATION}=Meta::Info::Affiliation->new();
	}
	if($elem eq "security_key") {
		$self->{TEMP_SECURITY_KEY}=Meta::Info::SecurityKey->new();
	}
	if($elem eq "im") {
		$self->{TEMP_IM}=Meta::Info::Im->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_end($elem);
	if($elem eq "webpage") {
		my($key)=$self->{TEMP_WEBPAGE}->get_title();
		$self->{TEMP_AUTHOR}->get_webpages()->insert($key,$self->{TEMP_WEBPAGE});
	}
	if($elem eq "email") {
		my($key)=$self->{TEMP_EMAIL}->get_title();
		$self->{TEMP_AUTHOR}->get_emails()->insert($key,$self->{TEMP_EMAIL});
	}
	if($elem eq "account") {
		my($key)=$self->{TEMP_ACCOUNT}->get_name();
		$self->{TEMP_AUTHOR}->get_accounts()->insert($key,$self->{TEMP_ACCOUNT});
	}
	if($elem eq "affiliation") {
		my($key)=$self->{TEMP_AFFILIATION}->get_title();
		$self->{TEMP_AUTHOR}->get_affiliations()->insert($key,$self->{TEMP_AFFILIATION});
	}
	if($elem eq "security_key") {
		my($key)=$self->{TEMP_SECURITY_KEY}->get_title();
		$self->{TEMP_AUTHOR}->get_security_keys()->insert($key,$self->{TEMP_SECURITY_KEY});
	}
	if($elem eq "im") {
		my($key)=$self->{TEMP_IM}->get_type();
		$self->{TEMP_AUTHOR}->get_ims()->insert($key,$self->{TEMP_IM});
	}
}

sub handle_endchar($$$) {
	my($self,$elem,$name)=@_;
#	Meta::Utils::Output::print("in here with elem [".$elem."],[".join(',',$self->context(),$name)."]\n");
	$self->SUPER::handle_endchar($elem,$name);
	if($self->in_context("author.honorific",$name)) {
		$self->{TEMP_AUTHOR}->set_honorific($elem);
	}
	if($self->in_context("author.firstname",$name)) {
		$self->{TEMP_AUTHOR}->set_firstname($elem);
	}
	if($self->in_context("author.surname",$name)) {
		$self->{TEMP_AUTHOR}->set_surname($elem);
	}
	if($self->in_context("author.initials",$name)) {
		$self->{TEMP_AUTHOR}->set_initials($elem);
	}
	if($self->in_context("author.webpages.webpage.title",$name)) {
		$self->{TEMP_WEBPAGE}->set_title($elem);
	}
	if($self->in_context("author.webpages.webpage.value",$name)) {
		$self->{TEMP_WEBPAGE}->set_value($elem);
	}
	if($self->in_context("author.emails.email.title",$name)) {
		$self->{TEMP_EMAIL}->set_title($elem);
	}
	if($self->in_context("author.emails.email.value",$name)) {
		$self->{TEMP_EMAIL}->set_value($elem);
	}
	if($self->in_context("author.accounts.account.name",$name)) {
		$self->{TEMP_ACCOUNT}->set_name($elem);
	}
	if($self->in_context("author.accounts.account.type",$name)) {
		$self->{TEMP_ACCOUNT}->set_type($elem);
	}
	if($self->in_context("author.accounts.account.user",$name)) {
		$self->{TEMP_ACCOUNT}->set_user($elem);
	}
	if($self->in_context("author.accounts.account.password",$name)) {
		$self->{TEMP_ACCOUNT}->set_password($elem);
	}
	if($self->in_context("author.accounts.account.system_name",$name)) {
		$self->{TEMP_ACCOUNT}->set_system_name($elem);
	}
	if($self->in_context("author.accounts.account.system_url",$name)) {
		$self->{TEMP_ACCOUNT}->set_system_url($elem);
	}
	if($self->in_context("author.accounts.account.mail",$name)) {
		$self->{TEMP_ACCOUNT}->set_mail($elem);
	}
	if($self->in_context("author.accounts.account.url",$name)) {
		$self->{TEMP_ACCOUNT}->set_url($elem);
	}
	if($self->in_context("author.accounts.account.directory",$name)) {
		$self->{TEMP_ACCOUNT}->set_directory($elem);
	}
	if($self->in_context("author.accounts.account.ssh",$name)) {
		$self->{TEMP_ACCOUNT}->set_ssh($elem);
	}
	if($self->in_context("author.security_keys.security_key.title",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_title($elem);
	}
	if($self->in_context("author.security_keys.security_key.code",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_code($elem);
	}
	if($self->in_context("author.affiliations.affiliation.title",$name)) {
		$self->{TEMP_AFFILIATION}->set_title($elem);
	}
	if($self->in_context("author.affiliations.affiliation.jobtitle",$name)) {
		$self->{TEMP_AFFILIATION}->set_jobtitle($elem);
	}
	if($self->in_context("author.affiliations.affiliation.orgname",$name)) {
		$self->{TEMP_AFFILIATION}->set_orgname($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.country",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_country($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.state",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_state($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.county",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_county($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.city",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_city($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.suburb",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_suburb($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.street",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_street($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.house_number",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_house_number($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.flat_number",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_flat_number($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.floor_number",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_floor_number($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.entrance_number",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_entrance_number($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.mail",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_mail($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.phone",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_phone($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.fax",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_fax($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.postcode",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_postcode($elem);
	}
	if($self->in_context("author.affiliations.affiliation.address.",$name)) {
		$self->{TEMP_AFFILIATION}->get_address()->set_($elem);
	}
	if($self->in_context("author.security_keys.security_key.server",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_server($elem);
	}
	if($self->in_context("author.security_keys.security_key.passphrase",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_passphrase($elem);
	}
	if($self->in_context("author.security_keys.security_key.public_key_url",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_public_key_url($elem);
	}
	if($self->in_context("author.security_keys.security_key.sig_name",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_sig_name($elem);
	}
	if($self->in_context("author.security_keys.security_key.sig_comment",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_sig_comment($elem);
	}
	if($self->in_context("author.security_keys.security_key.sig_email",$name)) {
		$self->{TEMP_SECURITY_KEY}->set_sig_email($elem);
	}
	if($self->in_context("author.ims.im.title",$name)) {
		$self->{TEMP_IM}->set_title($elem);
	}
	if($self->in_context("author.ims.im.type",$name)) {
		$self->{TEMP_IM}->set_type($elem);
	}
	if($self->in_context("author.ims.im.user",$name)) {
		$self->{TEMP_IM}->set_user($elem);
	}
	if($self->in_context("author.ims.im.password",$name)) {
		$self->{TEMP_IM}->set_password($elem);
	}
	if($self->in_context("author.ims.im.old_password",$name)) {
		$self->{TEMP_IM}->set_old_password($elem);
	}
	if($self->in_context("author.ims.im.active",$name)) {
		$self->{TEMP_IM}->set_active($elem);
	}
	if($self->in_context("author.ims.im.remark",$name)) {
		$self->{TEMP_IM}->set_remark($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Author - Object to parse an XML/author file.

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
	VERSION: 0.16

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Author qw();
	my($def_parser)=Meta::Xml::Parsers::Author->new();
	$def_parser->parsefile($file);
	my($def)=$def_parser->get_result();

=head1 DESCRIPTION

This object will create a Meta::Info::Author for you from an XML/author file. 

=head1 FUNCTIONS

	new($)
	get_result($)
	handle_start($$)
	handle_end($$)
	handle_endchar($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<get_result($)>

This method will retrieve the result of the parsing process.

=item B<handle_start($$)>

This will handle start tags.

=item B<handle_end($$)>

This will handle end tags.
This currently does nothing.

=item B<handle_endchar($$$)>

This will handle actual text.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Collector(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging again
	0.01 MV perl packaging again
	0.02 MV fix database problems
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV web site development
	0.13 MV weblog issues
	0.14 MV finish papers
	0.15 MV teachers project
	0.16 MV md5 issues

=head1 SEE ALSO

Meta::Info::Account(3), Meta::Info::Affiliation(3), Meta::Info::Author(3), Meta::Info::Email(3), Meta::Info::Im(3), Meta::Info::SecurityKey(3), Meta::Info::Webpage(3), Meta::Utils::Output(3), Meta::Xml::Parsers::Collector(3), strict(3)

=head1 TODO

Nothing.

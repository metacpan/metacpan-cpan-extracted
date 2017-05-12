#!/bin/echo This is a perl module and should not be run

package Meta::Info::Vcard;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.04";
@ISA=qw();

#sub new($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	return($self);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Info::Vcard - encapsulate VCARD type data manipulation.

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

	MANIFEST: Vcard.pm
	PROJECT: meta
	VERSION: 0.04

=head1 SYNOPSIS

	package foo;
	use Meta::Info::Vcard qw();
	my($object)=Meta::Info::Vcard->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is here to encapsulate Vcard type data. It is still not complete
in that it only contains stuff that I know about that is present in Vcard.

Here is how I got to know the Vcard status:
I filled out a full cards in netscape and evolution and saved them as Vcards
and got the format from there.

Services that this class provides:
0. parsing of text of a vcard and populating the object.
1. direct manipulatio of the objects fields.
2. writing of the object in VCARD type format.
3. reading and writing of the object in my own XML/DTD type format.
4. sending the object via sms to GSM type phones using GSM::SMS and others.
5. conversion of this object to various other formats.

Here is an example of a full VCARD taken from evolution version 1.0.8:
BEGIN:VCARD
X-EVOLUTION-FILE-AS:field_fileas
FN:field_title field_first field_middle field_last field_suffix
N:field_last;field_first;field_middle;field_title;field_suffix
ADR;WORK:field_business_po_box;field_business_address_2;field_business_address;field_business_city;field_business_state_province;field_business_zipcode;field_business_country
ADR;HOME:field_home_pobox;field_home_address_2;field_home_address;field_home_city;field_home_state/province;field_home_zipcode;field_home_country
ADR;POSTAL:field_other_pobox;field_other_address_2;field_other_address;field_other_city;field_other_state/province;field_other_zipcode;field_other_country
LABEL;QUOTED-PRINTABLE;WORK:field_business_po_box field_business_address=0Afield_business_address_2=0A=
field_business_city, field_business_state_province field_business_zipcode=0A=
field_business_country
LABEL;QUOTED-PRINTABLE;HOME:field_home_pobox field_home_address=0Afield_home_address_2=0Afield_home_ci=
ty, field_home_state/province field_home_zipcode=0Afield_home_country
LABEL;QUOTED-PRINTABLE;POSTAL:field_other_pobox field_other_address=0Afield_other_address_2=0Afield_othe=
r_city, field_other_state/province field_other_zipcode=0Afield_other_count=
ry
TEL;X-EVOLUTION-ASSISTANT:field_assistant
TEL;WORK;VOICE:field_business
TEL;WORK;VOICE:field_business_2
TEL;WORK;FAX:field_business_fax
TEL;X-EVOLUTION-CALLBACK:field_callback
TEL;CAR:field_car
TEL;WORK:field_company
TEL;HOME:field_home
TEL;HOME:field_home_2
TEL;HOME;FAX:field_home_fax
TEL;ISDN:field_ISDN
TEL;CELL:field_mobile
TEL;VOICE:field_other
TEL;FAX:field_other_fax
TEL;PAGER:field_pager
TEL;PREF:field_primary
TEL;X-EVOLUTION-RADIO:field_radio
TEL;X-EVOLUTION-TELEX:field_telex
TEL;X-EVOLUTION-TTYTDD:field_tty/tdd
EMAIL;INTERNET:field_primary_email
EMAIL;INTERNET:field_email2
EMAIL;INTERNET:field_email3
URL:field_web_page_address
ORG:field_organization;field_department
X-EVOLUTION-OFFICE:field_office
TITLE:field_job_title
ROLE:field_profession
X-EVOLUTION-MANAGER:field_managers_name
X-EVOLUTION-ASSISTANT:field_assistants_name
NICKNAME:field_nickname
X-EVOLUTION-SPOUSE:field_spouse
CALURI:field_public_calendar_url
FBURL:field_free/budy_url
NOTE:field_notes
X-EVOLUTION-RELATED_CONTACTS:E<lt>?xml version="1.0"?E<gt>E<lt>destinationsE<gt>E<lt>destination html_mail="no"E<gt>E<lt>emailE<gt>field_contactsE<lt>/emailE<gt>E<lt>/destinationE<gt>E<lt>/destinationsE<gt>
CATEGORIES:field_categories
UID:pas-id-3DCDA17B00000000
END:VCARD

All fields here are full and this is the base reference for deriving the actual info.
As evolution progresses though this standard will tend to expand (evolution has already
strained this too much in my opinion (xml would have done better)).

=head1 FUNCTIONS

	new($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Info::Vcard object.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV more pdmt stuff
	0.04 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

-get references to Vcards from the net and work to comply with the entire standard.

package Locale::Nationality::en;

use strict;
use warnings;

our $names;
our $VERSION = '1.04';

# -----------------------------------------------

sub names
{
	my($self) = @_;

	return $names;

} # End of names.

# -----------------------------------------------

sub new
{
	my($class) = @_;
	$names     =
[
'Afghan',
'Albanian',
'Algerian',
'American',
'Andorran',
'Angolan',
'Antiguans',
'Argentinean',
'Armenian',
'Australian',
'Austrian',
'Azerbaijani',
'Bahamian',
'Bahraini',
'Bangladeshi',
'Barbadian',
'Barbudans',
'Batswana',
'Belarusian',
'Belgian',
'Belizean',
'Beninese',
'Bhutanese',
'Bolivian',
'Bosnian',
'Brazilian',
'British',
'Bruneian',
'Bulgarian',
'Burkinabe',
'Burmese',
'Burundian',
'Cambodian',
'Cameroonian',
'Canadian',
'Cape Verdean',
'Central African',
'Chadian',
'Chilean',
'Chinese',
'Colombian',
'Comoran',
'Congolese',
'Congolese',
'Costa Rican',
'Croatian',
'Cuban',
'Cypriot',
'Czech',
'Danish',
'Djibouti',
'Dominican',
'Dominican',
'Dutch',
'Dutchman',
'Dutchwoman',
'East Timorese',
'Ecuadorean',
'Egyptian',
'Emirian',
'Equatorial Guinean',
'Eritrean',
'Estonian',
'Ethiopian',
'Fijian',
'Filipino',
'Finnish',
'French',
'Gabonese',
'Gambian',
'Georgian',
'German',
'Ghanaian',
'Greek',
'Grenadian',
'Guatemalan',
'Guinea-Bissauan',
'Guinean',
'Guyanese',
'Haitian',
'Herzegovinian',
'Honduran',
'Hungarian',
'I-Kiribati',
'Icelander',
'Indian',
'Indonesian',
'Iranian',
'Iraqi',
'Irish',
'Irish',
'Israeli',
'Italian',
'Ivorian',
'Jamaican',
'Japanese',
'Jordanian',
'Kazakhstani',
'Kenyan',
'Kittian and Nevisian',
'Kuwaiti',
'Kyrgyz',
'Laotian',
'Latvian',
'Lebanese',
'Liberian',
'Libyan',
'Liechtensteiner',
'Lithuanian',
'Luxembourger',
'Macedonian',
'Malagasy',
'Malawian',
'Malaysian',
'Maldivan',
'Malian',
'Maltese',
'Marshallese',
'Mauritanian',
'Mauritian',
'Mexican',
'Micronesian',
'Moldovan',
'Monacan',
'Mongolian',
'Moroccan',
'Mosotho',
'Motswana',
'Mozambican',
'Namibian',
'Nauruan',
'Nepalese',
'Netherlander',
'New Zealander',
'Ni-Vanuatu',
'Nicaraguan',
'Nigerian',
'Nigerien',
'North Korean',
'Northern Irish',
'Norwegian',
'Omani',
'Pakistani',
'Palauan',
'Panamanian',
'Papua New Guinean',
'Paraguayan',
'Peruvian',
'Polish',
'Portuguese',
'Qatari',
'Romanian',
'Russian',
'Rwandan',
'Saint Lucian',
'Salvadoran',
'Samoan',
'San Marinese',
'Sao Tomean',
'Saudi',
'Scottish',
'Senegalese',
'Serbian',
'Seychellois',
'Sierra Leonean',
'Singaporean',
'Slovakian',
'Slovenian',
'Solomon Islander',
'Somali',
'South African',
'South Korean',
'Spanish',
'Sri Lankan',
'Sudanese',
'Surinamer',
'Swazi',
'Swedish',
'Swiss',
'Syrian',
'Taiwanese',
'Tajik',
'Tanzanian',
'Thai',
'Togolese',
'Tongan',
'Trinidadian or Tobagonian',
'Tunisian',
'Turkish',
'Tuvaluan',
'Ugandan',
'Ukrainian',
'Uruguayan',
'Uzbekistani',
'Venezuelan',
'Vietnamese',
'Welsh',
'Welsh',
'Yemenite',
'Zambian',
'Zimbabwean',
];
	return bless({}, $class);

}	# End of new.

# -----------------------------------------------

1;

__END__

=pod

=head1 NAME

Locale::Nationality::en - English names of nationalities

=head1 Synopsis

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Locale::Nationality::en;

	# ------------------

	print map{"$_\n"} @{Locale::Nationality::en -> new -> names};

Or, as a 1-liner:

	perl -MLocale::Nationality::en -e 'print map{"$_\n"} @{Locale::Nationality::en -> new -> names}'

=head1 Description

C<Locale::Nationality::en> is a pure Perl module.

It provies you with a list of English names for nationalities.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

L<Download|http://savage.net.au/Perl-modules.html>.

L<Help with installation|http://savage.net.au/Perl-modules/html/installing-a-module.html>.

=head1 Constructor and initialization

new(...) returns a C<Locale::Nationality::en> object.

This is the class contructor.

Usage: Locale::Nationality::en -> new.

C<new()> does not take any parameters.

=head1 Method: names

Returns a sorted array ref of names.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Locale-Nationality-en>

=head1 Credits

L<Guava Studios supplied the list|http://www.guavastudios.com/nationality-list.htm>.

=head1 Author

C<Locale::Nationality::en> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

L<My homepage|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

L<Licenses|http://www.opensource.org/licenses/index.html>.

=cut

package Faker;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Data::Object::Role::Proxyable';
with 'Faker::Maker';

our $VERSION = '1.03'; # VERSION

# METHODS

method address_city_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_name', %args)->execute;
}

method address_city_prefix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_prefix', %args)->execute;
}

method address_city_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_city_suffix', %args)->execute;
}

method address_country_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_country_name', %args)->execute;
}

method address_latitude(%args) {
  $args{faker} = $self;

  return $self->plugin('address_latitude', %args)->execute;
}

method address_line1(%args) {
  $args{faker} = $self;

  return $self->plugin('address_line1', %args)->execute;
}

method address_line2(%args) {
  $args{faker} = $self;

  return $self->plugin('address_line2', %args)->execute;
}

method address_lines(%args) {
  $args{faker} = $self;

  return $self->plugin('address_lines', %args)->execute;
}

method address_longitude(%args) {
  $args{faker} = $self;

  return $self->plugin('address_longitude', %args)->execute;
}

method address_number(%args) {
  $args{faker} = $self;

  return $self->plugin('address_number', %args)->execute;
}

method address_postal_code(%args) {
  $args{faker} = $self;

  return $self->plugin('address_postal_code', %args)->execute;
}

method address_state_abbr(%args) {
  $args{faker} = $self;

  return $self->plugin('address_state_abbr', %args)->execute;
}

method address_state_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_state_name', %args)->execute;
}

method address_street_name(%args) {
  $args{faker} = $self;

  return $self->plugin('address_street_name', %args)->execute;
}

method address_street_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('address_street_suffix', %args)->execute;
}

method build_proxy($package, $method, %args) {
  $args{faker} = $self;

  my $under = delete $args{under};

  $method = "$under/$method" if $under;

  if (my $plugin = eval { $self->plugin($method, %args) }) {

    return sub { $plugin->execute };
  }

  return undef;
}

method color_hex_code(%args) {
  $args{faker} = $self;

  return $self->plugin('color_hex_code', %args)->execute;
}

method color_name(%args) {
  $args{faker} = $self;

  return $self->plugin('color_name', %args)->execute;
}

method color_rgbcolors(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors', %args)->execute;
}

method color_rgbcolors_array(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors_array', %args)->execute;
}

method color_rgbcolors_css(%args) {
  $args{faker} = $self;

  return $self->plugin('color_rgbcolors_css', %args)->execute;
}

method color_safe_hex_code(%args) {
  $args{faker} = $self;

  return $self->plugin('color_safe_hex_code', %args)->execute;
}

method color_safe_name(%args) {
  $args{faker} = $self;

  return $self->plugin('color_safe_name', %args)->execute;
}

method company_buzzword_type1(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type1', %args)->execute;
}

method company_buzzword_type2(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type2', %args)->execute;
}

method company_buzzword_type3(%args) {
  $args{faker} = $self;

  return $self->plugin('company_buzzword_type3', %args)->execute;
}

method company_description(%args) {
  $args{faker} = $self;

  return $self->plugin('company_description', %args)->execute;
}

method company_jargon_buzz_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_buzz_word', %args)->execute;
}

method company_jargon_edge_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_edge_word', %args)->execute;
}

method company_jargon_prop_word(%args) {
  $args{faker} = $self;

  return $self->plugin('company_jargon_prop_word', %args)->execute;
}

method company_name(%args) {
  $args{faker} = $self;

  return $self->plugin('company_name', %args)->execute;
}

method company_name_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('company_name_suffix', %args)->execute;
}

method company_tagline(%args) {
  $args{faker} = $self;

  return $self->plugin('company_tagline', %args)->execute;
}

method internet_domain_name(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_domain_name', %args)->execute;
}

method internet_domain_word(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_domain_word', %args)->execute;
}

method internet_email_address(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_email_address', %args)->execute;
}

method internet_email_domain(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_email_domain', %args)->execute;
}

method internet_ip_address(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address', %args)->execute;
}

method internet_ip_address_v4(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address_v4', %args)->execute;
}

method internet_ip_address_v6(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_ip_address_v6', %args)->execute;
}

method internet_root_domain(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_root_domain', %args)->execute;
}

method internet_url(%args) {
  $args{faker} = $self;

  return $self->plugin('internet_url', %args)->execute;
}

method lorem_paragraph(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_paragraph', %args)->execute;
}

method lorem_paragraphs(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_paragraphs', %args)->execute;
}

method lorem_sentence(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_sentence', %args)->execute;
}

method lorem_sentences(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_sentences', %args)->execute;
}

method lorem_word(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_word', %args)->execute;
}

method lorem_words(%args) {
  $args{faker} = $self;

  return $self->plugin('lorem_words', %args)->execute;
}

method payment_card_expiration(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_card_expiration', %args)->execute;
}

method payment_card_number(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_card_number', %args)->execute;
}

method payment_vendor(%args) {
  $args{faker} = $self;

  return $self->plugin('payment_vendor', %args)->execute;
}

method person_first_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_first_name', %args)->execute;
}

method person_last_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_last_name', %args)->execute;
}

method person_name(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name', %args)->execute;
}

method person_name_prefix(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name_prefix', %args)->execute;
}

method person_name_suffix(%args) {
  $args{faker} = $self;

  return $self->plugin('person_name_suffix', %args)->execute;
}

method person_username(%args) {
  $args{faker} = $self;

  return $self->plugin('person_username', %args)->execute;
}

method telephone_number(%args) {
  $args{faker} = $self;

  return $self->plugin('telephone_number', %args)->execute;
}

1;

=encoding utf8

=head1 NAME

Faker

=cut

=head1 ABSTRACT

Extensible Fake Data Generator

=cut

=head1 SYNOPSIS

  package main;

  use Faker;

  my $f = Faker->new;

=cut

=head1 DESCRIPTION

This package provides generates fake data for you. Whether you need to
bootstrap your database, create good-looking XML documents, fill-in your
persistence to stress test it, or anonymize data taken from a production
service, Faker makes it easy to generate fake data.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Pluggable>

L<Data::Object::Role::Proxyable>

L<Data::Object::Role::Throwable>

L<Faker::Maker>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 autoloading

  package Faker::Plugin::FileExt;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'faker';

  sub execute {
    'video/mpeg'
  }

  package main;

  use Faker;

  my $f = Faker->new;

  $f->_file_ext

This package supports the auto-loading of plugins, which means that anyone can
create non-core plugins (fake data generators) and load and control them using
Faker.

=cut

=head2 autoloading-under

  package Faker::Plugin::JaJp::PersonName;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'faker';

  sub execute {
    '鈴木 陽一'
  }

  package main;

  use Faker;

  my $f = Faker->new;

  $f->_person_name(under => 'ja_jp')

This package also supports auto-loading plugins under a specific sub-namespace
which is typical in creating fake data plugins for locales.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 address_city_name

  address_city_name(Any %args) : Str

The address_city_name method returns a random fake address city name. See the
L<Faker::Plugin::AddressCityName> plugin for more information.

=over 4

=item address_city_name example #1

  # given: synopsis

  $f->address_city_name

  # Lolastad

=back

=cut

=head2 address_city_prefix

  address_city_prefix(Any %args) : Str

The address_city_prefix method returns a random fake address city prefix. See
the L<Faker::Plugin::AddressCityPrefix> plugin for more information.

=over 4

=item address_city_prefix example #1

  # given: synopsis

  $f->address_city_prefix

  # South

=back

=cut

=head2 address_city_suffix

  address_city_suffix(Any %args) : Str

The address_city_suffix method returns a random fake address city suffix. See
the L<Faker::Plugin::AddressCitySuffix> plugin for more information.

=over 4

=item address_city_suffix example #1

  # given: synopsis

  $f->address_city_suffix

  # berg

=back

=cut

=head2 address_country_name

  address_country_name(Any %args) : Str

The address_country_name method returns a random fake address country name. See
the L<Faker::Plugin::AddressCountryName> plugin for more information.

=over 4

=item address_country_name example #1

  # given: synopsis

  $f->address_country_name

  # Iraq

=back

=cut

=head2 address_latitude

  address_latitude(Any %args) : Str

The address_latitude method returns a random fake address latitude. See the
L<Faker::Plugin::Address::Latitude> plugin for more information.

=over 4

=item address_latitude example #1

  # given: synopsis

  $f->address_latitude

  # 2338952

=back

=cut

=head2 address_line1

  address_line1(Any %args) : Str

The address_line1 method returns a random fake address line1. See the
L<Faker::Plugin::AddressLine1> plugin for more information.

=over 4

=item address_line1 example #1

  # given: synopsis

  $f->address_line1

  # 4 Schaefer Parkway

=back

=cut

=head2 address_line2

  address_line2(Any %args) : Str

The address_line2 method returns a random fake address line2. See the
L<Faker::Plugin::AddressLine2> plugin for more information.

=over 4

=item address_line2 example #1

  # given: synopsis

  $f->address_line2

  # Apt. 092

=back

=cut

=head2 address_lines

  address_lines(Any %args) : Str

The address_lines method returns a random fake address lines. See the
L<Faker::Plugin::AddressLines> plugin for more information.

=over 4

=item address_lines example #1

  # given: synopsis

  $f->address_lines

  # 3587 Thiel Avenue
  # Suite 335
  # Tobinmouth, ME 96440-0239

=back

=cut

=head2 address_longitude

  address_longitude(Any %args) : Str

The address_longitude method returns a random fake address longitude. See the
L<Faker::Plugin::AddressLongitude> plugin for more information.

=over 4

=item address_longitude example #1

  # given: synopsis

  $f->address_longitude

  # -28.920235

=back

=cut

=head2 address_number

  address_number(Any %args) : Str

The address_number method returns a random fake address number. See the
L<Faker::Plugin::AddressNumber> plugin for more information.

=over 4

=item address_number example #1

  # given: synopsis

  $f->address_number

  # 67

=back

=cut

=head2 address_postal_code

  address_postal_code(Any %args) : Str

The address_postal_code method returns a random fake address postal code. See
the L<Faker::Plugin::AddressPostalCode> plugin for more information.

=over 4

=item address_postal_code example #1

  # given: synopsis

  $f->address_postal_code

  # 02475

=back

=cut

=head2 address_state_abbr

  address_state_abbr(Any %args) : Str

The address_state_abbr method returns a random fake address state abbr. See the
L<Faker::Plugin::AddressStateAbbr> plugin for more information.

=over 4

=item address_state_abbr example #1

  # given: synopsis

  $f->address_state_abbr

  # OH

=back

=cut

=head2 address_state_name

  address_state_name(Any %args) : Str

The address_state_name method returns a random fake address state name. See the
L<Faker::Plugin::AddressStateName> plugin for more information.

=over 4

=item address_state_name example #1

  # given: synopsis

  $f->address_state_name

  # Georgia

=back

=cut

=head2 address_street_name

  address_street_name(Any %args) : Str

The address_street_name method returns a random fake address street name. See
the L<Faker::Plugin::AddressStreetName> plugin for more information.

=over 4

=item address_street_name example #1

  # given: synopsis

  $f->address_street_name

  # Reyna Avenue

=back

=cut

=head2 address_street_suffix

  address_street_suffix(Any %args) : Str

The address_street_suffix method returns a random fake address street suffix.
See the L<Faker::Plugin::AddressStreetSuffix> plugin for more information.

=over 4

=item address_street_suffix example #1

  # given: synopsis

  $f->address_street_suffix

  # Avenue

=back

=cut

=head2 color_hex_code

  color_hex_code(Any %args) : Str

The color_hex_code method returns a random fake color hex code. See the
L<Faker::Plugin::ColorHexCode> plugin for more information.

=over 4

=item color_hex_code example #1

  # given: synopsis

  $f->color_hex_code

  # #b9fe40

=back

=cut

=head2 color_name

  color_name(Any %args) : Str

The color_name method returns a random fake color name. See the
L<Faker::Plugin::ColorName> plugin for more information.

=over 4

=item color_name example #1

  # given: synopsis

  $f->color_name

  # LightSteelBlue

=back

=cut

=head2 color_rgbcolors

  color_rgbcolors(Any %args) : Str

The color_rgbcolors method returns a random fake color rgbcolors. See the
L<Faker::Plugin::ColorRgbcolors> plugin for more information.

=over 4

=item color_rgbcolors example #1

  # given: synopsis

  $f->color_rgbcolors

  # 77,186,28

=back

=cut

=head2 color_rgbcolors_array

  color_rgbcolors_array(Any %args) : ArrayRef

The color_rgbcolors_array method returns a random fake color rgbcolors array.
See the L<Faker::Plugin::ColorRgbcolorsArray> plugin for more information.

=over 4

=item color_rgbcolors_array example #1

  # given: synopsis

  $f->color_rgbcolors_array

  # [77,186,28]

=back

=cut

=head2 color_rgbcolors_css

  color_rgbcolors_css(Any %args) : Str

The color_rgbcolors_css method returns a random fake color rgbcolors css. See
the L<Faker::Plugin::ColorRgbcolorsCss> plugin for more information.

=over 4

=item color_rgbcolors_css example #1

  # given: synopsis

  $f->color_rgbcolors_css

  # rgb(115,98,44)

=back

=cut

=head2 color_safe_hex_code

  color_safe_hex_code(Any %args) : Str

The color_safe_hex_code method returns a random fake color safe hex code. See
the L<Faker::Plugin::ColorSafeHexCode> plugin for more information.

=over 4

=item color_safe_hex_code example #1

  # given: synopsis

  $f->color_safe_hex_code

  # #ff0078

=back

=cut

=head2 color_safe_name

  color_safe_name(Any %args) : Str

The color_safe_name method returns a random fake color safe name. See the
L<Faker::Plugin::ColorSafeName> plugin for more information.

=over 4

=item color_safe_name example #1

  # given: synopsis

  $f->color_safe_name

  # blue

=back

=cut

=head2 company_buzzword_type1

  company_buzzword_type1(Any %args) : Str

The company_buzzword_type1 method returns a random fake company buzzword type1.
See the L<Faker::Plugin::CompanyBuzzwordType1> plugin for more information.

=over 4

=item company_buzzword_type1 example #1

  # given: synopsis

  $f->company_buzzword_type1

  # implement

=back

=cut

=head2 company_buzzword_type2

  company_buzzword_type2(Any %args) : Str

The company_buzzword_type2 method returns a random fake company buzzword type2.
See the L<Faker::Plugin::CompanyBuzzwordType2> plugin for more information.

=over 4

=item company_buzzword_type2 example #1

  # given: synopsis

  $f->company_buzzword_type2

  # interactive

=back

=cut

=head2 company_buzzword_type3

  company_buzzword_type3(Any %args) : Str

The company_buzzword_type3 method returns a random fake company buzzword type3.
See the L<Faker::Plugin::CompanyBuzzwordType3> plugin for more information.

=over 4

=item company_buzzword_type3 example #1

  # given: synopsis

  $f->company_buzzword_type3

  # bandwidth

=back

=cut

=head2 company_description

  company_description(Any %args) : Str

The company_description method returns a random fake company description. See
the L<Faker::Plugin::CompanyDescription> plugin for more information.

=over 4

=item company_description example #1

  # given: synopsis

  $f->company_description

  # Excels at impactful pre-emptive decisions

=back

=cut

=head2 company_jargon_buzz_word

  company_jargon_buzz_word(Any %args) : Str

The company_jargon_buzz_word method returns a random fake company jargon buzz
word. See the L<Faker::Plugin::CompanyJargonBuzzWord> plugin for more
information.

=over 4

=item company_jargon_buzz_word example #1

  # given: synopsis

  $f->company_jargon_buzz_word

  # parallelism

=back

=cut

=head2 company_jargon_edge_word

  company_jargon_edge_word(Any %args) : Str

The company_jargon_edge_word method returns a random fake company jargon edge
word. See the L<Faker::Plugin::CompanyJargonEdgeWord> plugin for more
information.

=over 4

=item company_jargon_edge_word example #1

  # given: synopsis

  $f->company_jargon_edge_word

  # Customer-focused

=back

=cut

=head2 company_jargon_prop_word

  company_jargon_prop_word(Any %args) : Str

The company_jargon_prop_word method returns a random fake company jargon prop
word. See the L<Faker::Plugin::CompanyJargonPropWord> plugin for more
information.

=over 4

=item company_jargon_prop_word example #1

  # given: synopsis

  $f->company_jargon_prop_word

  # upward-trending

=back

=cut

=head2 company_name

  company_name(Any %args) : Str

The company_name method returns a random fake company name. See the
L<Faker::Plugin::CompanyName> plugin for more information.

=over 4

=item company_name example #1

  # given: synopsis

  $f->company_name

  # Boehm, Rutherford and Roberts

=back

=cut

=head2 company_name_suffix

  company_name_suffix(Any %args) : Str

The company_name_suffix method returns a random fake company name suffix. See
the L<Faker::Plugin::CompanyNameSuffix> plugin for more information.

=over 4

=item company_name_suffix example #1

  # given: synopsis

  $f->company_name_suffix

  # Group

=back

=cut

=head2 company_tagline

  company_tagline(Any %args) : Str

The company_tagline method returns a random fake company tagline. See the
L<Faker::Plugin::CompanyTagline> plugin for more information.

=over 4

=item company_tagline example #1

  # given: synopsis

  $f->company_tagline

  # cultivate end-to-end partnerships

=back

=cut

=head2 internet_domain_name

  internet_domain_name(Any %args) : Str

The internet_domain_name method returns a random fake internet domain name. See
the L<Faker::Plugin::InternetDomainName> plugin for more information.

=over 4

=item internet_domain_name example #1

  # given: synopsis

  $f->internet_domain_name

  # kassulke-cruickshank.biz

=back

=cut

=head2 internet_domain_word

  internet_domain_word(Any %args) : Str

The internet_domain_word method returns a random fake internet domain word. See
the L<Faker::Plugin::InternetDomainWord> plugin for more information.

=over 4

=item internet_domain_word example #1

  # given: synopsis

  $f->internet_domain_word

  # raynor-beier

=back

=cut

=head2 internet_email_address

  internet_email_address(Any %args) : Str

The internet_email_address method returns a random fake internet email address.
See the L<Faker::Plugin::InternetEmailAddress> plugin for more information.

=over 4

=item internet_email_address example #1

  # given: synopsis

  $f->internet_email_address

  # rose@maggio-pfannerstill-and-marquardt.com

=back

=cut

=head2 internet_email_domain

  internet_email_domain(Any %args) : Str

The internet_email_domain method returns a random fake internet email domain.
See the L<Faker::Plugin::InternetEmailDomain> plugin for more information.

=over 4

=item internet_email_domain example #1

  # given: synopsis

  $f->internet_email_domain

  # gmail.com

=back

=cut

=head2 internet_ip_address

  internet_ip_address(Any %args) : Str

The internet_ip_address method returns a random fake internet ip address. See
the L<Faker::Plugin::InternetIpAddress> plugin for more information.

=over 4

=item internet_ip_address example #1

  # given: synopsis

  $f->internet_ip_address

  # 193.199.217.87

=back

=cut

=head2 internet_ip_address_v4

  internet_ip_address_v4(Any %args) : Str

The internet_ip_address_v4 method returns a random fake internet ip address v4.
See the L<Faker::Plugin::InternetIpAddressV4> plugin for more information.

=over 4

=item internet_ip_address_v4 example #1

  # given: synopsis

  $f->internet_ip_address_v4

  # 45.212.129.22

=back

=cut

=head2 internet_ip_address_v6

  internet_ip_address_v6(Any %args) : Str

The internet_ip_address_v6 method returns a random fake internet ip address v6.
See the L<Faker::Plugin::InternetIpAddressV6> plugin for more information.

=over 4

=item internet_ip_address_v6 example #1

  # given: synopsis

  $f->internet_ip_address_v6

  # 4024:40e9:b107:681d:8ce1:bb12:3380:b476

=back

=cut

=head2 internet_root_domain

  internet_root_domain(Any %args) : Str

The internet_root_domain method returns a random fake internet root domain. See
the L<Faker::Plugin::InternetRootDomain> plugin for more information.

=over 4

=item internet_root_domain example #1

  # given: synopsis

  $f->internet_root_domain

  # biz

=back

=cut

=head2 internet_url

  internet_url(Any %args) : Str

The internet_url method returns a random fake internet url. See the
L<Faker::Plugin::InternetUrl> plugin for more information.

=over 4

=item internet_url example #1

  # given: synopsis

  $f->internet_url

  # https://krajcik-goyette.biz/

=back

=cut

=head2 lorem_paragraph

  lorem_paragraph(Any %args) : Str

The lorem_paragraph method returns a random fake lorem paragraph. See the
L<Faker::Plugin::LoremParagraph> plugin for more information.

=over 4

=item lorem_paragraph example #1

  # given: synopsis

  $f->lorem_paragraph

  # id tempore eum. vitae optio rerum enim nihil perspiciatis omnis et. ut
  # voluptates dicta qui culpa. a nam at nemo fugiat.

=back

=cut

=head2 lorem_paragraphs

  lorem_paragraphs(Any %args) : Str

The lorem_paragraphs method returns a random fake lorem paragraphs. See the
L<Faker::Plugin::LoremParagraphs> plugin for more information.

=over 4

=item lorem_paragraphs example #1

  # given: synopsis

  $f->lorem_paragraphs

  # modi minus pariatur accusamus possimus eaque id velit porro. voluptatum
  # natus saepe. non in quas est. ut quos autem occaecati quo.

  # saepe quae unde. vel hic consequuntur. quia aut ut nostrum amet. et
  # consequuntur occaecati.

=back

=cut

=head2 lorem_sentence

  lorem_sentence(Any %args) : Str

The lorem_sentence method returns a random fake lorem sentence. See the
L<Faker::Plugin::LoremSentence> plugin for more information.

=over 4

=item lorem_sentence example #1

  # given: synopsis

  $f->lorem_sentence

  # amet id id culpa reiciendis minima id corporis illum quas.

=back

=cut

=head2 lorem_sentences

  lorem_sentences(Any %args) : Str

The lorem_sentences method returns a random fake lorem sentences. See the
L<Faker::Plugin::LoremSentences> plugin for more information.

=over 4

=item lorem_sentences example #1

  # given: synopsis

  $f->lorem_sentences

  # laboriosam ipsam ipsum. animi accusantium quisquam repellendus. occaecati
  # itaque reiciendis perferendis exercitationem.

=back

=cut

=head2 lorem_word

  lorem_word(Any %args) : Str

The lorem_word method returns a random fake lorem word. See the
L<Faker::Plugin::LoremWord> plugin for more information.

=over 4

=item lorem_word example #1

  # given: synopsis

  $f->lorem_word

  # quos

=back

=cut

=head2 lorem_words

  lorem_words(Any %args) : Str

The lorem_words method returns a random fake lorem words. See the
L<Faker::Plugin::LoremWords> plugin for more information.

=over 4

=item lorem_words example #1

  # given: synopsis

  $f->lorem_words

  # autem assumenda commodi eum dolor

=back

=cut

=head2 payment_card_expiration

  payment_card_expiration(Any %args) : Str

The payment_card_expiration method returns a random fake payment card
expiration. See the L<Faker::Plugin::PaymentCardExpiration> plugin for more
information.

=over 4

=item payment_card_expiration example #1

  # given: synopsis

  $f->payment_card_expiration

  # 01/21

=back

=cut

=head2 payment_card_number

  payment_card_number(Any %args) : Str

The payment_card_number method returns a random fake payment card number. See
the L<Faker::Plugin::PaymentCardNumber> plugin for more information.

=over 4

=item payment_card_number example #1

  # given: synopsis

  $f->payment_card_number

  # 544772628796996

=back

=cut

=head2 payment_vendor

  payment_vendor(Any %args) : Str

The payment_vendor method returns a random fake payment vendor. See the
L<Faker::Plugin::PaymentVendor> plugin for more information.

=over 4

=item payment_vendor example #1

  # given: synopsis

  $f->payment_vendor

  # Visa

=back

=cut

=head2 person_first_name

  person_first_name(Any %args) : Str

The person_first_name method returns a random fake person first name. See the
L<Faker::Plugin::PersonFirstName> plugin for more information.

=over 4

=item person_first_name example #1

  # given: synopsis

  $f->person_first_name

  # Sandrine

=back

=cut

=head2 person_last_name

  person_last_name(Any %args) : Str

The person_last_name method returns a random fake person last name. See the
L<Faker::Plugin::PersonLastName> plugin for more information.

=over 4

=item person_last_name example #1

  # given: synopsis

  $f->person_last_name

  # Langosh

=back

=cut

=head2 person_name

  person_name(Any %args) : Str

The person_name method returns a random fake person name. See the
L<Faker::Plugin::PersonName> plugin for more information.

=over 4

=item person_name example #1

  # given: synopsis

  $f->person_name

  # Eveline Wintheiser

=back

=cut

=head2 person_name_prefix

  person_name_prefix(Any %args) : Str

The person_name_prefix method returns a random fake person name prefix. See the
L<Faker::Plugin::PersonNamePrefix> plugin for more information.

=over 4

=item person_name_prefix example #1

  # given: synopsis

  $f->person_name_prefix

  # Ms.

=back

=cut

=head2 person_name_suffix

  person_name_suffix(Any %args) : Str

The person_name_suffix method returns a random fake person name suffix. See the
L<Faker::Plugin::PersonNameSuffix> plugin for more information.

=over 4

=item person_name_suffix example #1

  # given: synopsis

  $f->person_name_suffix

  # Sr.

=back

=cut

=head2 person_username

  person_username(Any %args) : Str

The person_username method returns a random fake person username. See the
L<Faker::Plugin::PersonUsername> plugin for more information.

=over 4

=item person_username example #1

  # given: synopsis

  $f->person_username

  # Cayla25

=back

=cut

=head2 telephone_number

  telephone_number(Any %args) : Str

The telephone_number method returns a random fake telephone number. See the
L<Faker::Plugin::TelephoneNumber> plugin for more information.

=over 4

=item telephone_number example #1

  # given: synopsis

  $f->telephone_number

  # 549-844-2061

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/faker/blob/master/LICENSE>.

=head1 ACKNOWLEDGEMENTS

Parts of this library were inspired by the following implementations:

L<PHP Faker|https://github.com/fzaninotto/Faker>

L<Ruby Faker|https://github.com/stympy/faker>

L<Python Faker|https://github.com/joke2k/faker>

L<JS Faker|https://github.com/Marak/faker.js>

L<Elixir Faker|https://github.com/elixirs/faker>

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/faker/wiki>

L<Project|https://github.com/iamalnewkirk/faker>

L<Initiatives|https://github.com/iamalnewkirk/faker/projects>

L<Milestones|https://github.com/iamalnewkirk/faker/milestones>

L<Contributing|https://github.com/iamalnewkirk/faker/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/faker/issues>

=cut

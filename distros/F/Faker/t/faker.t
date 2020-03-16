use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Faker

=cut

=abstract

Extensible Fake Data Generator

=cut

=includes

method: address_city_name
method: address_city_prefix
method: address_city_suffix
method: address_country_name
method: address_latitude
method: address_line1
method: address_line2
method: address_lines
method: address_longitude
method: address_number
method: address_postal_code
method: address_state_abbr
method: address_state_name
method: address_street_name
method: address_street_suffix
method: color_hex_code
method: color_name
method: color_rgbcolors
method: color_rgbcolors_array
method: color_rgbcolors_css
method: color_safe_hex_code
method: color_safe_name
method: company_buzzword_type1
method: company_buzzword_type2
method: company_buzzword_type3
method: company_description
method: company_jargon_buzz_word
method: company_jargon_edge_word
method: company_jargon_prop_word
method: company_name
method: company_name_suffix
method: company_tagline
method: internet_domain_name
method: internet_domain_word
method: internet_email_address
method: internet_email_domain
method: internet_ip_address
method: internet_ip_address_v4
method: internet_ip_address_v6
method: internet_root_domain
method: internet_url
method: lorem_paragraph
method: lorem_paragraphs
method: lorem_sentence
method: lorem_sentences
method: lorem_word
method: lorem_words
method: payment_card_expiration
method: payment_card_number
method: payment_vendor
method: person_first_name
method: person_last_name
method: person_name
method: person_name_prefix
method: person_name_suffix
method: person_username
method: telephone_number

=cut

=synopsis

  package main;

  use Faker;

  my $f = Faker->new;

=cut

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Pluggable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides generates fake data for you. Whether you need to
bootstrap your database, create good-looking XML documents, fill-in your
persistence to stress test it, or anonymize data taken from a production
service, Faker makes it easy to generate fake data.

=cut

=scenario autoloading

This package supports the auto-loading of plugins, which means that anyone can
create non-core plugins (fake data generators) and load and control them using
Faker.

=example autoloading

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

=cut

=scenario autoloading-under

This package also supports auto-loading plugins under a specific sub-namespace
which is typical in creating fake data plugins for locales.

=example autoloading-under

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

=cut

=method address_city_name

The address_city_name method returns a random fake address city name. See the
L<Faker::Plugin::AddressCityName> plugin for more information.

=signature address_city_name

address_city_name(Any %args) : Str

=example-1 address_city_name

  # given: synopsis

  $f->address_city_name

  # Lolastad

=cut

=method address_city_prefix

The address_city_prefix method returns a random fake address city prefix. See
the L<Faker::Plugin::AddressCityPrefix> plugin for more information.

=signature address_city_prefix

address_city_prefix(Any %args) : Str

=example-1 address_city_prefix

  # given: synopsis

  $f->address_city_prefix

  # South

=cut

=method address_city_suffix

The address_city_suffix method returns a random fake address city suffix. See
the L<Faker::Plugin::AddressCitySuffix> plugin for more information.

=signature address_city_suffix

address_city_suffix(Any %args) : Str

=example-1 address_city_suffix

  # given: synopsis

  $f->address_city_suffix

  # berg

=cut

=method address_country_name

The address_country_name method returns a random fake address country name. See
the L<Faker::Plugin::AddressCountryName> plugin for more information.

=signature address_country_name

address_country_name(Any %args) : Str

=example-1 address_country_name

  # given: synopsis

  $f->address_country_name

  # Iraq

=cut

=method address_latitude

The address_latitude method returns a random fake address latitude. See the
L<Faker::Plugin::Address::Latitude> plugin for more information.

=signature address_latitude

address_latitude(Any %args) : Str

=example-1 address_latitude

  # given: synopsis

  $f->address_latitude

  # 2338952

=cut

=method address_line1

The address_line1 method returns a random fake address line1. See the
L<Faker::Plugin::AddressLine1> plugin for more information.

=signature address_line1

address_line1(Any %args) : Str

=example-1 address_line1

  # given: synopsis

  $f->address_line1

  # 4 Schaefer Parkway

=cut

=method address_line2

The address_line2 method returns a random fake address line2. See the
L<Faker::Plugin::AddressLine2> plugin for more information.

=signature address_line2

address_line2(Any %args) : Str

=example-1 address_line2

  # given: synopsis

  $f->address_line2

  # Apt. 092

=cut

=method address_lines

The address_lines method returns a random fake address lines. See the
L<Faker::Plugin::AddressLines> plugin for more information.

=signature address_lines

address_lines(Any %args) : Str

=example-1 address_lines

  # given: synopsis

  $f->address_lines

  # 3587 Thiel Avenue
  # Suite 335
  # Tobinmouth, ME 96440-0239

=cut

=method address_longitude

The address_longitude method returns a random fake address longitude. See the
L<Faker::Plugin::AddressLongitude> plugin for more information.

=signature address_longitude

address_longitude(Any %args) : Str

=example-1 address_longitude

  # given: synopsis

  $f->address_longitude

  # -28.920235

=cut

=method address_number

The address_number method returns a random fake address number. See the
L<Faker::Plugin::AddressNumber> plugin for more information.

=signature address_number

address_number(Any %args) : Str

=example-1 address_number

  # given: synopsis

  $f->address_number

  # 67

=cut

=method address_postal_code

The address_postal_code method returns a random fake address postal code. See
the L<Faker::Plugin::AddressPostalCode> plugin for more information.

=signature address_postal_code

address_postal_code(Any %args) : Str

=example-1 address_postal_code

  # given: synopsis

  $f->address_postal_code

  # 02475

=cut

=method address_state_abbr

The address_state_abbr method returns a random fake address state abbr. See the
L<Faker::Plugin::AddressStateAbbr> plugin for more information.

=signature address_state_abbr

address_state_abbr(Any %args) : Str

=example-1 address_state_abbr

  # given: synopsis

  $f->address_state_abbr

  # OH

=cut

=method address_state_name

The address_state_name method returns a random fake address state name. See the
L<Faker::Plugin::AddressStateName> plugin for more information.

=signature address_state_name

address_state_name(Any %args) : Str

=example-1 address_state_name

  # given: synopsis

  $f->address_state_name

  # Georgia

=cut

=method address_street_name

The address_street_name method returns a random fake address street name. See
the L<Faker::Plugin::AddressStreetName> plugin for more information.

=signature address_street_name

address_street_name(Any %args) : Str

=example-1 address_street_name

  # given: synopsis

  $f->address_street_name

  # Reyna Avenue

=cut

=method address_street_suffix

The address_street_suffix method returns a random fake address street suffix.
See the L<Faker::Plugin::AddressStreetSuffix> plugin for more information.

=signature address_street_suffix

address_street_suffix(Any %args) : Str

=example-1 address_street_suffix

  # given: synopsis

  $f->address_street_suffix

  # Avenue

=cut

=method color_hex_code

The color_hex_code method returns a random fake color hex code. See the
L<Faker::Plugin::ColorHexCode> plugin for more information.

=signature color_hex_code

color_hex_code(Any %args) : Str

=example-1 color_hex_code

  # given: synopsis

  $f->color_hex_code

  # #b9fe40

=cut

=method color_name

The color_name method returns a random fake color name. See the
L<Faker::Plugin::ColorName> plugin for more information.

=signature color_name

color_name(Any %args) : Str

=example-1 color_name

  # given: synopsis

  $f->color_name

  # LightSteelBlue

=cut

=method color_rgbcolors

The color_rgbcolors method returns a random fake color rgbcolors. See the
L<Faker::Plugin::ColorRgbcolors> plugin for more information.

=signature color_rgbcolors

color_rgbcolors(Any %args) : Str

=example-1 color_rgbcolors

  # given: synopsis

  $f->color_rgbcolors

  # 77,186,28

=cut

=method color_rgbcolors_array

The color_rgbcolors_array method returns a random fake color rgbcolors array.
See the L<Faker::Plugin::ColorRgbcolorsArray> plugin for more information.

=signature color_rgbcolors_array

color_rgbcolors_array(Any %args) : ArrayRef

=example-1 color_rgbcolors_array

  # given: synopsis

  $f->color_rgbcolors_array

  # [77,186,28]

=cut

=method color_rgbcolors_css

The color_rgbcolors_css method returns a random fake color rgbcolors css. See
the L<Faker::Plugin::ColorRgbcolorsCss> plugin for more information.

=signature color_rgbcolors_css

color_rgbcolors_css(Any %args) : Str

=example-1 color_rgbcolors_css

  # given: synopsis

  $f->color_rgbcolors_css

  # rgb(115,98,44)

=cut

=method color_safe_hex_code

The color_safe_hex_code method returns a random fake color safe hex code. See
the L<Faker::Plugin::ColorSafeHexCode> plugin for more information.

=signature color_safe_hex_code

color_safe_hex_code(Any %args) : Str

=example-1 color_safe_hex_code

  # given: synopsis

  $f->color_safe_hex_code

  # #ff0078

=cut

=method color_safe_name

The color_safe_name method returns a random fake color safe name. See the
L<Faker::Plugin::ColorSafeName> plugin for more information.

=signature color_safe_name

color_safe_name(Any %args) : Str

=example-1 color_safe_name

  # given: synopsis

  $f->color_safe_name

  # blue

=cut

=method company_buzzword_type1

The company_buzzword_type1 method returns a random fake company buzzword type1.
See the L<Faker::Plugin::CompanyBuzzwordType1> plugin for more information.

=signature company_buzzword_type1

company_buzzword_type1(Any %args) : Str

=example-1 company_buzzword_type1

  # given: synopsis

  $f->company_buzzword_type1

  # implement

=cut

=method company_buzzword_type2

The company_buzzword_type2 method returns a random fake company buzzword type2.
See the L<Faker::Plugin::CompanyBuzzwordType2> plugin for more information.

=signature company_buzzword_type2

company_buzzword_type2(Any %args) : Str

=example-1 company_buzzword_type2

  # given: synopsis

  $f->company_buzzword_type2

  # interactive

=cut

=method company_buzzword_type3

The company_buzzword_type3 method returns a random fake company buzzword type3.
See the L<Faker::Plugin::CompanyBuzzwordType3> plugin for more information.

=signature company_buzzword_type3

company_buzzword_type3(Any %args) : Str

=example-1 company_buzzword_type3

  # given: synopsis

  $f->company_buzzword_type3

  # bandwidth

=cut

=method company_description

The company_description method returns a random fake company description. See
the L<Faker::Plugin::CompanyDescription> plugin for more information.

=signature company_description

company_description(Any %args) : Str

=example-1 company_description

  # given: synopsis

  $f->company_description

  # Excels at impactful pre-emptive decisions

=cut

=method company_jargon_buzz_word

The company_jargon_buzz_word method returns a random fake company jargon buzz
word. See the L<Faker::Plugin::CompanyJargonBuzzWord> plugin for more
information.

=signature company_jargon_buzz_word

company_jargon_buzz_word(Any %args) : Str

=example-1 company_jargon_buzz_word

  # given: synopsis

  $f->company_jargon_buzz_word

  # parallelism

=cut

=method company_jargon_edge_word

The company_jargon_edge_word method returns a random fake company jargon edge
word. See the L<Faker::Plugin::CompanyJargonEdgeWord> plugin for more
information.

=signature company_jargon_edge_word

company_jargon_edge_word(Any %args) : Str

=example-1 company_jargon_edge_word

  # given: synopsis

  $f->company_jargon_edge_word

  # Customer-focused

=cut

=method company_jargon_prop_word

The company_jargon_prop_word method returns a random fake company jargon prop
word. See the L<Faker::Plugin::CompanyJargonPropWord> plugin for more
information.

=signature company_jargon_prop_word

company_jargon_prop_word(Any %args) : Str

=example-1 company_jargon_prop_word

  # given: synopsis

  $f->company_jargon_prop_word

  # upward-trending

=cut

=method company_name

The company_name method returns a random fake company name. See the
L<Faker::Plugin::CompanyName> plugin for more information.

=signature company_name

company_name(Any %args) : Str

=example-1 company_name

  # given: synopsis

  $f->company_name

  # Boehm, Rutherford and Roberts

=cut

=method company_name_suffix

The company_name_suffix method returns a random fake company name suffix. See
the L<Faker::Plugin::CompanyNameSuffix> plugin for more information.

=signature company_name_suffix

company_name_suffix(Any %args) : Str

=example-1 company_name_suffix

  # given: synopsis

  $f->company_name_suffix

  # Group

=cut

=method company_tagline

The company_tagline method returns a random fake company tagline. See the
L<Faker::Plugin::CompanyTagline> plugin for more information.

=signature company_tagline

company_tagline(Any %args) : Str

=example-1 company_tagline

  # given: synopsis

  $f->company_tagline

  # cultivate end-to-end partnerships

=cut

=method internet_domain_name

The internet_domain_name method returns a random fake internet domain name. See
the L<Faker::Plugin::InternetDomainName> plugin for more information.

=signature internet_domain_name

internet_domain_name(Any %args) : Str

=example-1 internet_domain_name

  # given: synopsis

  $f->internet_domain_name

  # kassulke-cruickshank.biz

=cut

=method internet_domain_word

The internet_domain_word method returns a random fake internet domain word. See
the L<Faker::Plugin::InternetDomainWord> plugin for more information.

=signature internet_domain_word

internet_domain_word(Any %args) : Str

=example-1 internet_domain_word

  # given: synopsis

  $f->internet_domain_word

  # raynor-beier

=cut

=method internet_email_address

The internet_email_address method returns a random fake internet email address.
See the L<Faker::Plugin::InternetEmailAddress> plugin for more information.

=signature internet_email_address

internet_email_address(Any %args) : Str

=example-1 internet_email_address

  # given: synopsis

  $f->internet_email_address

  # rose@maggio-pfannerstill-and-marquardt.com

=cut

=method internet_email_domain

The internet_email_domain method returns a random fake internet email domain.
See the L<Faker::Plugin::InternetEmailDomain> plugin for more information.

=signature internet_email_domain

internet_email_domain(Any %args) : Str

=example-1 internet_email_domain

  # given: synopsis

  $f->internet_email_domain

  # gmail.com

=cut

=method internet_ip_address

The internet_ip_address method returns a random fake internet ip address. See
the L<Faker::Plugin::InternetIpAddress> plugin for more information.

=signature internet_ip_address

internet_ip_address(Any %args) : Str

=example-1 internet_ip_address

  # given: synopsis

  $f->internet_ip_address

  # 193.199.217.87

=cut

=method internet_ip_address_v4

The internet_ip_address_v4 method returns a random fake internet ip address v4.
See the L<Faker::Plugin::InternetIpAddressV4> plugin for more information.

=signature internet_ip_address_v4

internet_ip_address_v4(Any %args) : Str

=example-1 internet_ip_address_v4

  # given: synopsis

  $f->internet_ip_address_v4

  # 45.212.129.22

=cut

=method internet_ip_address_v6

The internet_ip_address_v6 method returns a random fake internet ip address v6.
See the L<Faker::Plugin::InternetIpAddressV6> plugin for more information.

=signature internet_ip_address_v6

internet_ip_address_v6(Any %args) : Str

=example-1 internet_ip_address_v6

  # given: synopsis

  $f->internet_ip_address_v6

  # 4024:40e9:b107:681d:8ce1:bb12:3380:b476

=cut

=method internet_root_domain

The internet_root_domain method returns a random fake internet root domain. See
the L<Faker::Plugin::InternetRootDomain> plugin for more information.

=signature internet_root_domain

internet_root_domain(Any %args) : Str

=example-1 internet_root_domain

  # given: synopsis

  $f->internet_root_domain

  # biz

=cut

=method internet_url

The internet_url method returns a random fake internet url. See the
L<Faker::Plugin::InternetUrl> plugin for more information.

=signature internet_url

internet_url(Any %args) : Str

=example-1 internet_url

  # given: synopsis

  $f->internet_url

  # https://krajcik-goyette.biz/

=cut

=method lorem_paragraph

The lorem_paragraph method returns a random fake lorem paragraph. See the
L<Faker::Plugin::LoremParagraph> plugin for more information.

=signature lorem_paragraph

lorem_paragraph(Any %args) : Str

=example-1 lorem_paragraph

  # given: synopsis

  $f->lorem_paragraph

  # id tempore eum. vitae optio rerum enim nihil perspiciatis omnis et. ut
  # voluptates dicta qui culpa. a nam at nemo fugiat.

=cut

=method lorem_paragraphs

The lorem_paragraphs method returns a random fake lorem paragraphs. See the
L<Faker::Plugin::LoremParagraphs> plugin for more information.

=signature lorem_paragraphs

lorem_paragraphs(Any %args) : Str

=example-1 lorem_paragraphs

  # given: synopsis

  $f->lorem_paragraphs

  # modi minus pariatur accusamus possimus eaque id velit porro. voluptatum
  # natus saepe. non in quas est. ut quos autem occaecati quo.

  # saepe quae unde. vel hic consequuntur. quia aut ut nostrum amet. et
  # consequuntur occaecati.

=cut

=method lorem_sentence

The lorem_sentence method returns a random fake lorem sentence. See the
L<Faker::Plugin::LoremSentence> plugin for more information.

=signature lorem_sentence

lorem_sentence(Any %args) : Str

=example-1 lorem_sentence

  # given: synopsis

  $f->lorem_sentence

  # amet id id culpa reiciendis minima id corporis illum quas.

=cut

=method lorem_sentences

The lorem_sentences method returns a random fake lorem sentences. See the
L<Faker::Plugin::LoremSentences> plugin for more information.

=signature lorem_sentences

lorem_sentences(Any %args) : Str

=example-1 lorem_sentences

  # given: synopsis

  $f->lorem_sentences

  # laboriosam ipsam ipsum. animi accusantium quisquam repellendus. occaecati
  # itaque reiciendis perferendis exercitationem.

=cut

=method lorem_word

The lorem_word method returns a random fake lorem word. See the
L<Faker::Plugin::LoremWord> plugin for more information.

=signature lorem_word

lorem_word(Any %args) : Str

=example-1 lorem_word

  # given: synopsis

  $f->lorem_word

  # quos

=cut

=method lorem_words

The lorem_words method returns a random fake lorem words. See the
L<Faker::Plugin::LoremWords> plugin for more information.

=signature lorem_words

lorem_words(Any %args) : Str

=example-1 lorem_words

  # given: synopsis

  $f->lorem_words

  # autem assumenda commodi eum dolor

=cut

=method payment_card_expiration

The payment_card_expiration method returns a random fake payment card
expiration. See the L<Faker::Plugin::PaymentCardExpiration> plugin for more
information.

=signature payment_card_expiration

payment_card_expiration(Any %args) : Str

=example-1 payment_card_expiration

  # given: synopsis

  $f->payment_card_expiration

  # 01/21

=cut

=method payment_card_number

The payment_card_number method returns a random fake payment card number. See
the L<Faker::Plugin::PaymentCardNumber> plugin for more information.

=signature payment_card_number

payment_card_number(Any %args) : Str

=example-1 payment_card_number

  # given: synopsis

  $f->payment_card_number

  # 544772628796996

=cut

=method payment_vendor

The payment_vendor method returns a random fake payment vendor. See the
L<Faker::Plugin::PaymentVendor> plugin for more information.

=signature payment_vendor

payment_vendor(Any %args) : Str

=example-1 payment_vendor

  # given: synopsis

  $f->payment_vendor

  # Visa

=cut

=method person_first_name

The person_first_name method returns a random fake person first name. See the
L<Faker::Plugin::PersonFirstName> plugin for more information.

=signature person_first_name

person_first_name(Any %args) : Str

=example-1 person_first_name

  # given: synopsis

  $f->person_first_name

  # Sandrine

=cut

=method person_last_name

The person_last_name method returns a random fake person last name. See the
L<Faker::Plugin::PersonLastName> plugin for more information.

=signature person_last_name

person_last_name(Any %args) : Str

=example-1 person_last_name

  # given: synopsis

  $f->person_last_name

  # Langosh

=cut

=method person_name

The person_name method returns a random fake person name. See the
L<Faker::Plugin::PersonName> plugin for more information.

=signature person_name

person_name(Any %args) : Str

=example-1 person_name

  # given: synopsis

  $f->person_name

  # Eveline Wintheiser

=cut

=method person_name_prefix

The person_name_prefix method returns a random fake person name prefix. See the
L<Faker::Plugin::PersonNamePrefix> plugin for more information.

=signature person_name_prefix

person_name_prefix(Any %args) : Str

=example-1 person_name_prefix

  # given: synopsis

  $f->person_name_prefix

  # Ms.

=cut

=method person_name_suffix

The person_name_suffix method returns a random fake person name suffix. See the
L<Faker::Plugin::PersonNameSuffix> plugin for more information.

=signature person_name_suffix

person_name_suffix(Any %args) : Str

=example-1 person_name_suffix

  # given: synopsis

  $f->person_name_suffix

  # Sr.

=cut

=method person_username

The person_username method returns a random fake person username. See the
L<Faker::Plugin::PersonUsername> plugin for more information.

=signature person_username

person_username(Any %args) : Str

=example-1 person_username

  # given: synopsis

  $f->person_username

  # Cayla25

=cut

=method telephone_number

The telephone_number method returns a random fake telephone number. See the
L<Faker::Plugin::TelephoneNumber> plugin for more information.

=signature telephone_number

telephone_number(Any %args) : Str

=example-1 telephone_number

  # given: synopsis

  $f->telephone_number

  # 549-844-2061

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->does('Data::Object::Role::Proxyable');
  ok $result->does('Data::Object::Role::Pluggable');
  ok $result->does('Data::Object::Role::Throwable');

  $result
});

$subs->scenario('autoloading', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->scenario('autoloading-under', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subs->example(-1, 'address_city_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_city_prefix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_city_suffix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_country_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_latitude', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_line1', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_line2', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_lines', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_longitude', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_number', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_postal_code', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_state_abbr', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_state_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_street_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'address_street_suffix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_hex_code', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_rgbcolors', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_rgbcolors_array', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_rgbcolors_css', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_safe_hex_code', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'color_safe_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_buzzword_type1', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_buzzword_type2', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_buzzword_type3', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_description', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_jargon_buzz_word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_jargon_edge_word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_jargon_prop_word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_name_suffix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'company_tagline', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_domain_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_domain_word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_email_address', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_email_domain', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_ip_address', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_ip_address_v4', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_ip_address_v6', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_root_domain', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'internet_url', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_paragraph', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_paragraphs', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_sentence', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_sentences', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'lorem_words', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'payment_card_expiration', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'payment_card_number', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'payment_vendor', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_first_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_last_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_name', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_name_prefix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_name_suffix', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'person_username', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'telephone_number', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;

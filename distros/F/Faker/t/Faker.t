package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);
my $seed = 42;

=name

Faker

=cut

$test->for('name');

=tagline

Fake Data Generator

=cut

$test->for('tagline');

=abstract

Extensible Fake Data Generator

=cut

$test->for('abstract');

=includes

method: new
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
method: address_region_name
method: address_state_abbr
method: address_state_name
method: address_street_address
method: address_street_name
method: address_street_suffix
method: cache
method: color_hex_code
method: color_name
method: color_rgb_colorset
method: color_rgb_colorset_css
method: color_safe_hex_code
method: color_safe_name
method: company_description
method: company_name
method: company_name_suffix
method: company_tagline
method: internet_domain_name
method: internet_domain_tld
method: internet_domain_word
method: internet_email_address
method: internet_email_domain
method: internet_ip_address
method: internet_ip_address_v4
method: internet_ip_address_v6
method: internet_url
method: jargon_adjective
method: jargon_adverb
method: jargon_noun
method: jargon_term_prefix
method: jargon_term_suffix
method: jargon_verb
method: lorem_paragraph
method: lorem_paragraphs
method: lorem_sentence
method: lorem_sentences
method: lorem_word
method: lorem_words
method: payment_card_american_express
method: payment_card_discover
method: payment_card_expiration
method: payment_card_mastercard
method: payment_card_number
method: payment_card_visa
method: payment_vendor
method: person_first_name
method: person_formal_name
method: person_gender
method: person_last_name
method: person_name
method: person_name_prefix
method: person_name_suffix
method: software_author
method: software_name
method: software_semver
method: software_version
method: telephone_number
method: user_login
method: user_password

=cut

$test->for('includes');

=synopsis

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

  # my $last_name = $faker->person_name;

  # "Alayna Josephine Kunde"

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  is $result->person_name, "Russel Krajcik";
  is $result->person_name, "Alayna Josephine Kunde";

  $result
});

=description

This distribution provides a library of fake data generators and a framework
for extending the library via plugins.

+=encoding utf8

=cut

$test->for('description');

=integrates

Venus::Role::Buildable
Venus::Role::Proxyable
Venus::Role::Optional

=cut

=attribute caches

The caches attribute holds the cached values returned from L</cache>.

=signature caches

  caches(HashRef $data) (Object)

=metadata caches

{
  since => '1.10',
}

=example-1 caches

  # given: synopsis

  package main;

  my $caches = $faker->caches;

  # bless({value => {}}, 'Venus::Hash')

=cut

$test->for('example', 1, 'caches', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Hash');

  $result
});

=example-2 caches

  # given: synopsis

  package main;

  my $caches = $faker->caches({});

  # bless({value => {}}, 'Venus::Hash')

=cut

$test->for('example', 2, 'caches', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Hash');

  $result
});

=attribute locales

The locales attribute holds the locales used to find and generate localized
data.

=signature locales

  locales(ArrayRef $data) (Object)

=metadata locales

{
  since => '1.10',
}

=example-1 locales

  # given: synopsis

  package main;

  my $locales = $faker->locales;

  # bless({value => []}, 'Venus::Array')

=cut

$test->for('example', 1, 'locales', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Array');

  $result
});

=example-2 locales

  # given: synopsis

  package main;

  my $locales = $faker->locales([]);

  # bless({value => []}, 'Venus::Array')

=cut

$test->for('example', 2, 'locales', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Array');

  $result
});

=method new

The new method returns a new instance of the class.

=signature new

  new(Str $data | ArrayRef $data | HashRef $data) (Faker)

=metadata new

{
  since => '1.10',
}

=example-1 new

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  is $result->person_name, "Russel Krajcik";

  $result
});

=example-2 new

  package main;

  use Faker;

  my $faker = Faker->new(['en-us', 'es-es']);

  # my $first_name = $faker->person_name;

  # "Rafael Loera"

=cut

$test->for('example', 2, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  is $result->person_name, "Rafael Loera";

  $result
});

=example-3 new

  package main;

  use Faker;

  my $faker = Faker->new({locales => ['en-us']});

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

=cut

$test->for('example', 3, 'new', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  is $result->person_name, "Russel Krajcik";

  $result
});

=method address_city_name

The address_city_name method returns a random address city name.

=signature address_city_name

  address_city_name(HashRef $data) (Str)

=metadata address_city_name

{
  since => '1.10',
}

=example-1 address_city_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_name = $faker->address_city_name;

  # "West Jamison"

  # $address_city_name = $faker->address_city_name;

  # "Mayertown"

  # $address_city_name = $faker->address_city_name;

  # "Juliaborough"

=cut

$test->for('example', 1, 'address_city_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  ok my $address_city_name = $result->address_city_name;
  is $address_city_name, "West Jamison";
  ok $address_city_name = $result->address_city_name;
  is $address_city_name, "Mayertown";
  ok $address_city_name = $result->address_city_name;
  is $address_city_name, "Juliaborough";

  $address_city_name
});

=method address_city_prefix

The address_city_prefix method returns a random address city prefix.

=signature address_city_prefix

  address_city_prefix(HashRef $data) (Str)

=metadata address_city_prefix

{
  since => '1.10',
}

=example-1 address_city_prefix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_prefix = $faker->address_city_prefix;

  # "West"

  # $address_city_prefix = $faker->address_city_prefix;

  # "West"

  # $address_city_prefix = $faker->address_city_prefix;

  # "Lake"

=cut

$test->for('example', 1, 'address_city_prefix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_city_prefix = $result->address_city_prefix;
  is $address_city_prefix, "West";
  ok $address_city_prefix = $result->address_city_prefix;
  is $address_city_prefix, "West";
  ok $address_city_prefix = $result->address_city_prefix;
  is $address_city_prefix, "Lake";

  $address_city_prefix
});

=method address_city_suffix

ok $address_city_suffix method returns a random address city suffix.

=signature address_city_suffix

  address_city_suffix(HashRef $data) (Str)

=metadata address_city_suffix

{
  since => '1.10',
}

=example-1 address_city_suffix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_suffix = $faker->address_city_suffix;

  # "borough"

  # $address_city_suffix = $faker->address_city_suffix;

  # "view"

  # $address_city_suffix = $faker->address_city_suffix;

  # "haven"

=cut

$test->for('example', 1, 'address_city_suffix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_city_suffix = $result->address_city_suffix;
  is $address_city_suffix, "borough";
  ok $address_city_suffix = $result->address_city_suffix;
  is $address_city_suffix, "view";
  ok $address_city_suffix = $result->address_city_suffix;
  is $address_city_suffix, "haven";

  $address_city_suffix
});

=method address_country_name

The address_country_name method returns a random address country name.

=signature address_country_name

  address_country_name(HashRef $data) (Str)

=metadata address_country_name

{
  since => '1.10',
}

=example-1 address_country_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_country_name = $faker->address_country_name;

  # "Greenland"

  # $address_country_name = $faker->address_country_name;

  # "Ireland"

  # $address_country_name = $faker->address_country_name;

  # "Svalbard & Jan Mayen Islands"

=cut

$test->for('example', 1, 'address_country_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_country_name = $result->address_country_name;
  is $address_country_name, "Greenland";
  ok $address_country_name = $result->address_country_name;
  is $address_country_name, "Ireland";
  ok $address_country_name = $result->address_country_name;
  is $address_country_name, "Svalbard & Jan Mayen Islands";

  $address_country_name
});

=method address_latitude

The address_latitude method returns a random address latitude.

=signature address_latitude

  address_latitude(HashRef $data) (Str)

=metadata address_latitude

{
  since => '1.10',
}

=example-1 address_latitude

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_latitude = $faker->address_latitude;

  # 30.843133

  # $address_latitude = $faker->address_latitude;

  # 77.079663

  # $address_latitude = $faker->address_latitude;

  # -41.660985

=cut

$test->for('example', 1, 'address_latitude', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_latitude = $result->address_latitude;
  is $address_latitude, 30.843133;
  ok $address_latitude = $result->address_latitude;
  is $address_latitude, 77.079663;
  ok $address_latitude = $result->address_latitude;
  is $address_latitude, -41.660985;

  $address_latitude
});

=method address_line1

The address_line1 method returns a random address line1.

=signature address_line1

  address_line1(HashRef $data) (Str)

=metadata address_line1

{
  since => '1.10',
}

=example-1 address_line1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_line1 = $faker->address_line1;

  # "44084 Mayer Brook"

  # $address_line1 = $faker->address_line1;

  # "4 Amalia Terrace"

  # $address_line1 = $faker->address_line1;

  # "20370 Emard Street"

=cut

$test->for('example', 1, 'address_line1', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_line1 = $result->address_line1;
  is $address_line1, "44084 Mayer Brook";
  ok $address_line1 = $result->address_line1;
  is $address_line1, "4 Amalia Terrace";
  ok $address_line1 = $result->address_line1;
  is $address_line1, "20370 Emard Street";

  $address_line1
});

=method address_line2

The address_line2 method returns a random address line2.

=signature address_line2

  address_line2(HashRef $data) (Str)

=metadata address_line2

{
  since => '1.10',
}

=example-1 address_line2

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_line2 = $faker->address_line2;

  # "Mailbox 1408"

  # $address_line2 = $faker->address_line2;

  # "Mailbox 684"

  # $address_line2 = $faker->address_line2;

  # "Suite 076"

=cut

$test->for('example', 1, 'address_line2', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_line2 = $result->address_line2;
  is $address_line2, "Mailbox 1408";
  ok $address_line2 = $result->address_line2;
  is $address_line2, "Mailbox 684";
  ok $address_line2 = $result->address_line2;
  is $address_line2, "Suite 076";

  $address_line2
});

=method address_lines

The address_lines method returns a random address lines.

=signature address_lines

  address_lines(HashRef $data) (Str)

=metadata address_lines

{
  since => '1.10',
}

=example-1 address_lines

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_lines = $faker->address_lines;

  # "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022"

  # $address_lines = $faker->address_lines;

  # "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836"

  # $address_lines = $faker->address_lines;

  # "68768 Weissnat Point\nRitchieburgh, New Mexico 53892"

=cut

$test->for('example', 1, 'address_lines', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  ok my $address_lines = $result->address_lines;
  is $address_lines,
    "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022";
  ok $address_lines = $result->address_lines;
  is $address_lines,
    "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836";
  ok $address_lines = $result->address_lines;
  is $address_lines,
    "68768 Weissnat Point\nRitchieburgh, New Mexico 53892";

  $address_lines
});

=method address_longitude

The address_longitude method returns a random address longitude.

=signature address_longitude

  address_longitude(HashRef $data) (Str)

=metadata address_longitude

{
  since => '1.10',
}

=example-1 address_longitude

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_longitude = $faker->address_longitude;

  # 30.843133

  # $address_longitude = $faker->address_longitude;

  # 77.079663

  # $address_longitude = $faker->address_longitude;

  # -41.660985

=cut

$test->for('example', 1, 'address_longitude', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_longitude = $result->address_longitude;
  is $address_longitude, 30.843133;
  ok $address_longitude = $result->address_longitude;
  is $address_longitude, 77.079663;
  ok $address_longitude = $result->address_longitude;
  is $address_longitude, -41.660985;

  $address_longitude
});

=method address_number

The address_number method returns a random address number.

=signature address_number

  address_number(HashRef $data) (Str)

=metadata address_number

{
  since => '1.10',
}

=example-1 address_number

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_number = $faker->address_number;

  # 8140

  # $address_number = $faker->address_number;

  # 5684

  # $address_number = $faker->address_number;

  # 57694

=cut

$test->for('example', 1, 'address_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_number = $result->address_number;
  is $address_number, 8140;
  ok $address_number = $result->address_number;
  is $address_number, 5684;
  ok $address_number = $result->address_number;
  is $address_number, 57694;

  $address_number
});

=method address_postal_code

The address_postal_code method returns a random address postal code.

=signature address_postal_code

  address_postal_code(HashRef $data) (Str)

=metadata address_postal_code

{
  since => '1.10',
}

=example-1 address_postal_code

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_postal_code = $faker->address_postal_code;

  # 14084

  # $address_postal_code = $faker->address_postal_code;

  # "84550-7694"

  # $address_postal_code = $faker->address_postal_code;

  # 43908

=cut

$test->for('example', 1, 'address_postal_code', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_postal_code = $result->address_postal_code;
  is $address_postal_code, 14084;
  ok $address_postal_code = $result->address_postal_code;
  is $address_postal_code, "84550-7694";
  ok $address_postal_code = $result->address_postal_code;
  is $address_postal_code, 43908;

  $address_postal_code
});

=method address_region_name

The address_region_name method returns a random address region name.

=signature address_region_name

  address_region_name(HashRef $data) (Str)

=metadata address_region_name

{
  since => '1.10',
}

=example-1 address_region_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_region_name = $faker->address_region_name;

  # "Massachusetts"

  # $address_region_name = $faker->address_region_name;

  # "MO"

  # $address_region_name = $faker->address_region_name;

  # "NE"

=cut

$test->for('example', 1, 'address_region_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_region_name = $result->address_region_name;
  is $address_region_name, "Massachusetts";
  ok $address_region_name = $result->address_region_name;
  is $address_region_name, "MO";
  ok $address_region_name = $result->address_region_name;
  is $address_region_name, "NE";

  $address_region_name
});

=method address_state_abbr

The address_state_abbr method returns a random address state abbr.

=signature address_state_abbr

  address_state_abbr(HashRef $data) (Str)

=metadata address_state_abbr

{
  since => '1.10',
}

=example-1 address_state_abbr

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_state_abbr = $faker->address_state_abbr;

  # "KY"

  # $address_state_abbr = $faker->address_state_abbr;

  # "ME"

  # $address_state_abbr = $faker->address_state_abbr;

  # "TX"

=cut

$test->for('example', 1, 'address_state_abbr', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_state_abbr = $result->address_state_abbr;
  is $address_state_abbr, "KY";
  ok $address_state_abbr = $result->address_state_abbr;
  is $address_state_abbr, "ME";
  ok $address_state_abbr = $result->address_state_abbr;
  is $address_state_abbr, "TX";

  $address_state_abbr
});

=method address_state_name

The address_state_name method returns a random address state name.

=signature address_state_name

  address_state_name(HashRef $data) (Str)

=metadata address_state_name

{
  since => '1.10',
}

=example-1 address_state_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_state_name = $faker->address_state_name;

  # "Kentucky"

  # $address_state_name = $faker->address_state_name;

  # "Massachusetts"

  # $address_state_name = $faker->address_state_name;

  # "Texas"

=cut

$test->for('example', 1, 'address_state_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_state_name = $result->address_state_name;
  is $address_state_name, "Kentucky";
  ok $address_state_name = $result->address_state_name;
  is $address_state_name, "Massachusetts";
  ok $address_state_name = $result->address_state_name;
  is $address_state_name, "Texas";

  $address_state_name
});

=method address_street_address

The address_street_address method returns a random address street address.

=signature address_street_address

  address_street_address(HashRef $data) (Str)

=metadata address_street_address

{
  since => '1.10',
}

=example-1 address_street_address

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_address = $faker->address_street_address;

  # "4084 Mayer Brook Suite 94"

  # $address_street_address = $faker->address_street_address;

  # "9908 Mustafa Harbor Suite 828"

  # $address_street_address = $faker->address_street_address;

  # "958 Greenholt Orchard"

=cut

$test->for('example', 1, 'address_street_address', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_street_address = $result->address_street_address;
  is $address_street_address, "4084 Mayer Brook Suite 94";
  ok $address_street_address = $result->address_street_address;
  is $address_street_address, "9908 Mustafa Harbor Suite 828";
  ok $address_street_address = $result->address_street_address;
  is $address_street_address, "958 Greenholt Orchard";

  $address_street_address
});

=method address_street_name

The address_street_name method returns a random address street name.

=signature address_street_name

  address_street_name(HashRef $data) (Str)

=metadata address_street_name

{
  since => '1.10',
}

=example-1 address_street_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_name = $faker->address_street_name;

  # "Russel Parkway"

  # $address_street_name = $faker->address_street_name;

  # "Mayer Brook"

  # $address_street_name = $faker->address_street_name;

  # "Kuhic Path"

=cut

$test->for('example', 1, 'address_street_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_street_name = $result->address_street_name;
  is $address_street_name, "Russel Parkway";
  ok $address_street_name = $result->address_street_name;
  is $address_street_name, "Mayer Brook";
  ok $address_street_name = $result->address_street_name;
  is $address_street_name, "Kuhic Path";

  $address_street_name
});

=method address_street_suffix

The address_street_suffix method returns a random address street suffix.

=signature address_street_suffix

  address_street_suffix(HashRef $data) (Str)

=metadata address_street_suffix

{
  since => '1.10',
}

=example-1 address_street_suffix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_suffix = $faker->address_street_suffix;

  # "Key"

  # $address_street_suffix = $faker->address_street_suffix;

  # "Mission"

  # $address_street_suffix = $faker->address_street_suffix;

  # "Street"

=cut

$test->for('example', 1, 'address_street_suffix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $address_street_suffix = $result->address_street_suffix;
  is $address_street_suffix, "Key";
  ok $address_street_suffix = $result->address_street_suffix;
  is $address_street_suffix, "Mission";
  ok $address_street_suffix = $result->address_street_suffix;
  is $address_street_suffix, "Street";

  $address_street_suffix
});

=method cache

The cache method dispatches to the method specified, caches the method name and
return value, and returns the value. Subsequent calls will return the cached
value.

=signature cache

  cache(Str $method, Any @args) (Str)

=metadata cache

{
  since => '1.10',
}

=example-1 cache

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $cache = $faker->cache('person_name');

  # "Keeley Balistreri"

  # $cache = $faker->cache('person_name');

  # "Keeley Balistreri"

=cut

$test->for('example', 1, 'cache', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  my $cache = $result->cache('person_name');
  is $cache, "Keeley Balistreri";
  $cache = $result->cache('person_name');
  is $cache, "Keeley Balistreri";
  $result->caches->delete('person_name');

  $result
});

=example-2 cache

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $cache = $faker->cache('company_tagline');

  # "iterate back-end content"

  # $cache = $faker->cache('company_tagline');

  # "iterate back-end content"

=cut

$test->for('example', 2, 'cache', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  my $cache = $result->cache('company_tagline');
  is $cache, "iterate back-end content";
  $cache = $result->cache('company_tagline');
  is $cache, "iterate back-end content";
  $result->caches->delete('company_tagline');

  $result
});

=method color_hex_code

The color_hex_code method returns a random color hex code.

=signature color_hex_code

  color_hex_code(HashRef $data) (Str)

=metadata color_hex_code

{
  since => '1.10',
}

=example-1 color_hex_code

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_hex_code = $faker->color_hex_code;

  # "#57bb49"

  # $color_hex_code = $faker->color_hex_code;

  # "#6c1e68"

  # $color_hex_code = $faker->color_hex_code;

  # "#db3fb2"

=cut

$test->for('example', 1, 'color_hex_code', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_hex_code = $result->color_hex_code;
  is $color_hex_code, "#57bb49";
  ok $color_hex_code = $result->color_hex_code;
  is $color_hex_code, "#6c1e68";
  ok $color_hex_code = $result->color_hex_code;
  is $color_hex_code, "#db3fb2";

  $color_hex_code
});

=method color_name

The color_name method returns a random color name.

=signature color_name

  color_name(HashRef $data) (Str)

=metadata color_name

{
  since => '1.10',
}

=example-1 color_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_name = $faker->color_name;

  # "GhostWhite"

  # $color_name = $faker->color_name;

  # "Khaki"

  # $color_name = $faker->color_name;

  # "SeaGreen"

=cut

$test->for('example', 1, 'color_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_name = $result->color_name;
  is $color_name, "GhostWhite";
  ok $color_name = $result->color_name;
  is $color_name, "Khaki";
  ok $color_name = $result->color_name;
  is $color_name, "SeaGreen";

  $color_name
});

=method color_rgb_colorset

The color_rgb_colorset method returns a random color rgb colorset.

=signature color_rgb_colorset

  color_rgb_colorset(HashRef $data) (Str)

=metadata color_rgb_colorset

{
  since => '1.10',
}

=example-1 color_rgb_colorset

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_rgb_colorset = $faker->color_rgb_colorset;

  # [28, 112, 22]

  # $color_rgb_colorset = $faker->color_rgb_colorset;

  # [219, 63, 178]

  # $color_rgb_colorset = $faker->color_rgb_colorset;

  # [176, 217, 21]

=cut

$test->for('example', 1, 'color_rgb_colorset', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_rgb_colorset = $result->color_rgb_colorset;
  is_deeply $color_rgb_colorset, [28, 112, 22];
  ok $color_rgb_colorset = $result->color_rgb_colorset;
  is_deeply $color_rgb_colorset, [219, 63, 178];
  ok $color_rgb_colorset = $result->color_rgb_colorset;
  is_deeply $color_rgb_colorset, [176, 217, 21];

  $color_rgb_colorset
});

=method color_rgb_colorset_css

The color_rgb_colorset_css method returns a random color rgb colorset css.

=signature color_rgb_colorset_css

  color_rgb_colorset_css(HashRef $data) (Str)

=metadata color_rgb_colorset_css

{
  since => '1.10',
}

=example-1 color_rgb_colorset_css

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(108, 30, 104)"

  # $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(122, 147, 147)"

  # $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(147, 224, 22)"

=cut

$test->for('example', 1, 'color_rgb_colorset_css', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_rgb_colorset_css = $result->color_rgb_colorset_css;
  is $color_rgb_colorset_css, "rgb(108, 30, 104)";
  ok $color_rgb_colorset_css = $result->color_rgb_colorset_css;
  is $color_rgb_colorset_css, "rgb(122, 147, 147)";
  ok $color_rgb_colorset_css = $result->color_rgb_colorset_css;
  is $color_rgb_colorset_css, "rgb(147, 224, 22)";

  $color_rgb_colorset_css
});

=method color_safe_hex_code

The color_safe_hex_code method returns a random color safe hex code.

=signature color_safe_hex_code

  color_safe_hex_code(HashRef $data) (Str)

=metadata color_safe_hex_code

{
  since => '1.10',
}

=example-1 color_safe_hex_code

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff0057"

  # $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff006c"

  # $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff00db"

=cut

$test->for('example', 1, 'color_safe_hex_code', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_safe_hex_code = $result->color_safe_hex_code;
  is $color_safe_hex_code, "#ff0057";
  ok $color_safe_hex_code = $result->color_safe_hex_code;
  is $color_safe_hex_code, "#ff006c";
  ok $color_safe_hex_code = $result->color_safe_hex_code;
  is $color_safe_hex_code, "#ff00db";

  $color_safe_hex_code
});

=method color_safe_name

The color_safe_name method returns a random color safe name.

=signature color_safe_name

  color_safe_name(HashRef $data) (Str)

=metadata color_safe_name

{
  since => '1.10',
}

=example-1 color_safe_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_safe_name = $faker->color_safe_name;

  # "purple"

  # $color_safe_name = $faker->color_safe_name;

  # "teal"

  # $color_safe_name = $faker->color_safe_name;

  # "fuchsia"

=cut

$test->for('example', 1, 'color_safe_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $color_safe_name = $result->color_safe_name;
  is $color_safe_name, "purple";
  ok $color_safe_name = $result->color_safe_name;
  is $color_safe_name, "teal";
  ok $color_safe_name = $result->color_safe_name;
  is $color_safe_name, "fuchsia";

  $color_safe_name
});

=method company_description

The company_description method returns a random company description.

=signature company_description

  company_description(HashRef $data) (Str)

=metadata company_description

{
  since => '1.10',
}

=example-1 company_description

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_description = $faker->company_description;

  # "Excels at full-range synchronised implementations"

  # $company_description = $faker->company_description;

  # "Provides logistical ameliorated methodologies"

  # $company_description = $faker->company_description;

  # "Offering hybrid future-proofed applications"

=cut

$test->for('example', 1, 'company_description', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $company_description = $result->company_description;
  is $company_description, "Excels at full-range synchronised implementations";
  ok $company_description = $result->company_description;
  is $company_description, "Provides logistical ameliorated methodologies";
  ok $company_description = $result->company_description;
  is $company_description, "Offering hybrid future-proofed applications";

  $company_description
});

=method company_name

The company_name method returns a random company name.

=signature company_name

  company_name(HashRef $data) (Str)

=metadata company_name

{
  since => '1.10',
}

=example-1 company_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_name = $faker->company_name;

  # "Johnston-Steuber"

  # $company_name = $faker->company_name;

  # "Skiles-Mayer"

  # $company_name = $faker->company_name;

  # "Miller and Sons"

=cut

$test->for('example', 1, 'company_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $company_name = $result->company_name;
  is $company_name, "Johnston-Steuber";
  ok $company_name = $result->company_name;
  is $company_name, "Skiles-Mayer";
  ok $company_name = $result->company_name;
  is $company_name, "Miller and Sons";

  $company_name
});

=method company_name_suffix

The company_name_suffix method returns a random company name suffix.

=signature company_name_suffix

  company_name_suffix(HashRef $data) (Str)

=metadata company_name_suffix

{
  since => '1.10',
}

=example-1 company_name_suffix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_name_suffix = $faker->company_name_suffix;

  # "Inc."

  # $company_name_suffix = $faker->company_name_suffix;

  # "Incorporated"

  # $company_name_suffix = $faker->company_name_suffix;

  # "Ventures"

=cut

$test->for('example', 1, 'company_name_suffix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $company_name_suffix = $result->company_name_suffix;
  is $company_name_suffix, "Inc.";
  ok $company_name_suffix = $result->company_name_suffix;
  is $company_name_suffix, "Incorporated";
  ok $company_name_suffix = $result->company_name_suffix;
  is $company_name_suffix, "Ventures";

  $company_name_suffix
});

=method company_tagline

The company_tagline method returns a random company tagline.

=signature company_tagline

  company_tagline(HashRef $data) (Str)

=metadata company_tagline

{
  since => '1.10',
}

=example-1 company_tagline

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_tagline = $faker->company_tagline;

  # "transform revolutionary supply-chains"

  # $company_tagline = $faker->company_tagline;

  # "generate front-end web-readiness"

  # $company_tagline = $faker->company_tagline;

  # "iterate back-end content"

=cut

$test->for('example', 1, 'company_tagline', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $company_tagline = $result->company_tagline;
  is $company_tagline, "transform revolutionary supply-chains";
  ok $company_tagline = $result->company_tagline;
  is $company_tagline, "generate front-end web-readiness";
  ok $company_tagline = $result->company_tagline;
  is $company_tagline, "iterate back-end content";

  $company_tagline
});

=method internet_domain_name

The internet_domain_name method returns a random internet domain name.

=signature internet_domain_name

  internet_domain_name(HashRef $data) (Str)

=metadata internet_domain_name

{
  since => '1.10',
}

=example-1 internet_domain_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_name = $faker->internet_domain_name;

  # "steuber-krajcik.org"

  # $internet_domain_name = $faker->internet_domain_name;

  # "miller-and-sons.com"

  # $internet_domain_name = $faker->internet_domain_name;

  # "witting-entertainment.com"

=cut

$test->for('example', 1, 'internet_domain_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_domain_name = $result->internet_domain_name;
  is $internet_domain_name, "steuber-krajcik.org";
  ok $internet_domain_name = $result->internet_domain_name;
  is $internet_domain_name, "miller-and-sons.com";
  ok $internet_domain_name = $result->internet_domain_name;
  is $internet_domain_name, "witting-entertainment.com";

  $internet_domain_name
});

=method internet_domain_tld

The internet_domain_tld method returns a random internet domain tld.

=signature internet_domain_tld

  internet_domain_tld(HashRef $data) (Str)

=metadata internet_domain_tld

{
  since => '1.10',
}

=example-1 internet_domain_tld

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_tld = $faker->internet_domain_tld;

  # "com"

  # $internet_domain_tld = $faker->internet_domain_tld;

  # "com"

  # $internet_domain_tld = $faker->internet_domain_tld;

  # "org"

=cut

$test->for('example', 1, 'internet_domain_tld', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_domain_tld = $result->internet_domain_tld;
  is $internet_domain_tld, "com";
  ok $internet_domain_tld = $result->internet_domain_tld;
  is $internet_domain_tld, "com";
  ok $internet_domain_tld = $result->internet_domain_tld;
  is $internet_domain_tld, "org";

  $internet_domain_tld
});

=method internet_domain_word

The internet_domain_word method returns a random internet domain word.

=signature internet_domain_word

  internet_domain_word(HashRef $data) (Str)

=metadata internet_domain_word

{
  since => '1.10',
}

=example-1 internet_domain_word

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_word = $faker->internet_domain_word;

  # "bode-and-sons"

  # $internet_domain_word = $faker->internet_domain_word;

  # "mayer-balistreri-and-miller"

  # $internet_domain_word = $faker->internet_domain_word;

  # "kerluke-waelchi"

=cut

$test->for('example', 1, 'internet_domain_word', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_domain_word = $result->internet_domain_word;
  is $internet_domain_word, "bode-and-sons";
  ok $internet_domain_word = $result->internet_domain_word;
  is $internet_domain_word, "mayer-balistreri-and-miller";
  ok $internet_domain_word = $result->internet_domain_word;
  is $internet_domain_word, "kerluke-waelchi";

  $internet_domain_word
});

=method internet_email_address

The internet_email_address method returns a random internet email address.

=signature internet_email_address

  internet_email_address(HashRef $data) (Str)

=metadata internet_email_address

{
  since => '1.10',
}

=example-1 internet_email_address

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_email_address = $faker->internet_email_address;

  # "russel54\@mayer-balistreri-and-miller.com"

  # $internet_email_address = $faker->internet_email_address;

  # "viviane82\@rempel-entertainment.com"

  # $internet_email_address = $faker->internet_email_address;

  # "yborer\@outlook.com"

=cut

$test->for('example', 1, 'internet_email_address', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_email_address = $result->internet_email_address;
  is $internet_email_address, "russel54\@mayer-balistreri-and-miller.com";
  ok $internet_email_address = $result->internet_email_address;
  is $internet_email_address, "viviane82\@rempel-entertainment.com";
  ok $internet_email_address = $result->internet_email_address;
  is $internet_email_address, "yborer\@outlook.com";

  $internet_email_address
});

=method internet_email_domain

The internet_email_domain method returns a random internet email domain.

=signature internet_email_domain

  internet_email_domain(HashRef $data) (Str)

=metadata internet_email_domain

{
  since => '1.10',
}

=example-1 internet_email_domain

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_email_domain = $faker->internet_email_domain;

  # "icloud.com"

  # $internet_email_domain = $faker->internet_email_domain;

  # "icloud.com"

  # $internet_email_domain = $faker->internet_email_domain;

  # "yahoo.com"

=cut

$test->for('example', 1, 'internet_email_domain', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_email_domain = $result->internet_email_domain;
  is $internet_email_domain, "icloud.com";
  ok $internet_email_domain = $result->internet_email_domain;
  is $internet_email_domain, "icloud.com";
  ok $internet_email_domain = $result->internet_email_domain;
  is $internet_email_domain, "yahoo.com";

  $internet_email_domain
});

=method internet_ip_address

The internet_ip_address method returns a random internet ip address.

=signature internet_ip_address

  internet_ip_address(HashRef $data) (Str)

=metadata internet_ip_address

{
  since => '1.10',
}

=example-1 internet_ip_address

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address = $faker->internet_ip_address;

  # "108.20.219.127"

  # $internet_ip_address = $faker->internet_ip_address;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48"

  # $internet_ip_address = $faker->internet_ip_address;

  # "89.236.15.220"

=cut

$test->for('example', 1, 'internet_ip_address', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_ip_address = $result->internet_ip_address;
  is $internet_ip_address, "108.20.219.127";
  ok $internet_ip_address = $result->internet_ip_address;
  is $internet_ip_address, "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";
  ok $internet_ip_address = $result->internet_ip_address;
  is $internet_ip_address, "89.236.15.220";

  $internet_ip_address
});

=method internet_ip_address_v4

The internet_ip_address_v4 method returns a random internet ip address v4.

=signature internet_ip_address_v4

  internet_ip_address_v4(HashRef $data) (Str)

=metadata internet_ip_address_v4

{
  since => '1.10',
}

=example-1 internet_ip_address_v4

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "87.28.108.20"

  # $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "127.122.176.213"

  # $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "147.136.6.197"

=cut

$test->for('example', 1, 'internet_ip_address_v4', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_ip_address_v4 = $result->internet_ip_address_v4;
  is $internet_ip_address_v4, "87.28.108.20";
  ok $internet_ip_address_v4 = $result->internet_ip_address_v4;
  is $internet_ip_address_v4, "127.122.176.213";
  ok $internet_ip_address_v4 = $result->internet_ip_address_v4;
  is $internet_ip_address_v4, "147.136.6.197";

  $internet_ip_address_v4
});

=method internet_ip_address_v6

The internet_ip_address_v6 method returns a random internet ip address v6.

=signature internet_ip_address_v6

  internet_ip_address_v6(HashRef $data) (Str)

=metadata internet_ip_address_v6

{
  since => '1.10',
}

=example-1 internet_ip_address_v6

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9"

  # $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48"

  # $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951"

=cut

$test->for('example', 1, 'internet_ip_address_v6', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_ip_address_v6 = $result->internet_ip_address_v6;
  is $internet_ip_address_v6, "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9";
  ok $internet_ip_address_v6 = $result->internet_ip_address_v6;
  is $internet_ip_address_v6, "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48";
  ok $internet_ip_address_v6 = $result->internet_ip_address_v6;
  is $internet_ip_address_v6, "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951";

  $internet_ip_address_v6
});

=method internet_url

The internet_url method returns a random internet url.

=signature internet_url

  internet_url(HashRef $data) (Str)

=metadata internet_url

{
  since => '1.10',
}

=example-1 internet_url

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_url = $faker->internet_url;

  # "https://krajcik-skiles-and-mayer.com/"

  # $internet_url = $faker->internet_url;

  # "http://heidenreich-beier.co/"

  # $internet_url = $faker->internet_url;

  # "https://goldner-mann-and-emard.org/"

=cut

$test->for('example', 1, 'internet_url', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $internet_url = $result->internet_url;
  is $internet_url, "https://krajcik-skiles-and-mayer.com/";
  ok $internet_url = $result->internet_url;
  is $internet_url, "http://heidenreich-beier.co/";
  ok $internet_url = $result->internet_url;
  is $internet_url, "https://goldner-mann-and-emard.org/";

  $internet_url
});

=method jargon_adjective

The jargon_adjective method returns a random jargon adjective.

=signature jargon_adjective

  jargon_adjective(HashRef $data) (Str)

=metadata jargon_adjective

{
  since => '1.10',
}

=example-1 jargon_adjective

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_adjective = $faker->jargon_adjective;

  # "virtual"

  # $jargon_adjective = $faker->jargon_adjective;

  # "killer"

  # $jargon_adjective = $faker->jargon_adjective;

  # "cutting-edge"

=cut

$test->for('example', 1, 'jargon_adjective', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_adjective = $result->jargon_adjective;
  is $jargon_adjective, "virtual";
  ok $jargon_adjective = $result->jargon_adjective;
  is $jargon_adjective, "killer";
  ok $jargon_adjective = $result->jargon_adjective;
  is $jargon_adjective, "cutting-edge";

  $jargon_adjective
});

=method jargon_adverb

The jargon_adverb method returns a random jargon adverb.

=signature jargon_adverb

  jargon_adverb(HashRef $data) (Str)

=metadata jargon_adverb

{
  since => '1.10',
}

=example-1 jargon_adverb

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_adverb = $faker->jargon_adverb;

  # "future-proofed"

  # $jargon_adverb = $faker->jargon_adverb;

  # "managed"

  # $jargon_adverb = $faker->jargon_adverb;

  # "synchronised"

=cut

$test->for('example', 1, 'jargon_adverb', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_adverb = $result->jargon_adverb;
  is $jargon_adverb, "future-proofed";
  ok $jargon_adverb = $result->jargon_adverb;
  is $jargon_adverb, "managed";
  ok $jargon_adverb = $result->jargon_adverb;
  is $jargon_adverb, "synchronised";

  $jargon_adverb
});

=method jargon_noun

The jargon_noun method returns a random jargon noun.

=signature jargon_noun

  jargon_noun(HashRef $data) (Str)

=metadata jargon_noun

{
  since => '1.10',
}

=example-1 jargon_noun

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_noun = $faker->jargon_noun;

  # "action-items"

  # $jargon_noun = $faker->jargon_noun;

  # "technologies"

  # $jargon_noun = $faker->jargon_noun;

  # "applications"

=cut

$test->for('example', 1, 'jargon_noun', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_noun = $result->jargon_noun;
  is $jargon_noun, "action-items";
  ok $jargon_noun = $result->jargon_noun;
  is $jargon_noun, "technologies";
  ok $jargon_noun = $result->jargon_noun;
  is $jargon_noun, "applications";

  $jargon_noun
});

=method jargon_term_prefix

The jargon_term_prefix method returns a random jargon term prefix.

=signature jargon_term_prefix

  jargon_term_prefix(HashRef $data) (Str)

=metadata jargon_term_prefix

{
  since => '1.10',
}

=example-1 jargon_term_prefix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_term_prefix = $faker->jargon_term_prefix;

  # "encompassing"

  # $jargon_term_prefix = $faker->jargon_term_prefix;

  # "full-range"

  # $jargon_term_prefix = $faker->jargon_term_prefix;

  # "systematic"

=cut

$test->for('example', 1, 'jargon_term_prefix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_term_prefix = $result->jargon_term_prefix;
  is $jargon_term_prefix, "encompassing";
  ok $jargon_term_prefix = $result->jargon_term_prefix;
  is $jargon_term_prefix, "full-range";
  ok $jargon_term_prefix = $result->jargon_term_prefix;
  is $jargon_term_prefix, "systematic";

  $jargon_term_prefix
});

=method jargon_term_suffix

The jargon_term_suffix method returns a random jargon term suffix.

=signature jargon_term_suffix

  jargon_term_suffix(HashRef $data) (Str)

=metadata jargon_term_suffix

{
  since => '1.10',
}

=example-1 jargon_term_suffix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_term_suffix = $faker->jargon_term_suffix;

  # "flexibilities"

  # $jargon_term_suffix = $faker->jargon_term_suffix;

  # "graphical user interfaces"

  # $jargon_term_suffix = $faker->jargon_term_suffix;

  # "standardization"

=cut

$test->for('example', 1, 'jargon_term_suffix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_term_suffix = $result->jargon_term_suffix;
  is $jargon_term_suffix, "flexibilities";
  ok $jargon_term_suffix = $result->jargon_term_suffix;
  is $jargon_term_suffix, "graphical user interfaces";
  ok $jargon_term_suffix = $result->jargon_term_suffix;
  is $jargon_term_suffix, "standardization";

  $jargon_term_suffix
});

=method jargon_verb

The jargon_verb method returns a random jargon verb.

=signature jargon_verb

  jargon_verb(HashRef $data) (Str)

=metadata jargon_verb

{
  since => '1.10',
}

=example-1 jargon_verb

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_verb = $faker->jargon_verb;

  # "harness"

  # $jargon_verb = $faker->jargon_verb;

  # "strategize"

  # $jargon_verb = $faker->jargon_verb;

  # "exploit"

=cut

$test->for('example', 1, 'jargon_verb', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $jargon_verb = $result->jargon_verb;
  is $jargon_verb, "harness";
  ok $jargon_verb = $result->jargon_verb;
  is $jargon_verb, "strategize";
  ok $jargon_verb = $result->jargon_verb;
  is $jargon_verb, "exploit";

  $jargon_verb
});

=method lorem_paragraph

The lorem_paragraph method returns a random lorem paragraph.

=signature lorem_paragraph

  lorem_paragraph(HashRef $data) (Str)

=metadata lorem_paragraph

{
  since => '1.10',
}

=example-1 lorem_paragraph

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_paragraph = $faker->lorem_paragraph;

  # "deleniti fugiat in accusantium animi corrupti dolores. eos ..."

  # $lorem_paragraph = $faker->lorem_paragraph;

  # "ducimus placeat autem ut sit adipisci asperiores quae ipsum..."

  # $lorem_paragraph = $faker->lorem_paragraph;

  # "dignissimos est magni quia aut et hic eos architecto repudi..."

=cut

$test->for('example', 1, 'lorem_paragraph', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_paragraph = $result->lorem_paragraph;
  like $lorem_paragraph, qr/deleniti eligendi fugiat in provident accusantium/;
  ok $lorem_paragraph = $result->lorem_paragraph;
  like $lorem_paragraph, qr/magnam sed quasi quas vel earum est veniam quaerat/;
  ok $lorem_paragraph = $result->lorem_paragraph;
  like $lorem_paragraph, qr/consequatur earum ducimus minus placeat et autem/;

  $lorem_paragraph
});

=method lorem_paragraphs

The lorem_paragraphs method returns a random lorem paragraphs.

=signature lorem_paragraphs

  lorem_paragraphs(HashRef $data) (Str)

=metadata lorem_paragraphs

{
  since => '1.10',
}

=example-1 lorem_paragraphs

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_paragraphs = $faker->lorem_paragraphs;

  # "eligendi laudantium provident assumenda voluptates sed iu..."

  # $lorem_paragraphs = $faker->lorem_paragraphs;

  # "accusantium ex pariatur perferendis voluptate iusto iure fu..."

  # $lorem_paragraphs = $faker->lorem_paragraphs;

  # "sit ut molestiae consequatur error tempora inventore est so..."

=cut

$test->for('example', 1, 'lorem_paragraphs', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_paragraphs = $result->lorem_paragraphs;
  like $lorem_paragraphs, qr/vero et deleniti eligendi fugiat in provident/;
  ok $lorem_paragraphs = $result->lorem_paragraphs;
  like $lorem_paragraphs, qr/deserunt consequatur ducimus enim blanditiis/;
  ok $lorem_paragraphs = $result->lorem_paragraphs;
  like $lorem_paragraphs, qr/accusantium sit ex totam pariatur odio/;

  $lorem_paragraphs
});

=method lorem_sentence

The lorem_sentence method returns a random lorem sentence.

=signature lorem_sentence

  lorem_sentence(HashRef $data) (Str)

=metadata lorem_sentence

{
  since => '1.10',
}

=example-1 lorem_sentence

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_sentence = $faker->lorem_sentence;

  # "vitae et eligendi laudantium provident assumenda voluptates..."

  # $lorem_sentence = $faker->lorem_sentence;

  # "aspernatur qui ad error numquam illum sunt cupiditate recus..."

  # $lorem_sentence = $faker->lorem_sentence;

  # "incidunt ut ratione sequi non illum laborum dolorum et earu..."

=cut

$test->for('example', 1, 'lorem_sentence', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_sentence = $result->lorem_sentence;
  like $lorem_sentence, qr/nihil vitae vero et deleniti eligendi fugiat/;
  ok $lorem_sentence = $result->lorem_sentence;
  like $lorem_sentence, qr/voluptates corrupti sed dolores iusto aliquid/;
  ok $lorem_sentence = $result->lorem_sentence;
  like $lorem_sentence, qr/nostrum error at numquam et illum numquam/;

  $lorem_sentence
});

=method lorem_sentences

The lorem_sentences method returns a random lorem sentences.

=signature lorem_sentences

  lorem_sentences(HashRef $data) (Str)

=metadata lorem_sentences

{
  since => '1.10',
}

=example-1 lorem_sentences

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_sentences = $faker->lorem_sentences;

  # "vero deleniti fugiat in accusantium animi corrupti. et eos ..."

  # $lorem_sentences = $faker->lorem_sentences;

  # "enim accusantium aliquid id reprehenderit consequatur ducim..."

  # $lorem_sentences = $faker->lorem_sentences;

  # "reprehenderit ut autem cumque ea sint dolorem impedit et qu..."

=cut

$test->for('example', 1, 'lorem_sentences', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_sentences = $result->lorem_sentences;
  like $lorem_sentences, qr/vero et deleniti eligendi fugiat laudantium/;
  ok $lorem_sentences = $result->lorem_sentences;
  like $lorem_sentences, qr/incidunt voluptas ut et ratione in sequi dolore/;
  ok $lorem_sentences = $result->lorem_sentences;
  like $lorem_sentences, qr/sit dolorem adipisci consequatur asperiores et/;

  $lorem_sentences
});

=method lorem_word

The lorem_word method returns a random lorem word.

=signature lorem_word

  lorem_word(HashRef $data) (Str)

=metadata lorem_word

{
  since => '1.10',
}

=example-1 lorem_word

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_word = $faker->lorem_word;

  # "nisi"

  # $lorem_word = $faker->lorem_word;

  # "nihil"

  # $lorem_word = $faker->lorem_word;

  # "vero"

=cut

$test->for('example', 1, 'lorem_word', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_word = $result->lorem_word;
  is $lorem_word, "nisi";
  ok $lorem_word = $result->lorem_word;
  is $lorem_word, "nihil";
  ok $lorem_word = $result->lorem_word;
  is $lorem_word, "vero";

  $lorem_word
});

=method lorem_words

The lorem_words method returns a random lorem words.

=signature lorem_words

  lorem_words(HashRef $data) (Str)

=metadata lorem_words

{
  since => '1.10',
}

=example-1 lorem_words

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_words = $faker->lorem_words;

  # "aut vitae et eligendi laudantium"

  # $lorem_words = $faker->lorem_words;

  # "accusantium animi corrupti dolores aliquid"

  # $lorem_words = $faker->lorem_words;

  # "eos pariatur quia corporis illo"

=cut

$test->for('example', 1, 'lorem_words', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $lorem_words = $result->lorem_words;
  is $lorem_words, "nisi aut nihil vitae vero";
  ok $lorem_words = $result->lorem_words;
  is $lorem_words, "deleniti eligendi fugiat laudantium in";
  ok $lorem_words = $result->lorem_words;
  is $lorem_words, "accusantium assumenda animi voluptates corrupti";

  $lorem_words
});

=method payment_card_american_express

The payment_card_american_express method returns a random payment card american express.

=signature payment_card_american_express

  payment_card_american_express(HashRef $data) (Str)

=metadata payment_card_american_express

{
  since => '1.10',
}

=example-1 payment_card_american_express

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_american_express = $faker->payment_card_american_express;

  # 34140844684550

  # $payment_card_american_express = $faker->payment_card_american_express;

  # 37945443908982

  # $payment_card_american_express = $faker->payment_card_american_express;

  # 34370225828820

=cut

$test->for('example', 1, 'payment_card_american_express', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_american_express = $result->payment_card_american_express;
  is $payment_card_american_express, 34140844684550;
  ok $payment_card_american_express = $result->payment_card_american_express;
  is $payment_card_american_express, 37945443908982;
  ok $payment_card_american_express = $result->payment_card_american_express;
  is $payment_card_american_express, 34370225828820;

  $payment_card_american_express
});

=method payment_card_discover

The payment_card_discover method returns a random payment card discover.

=signature payment_card_discover

  payment_card_discover(HashRef $data) (Str)

=metadata payment_card_discover

{
  since => '1.10',
}

=example-1 payment_card_discover

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_discover = $faker->payment_card_discover;

  # 601131408446845

  # $payment_card_discover = $faker->payment_card_discover;

  # 601107694544390

  # $payment_card_discover = $faker->payment_card_discover;

  # 601198220370225

=cut

$test->for('example', 1, 'payment_card_discover', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_discover = $result->payment_card_discover;
  is $payment_card_discover, 601131408446845;
  ok $payment_card_discover = $result->payment_card_discover;
  is $payment_card_discover, 601107694544390;
  ok $payment_card_discover = $result->payment_card_discover;
  is $payment_card_discover, 601198220370225;

  $payment_card_discover
});

=method payment_card_expiration

The payment_card_expiration method returns a random payment card expiration.

=signature payment_card_expiration

  payment_card_expiration(HashRef $data) (Str)

=metadata payment_card_expiration

{
  since => '1.10',
}

=example-1 payment_card_expiration

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_expiration = $faker->payment_card_expiration;

  # "02/24"

  # $payment_card_expiration = $faker->payment_card_expiration;

  # "11/23"

  # $payment_card_expiration = $faker->payment_card_expiration;

  # "09/24"

=cut

$test->for('example', 1, 'payment_card_expiration', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_expiration = $result->payment_card_expiration;
  is $payment_card_expiration, "02/24";
  ok $payment_card_expiration = $result->payment_card_expiration;
  is $payment_card_expiration, "11/23";
  ok $payment_card_expiration = $result->payment_card_expiration;
  is $payment_card_expiration, "09/24";

  $payment_card_expiration
});

=method payment_card_mastercard

The payment_card_mastercard method returns a random payment card mastercard.

=signature payment_card_mastercard

  payment_card_mastercard(HashRef $data) (Str)

=metadata payment_card_mastercard

{
  since => '1.10',
}

=example-1 payment_card_mastercard

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_mastercard = $faker->payment_card_mastercard;

  # 521408446845507

  # $payment_card_mastercard = $faker->payment_card_mastercard;

  # 554544390898220

  # $payment_card_mastercard = $faker->payment_card_mastercard;

  # 540225828820558

=cut

$test->for('example', 1, 'payment_card_mastercard', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_mastercard = $result->payment_card_mastercard;
  is $payment_card_mastercard, 521408446845507;
  ok $payment_card_mastercard = $result->payment_card_mastercard;
  is $payment_card_mastercard, 554544390898220;
  ok $payment_card_mastercard = $result->payment_card_mastercard;
  is $payment_card_mastercard, 540225828820558;

  $payment_card_mastercard
});

=method payment_card_number

The payment_card_number method returns a random payment card number.

=signature payment_card_number

  payment_card_number(HashRef $data) (Str)

=metadata payment_card_number

{
  since => '1.10',
}

=example-1 payment_card_number

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_number = $faker->payment_card_number;

  # 453208446845507

  # $payment_card_number = $faker->payment_card_number;

  # 37443908982203

  # $payment_card_number = $faker->payment_card_number;

  # 491658288205589

=cut

$test->for('example', 1, 'payment_card_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_number = $result->payment_card_number;
  is $payment_card_number, 453208446845507;
  ok $payment_card_number = $result->payment_card_number;
  is $payment_card_number, 37443908982203;
  ok $payment_card_number = $result->payment_card_number;
  is $payment_card_number, 491658288205589;

  $payment_card_number
});

=method payment_card_visa

The payment_card_visa method returns a random payment card visa.

=signature payment_card_visa

  payment_card_visa(HashRef $data) (Str)

=metadata payment_card_visa

{
  since => '1.10',
}

=example-1 payment_card_visa

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_visa = $faker->payment_card_visa;

  # 453214084468

  # $payment_card_visa = $faker->payment_card_visa;

  # 402400715076

  # $payment_card_visa = $faker->payment_card_visa;

  # 492954439089

=cut

$test->for('example', 1, 'payment_card_visa', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_card_visa = $result->payment_card_visa;
  is $payment_card_visa, 453214084468;
  ok $payment_card_visa = $result->payment_card_visa;
  is $payment_card_visa, 402400715076;
  ok $payment_card_visa = $result->payment_card_visa;
  is $payment_card_visa, 492954439089;

  $payment_card_visa
});

=method payment_vendor

The payment_vendor method returns a random payment vendor.

=signature payment_vendor

  payment_vendor(HashRef $data) (Str)

=metadata payment_vendor

{
  since => '1.10',
}

=example-1 payment_vendor

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_vendor = $faker->payment_vendor;

  # "Visa"

  # $payment_vendor = $faker->payment_vendor;

  # "MasterCard"

  # $payment_vendor = $faker->payment_vendor;

  # "American Express"

=cut

$test->for('example', 1, 'payment_vendor', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $payment_vendor = $result->payment_vendor;
  is $payment_vendor, "Visa";
  ok $payment_vendor = $result->payment_vendor;
  is $payment_vendor, "MasterCard";
  ok $payment_vendor = $result->payment_vendor;
  is $payment_vendor, "American Express";

  $payment_vendor
});

=method person_first_name

The person_first_name method returns a random person first name.

=signature person_first_name

  person_first_name(HashRef $data) (Str)

=metadata person_first_name

{
  since => '1.10',
}

=example-1 person_first_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_first_name = $faker->person_first_name;

  # "Haskell"

  # $person_first_name = $faker->person_first_name;

  # "Jamison"

  # $person_first_name = $faker->person_first_name;

  # "Keeley"

=cut

$test->for('example', 1, 'person_first_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_first_name = $result->person_first_name;
  is $person_first_name, "Haskell";
  ok $person_first_name = $result->person_first_name;
  is $person_first_name, "Jamison";
  ok $person_first_name = $result->person_first_name;
  is $person_first_name, "Keeley";

  $person_first_name
});

=method person_formal_name

The person_formal_name method returns a random person formal name.

=signature person_formal_name

  person_formal_name(HashRef $data) (Str)

=metadata person_formal_name

{
  since => '1.10',
}

=example-1 person_formal_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_formal_name = $faker->person_formal_name;

  # "Russel Krajcik"

  # $person_formal_name = $faker->person_formal_name;

  # "Miss Josephine Forest Beier DDS"

  # $person_formal_name = $faker->person_formal_name;

  # "Duncan Mann"

=cut

$test->for('example', 1, 'person_formal_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_formal_name = $result->person_formal_name;
  is $person_formal_name, "Russel Krajcik";
  ok $person_formal_name = $result->person_formal_name;
  is $person_formal_name, "Miss Josephine Forest Beier DDS";
  ok $person_formal_name = $result->person_formal_name;
  is $person_formal_name, "Duncan Mann";

  $person_formal_name
});

=method person_gender

The person_gender method returns a random person gender.

=signature person_gender

  person_gender(HashRef $data) (Str)

=metadata person_gender

{
  since => '1.10',
}

=example-1 person_gender

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_gender = $faker->person_gender;

  # "male"

  # $person_gender = $faker->person_gender;

  # "male"

  # $person_gender = $faker->person_gender;

  # "female"

=cut

$test->for('example', 1, 'person_gender', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_gender = $result->person_gender;
  is $person_gender, "male";
  ok $person_gender = $result->person_gender;
  is $person_gender, "male";
  ok $person_gender = $result->person_gender;
  is $person_gender, "female";

  $person_gender
});

=method person_last_name

The person_last_name method returns a random person last name.

=signature person_last_name

  person_last_name(HashRef $data) (Str)

=metadata person_last_name

{
  since => '1.10',
}

=example-1 person_last_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_last_name = $faker->person_last_name;

  # "Heaney"

  # $person_last_name = $faker->person_last_name;

  # "Johnston"

  # $person_last_name = $faker->person_last_name;

  # "Steuber"

=cut

$test->for('example', 1, 'person_last_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_last_name = $result->person_last_name;
  is $person_last_name, "Heaney";
  ok $person_last_name = $result->person_last_name;
  is $person_last_name, "Johnston";
  ok $person_last_name = $result->person_last_name;
  is $person_last_name, "Steuber";

  $person_last_name
});

=method person_name

The person_name method returns a random person name.

=signature person_name

  person_name(HashRef $data) (Str)

=metadata person_name

{
  since => '1.10',
}

=example-1 person_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name = $faker->person_name;

  # "Russel Krajcik"

  # $person_name = $faker->person_name;

  # "Alayna Josephine Kunde"

  # $person_name = $faker->person_name;

  # "Viviane Fritsch"

=cut

$test->for('example', 1, 'person_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_name = $result->person_name;
  is $person_name, "Russel Krajcik";
  ok $person_name = $result->person_name;
  is $person_name, "Alayna Josephine Kunde";
  ok $person_name = $result->person_name;
  is $person_name, "Viviane Fritsch";

  $person_name
});

=method person_name_prefix

The person_name_prefix method returns a random person name prefix.

=signature person_name_prefix

  person_name_prefix(HashRef $data) (Str)

=metadata person_name_prefix

{
  since => '1.10',
}

=example-1 person_name_prefix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name_prefix = $faker->person_name_prefix;

  # "Mr."

  # $person_name_prefix = $faker->person_name_prefix;

  # "Mr."

  # $person_name_prefix = $faker->person_name_prefix;

  # "Sir"

=cut

$test->for('example', 1, 'person_name_prefix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_name_prefix = $result->person_name_prefix;
  is $person_name_prefix, "Mr.";
  ok $person_name_prefix = $result->person_name_prefix;
  is $person_name_prefix, "Mr.";
  ok $person_name_prefix = $result->person_name_prefix;
  is $person_name_prefix, "Sir";

  $person_name_prefix
});

=method person_name_suffix

The person_name_suffix method returns a random person name suffix.

=signature person_name_suffix

  person_name_suffix(HashRef $data) (Str)

=metadata person_name_suffix

{
  since => '1.10',
}

=example-1 person_name_suffix

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name_suffix = $faker->person_name_suffix;

  # "I"

  # $person_name_suffix = $faker->person_name_suffix;

  # "I"

  # $person_name_suffix = $faker->person_name_suffix;

  # "II"

=cut

$test->for('example', 1, 'person_name_suffix', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $person_name_suffix = $result->person_name_suffix;
  is $person_name_suffix, "I";
  ok $person_name_suffix = $result->person_name_suffix;
  is $person_name_suffix, "I";
  ok $person_name_suffix = $result->person_name_suffix;
  is $person_name_suffix, "II";

  $person_name_suffix
});

=method software_author

The software_author method returns a random software author.

=signature software_author

  software_author(HashRef $data) (Str)

=metadata software_author

{
  since => '1.10',
}

=example-1 software_author

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_author = $faker->software_author;

  # "Jamison Skiles"

  # $software_author = $faker->software_author;

  # "Josephine Kunde"

  # $software_author = $faker->software_author;

  # "Darby Boyer"

=cut

$test->for('example', 1, 'software_author', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $software_author = $result->software_author;
  is $software_author, "Jamison Skiles";
  ok $software_author = $result->software_author;
  is $software_author, "Josephine Kunde";
  ok $software_author = $result->software_author;
  is $software_author, "Darby Boyer";

  $software_author
});

=method software_name

The software_name method returns a random software name.

=signature software_name

  software_name(HashRef $data) (Str)

=metadata software_name

{
  since => '1.10',
}

=example-1 software_name

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_name = $faker->software_name;

  # "Job"

  # $software_name = $faker->software_name;

  # "Zamit"

  # $software_name = $faker->software_name;

  # "Stronghold"

=cut

$test->for('example', 1, 'software_name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $software_name = $result->software_name;
  is $software_name, "Job";
  ok $software_name = $result->software_name;
  is $software_name, "Zamit";
  ok $software_name = $result->software_name;
  is $software_name, "Stronghold";

  $software_name
});

=method software_semver

The software_semver method returns a random software semver.

=signature software_semver

  software_semver(HashRef $data) (Str)

=metadata software_semver

{
  since => '1.10',
}

=example-1 software_semver

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_semver = $faker->software_semver;

  # "1.4.0"

  # $software_semver = $faker->software_semver;

  # "4.6.8"

  # $software_semver = $faker->software_semver;

  # "5.0.7"

=cut

$test->for('example', 1, 'software_semver', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $software_semver = $result->software_semver;
  is $software_semver, "1.4.0";
  ok $software_semver = $result->software_semver;
  is $software_semver, "4.6.8";
  ok $software_semver = $result->software_semver;
  is $software_semver, "5.0.7";

  $software_semver
});

=method software_version

The software_version method returns a random software version.

=signature software_version

  software_version(HashRef $data) (Str)

=metadata software_version

{
  since => '1.10',
}

=example-1 software_version

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_version = $faker->software_version;

  # 1.4

  # $software_version = $faker->software_version;

  # "0.4.4"

  # $software_version = $faker->software_version;

  # "0.4.5"

=cut

$test->for('example', 1, 'software_version', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $software_version = $result->software_version;
  is $software_version, 1.4;
  ok $software_version = $result->software_version;
  is $software_version, "0.4.4";
  ok $software_version = $result->software_version;
  is $software_version, "0.4.5";

  $software_version
});

=method telephone_number

The telephone_number method returns a random telephone number.

=signature telephone_number

  telephone_number(HashRef $data) (Str)

=metadata telephone_number

{
  since => '1.10',
}

=example-1 telephone_number

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $telephone_number = $faker->telephone_number;

  # "01408446845"

  # $telephone_number = $faker->telephone_number;

  # "769-454-4390"

  # $telephone_number = $faker->telephone_number;

  # "1-822-037-0225x82882"

=cut

$test->for('example', 1, 'telephone_number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $telephone_number = $result->telephone_number;
  is $telephone_number, "01408446845";
  ok $telephone_number = $result->telephone_number;
  is $telephone_number, "769-454-4390";
  ok $telephone_number = $result->telephone_number;
  is $telephone_number, "1-822-037-0225x82882";

  $telephone_number
});

=method user_login

The user_login method returns a random user login.

=signature user_login

  user_login(HashRef $data) (Str)

=metadata user_login

{
  since => '1.10',
}

=example-1 user_login

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $user_login = $faker->user_login;

  # "Russel44"

  # $user_login = $faker->user_login;

  # "aMayer7694"

  # $user_login = $faker->user_login;

  # "Amalia89"

=cut

$test->for('example', 1, 'user_login', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $user_login = $result->user_login;
  is $user_login, "Russel44";
  ok $user_login = $result->user_login;
  is $user_login, "aMayer7694";
  ok $user_login = $result->user_login;
  is $user_login, "Amalia89";

  $user_login
});

=method user_password

The user_password method returns a random user password.

=signature user_password

  user_password(HashRef $data) (Str)

=metadata user_password

{
  since => '1.10',
}

=example-1 user_password

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $user_password = $faker->user_password;

  # "48R+a}[Lb?&0725"

  # $user_password = $faker->user_password;

  # ",0w\$h4155>*0M"

  # $user_password = $faker->user_password;

  # ")P2^'q695a}8GX"

=cut

$test->for('example', 1, 'user_password', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Faker');
  ok $result->random->reseed($seed);
  my $user_password = $result->user_password;
  is $user_password, "48R+a}[Lb?&0725";
  ok $user_password = $result->user_password;
  is $user_password, ",0w\$h4155>*0M";
  ok $user_password = $result->user_password;
  is $user_password, ")P2^'q695a}8GX";

  $user_password
});


=feature plugins-feature

This package loads and dispatches calls to plugins (the fake data generators)
which allow for extending the library in environment-specific ways.

=cut

$test->for('feature', 'plugins-feature');

=example-1 plugins-feature

  package Faker::Plugin::HttpContentType;

  use base 'Faker::Plugin';

  sub execute {
    'video/mpeg'
  }

  package main;

  use Faker;

  my $faker = Faker->new;

  my $http_content_type = $faker->http_content_type;

  # "video/mpeg"

=cut

$test->for('example', 1, 'plugins-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "video/mpeg";

  $result
});

=example-2 plugins-feature

  package Faker::Plugin::HttpContentType;

  use base 'Faker::Plugin';

  sub execute {
    'video/mpeg'
  }

  package main;

  my $plugin = Faker::Plugin::HttpContentType->new;

  my $http_content_type = $plugin->execute;

  # "video/mpeg"

=cut

$test->for('example', 2, 'plugins-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  is $result, "video/mpeg";

  $result
});

=feature locales-feature

This package can be configured to return localized fake data, typically
organized under namespaces specific to the locale specified.

=cut

$test->for('feature', 'locales-feature');

=example-1 locales-feature

  package Faker::Plugin::Dothraki::RandomPhrase;

  use base 'Faker::Plugin';

  sub execute {
    'Hash yer dothrae chek asshekh?'
  }

  package main;

  use Faker;

  my $faker = Faker->new('dothraki');

  my $random_phrase = $faker->random_phrase;

  # "Hash yer dothrae chek asshekh?"

=cut

$test->for('example', 1, 'locales-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-2 locales-feature

  package Faker::Plugin::Klingon::RandomPhrase;

  use base 'Faker::Plugin';

  sub execute {
    'nuqDaq ’oH puchpa’’e’'
  }

  package main;

  use Faker;

  my $faker = Faker->new('klingon');

  my $random_phrase = $faker->random_phrase;

  # "nuqDaq ’oH puchpa’’e’"

=cut

$test->for('example', 2, 'locales-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=example-3 locales-feature

  package Faker::Plugin::Dothraki::RandomPhrase;

  use base 'Faker::Plugin';

  sub execute {
    'Hash yer dothrae chek asshekh?'
  }

  package Faker::Plugin::Klingon::RandomPhrase;

  use base 'Faker::Plugin';

  sub execute {
    'nuqDaq ’oH puchpa’’e’'
  }

  package main;

  use Faker;

  my $faker = Faker->new(['dothraki', 'klingon']);

  my $random_phrase = $faker->random_phrase;

  # "nuqDaq ’oH puchpa’’e’"

  # $random_phrase = $faker->random_phrase;

  # "Hash yer dothrae chek asshekh?"

  # $random_phrase = $faker->random_phrase;

  # "nuqDaq ’oH puchpa’’e’"

  # $random_phrase = $faker->random_phrase;

  # "nuqDaq ’oH puchpa’’e’"

=cut

$test->for('example', 3, 'locales-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=feature caching-feature

Often one generator's fake data is composed of the output from other
generators. Caching can be used to make generators faster, and to make fake
data more realistic.

=cut

$test->for('feature', 'caching-feature');

=example-1 caching-feature

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  my $person_first_name = $faker->person_first_name;

  # "Jordi"

  my $person_last_name = $faker->person_last_name;

  # "Smitham"

  my $internet_email_address = $faker->internet_email_address;

  # "deshaun8768@hotmail.com"

  $person_first_name = $faker->cache('person_first_name');

  # "Arlene"

  $person_last_name = $faker->cache('person_last_name');

  # "Cassin"

  $internet_email_address = $faker->internet_email_address;

  # "arlene6025@proton.me"

=cut

$test->for('example', 1, 'caching-feature', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;

  $result
});

=authors

Awncorp, C<awncorp@cpan.org>

=cut

# END

$test->render('lib/Faker.pod') if $ENV{RENDER};

ok 1 and done_testing;

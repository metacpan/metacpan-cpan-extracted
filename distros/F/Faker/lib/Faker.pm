package Faker;

use 5.018;

use strict;
use warnings;

use Venus::Class 'attr', 'with';

with 'Venus::Role::Buildable';
with 'Venus::Role::Proxyable';
with 'Venus::Role::Optional';

# VERSION

our $VERSION = '1.17';

# AUTHORITY

our $AUTHORITY = 'cpan:AWNCORP';

# STATE

state $sources = {};

# ATTRIBUTES

attr 'caches';
attr 'locales';

# DEFAULTS

sub coerce_caches {
  return 'Venus::Hash';
}

sub default_caches {
  return {};
}

sub coerce_locales {
  return 'Venus::Array';
}

sub default_locales {
  return [];
}

# BUILDERS

sub build_arg {
  my ($self, $data) = @_;

  return {
    locales => ref $data eq 'ARRAY' ? $data : [$data],
  };
}

sub build_proxy {
  my ($self, $package, $method, @args) = @_;

  return sub { $self->caches->get($method) } if $self->caches->exists($method);

  return unless my $source = $self->sources($method)->random;

  return sub { $source->build(faker => $self)->execute(@args) };
}

# METHODS

sub cache {
  my ($self, $method, @args) = @_;

  return if !$method;

  my $result = $self->caches->set($method, $self->$method(@args));

  return $result;
}

sub plugin {
  my ($self, @args) = @_;

  return $self->space->child('plugin', @args);
}

sub random {
  my ($self) = @_;

  require Venus::Random;

  state $random = Venus::Random->new;

  return $random;
}

sub space {
  my ($self) = @_;

  require Venus::Space;

  state $space = Venus::Space->new(ref $self || $self);

  return $space;
}

sub sources {
  my ($self, $method) = @_;

  return if !$method;

  require Venus::Array;

  my $plugins = Venus::Array->new([$self->plugin($method)]);

  $plugins->push(map {$self->plugin($_, $method)} $self->locales->list);

  $plugins->value([grep {$$sources{"$_"} //= $_->tryload} $plugins->list]);

  return $plugins;
}

1;


=head1 NAME

Faker - Fake Data Generator

=cut

=head1 ABSTRACT

Extensible Fake Data Generator

=cut

=head1 VERSION

1.17

=cut

=head1 SYNOPSIS

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

  # my $last_name = $faker->person_name;

  # "Alayna Josephine Kunde"

=cut

=head1 DESCRIPTION

This distribution provides a library of fake data generators and a framework
for extending the library via plugins.

=encoding utf8

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 caches

  caches(HashRef $data) (Object)

The caches attribute holds the cached values returned from L</cache>.

I<Since C<1.10>>

=over 4

=item caches example 1

  # given: synopsis

  package main;

  my $caches = $faker->caches;

  # bless({value => {}}, 'Venus::Hash')

=back

=over 4

=item caches example 2

  # given: synopsis

  package main;

  my $caches = $faker->caches({});

  # bless({value => {}}, 'Venus::Hash')

=back

=cut

=head2 locales

  locales(ArrayRef $data) (Object)

The locales attribute holds the locales used to find and generate localized
data.

I<Since C<1.10>>

=over 4

=item locales example 1

  # given: synopsis

  package main;

  my $locales = $faker->locales;

  # bless({value => []}, 'Venus::Array')

=back

=over 4

=item locales example 2

  # given: synopsis

  package main;

  my $locales = $faker->locales([]);

  # bless({value => []}, 'Venus::Array')

=back

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Proxyable>

L<Venus::Role::Optional>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 address_city_name

  address_city_name(HashRef $data) (Str)

The address_city_name method returns a random address city name.

I<Since C<1.10>>

=over 4

=item address_city_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_name = $faker->address_city_name;

  # "West Jamison"

  # $address_city_name = $faker->address_city_name;

  # "Mayertown"

  # $address_city_name = $faker->address_city_name;

  # "Juliaborough"

=back

=cut

=head2 address_city_prefix

  address_city_prefix(HashRef $data) (Str)

The address_city_prefix method returns a random address city prefix.

I<Since C<1.10>>

=over 4

=item address_city_prefix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_prefix = $faker->address_city_prefix;

  # "West"

  # $address_city_prefix = $faker->address_city_prefix;

  # "West"

  # $address_city_prefix = $faker->address_city_prefix;

  # "Lake"

=back

=cut

=head2 address_city_suffix

  address_city_suffix(HashRef $data) (Str)

ok $address_city_suffix method returns a random address city suffix.

I<Since C<1.10>>

=over 4

=item address_city_suffix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_city_suffix = $faker->address_city_suffix;

  # "borough"

  # $address_city_suffix = $faker->address_city_suffix;

  # "view"

  # $address_city_suffix = $faker->address_city_suffix;

  # "haven"

=back

=cut

=head2 address_country_name

  address_country_name(HashRef $data) (Str)

The address_country_name method returns a random address country name.

I<Since C<1.10>>

=over 4

=item address_country_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_country_name = $faker->address_country_name;

  # "Greenland"

  # $address_country_name = $faker->address_country_name;

  # "Ireland"

  # $address_country_name = $faker->address_country_name;

  # "Svalbard & Jan Mayen Islands"

=back

=cut

=head2 address_latitude

  address_latitude(HashRef $data) (Str)

The address_latitude method returns a random address latitude.

I<Since C<1.10>>

=over 4

=item address_latitude example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_latitude = $faker->address_latitude;

  # 30.843133

  # $address_latitude = $faker->address_latitude;

  # 77.079663

  # $address_latitude = $faker->address_latitude;

  # -41.660985

=back

=cut

=head2 address_line1

  address_line1(HashRef $data) (Str)

The address_line1 method returns a random address line1.

I<Since C<1.10>>

=over 4

=item address_line1 example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_line1 = $faker->address_line1;

  # "44084 Mayer Brook"

  # $address_line1 = $faker->address_line1;

  # "4 Amalia Terrace"

  # $address_line1 = $faker->address_line1;

  # "20370 Emard Street"

=back

=cut

=head2 address_line2

  address_line2(HashRef $data) (Str)

The address_line2 method returns a random address line2.

I<Since C<1.10>>

=over 4

=item address_line2 example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_line2 = $faker->address_line2;

  # "Mailbox 1408"

  # $address_line2 = $faker->address_line2;

  # "Mailbox 684"

  # $address_line2 = $faker->address_line2;

  # "Suite 076"

=back

=cut

=head2 address_lines

  address_lines(HashRef $data) (Str)

The address_lines method returns a random address lines.

I<Since C<1.10>>

=over 4

=item address_lines example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_lines = $faker->address_lines;

  # "4 Koelpin Plaza Unit 694\nWest Viviane, IA 37022"

  # $address_lines = $faker->address_lines;

  # "90558 Greenholt Orchard\nApt. 250\nPfannerstillberg, New Mexico 52836"

  # $address_lines = $faker->address_lines;

  # "68768 Weissnat Point\nRitchieburgh, New Mexico 53892"

=back

=cut

=head2 address_longitude

  address_longitude(HashRef $data) (Str)

The address_longitude method returns a random address longitude.

I<Since C<1.10>>

=over 4

=item address_longitude example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_longitude = $faker->address_longitude;

  # 30.843133

  # $address_longitude = $faker->address_longitude;

  # 77.079663

  # $address_longitude = $faker->address_longitude;

  # -41.660985

=back

=cut

=head2 address_number

  address_number(HashRef $data) (Str)

The address_number method returns a random address number.

I<Since C<1.10>>

=over 4

=item address_number example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_number = $faker->address_number;

  # 8140

  # $address_number = $faker->address_number;

  # 5684

  # $address_number = $faker->address_number;

  # 57694

=back

=cut

=head2 address_postal_code

  address_postal_code(HashRef $data) (Str)

The address_postal_code method returns a random address postal code.

I<Since C<1.10>>

=over 4

=item address_postal_code example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_postal_code = $faker->address_postal_code;

  # 14084

  # $address_postal_code = $faker->address_postal_code;

  # "84550-7694"

  # $address_postal_code = $faker->address_postal_code;

  # 43908

=back

=cut

=head2 address_region_name

  address_region_name(HashRef $data) (Str)

The address_region_name method returns a random address region name.

I<Since C<1.10>>

=over 4

=item address_region_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_region_name = $faker->address_region_name;

  # "Massachusetts"

  # $address_region_name = $faker->address_region_name;

  # "MO"

  # $address_region_name = $faker->address_region_name;

  # "NE"

=back

=cut

=head2 address_state_abbr

  address_state_abbr(HashRef $data) (Str)

The address_state_abbr method returns a random address state abbr.

I<Since C<1.10>>

=over 4

=item address_state_abbr example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_state_abbr = $faker->address_state_abbr;

  # "KY"

  # $address_state_abbr = $faker->address_state_abbr;

  # "ME"

  # $address_state_abbr = $faker->address_state_abbr;

  # "TX"

=back

=cut

=head2 address_state_name

  address_state_name(HashRef $data) (Str)

The address_state_name method returns a random address state name.

I<Since C<1.10>>

=over 4

=item address_state_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_state_name = $faker->address_state_name;

  # "Kentucky"

  # $address_state_name = $faker->address_state_name;

  # "Massachusetts"

  # $address_state_name = $faker->address_state_name;

  # "Texas"

=back

=cut

=head2 address_street_address

  address_street_address(HashRef $data) (Str)

The address_street_address method returns a random address street address.

I<Since C<1.10>>

=over 4

=item address_street_address example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_address = $faker->address_street_address;

  # "4084 Mayer Brook Suite 94"

  # $address_street_address = $faker->address_street_address;

  # "9908 Mustafa Harbor Suite 828"

  # $address_street_address = $faker->address_street_address;

  # "958 Greenholt Orchard"

=back

=cut

=head2 address_street_name

  address_street_name(HashRef $data) (Str)

The address_street_name method returns a random address street name.

I<Since C<1.10>>

=over 4

=item address_street_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_name = $faker->address_street_name;

  # "Russel Parkway"

  # $address_street_name = $faker->address_street_name;

  # "Mayer Brook"

  # $address_street_name = $faker->address_street_name;

  # "Kuhic Path"

=back

=cut

=head2 address_street_suffix

  address_street_suffix(HashRef $data) (Str)

The address_street_suffix method returns a random address street suffix.

I<Since C<1.10>>

=over 4

=item address_street_suffix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $address_street_suffix = $faker->address_street_suffix;

  # "Key"

  # $address_street_suffix = $faker->address_street_suffix;

  # "Mission"

  # $address_street_suffix = $faker->address_street_suffix;

  # "Street"

=back

=cut

=head2 cache

  cache(Str $method, Any @args) (Str)

The cache method dispatches to the method specified, caches the method name and
return value, and returns the value. Subsequent calls will return the cached
value.

I<Since C<1.10>>

=over 4

=item cache example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $cache = $faker->cache('person_name');

  # "Keeley Balistreri"

  # $cache = $faker->cache('person_name');

  # "Keeley Balistreri"

=back

=over 4

=item cache example 2

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $cache = $faker->cache('company_tagline');

  # "iterate back-end content"

  # $cache = $faker->cache('company_tagline');

  # "iterate back-end content"

=back

=cut

=head2 color_hex_code

  color_hex_code(HashRef $data) (Str)

The color_hex_code method returns a random color hex code.

I<Since C<1.10>>

=over 4

=item color_hex_code example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_hex_code = $faker->color_hex_code;

  # "#57bb49"

  # $color_hex_code = $faker->color_hex_code;

  # "#6c1e68"

  # $color_hex_code = $faker->color_hex_code;

  # "#db3fb2"

=back

=cut

=head2 color_name

  color_name(HashRef $data) (Str)

The color_name method returns a random color name.

I<Since C<1.10>>

=over 4

=item color_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_name = $faker->color_name;

  # "GhostWhite"

  # $color_name = $faker->color_name;

  # "Khaki"

  # $color_name = $faker->color_name;

  # "SeaGreen"

=back

=cut

=head2 color_rgb_colorset

  color_rgb_colorset(HashRef $data) (Str)

The color_rgb_colorset method returns a random color rgb colorset.

I<Since C<1.10>>

=over 4

=item color_rgb_colorset example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_rgb_colorset = $faker->color_rgb_colorset;

  # [28, 112, 22]

  # $color_rgb_colorset = $faker->color_rgb_colorset;

  # [219, 63, 178]

  # $color_rgb_colorset = $faker->color_rgb_colorset;

  # [176, 217, 21]

=back

=cut

=head2 color_rgb_colorset_css

  color_rgb_colorset_css(HashRef $data) (Str)

The color_rgb_colorset_css method returns a random color rgb colorset css.

I<Since C<1.10>>

=over 4

=item color_rgb_colorset_css example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(108, 30, 104)"

  # $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(122, 147, 147)"

  # $color_rgb_colorset_css = $faker->color_rgb_colorset_css;

  # "rgb(147, 224, 22)"

=back

=cut

=head2 color_safe_hex_code

  color_safe_hex_code(HashRef $data) (Str)

The color_safe_hex_code method returns a random color safe hex code.

I<Since C<1.10>>

=over 4

=item color_safe_hex_code example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff0057"

  # $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff006c"

  # $color_safe_hex_code = $faker->color_safe_hex_code;

  # "#ff00db"

=back

=cut

=head2 color_safe_name

  color_safe_name(HashRef $data) (Str)

The color_safe_name method returns a random color safe name.

I<Since C<1.10>>

=over 4

=item color_safe_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $color_safe_name = $faker->color_safe_name;

  # "purple"

  # $color_safe_name = $faker->color_safe_name;

  # "teal"

  # $color_safe_name = $faker->color_safe_name;

  # "fuchsia"

=back

=cut

=head2 company_description

  company_description(HashRef $data) (Str)

The company_description method returns a random company description.

I<Since C<1.10>>

=over 4

=item company_description example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_description = $faker->company_description;

  # "Excels at full-range synchronised implementations"

  # $company_description = $faker->company_description;

  # "Provides logistical ameliorated methodologies"

  # $company_description = $faker->company_description;

  # "Offering hybrid future-proofed applications"

=back

=cut

=head2 company_name

  company_name(HashRef $data) (Str)

The company_name method returns a random company name.

I<Since C<1.10>>

=over 4

=item company_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_name = $faker->company_name;

  # "Johnston-Steuber"

  # $company_name = $faker->company_name;

  # "Skiles-Mayer"

  # $company_name = $faker->company_name;

  # "Miller and Sons"

=back

=cut

=head2 company_name_suffix

  company_name_suffix(HashRef $data) (Str)

The company_name_suffix method returns a random company name suffix.

I<Since C<1.10>>

=over 4

=item company_name_suffix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_name_suffix = $faker->company_name_suffix;

  # "Inc."

  # $company_name_suffix = $faker->company_name_suffix;

  # "Incorporated"

  # $company_name_suffix = $faker->company_name_suffix;

  # "Ventures"

=back

=cut

=head2 company_tagline

  company_tagline(HashRef $data) (Str)

The company_tagline method returns a random company tagline.

I<Since C<1.10>>

=over 4

=item company_tagline example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $company_tagline = $faker->company_tagline;

  # "transform revolutionary supply-chains"

  # $company_tagline = $faker->company_tagline;

  # "generate front-end web-readiness"

  # $company_tagline = $faker->company_tagline;

  # "iterate back-end content"

=back

=cut

=head2 internet_domain_name

  internet_domain_name(HashRef $data) (Str)

The internet_domain_name method returns a random internet domain name.

I<Since C<1.10>>

=over 4

=item internet_domain_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_name = $faker->internet_domain_name;

  # "steuber-krajcik.org"

  # $internet_domain_name = $faker->internet_domain_name;

  # "miller-and-sons.com"

  # $internet_domain_name = $faker->internet_domain_name;

  # "witting-entertainment.com"

=back

=cut

=head2 internet_domain_tld

  internet_domain_tld(HashRef $data) (Str)

The internet_domain_tld method returns a random internet domain tld.

I<Since C<1.10>>

=over 4

=item internet_domain_tld example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_tld = $faker->internet_domain_tld;

  # "com"

  # $internet_domain_tld = $faker->internet_domain_tld;

  # "com"

  # $internet_domain_tld = $faker->internet_domain_tld;

  # "org"

=back

=cut

=head2 internet_domain_word

  internet_domain_word(HashRef $data) (Str)

The internet_domain_word method returns a random internet domain word.

I<Since C<1.10>>

=over 4

=item internet_domain_word example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_domain_word = $faker->internet_domain_word;

  # "bode-and-sons"

  # $internet_domain_word = $faker->internet_domain_word;

  # "mayer-balistreri-and-miller"

  # $internet_domain_word = $faker->internet_domain_word;

  # "kerluke-waelchi"

=back

=cut

=head2 internet_email_address

  internet_email_address(HashRef $data) (Str)

The internet_email_address method returns a random internet email address.

I<Since C<1.10>>

=over 4

=item internet_email_address example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_email_address = $faker->internet_email_address;

  # "russel54\@mayer-balistreri-and-miller.com"

  # $internet_email_address = $faker->internet_email_address;

  # "viviane82\@rempel-entertainment.com"

  # $internet_email_address = $faker->internet_email_address;

  # "yborer\@outlook.com"

=back

=cut

=head2 internet_email_domain

  internet_email_domain(HashRef $data) (Str)

The internet_email_domain method returns a random internet email domain.

I<Since C<1.10>>

=over 4

=item internet_email_domain example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_email_domain = $faker->internet_email_domain;

  # "icloud.com"

  # $internet_email_domain = $faker->internet_email_domain;

  # "icloud.com"

  # $internet_email_domain = $faker->internet_email_domain;

  # "yahoo.com"

=back

=cut

=head2 internet_ip_address

  internet_ip_address(HashRef $data) (Str)

The internet_ip_address method returns a random internet ip address.

I<Since C<1.10>>

=over 4

=item internet_ip_address example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address = $faker->internet_ip_address;

  # "108.20.219.127"

  # $internet_ip_address = $faker->internet_ip_address;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48"

  # $internet_ip_address = $faker->internet_ip_address;

  # "89.236.15.220"

=back

=cut

=head2 internet_ip_address_v4

  internet_ip_address_v4(HashRef $data) (Str)

The internet_ip_address_v4 method returns a random internet ip address v4.

I<Since C<1.10>>

=over 4

=item internet_ip_address_v4 example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "87.28.108.20"

  # $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "127.122.176.213"

  # $internet_ip_address_v4 = $faker->internet_ip_address_v4;

  # "147.136.6.197"

=back

=cut

=head2 internet_ip_address_v6

  internet_ip_address_v6(HashRef $data) (Str)

The internet_ip_address_v6 method returns a random internet ip address v6.

I<Since C<1.10>>

=over 4

=item internet_ip_address_v6 example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "57bb:1c70:6c1e:14c3:db3f:7fb1:7a93:b0d9"

  # $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "7680:93e0:88b2:06a0:c512:99e4:e8a9:7d48"

  # $internet_ip_address_v6 = $faker->internet_ip_address_v6;

  # "7f27:7009:5984:ec03:0f75:dc22:f8d4:d951"

=back

=cut

=head2 internet_url

  internet_url(HashRef $data) (Str)

The internet_url method returns a random internet url.

I<Since C<1.10>>

=over 4

=item internet_url example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $internet_url = $faker->internet_url;

  # "https://krajcik-skiles-and-mayer.com/"

  # $internet_url = $faker->internet_url;

  # "http://heidenreich-beier.co/"

  # $internet_url = $faker->internet_url;

  # "https://goldner-mann-and-emard.org/"

=back

=cut

=head2 jargon_adjective

  jargon_adjective(HashRef $data) (Str)

The jargon_adjective method returns a random jargon adjective.

I<Since C<1.10>>

=over 4

=item jargon_adjective example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_adjective = $faker->jargon_adjective;

  # "virtual"

  # $jargon_adjective = $faker->jargon_adjective;

  # "killer"

  # $jargon_adjective = $faker->jargon_adjective;

  # "cutting-edge"

=back

=cut

=head2 jargon_adverb

  jargon_adverb(HashRef $data) (Str)

The jargon_adverb method returns a random jargon adverb.

I<Since C<1.10>>

=over 4

=item jargon_adverb example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_adverb = $faker->jargon_adverb;

  # "future-proofed"

  # $jargon_adverb = $faker->jargon_adverb;

  # "managed"

  # $jargon_adverb = $faker->jargon_adverb;

  # "synchronised"

=back

=cut

=head2 jargon_noun

  jargon_noun(HashRef $data) (Str)

The jargon_noun method returns a random jargon noun.

I<Since C<1.10>>

=over 4

=item jargon_noun example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_noun = $faker->jargon_noun;

  # "action-items"

  # $jargon_noun = $faker->jargon_noun;

  # "technologies"

  # $jargon_noun = $faker->jargon_noun;

  # "applications"

=back

=cut

=head2 jargon_term_prefix

  jargon_term_prefix(HashRef $data) (Str)

The jargon_term_prefix method returns a random jargon term prefix.

I<Since C<1.10>>

=over 4

=item jargon_term_prefix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_term_prefix = $faker->jargon_term_prefix;

  # "encompassing"

  # $jargon_term_prefix = $faker->jargon_term_prefix;

  # "full-range"

  # $jargon_term_prefix = $faker->jargon_term_prefix;

  # "systematic"

=back

=cut

=head2 jargon_term_suffix

  jargon_term_suffix(HashRef $data) (Str)

The jargon_term_suffix method returns a random jargon term suffix.

I<Since C<1.10>>

=over 4

=item jargon_term_suffix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_term_suffix = $faker->jargon_term_suffix;

  # "flexibilities"

  # $jargon_term_suffix = $faker->jargon_term_suffix;

  # "graphical user interfaces"

  # $jargon_term_suffix = $faker->jargon_term_suffix;

  # "standardization"

=back

=cut

=head2 jargon_verb

  jargon_verb(HashRef $data) (Str)

The jargon_verb method returns a random jargon verb.

I<Since C<1.10>>

=over 4

=item jargon_verb example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $jargon_verb = $faker->jargon_verb;

  # "harness"

  # $jargon_verb = $faker->jargon_verb;

  # "strategize"

  # $jargon_verb = $faker->jargon_verb;

  # "exploit"

=back

=cut

=head2 lorem_paragraph

  lorem_paragraph(HashRef $data) (Str)

The lorem_paragraph method returns a random lorem paragraph.

I<Since C<1.10>>

=over 4

=item lorem_paragraph example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_paragraph = $faker->lorem_paragraph;

  # "deleniti fugiat in accusantium animi corrupti dolores. eos ..."

  # $lorem_paragraph = $faker->lorem_paragraph;

  # "ducimus placeat autem ut sit adipisci asperiores quae ipsum..."

  # $lorem_paragraph = $faker->lorem_paragraph;

  # "dignissimos est magni quia aut et hic eos architecto repudi..."

=back

=cut

=head2 lorem_paragraphs

  lorem_paragraphs(HashRef $data) (Str)

The lorem_paragraphs method returns a random lorem paragraphs.

I<Since C<1.10>>

=over 4

=item lorem_paragraphs example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_paragraphs = $faker->lorem_paragraphs;

  # "eligendi laudantium provident assumenda voluptates sed iu..."

  # $lorem_paragraphs = $faker->lorem_paragraphs;

  # "accusantium ex pariatur perferendis voluptate iusto iure fu..."

  # $lorem_paragraphs = $faker->lorem_paragraphs;

  # "sit ut molestiae consequatur error tempora inventore est so..."

=back

=cut

=head2 lorem_sentence

  lorem_sentence(HashRef $data) (Str)

The lorem_sentence method returns a random lorem sentence.

I<Since C<1.10>>

=over 4

=item lorem_sentence example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_sentence = $faker->lorem_sentence;

  # "vitae et eligendi laudantium provident assumenda voluptates..."

  # $lorem_sentence = $faker->lorem_sentence;

  # "aspernatur qui ad error numquam illum sunt cupiditate recus..."

  # $lorem_sentence = $faker->lorem_sentence;

  # "incidunt ut ratione sequi non illum laborum dolorum et earu..."

=back

=cut

=head2 lorem_sentences

  lorem_sentences(HashRef $data) (Str)

The lorem_sentences method returns a random lorem sentences.

I<Since C<1.10>>

=over 4

=item lorem_sentences example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_sentences = $faker->lorem_sentences;

  # "vero deleniti fugiat in accusantium animi corrupti. et eos ..."

  # $lorem_sentences = $faker->lorem_sentences;

  # "enim accusantium aliquid id reprehenderit consequatur ducim..."

  # $lorem_sentences = $faker->lorem_sentences;

  # "reprehenderit ut autem cumque ea sint dolorem impedit et qu..."

=back

=cut

=head2 lorem_word

  lorem_word(HashRef $data) (Str)

The lorem_word method returns a random lorem word.

I<Since C<1.10>>

=over 4

=item lorem_word example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_word = $faker->lorem_word;

  # "nisi"

  # $lorem_word = $faker->lorem_word;

  # "nihil"

  # $lorem_word = $faker->lorem_word;

  # "vero"

=back

=cut

=head2 lorem_words

  lorem_words(HashRef $data) (Str)

The lorem_words method returns a random lorem words.

I<Since C<1.10>>

=over 4

=item lorem_words example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $lorem_words = $faker->lorem_words;

  # "aut vitae et eligendi laudantium"

  # $lorem_words = $faker->lorem_words;

  # "accusantium animi corrupti dolores aliquid"

  # $lorem_words = $faker->lorem_words;

  # "eos pariatur quia corporis illo"

=back

=cut

=head2 new

  new(Str $data | ArrayRef $data | HashRef $data) (Faker)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

=back

=over 4

=item new example 2

  package main;

  use Faker;

  my $faker = Faker->new(['en-us', 'es-es']);

  # my $first_name = $faker->person_name;

  # "Rafael Loera"

=back

=over 4

=item new example 3

  package main;

  use Faker;

  my $faker = Faker->new({locales => ['en-us']});

  # my $first_name = $faker->person_name;

  # "Russel Krajcik"

=back

=cut

=head2 payment_card_american_express

  payment_card_american_express(HashRef $data) (Str)

The payment_card_american_express method returns a random payment card american express.

I<Since C<1.10>>

=over 4

=item payment_card_american_express example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_american_express = $faker->payment_card_american_express;

  # 34140844684550

  # $payment_card_american_express = $faker->payment_card_american_express;

  # 37945443908982

  # $payment_card_american_express = $faker->payment_card_american_express;

  # 34370225828820

=back

=cut

=head2 payment_card_discover

  payment_card_discover(HashRef $data) (Str)

The payment_card_discover method returns a random payment card discover.

I<Since C<1.10>>

=over 4

=item payment_card_discover example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_discover = $faker->payment_card_discover;

  # 601131408446845

  # $payment_card_discover = $faker->payment_card_discover;

  # 601107694544390

  # $payment_card_discover = $faker->payment_card_discover;

  # 601198220370225

=back

=cut

=head2 payment_card_expiration

  payment_card_expiration(HashRef $data) (Str)

The payment_card_expiration method returns a random payment card expiration.

I<Since C<1.10>>

=over 4

=item payment_card_expiration example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_expiration = $faker->payment_card_expiration;

  # "02/24"

  # $payment_card_expiration = $faker->payment_card_expiration;

  # "11/23"

  # $payment_card_expiration = $faker->payment_card_expiration;

  # "09/24"

=back

=cut

=head2 payment_card_mastercard

  payment_card_mastercard(HashRef $data) (Str)

The payment_card_mastercard method returns a random payment card mastercard.

I<Since C<1.10>>

=over 4

=item payment_card_mastercard example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_mastercard = $faker->payment_card_mastercard;

  # 521408446845507

  # $payment_card_mastercard = $faker->payment_card_mastercard;

  # 554544390898220

  # $payment_card_mastercard = $faker->payment_card_mastercard;

  # 540225828820558

=back

=cut

=head2 payment_card_number

  payment_card_number(HashRef $data) (Str)

The payment_card_number method returns a random payment card number.

I<Since C<1.10>>

=over 4

=item payment_card_number example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_number = $faker->payment_card_number;

  # 453208446845507

  # $payment_card_number = $faker->payment_card_number;

  # 37443908982203

  # $payment_card_number = $faker->payment_card_number;

  # 491658288205589

=back

=cut

=head2 payment_card_visa

  payment_card_visa(HashRef $data) (Str)

The payment_card_visa method returns a random payment card visa.

I<Since C<1.10>>

=over 4

=item payment_card_visa example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_card_visa = $faker->payment_card_visa;

  # 453214084468

  # $payment_card_visa = $faker->payment_card_visa;

  # 402400715076

  # $payment_card_visa = $faker->payment_card_visa;

  # 492954439089

=back

=cut

=head2 payment_vendor

  payment_vendor(HashRef $data) (Str)

The payment_vendor method returns a random payment vendor.

I<Since C<1.10>>

=over 4

=item payment_vendor example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $payment_vendor = $faker->payment_vendor;

  # "Visa"

  # $payment_vendor = $faker->payment_vendor;

  # "MasterCard"

  # $payment_vendor = $faker->payment_vendor;

  # "American Express"

=back

=cut

=head2 person_first_name

  person_first_name(HashRef $data) (Str)

The person_first_name method returns a random person first name.

I<Since C<1.10>>

=over 4

=item person_first_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_first_name = $faker->person_first_name;

  # "Haskell"

  # $person_first_name = $faker->person_first_name;

  # "Jamison"

  # $person_first_name = $faker->person_first_name;

  # "Keeley"

=back

=cut

=head2 person_formal_name

  person_formal_name(HashRef $data) (Str)

The person_formal_name method returns a random person formal name.

I<Since C<1.10>>

=over 4

=item person_formal_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_formal_name = $faker->person_formal_name;

  # "Russel Krajcik"

  # $person_formal_name = $faker->person_formal_name;

  # "Miss Josephine Forest Beier DDS"

  # $person_formal_name = $faker->person_formal_name;

  # "Duncan Mann"

=back

=cut

=head2 person_gender

  person_gender(HashRef $data) (Str)

The person_gender method returns a random person gender.

I<Since C<1.10>>

=over 4

=item person_gender example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_gender = $faker->person_gender;

  # "male"

  # $person_gender = $faker->person_gender;

  # "male"

  # $person_gender = $faker->person_gender;

  # "female"

=back

=cut

=head2 person_last_name

  person_last_name(HashRef $data) (Str)

The person_last_name method returns a random person last name.

I<Since C<1.10>>

=over 4

=item person_last_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_last_name = $faker->person_last_name;

  # "Heaney"

  # $person_last_name = $faker->person_last_name;

  # "Johnston"

  # $person_last_name = $faker->person_last_name;

  # "Steuber"

=back

=cut

=head2 person_name

  person_name(HashRef $data) (Str)

The person_name method returns a random person name.

I<Since C<1.10>>

=over 4

=item person_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name = $faker->person_name;

  # "Russel Krajcik"

  # $person_name = $faker->person_name;

  # "Alayna Josephine Kunde"

  # $person_name = $faker->person_name;

  # "Viviane Fritsch"

=back

=cut

=head2 person_name_prefix

  person_name_prefix(HashRef $data) (Str)

The person_name_prefix method returns a random person name prefix.

I<Since C<1.10>>

=over 4

=item person_name_prefix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name_prefix = $faker->person_name_prefix;

  # "Mr."

  # $person_name_prefix = $faker->person_name_prefix;

  # "Mr."

  # $person_name_prefix = $faker->person_name_prefix;

  # "Sir"

=back

=cut

=head2 person_name_suffix

  person_name_suffix(HashRef $data) (Str)

The person_name_suffix method returns a random person name suffix.

I<Since C<1.10>>

=over 4

=item person_name_suffix example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $person_name_suffix = $faker->person_name_suffix;

  # "I"

  # $person_name_suffix = $faker->person_name_suffix;

  # "I"

  # $person_name_suffix = $faker->person_name_suffix;

  # "II"

=back

=cut

=head2 software_author

  software_author(HashRef $data) (Str)

The software_author method returns a random software author.

I<Since C<1.10>>

=over 4

=item software_author example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_author = $faker->software_author;

  # "Jamison Skiles"

  # $software_author = $faker->software_author;

  # "Josephine Kunde"

  # $software_author = $faker->software_author;

  # "Darby Boyer"

=back

=cut

=head2 software_name

  software_name(HashRef $data) (Str)

The software_name method returns a random software name.

I<Since C<1.10>>

=over 4

=item software_name example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_name = $faker->software_name;

  # "Job"

  # $software_name = $faker->software_name;

  # "Zamit"

  # $software_name = $faker->software_name;

  # "Stronghold"

=back

=cut

=head2 software_semver

  software_semver(HashRef $data) (Str)

The software_semver method returns a random software semver.

I<Since C<1.10>>

=over 4

=item software_semver example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_semver = $faker->software_semver;

  # "1.4.0"

  # $software_semver = $faker->software_semver;

  # "4.6.8"

  # $software_semver = $faker->software_semver;

  # "5.0.7"

=back

=cut

=head2 software_version

  software_version(HashRef $data) (Str)

The software_version method returns a random software version.

I<Since C<1.10>>

=over 4

=item software_version example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $software_version = $faker->software_version;

  # 1.4

  # $software_version = $faker->software_version;

  # "0.4.4"

  # $software_version = $faker->software_version;

  # "0.4.5"

=back

=cut

=head2 telephone_number

  telephone_number(HashRef $data) (Str)

The telephone_number method returns a random telephone number.

I<Since C<1.10>>

=over 4

=item telephone_number example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $telephone_number = $faker->telephone_number;

  # "01408446845"

  # $telephone_number = $faker->telephone_number;

  # "769-454-4390"

  # $telephone_number = $faker->telephone_number;

  # "1-822-037-0225x82882"

=back

=cut

=head2 user_login

  user_login(HashRef $data) (Str)

The user_login method returns a random user login.

I<Since C<1.10>>

=over 4

=item user_login example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $user_login = $faker->user_login;

  # "Russel44"

  # $user_login = $faker->user_login;

  # "aMayer7694"

  # $user_login = $faker->user_login;

  # "Amalia89"

=back

=cut

=head2 user_password

  user_password(HashRef $data) (Str)

The user_password method returns a random user password.

I<Since C<1.10>>

=over 4

=item user_password example 1

  package main;

  use Faker;

  my $faker = Faker->new('en-us');

  # my $user_password = $faker->user_password;

  # "48R+a}[Lb?&0725"

  # $user_password = $faker->user_password;

  # ",0w\$h4155>*0M"

  # $user_password = $faker->user_password;

  # ")P2^'q695a}8GX"

=back

=cut

=head1 FEATURES

This package provides the following features:

=cut

=over 4

=item plugins-feature

This package loads and dispatches calls to plugins (the fake data generators)
which allow for extending the library in environment-specific ways.

B<example 1>

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

B<example 2>

  package Faker::Plugin::HttpContentType;

  use base 'Faker::Plugin';

  sub execute {
    'video/mpeg'
  }

  package main;

  my $plugin = Faker::Plugin::HttpContentType->new;

  my $http_content_type = $plugin->execute;

  # "video/mpeg"

=back

=over 4

=item locales-feature

This package can be configured to return localized fake data, typically
organized under namespaces specific to the locale specified.

B<example 1>

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

B<example 2>

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

B<example 3>

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

=back

=over 4

=item caching-feature

Often one generator's fake data is composed of the output from other
generators. Caching can be used to make generators faster, and to make fake
data more realistic.

B<example 1>

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

=back

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut
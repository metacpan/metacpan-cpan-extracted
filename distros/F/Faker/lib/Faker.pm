# ABSTRACT: Extensible Fake Data Generator
package Faker;

use Faker::Base;
use Faker::Function qw(confess tryload);

our $VERSION = '0.12'; # VERSION

has locale => (
    is      => 'ro',
    isa     => STRING,
    default => 'en_US',
);

has namespace => (
    is      => 'ro',
    isa     => STRING,
    default => 'Faker::Provider',
);

has providers => (
    is      => 'ro',
    isa     => HASH,
    default => fun {{}},
);

method provider (STRING $name) {
    my $providers = $self->providers;
    my $namespace = $self->namespace;
    my $locale    = $self->locale;
    my $default   = 'en_US';

    return $providers->{$name}
        if $providers->{$name};

    my @classes;
    my $explicit  = $locale && $locale ne $default;

    push @classes, join '::', $namespace, $locale, $name if $explicit;
    push @classes, join '::', $namespace, $default, $name;
    push @classes, join '::', $namespace, $name;

    for my $class (@classes) {
        next unless tryload $class;
        return $providers->{$name} = $class->new(factory => $self);
    }

    my $classes = join ' or ', @classes;
    confess "Unable to locate or load provider $classes";
}

method address_city_name (@args) {
    $self->provider('Address')->city_name(@args);
}

method address_city_prefix (@args) {
    $self->provider('Address')->city_prefix(@args);
}

method address_city_suffix (@args) {
    $self->provider('Address')->city_suffix(@args);
}

method address_country_name (@args) {
    $self->provider('Address')->country_name(@args);
}

method address_latitude (@args) {
    $self->provider('Address')->latitude(@args);
}

method address_line1 (@args) {
    $self->provider('Address')->line1(@args);
}

method address_line2 (@args) {
    $self->provider('Address')->line2(@args);
}

method address_lines (@args) {
    $self->provider('Address')->lines(@args);
}

method address_longitude (@args) {
    $self->provider('Address')->longitude(@args);
}

method address_number (@args) {
    $self->provider('Address')->number(@args);
}

method address_postal_code (@args) {
    $self->provider('Address')->postal_code(@args);
}

method address_state_abbr (@args) {
    $self->provider('Address')->state_abbr(@args);
}

method address_state_name (@args) {
    $self->provider('Address')->state_name(@args);
}

method address_street_name (@args) {
    $self->provider('Address')->street_name(@args);
}

method address_street_suffix (@args) {
    $self->provider('Address')->street_suffix(@args);
}

method color_hex_code (@args) {
    $self->provider('Color')->hex_code(@args);
}

method color_name (@args) {
    $self->provider('Color')->name(@args);
}

method color_rgbcolors (@args) {
    $self->provider('Color')->rgbcolors(@args);
}

method color_rgbcolors_array (@args) {
    $self->provider('Color')->rgbcolors_array(@args);
}

method color_rgbcolors_css (@args) {
    $self->provider('Color')->rgbcolors_css(@args);
}

method color_safe_hex_code (@args) {
    $self->provider('Color')->safe_hex_code(@args);
}

method color_safe_name (@args) {
    $self->provider('Color')->safe_name(@args);
}

method company_buzzword_type1 (@args) {
    $self->provider('Company')->buzzword_type1(@args);
}

method company_buzzword_type2 (@args) {
    $self->provider('Company')->buzzword_type2(@args);
}

method company_buzzword_type3 (@args) {
    $self->provider('Company')->buzzword_type3(@args);
}

method company_description (@args) {
    $self->provider('Company')->description(@args);
}

method company_jargon_buzz_word (@args) {
    $self->provider('Company')->jargon_buzz_word(@args);
}

method company_jargon_edge_word (@args) {
    $self->provider('Company')->jargon_edge_word(@args);
}

method company_jargon_prop_word (@args) {
    $self->provider('Company')->jargon_prop_word(@args);
}

method company_name (@args) {
    $self->provider('Company')->name(@args);
}

method company_name_suffix (@args) {
    $self->provider('Company')->name_suffix(@args);
}

method company_tagline (@args) {
    $self->provider('Company')->tagline(@args);
}

method internet_domain_name (@args) {
    $self->provider('Internet')->domain_name(@args);
}

method internet_domain_word (@args) {
    $self->provider('Internet')->domain_word(@args);
}

method internet_email_address (@args) {
    $self->provider('Internet')->email_address(@args);
}

method internet_email_domain (@args) {
    $self->provider('Internet')->email_domain(@args);
}

method internet_ip_address (@args) {
    $self->provider('Internet')->ip_address(@args);
}

method internet_ip_address_v4 (@args) {
    $self->provider('Internet')->ip_address_v4(@args);
}

method internet_ip_address_v6 (@args) {
    $self->provider('Internet')->ip_address_v6(@args);
}

method internet_root_domain (@args) {
    $self->provider('Internet')->root_domain(@args);
}

method internet_url (@args) {
    $self->provider('Internet')->url(@args);
}

method lorem_paragraph (@args) {
    $self->provider('Lorem')->paragraph(@args);
}

method lorem_paragraphs (@args) {
    $self->provider('Lorem')->paragraphs(@args);
}

method lorem_sentence (@args) {
    $self->provider('Lorem')->sentence(@args);
}

method lorem_sentences (@args) {
    $self->provider('Lorem')->sentences(@args);
}

method lorem_word (@args) {
    $self->provider('Lorem')->word(@args);
}

method lorem_words (@args) {
    $self->provider('Lorem')->words(@args);
}

method person_first_name (@args) {
    $self->provider('Person')->first_name(@args);
}

method person_last_name (@args) {
    $self->provider('Person')->last_name(@args);
}

method person_name (@args) {
    $self->provider('Person')->name(@args);
}

method person_name_prefix (@args) {
    $self->provider('Person')->name_prefix(@args);
}

method person_name_suffix (@args) {
    $self->provider('Person')->name_suffix(@args);
}

method person_username (@args) {
    $self->provider('Person')->username(@args);
}

method telephone_number (@args) {
    $self->provider('Telephone')->number(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker - Extensible Fake Data Generator

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;

    my $faker = Faker->new;

    my $address   = $faker->provider('Address');
    my $color     = $faker->provider('Color');
    my $company   = $faker->provider('Company');
    my $internet  = $faker->provider('Internet');
    my $lorem     = $faker->provider('Lorem');
    my $payment   = $faker->provider('Payment');
    my $person    = $faker->provider('Person');
    my $telephone = $faker->provider('Telephone');

    say $address->lines;
    say $color->name;
    say $company->name;
    say $internet->ip_address;
    say $lorem->sentences;
    say $payment->card_number;
    say $person->username;
    say $telephone->number;

    # or

    say $faker->address_lines;
    say $faker->color_name;
    say $faker->company_name;
    say $faker->internet_ip_address;
    say $faker->lorem_sentences;
    say $faker->payment_card_number;
    say $faker->person_username;
    say $faker->telephone_number;

=head1 DESCRIPTION

Faker is a Perl library that generates fake data for you. Whether you need to
bootstrap your database, create good-looking XML documents, fill-in your
persistence to stress test it, or anonymize data taken from a production
service, Faker makes it easy to generate fake data. B<Note: This is an early
release available for testing and feedback and as such is subject to change.>

=head1 ATTRIBUTES

=head2 namespace

    $faker->namespace('MyApp::FakeData');

The namespace attribute contains the namespace from which providers will be
loaded. This attribute defaults to Faker::Provider.

=head2 locale

    $faker->locale('en_US');

The locale attribute contains the locale string which is concatenated with the
namespace attribute to load fake data which is locale-specific.

=head1 METHODS

=head2 provider

    $faker->provider('Company'); # Faker::Provider::en_US::Company

The provider method uses the namespace and locale attributes to load a
particular provider which provides methods to generate fake data.

=head2 address_city_name

    $faker->address_city_name; # Leathaville

The address_city_name method generates a random ficticious city name. This
method is a proxy method which is the equivilent of calling the C<city_name>
method on the L<Faker::Provider::Address> class.

=head2 address_city_prefix

    $faker->address_city_prefix; # East

The address_city_prefix method generates a random ficticious city prefix. This
method is a proxy method which is the equivilent of calling the C<city_prefix>
method on the L<Faker::Provider::en_US::Address> class.

=head2 address_city_suffix

    $faker->address_city_suffix; # town

The address_city_suffix method generates a random ficticious city suffix. This
method is a proxy method which is the equivilent of calling the C<city_suffix>
method on the L<Faker::Provider::Address> class.

=head2 address_country_name

    $faker->address_country_name; # Maldives

The address_country_name method generates a random ficticious country name.
This method is a proxy method which is the equivilent of calling the
C<country_name> method on the L<Faker::Provider::en_US::Address> class.

=head2 address_latitude

    $faker->address_latitude; # 71.339800

The address_latitude method generates a random ficticious latitude point. This
method is a proxy method which is the equivilent of calling the C<latitude>
method on the L<Faker::Provider::Address> class.

=head2 address_line1

    $faker->address_line1; # 55 Wolf Street

The address_line1 method generates a random ficticious street address. This
method is a proxy method which is the equivilent of calling the C<line1> method
on the L<Faker::Provider::Address> class.

=head2 address_line2

    $faker->address_line2; # Apt. 097

The address_line2 method generates a random ficticious address line2. This
method is a proxy method which is the equivilent of calling the C<line2> method
on the L<Faker::Provider::en_US::Address> class.

=head2 address_lines

    $faker->address_lines; # 23 West Parkway, Antoinetteford, 57654-9772

The address_lines method generates a random ficticious stree address. This
method is a proxy method which is the equivilent of calling the C<lines> method
on the L<Faker::Provider::Address> class.

=head2 address_longitude

    $faker->address_longitude; # 40.987408

The address_longitude method generates a random ficticious longitude point.
This method is a proxy method which is the equivilent of calling the
C<longitude> method on the L<Faker::Provider::Address> class.

=head2 address_number

    $faker->address_number; # 5

The address_number method generates a random ficticious street number. This
method is a proxy method which is the equivilent of calling the C<number>
method on the L<Faker::Provider::Address> class.

=head2 address_postal_code

    $faker->address_postal_code; # 54708-5923

The address_postal_code method generates a random ficticious postal code. This
method is a proxy method which is the equivilent of calling the C<postal_code>
method on the L<Faker::Provider::Address> class.

=head2 address_state_abbr

    $faker->address_state_abbr; # MT

The address_state_abbr method generates a random ficticious state abbr. This
method is a proxy method which is the equivilent of calling the C<state_abbr>
method on the L<Faker::Provider::en_US::Address> class.

=head2 address_state_name

    $faker->address_state_name; # Missouri

The address_state_name method generates a random ficticious state name. This
method is a proxy method which is the equivilent of calling the C<state_name>
method on the L<Faker::Provider::en_US::Address> class.

=head2 address_street_name

    $faker->address_street_name; # Gottlieb Avenue

The address_street_name method generates a random ficticious street name. This
method is a proxy method which is the equivilent of calling the C<street_name>
method on the L<Faker::Provider::Address> class.

=head2 address_street_suffix

    $faker->address_street_suffix; # Street

The address_street_suffix method generates a random ficticious street suffix.
This method is a proxy method which is the equivilent of calling the
C<street_suffix> method on the L<Faker::Provider::Address> class.

=head2 color_hex_code

    $faker->color_hex_code; # #f69e17

The color_hex_code method generates a random ficticious hex color. This method
is a proxy method which is the equivilent of calling the C<hex_code> method on
the L<Faker::Provider::Color> class.

=head2 color_name

    $faker->color_name; # DarkBlue

The color_name method generates a random ficticious color name. This method is
a proxy method which is the equivilent of calling the C<name> method on the
L<Faker::Provider::Color> class.

=head2 color_rgbcolors

    $faker->color_rgbcolors; # 191,5,180

The color_rgbcolors method generates a random ficticious rgb colors. This
method is a proxy method which is the equivilent of calling the C<rgbcolors>
method on the L<Faker::Provider::Color> class.

=head2 color_rgbcolors_array

    $faker->color_rgbcolors_array; # [217,103,213]

The color_rgbcolors_array method generates a random ficticious rgb colors. This
method is a proxy method which is the equivilent of calling the
C<rgbcolors_array> method on the L<Faker::Provider::Color> class.

=head2 color_rgbcolors_css

    $faker->color_rgbcolors_css; # rgb(173,240,91)

The color_rgbcolors_css method generates a random ficticious rgbcolors for css.
This method is a proxy method which is the equivilent of calling the
C<rgbcolors_css> method on the L<Faker::Provider::Color> class.

=head2 color_safe_hex_code

    $faker->color_safe_hex_code; # #ff003e

The color_safe_hex_code method generates a random ficticious safe hex color.
This method is a proxy method which is the equivilent of calling the
C<safe_hex_code> method on the L<Faker::Provider::Color> class.

=head2 color_safe_name

    $faker->color_safe_name; # fuchsia

The color_safe_name method generates a random ficticious safe color name. This
method is a proxy method which is the equivilent of calling the C<safe_name>
method on the L<Faker::Provider::Color> class.

=head2 company_buzzword_type1

    $faker->company_buzzword_type1; # synergize

The company_buzzword_type1 method generates a random ficticious buzzword type1.
This method is a proxy method which is the equivilent of calling the
C<buzzword_type1> method on the L<Faker::Provider::en_US::Company> class.

=head2 company_buzzword_type2

    $faker->company_buzzword_type2; # vertical

The company_buzzword_type2 method generates a random ficticious buzzword type2.
This method is a proxy method which is the equivilent of calling the
C<buzzword_type2> method on the L<Faker::Provider::en_US::Company> class.

=head2 company_buzzword_type3

    $faker->company_buzzword_type3; # methodologies

The company_buzzword_type3 method generates a random ficticious buzzword type3.
This method is a proxy method which is the equivilent of calling the
C<buzzword_type3> method on the L<Faker::Provider::en_US::Company> class.

=head2 company_description

    $faker->company_description; # Delivers discrete processimprovement

The company_description method generates a random ficticious description. This
method is a proxy method which is the equivilent of calling the C<description>
method on the L<Faker::Provider::en_US::Company> class.

=head2 company_jargon_buzz_word

    $faker->company_jargon_buzz_word; # encryption

The company_jargon_buzz_word method generates a random ficticious jargon buzz
word. This method is a proxy method which is the equivilent of calling the
C<jargon_buzz_word> method on the L<Faker::Provider::en_US::Company> class.

=head2 company_jargon_edge_word

    $faker->company_jargon_edge_word; # Public-key

The company_jargon_edge_word method generates a random ficticious jargon edge
word. This method is a proxy method which is the equivilent of calling the
C<jargon_edge_word> method on the L<Faker::Provider::en_US::Company> class.

=head2 company_jargon_prop_word

    $faker->company_jargon_prop_word; # upward-trending

The company_jargon_prop_word method generates a random ficticious jargon
proposition word. This method is a proxy method which is the equivilent of
calling the C<jargon_prop_word> method on the
L<Faker::Provider::en_US::Company> class.

=head2 company_name

    $faker->company_name; # Quitzon Inc.

The company_name method generates a random ficticious company name. This method
is a proxy method which is the equivilent of calling the C<name> method on the
L<Faker::Provider::Company> class.

=head2 company_name_suffix

    $faker->company_name_suffix; # Inc.

The company_name_suffix method generates a random ficticious company name
suffix. This method is a proxy method which is the equivilent of calling the
C<name_suffix> method on the L<Faker::Provider::Company> class.

=head2 company_tagline

    $faker->company_tagline; # mindshare customized seize

The company_tagline method generates a random ficticious tagline. This method
is a proxy method which is the equivilent of calling the C<tagline> method on
the L<Faker::Provider::en_US::Company> class.

=head2 internet_domain_name

    $faker->internet_domain_name; # bauch-co.net

The internet_domain_name method generates a random ficticious domain name. This
method is a proxy method which is the equivilent of calling the C<domain_name>
method on the L<Faker::Provider::Internet> class.

=head2 internet_domain_word

    $faker->internet_domain_word; # jerde-gulgowski

The internet_domain_word method generates a random ficticious domain word. This
method is a proxy method which is the equivilent of calling the C<domain_word>
method on the L<Faker::Provider::Internet> class.

=head2 internet_email_address

    $faker->internet_email_address; # jessy.kunze\@brekke-cartwright.net

The internet_email_address method generates a random ficticious email address.
This method is a proxy method which is the equivilent of calling the
C<email_address> method on the L<Faker::Provider::Internet> class.

=head2 internet_email_domain

    $faker->internet_email_domain; # gmail.com

The internet_email_domain method generates a random ficticious email domain.
This method is a proxy method which is the equivilent of calling the
C<email_domain> method on the L<Faker::Provider::Internet> class.

=head2 internet_ip_address

    $faker->internet_ip_address; # 151.127.26.209

The internet_ip_address method generates a random ficticious ip address. This
method is a proxy method which is the equivilent of calling the C<ip_address>
method on the L<Faker::Provider::Internet> class.

=head2 internet_ip_address_v4

    $faker->internet_ip_address_v4; # 165.132.192.226

The internet_ip_address_v4 method generates a random ficticious ip address v4.
This method is a proxy method which is the equivilent of calling the
C<ip_address_v4> method on the L<Faker::Provider::Internet> class.

=head2 internet_ip_address_v6

    $faker->internet_ip_address_v6; # 8ae5:e9ac:e5fb:4fc2:7763:fa5e:aaf4:8120

The internet_ip_address_v6 method generates a random ficticious ip address v6.
This method is a proxy method which is the equivilent of calling the
C<ip_address_v6> method on the L<Faker::Provider::Internet> class.

=head2 internet_root_domain

    $faker->internet_root_domain; # org

The internet_root_domain method generates a random ficticious root domain. This
method is a proxy method which is the equivilent of calling the C<root_domain>
method on the L<Faker::Provider::Internet> class.

=head2 internet_url

    $faker->internet_url; # http://bauch-runte-and-ondricka.info/

The internet_url method generates a random ficticious url. This method is a
proxy method which is the equivilent of calling the C<url> method on the
L<Faker::Provider::Internet> class.

=head2 lorem_paragraph

    $faker->lorem_paragraph;
    # velit vitae molestiae ut dolores. amet est qui rem placeat accusamus
    # accusamus labore. qui quidem expedita non.\n\n

The lorem_paragraph method generates a random ficticious paragraph. This method
is a proxy method which is the equivilent of calling the C<paragraph> method on
the L<Faker::Provider::Lorem> class.

=head2 lorem_paragraphs

    $faker->lorem_paragraphs;
    # nobis minus aut nam. odio autem fuga et reprehenderit. magnam eius et
    # possimus.\n\nvelit nam vel nam harum maxime id dolorum. sed ut molestiae
    # cumque voluptas aspernatur quidem aut dicta. officia laborum dolorem ab
    # ipsa deleniti.\n\n

The lorem_paragraphs method generates a random ficticious paragraphs. This
method is a proxy method which is the equivilent of calling the C<paragraphs>
method on the L<Faker::Provider::Lorem> class.

=head2 lorem_sentence

    $faker->lorem_sentence; # animi iure quo assumenda est.

The lorem_sentence method generates a random ficticious sentence. This method
is a proxy method which is the equivilent of calling the C<sentence> method on
the L<Faker::Provider::Lorem> class.

=head2 lorem_sentences

    $faker->lorem_sentences;
    # placeat beatae qui aliquid. distinctio quasi repudiandae hic id.
    # explicabo culpa debitis excepturi aliquam quo ea.

The lorem_sentences method generates a random ficticious sentences. This method
is a proxy method which is the equivilent of calling the C<sentences> method on
the L<Faker::Provider::Lorem> class.

=head2 lorem_word

    $faker->lorem_word; # quidem

The lorem_word method generates a random ficticious word. This method is a
proxy method which is the equivilent of calling the C<word> method on the
L<Faker::Provider::Lorem> class.

=head2 lorem_words

    $faker->lorem_words; # voluptatibus officia delectus unde sed

The lorem_words method generates a random ficticious words. This method
is a proxy method which is the equivilent of calling the C<words> method on
the L<Faker::Provider::Lorem> class.

=head2 payment_card_expiration

    $faker->payment_card_expiration; # 02/17

The payment_card_expiration method generates a random ficticious credit card
expiration date. This method is a proxy method which is the equivilent of
calling the C<card_expiration> method on the L<Faker::Provider::Payment> class.

=head2 payment_card_number

    $faker->payment_card_number; # 37814449158323

The payment_card_number method generates a random ficticious credit card
number. This method is a proxy method which is the equivilent of calling the
C<card_number> method on the L<Faker::Provider::Payment> class.

=head2 payment_vendor

    $faker->payment_vendor; # MasterCard

The payment_vendor method generates a random ficticious credit card vendor.
This method is a proxy method which is the equivilent of calling the C<vendor>
method on the L<Faker::Provider::Payment> class.

=head2 person_first_name

    $faker->person_first_name; # John

The person_first_name method generates a random ficticious first name. This
method is a proxy method which is the equivilent of calling the C<first_name>
method on the L<Faker::Provider::Person> class.

=head2 person_last_name

    $faker->person_last_name; # Doe

The person_last_name method generates a random ficticious last name. This
method is a proxy method which is the equivilent of calling the C<last_name>
method on the L<Faker::Provider::Person> class.

=head2 person_name

    $faker->person_name; # Jane Doe

The person_name method generates a random ficticious full name. This method is
a proxy method which is the equivilent of calling the C<name> method on the
L<Faker::Provider::Person> class.

=head2 person_name_prefix

    $faker->person_name_prefix; # Miss

The person_name_prefix method generates a random ficticious name prefix. This
method is a proxy method which is the equivilent of calling the C<name_prefix>
method on the L<Faker::Provider::en_US::Person> class.

=head2 person_name_suffix

    $faker->person_name_suffix; # III

The person_name_suffix method generates a random ficticious name suffix. This
method is a proxy method which is the equivilent of calling the C<name_suffix>
method on the L<Faker::Provider::en_US::Person> class.

=head2 person_username

    $faker->person_username; # Jane.Doe

The person_username method generates a random ficticious username. This method
is a proxy method which is the equivilent of calling the C<username> method on
the L<Faker::Provider::Person> class.

=head2 telephone_number

    $faker->telephone_number; # (111) 456-1127

The telephone_number method generates a random ficticious telephone number.
This method is a proxy method which is the equivilent of calling the C<number>
method on the L<Faker::Provider::Telephone> class.

=head1 ACKNOWLEDGEMENTS

Some parts of this library were adopted from the following implementations.

=over 4

=item *

JS Faker L<https://github.com/Marak/faker.js>

=item *

PHP Faker L<https://github.com/fzaninotto/Faker>

=item *

Python Faker L<https://github.com/joke2k/faker>

=item *

Ruby Faker L<https://github.com/stympy/faker>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# NAME

Faker

# ABSTRACT

Extensible Fake Data Generator

# SYNOPSIS

    package main;

    use Faker;

    my $f = Faker->new;

# DESCRIPTION

This package provides generates fake data for you. Whether you need to
bootstrap your database, create good-looking XML documents, fill-in your
persistence to stress test it, or anonymize data taken from a production
service, Faker makes it easy to generate fake data.

# INTEGRATES

This package integrates behaviors from:

[Data::Object::Role::Pluggable](https://metacpan.org/pod/Data::Object::Role::Pluggable)

[Data::Object::Role::Proxyable](https://metacpan.org/pod/Data::Object::Role::Proxyable)

[Data::Object::Role::Throwable](https://metacpan.org/pod/Data::Object::Role::Throwable)

# LIBRARIES

This package uses type constraints from:

[Types::Standard](https://metacpan.org/pod/Types::Standard)

# SCENARIOS

This package supports the following scenarios:

## autoloading

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

## autoloading-under

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

# METHODS

This package implements the following methods:

## address\_city\_name

    address_city_name(Any %args) : Str

The address\_city\_name method returns a random fake address city name. See the
[Faker::Plugin::AddressCityName](https://metacpan.org/pod/Faker::Plugin::AddressCityName) plugin for more information.

- address\_city\_name example #1

        # given: synopsis

        $f->address_city_name

        # Lolastad

## address\_city\_prefix

    address_city_prefix(Any %args) : Str

The address\_city\_prefix method returns a random fake address city prefix. See
the [Faker::Plugin::AddressCityPrefix](https://metacpan.org/pod/Faker::Plugin::AddressCityPrefix) plugin for more information.

- address\_city\_prefix example #1

        # given: synopsis

        $f->address_city_prefix

        # South

## address\_city\_suffix

    address_city_suffix(Any %args) : Str

The address\_city\_suffix method returns a random fake address city suffix. See
the [Faker::Plugin::AddressCitySuffix](https://metacpan.org/pod/Faker::Plugin::AddressCitySuffix) plugin for more information.

- address\_city\_suffix example #1

        # given: synopsis

        $f->address_city_suffix

        # berg

## address\_country\_name

    address_country_name(Any %args) : Str

The address\_country\_name method returns a random fake address country name. See
the [Faker::Plugin::AddressCountryName](https://metacpan.org/pod/Faker::Plugin::AddressCountryName) plugin for more information.

- address\_country\_name example #1

        # given: synopsis

        $f->address_country_name

        # Iraq

## address\_latitude

    address_latitude(Any %args) : Str

The address\_latitude method returns a random fake address latitude. See the
[Faker::Plugin::Address::Latitude](https://metacpan.org/pod/Faker::Plugin::Address::Latitude) plugin for more information.

- address\_latitude example #1

        # given: synopsis

        $f->address_latitude

        # 2338952

## address\_line1

    address_line1(Any %args) : Str

The address\_line1 method returns a random fake address line1. See the
[Faker::Plugin::AddressLine1](https://metacpan.org/pod/Faker::Plugin::AddressLine1) plugin for more information.

- address\_line1 example #1

        # given: synopsis

        $f->address_line1

        # 4 Schaefer Parkway

## address\_line2

    address_line2(Any %args) : Str

The address\_line2 method returns a random fake address line2. See the
[Faker::Plugin::AddressLine2](https://metacpan.org/pod/Faker::Plugin::AddressLine2) plugin for more information.

- address\_line2 example #1

        # given: synopsis

        $f->address_line2

        # Apt. 092

## address\_lines

    address_lines(Any %args) : Str

The address\_lines method returns a random fake address lines. See the
[Faker::Plugin::AddressLines](https://metacpan.org/pod/Faker::Plugin::AddressLines) plugin for more information.

- address\_lines example #1

        # given: synopsis

        $f->address_lines

        # 3587 Thiel Avenue
        # Suite 335
        # Tobinmouth, ME 96440-0239

## address\_longitude

    address_longitude(Any %args) : Str

The address\_longitude method returns a random fake address longitude. See the
[Faker::Plugin::AddressLongitude](https://metacpan.org/pod/Faker::Plugin::AddressLongitude) plugin for more information.

- address\_longitude example #1

        # given: synopsis

        $f->address_longitude

        # -28.920235

## address\_number

    address_number(Any %args) : Str

The address\_number method returns a random fake address number. See the
[Faker::Plugin::AddressNumber](https://metacpan.org/pod/Faker::Plugin::AddressNumber) plugin for more information.

- address\_number example #1

        # given: synopsis

        $f->address_number

        # 67

## address\_postal\_code

    address_postal_code(Any %args) : Str

The address\_postal\_code method returns a random fake address postal code. See
the [Faker::Plugin::AddressPostalCode](https://metacpan.org/pod/Faker::Plugin::AddressPostalCode) plugin for more information.

- address\_postal\_code example #1

        # given: synopsis

        $f->address_postal_code

        # 02475

## address\_state\_abbr

    address_state_abbr(Any %args) : Str

The address\_state\_abbr method returns a random fake address state abbr. See the
[Faker::Plugin::AddressStateAbbr](https://metacpan.org/pod/Faker::Plugin::AddressStateAbbr) plugin for more information.

- address\_state\_abbr example #1

        # given: synopsis

        $f->address_state_abbr

        # OH

## address\_state\_name

    address_state_name(Any %args) : Str

The address\_state\_name method returns a random fake address state name. See the
[Faker::Plugin::AddressStateName](https://metacpan.org/pod/Faker::Plugin::AddressStateName) plugin for more information.

- address\_state\_name example #1

        # given: synopsis

        $f->address_state_name

        # Georgia

## address\_street\_name

    address_street_name(Any %args) : Str

The address\_street\_name method returns a random fake address street name. See
the [Faker::Plugin::AddressStreetName](https://metacpan.org/pod/Faker::Plugin::AddressStreetName) plugin for more information.

- address\_street\_name example #1

        # given: synopsis

        $f->address_street_name

        # Reyna Avenue

## address\_street\_suffix

    address_street_suffix(Any %args) : Str

The address\_street\_suffix method returns a random fake address street suffix.
See the [Faker::Plugin::AddressStreetSuffix](https://metacpan.org/pod/Faker::Plugin::AddressStreetSuffix) plugin for more information.

- address\_street\_suffix example #1

        # given: synopsis

        $f->address_street_suffix

        # Avenue

## color\_hex\_code

    color_hex_code(Any %args) : Str

The color\_hex\_code method returns a random fake color hex code. See the
[Faker::Plugin::ColorHexCode](https://metacpan.org/pod/Faker::Plugin::ColorHexCode) plugin for more information.

- color\_hex\_code example #1

        # given: synopsis

        $f->color_hex_code

        # #b9fe40

## color\_name

    color_name(Any %args) : Str

The color\_name method returns a random fake color name. See the
[Faker::Plugin::ColorName](https://metacpan.org/pod/Faker::Plugin::ColorName) plugin for more information.

- color\_name example #1

        # given: synopsis

        $f->color_name

        # LightSteelBlue

## color\_rgbcolors

    color_rgbcolors(Any %args) : Str

The color\_rgbcolors method returns a random fake color rgbcolors. See the
[Faker::Plugin::ColorRgbcolors](https://metacpan.org/pod/Faker::Plugin::ColorRgbcolors) plugin for more information.

- color\_rgbcolors example #1

        # given: synopsis

        $f->color_rgbcolors

        # 77,186,28

## color\_rgbcolors\_array

    color_rgbcolors_array(Any %args) : ArrayRef

The color\_rgbcolors\_array method returns a random fake color rgbcolors array.
See the [Faker::Plugin::ColorRgbcolorsArray](https://metacpan.org/pod/Faker::Plugin::ColorRgbcolorsArray) plugin for more information.

- color\_rgbcolors\_array example #1

        # given: synopsis

        $f->color_rgbcolors_array

        # [77,186,28]

## color\_rgbcolors\_css

    color_rgbcolors_css(Any %args) : Str

The color\_rgbcolors\_css method returns a random fake color rgbcolors css. See
the [Faker::Plugin::ColorRgbcolorsCss](https://metacpan.org/pod/Faker::Plugin::ColorRgbcolorsCss) plugin for more information.

- color\_rgbcolors\_css example #1

        # given: synopsis

        $f->color_rgbcolors_css

        # rgb(115,98,44)

## color\_safe\_hex\_code

    color_safe_hex_code(Any %args) : Str

The color\_safe\_hex\_code method returns a random fake color safe hex code. See
the [Faker::Plugin::ColorSafeHexCode](https://metacpan.org/pod/Faker::Plugin::ColorSafeHexCode) plugin for more information.

- color\_safe\_hex\_code example #1

        # given: synopsis

        $f->color_safe_hex_code

        # #ff0078

## color\_safe\_name

    color_safe_name(Any %args) : Str

The color\_safe\_name method returns a random fake color safe name. See the
[Faker::Plugin::ColorSafeName](https://metacpan.org/pod/Faker::Plugin::ColorSafeName) plugin for more information.

- color\_safe\_name example #1

        # given: synopsis

        $f->color_safe_name

        # blue

## company\_buzzword\_type1

    company_buzzword_type1(Any %args) : Str

The company\_buzzword\_type1 method returns a random fake company buzzword type1.
See the [Faker::Plugin::CompanyBuzzwordType1](https://metacpan.org/pod/Faker::Plugin::CompanyBuzzwordType1) plugin for more information.

- company\_buzzword\_type1 example #1

        # given: synopsis

        $f->company_buzzword_type1

        # implement

## company\_buzzword\_type2

    company_buzzword_type2(Any %args) : Str

The company\_buzzword\_type2 method returns a random fake company buzzword type2.
See the [Faker::Plugin::CompanyBuzzwordType2](https://metacpan.org/pod/Faker::Plugin::CompanyBuzzwordType2) plugin for more information.

- company\_buzzword\_type2 example #1

        # given: synopsis

        $f->company_buzzword_type2

        # interactive

## company\_buzzword\_type3

    company_buzzword_type3(Any %args) : Str

The company\_buzzword\_type3 method returns a random fake company buzzword type3.
See the [Faker::Plugin::CompanyBuzzwordType3](https://metacpan.org/pod/Faker::Plugin::CompanyBuzzwordType3) plugin for more information.

- company\_buzzword\_type3 example #1

        # given: synopsis

        $f->company_buzzword_type3

        # bandwidth

## company\_description

    company_description(Any %args) : Str

The company\_description method returns a random fake company description. See
the [Faker::Plugin::CompanyDescription](https://metacpan.org/pod/Faker::Plugin::CompanyDescription) plugin for more information.

- company\_description example #1

        # given: synopsis

        $f->company_description

        # Excels at impactful pre-emptive decisions

## company\_jargon\_buzz\_word

    company_jargon_buzz_word(Any %args) : Str

The company\_jargon\_buzz\_word method returns a random fake company jargon buzz
word. See the [Faker::Plugin::CompanyJargonBuzzWord](https://metacpan.org/pod/Faker::Plugin::CompanyJargonBuzzWord) plugin for more
information.

- company\_jargon\_buzz\_word example #1

        # given: synopsis

        $f->company_jargon_buzz_word

        # parallelism

## company\_jargon\_edge\_word

    company_jargon_edge_word(Any %args) : Str

The company\_jargon\_edge\_word method returns a random fake company jargon edge
word. See the [Faker::Plugin::CompanyJargonEdgeWord](https://metacpan.org/pod/Faker::Plugin::CompanyJargonEdgeWord) plugin for more
information.

- company\_jargon\_edge\_word example #1

        # given: synopsis

        $f->company_jargon_edge_word

        # Customer-focused

## company\_jargon\_prop\_word

    company_jargon_prop_word(Any %args) : Str

The company\_jargon\_prop\_word method returns a random fake company jargon prop
word. See the [Faker::Plugin::CompanyJargonPropWord](https://metacpan.org/pod/Faker::Plugin::CompanyJargonPropWord) plugin for more
information.

- company\_jargon\_prop\_word example #1

        # given: synopsis

        $f->company_jargon_prop_word

        # upward-trending

## company\_name

    company_name(Any %args) : Str

The company\_name method returns a random fake company name. See the
[Faker::Plugin::CompanyName](https://metacpan.org/pod/Faker::Plugin::CompanyName) plugin for more information.

- company\_name example #1

        # given: synopsis

        $f->company_name

        # Boehm, Rutherford and Roberts

## company\_name\_suffix

    company_name_suffix(Any %args) : Str

The company\_name\_suffix method returns a random fake company name suffix. See
the [Faker::Plugin::CompanyNameSuffix](https://metacpan.org/pod/Faker::Plugin::CompanyNameSuffix) plugin for more information.

- company\_name\_suffix example #1

        # given: synopsis

        $f->company_name_suffix

        # Group

## company\_tagline

    company_tagline(Any %args) : Str

The company\_tagline method returns a random fake company tagline. See the
[Faker::Plugin::CompanyTagline](https://metacpan.org/pod/Faker::Plugin::CompanyTagline) plugin for more information.

- company\_tagline example #1

        # given: synopsis

        $f->company_tagline

        # cultivate end-to-end partnerships

## internet\_domain\_name

    internet_domain_name(Any %args) : Str

The internet\_domain\_name method returns a random fake internet domain name. See
the [Faker::Plugin::InternetDomainName](https://metacpan.org/pod/Faker::Plugin::InternetDomainName) plugin for more information.

- internet\_domain\_name example #1

        # given: synopsis

        $f->internet_domain_name

        # kassulke-cruickshank.biz

## internet\_domain\_word

    internet_domain_word(Any %args) : Str

The internet\_domain\_word method returns a random fake internet domain word. See
the [Faker::Plugin::InternetDomainWord](https://metacpan.org/pod/Faker::Plugin::InternetDomainWord) plugin for more information.

- internet\_domain\_word example #1

        # given: synopsis

        $f->internet_domain_word

        # raynor-beier

## internet\_email\_address

    internet_email_address(Any %args) : Str

The internet\_email\_address method returns a random fake internet email address.
See the [Faker::Plugin::InternetEmailAddress](https://metacpan.org/pod/Faker::Plugin::InternetEmailAddress) plugin for more information.

- internet\_email\_address example #1

        # given: synopsis

        $f->internet_email_address

        # rose@maggio-pfannerstill-and-marquardt.com

## internet\_email\_domain

    internet_email_domain(Any %args) : Str

The internet\_email\_domain method returns a random fake internet email domain.
See the [Faker::Plugin::InternetEmailDomain](https://metacpan.org/pod/Faker::Plugin::InternetEmailDomain) plugin for more information.

- internet\_email\_domain example #1

        # given: synopsis

        $f->internet_email_domain

        # gmail.com

## internet\_ip\_address

    internet_ip_address(Any %args) : Str

The internet\_ip\_address method returns a random fake internet ip address. See
the [Faker::Plugin::InternetIpAddress](https://metacpan.org/pod/Faker::Plugin::InternetIpAddress) plugin for more information.

- internet\_ip\_address example #1

        # given: synopsis

        $f->internet_ip_address

        # 193.199.217.87

## internet\_ip\_address\_v4

    internet_ip_address_v4(Any %args) : Str

The internet\_ip\_address\_v4 method returns a random fake internet ip address v4.
See the [Faker::Plugin::InternetIpAddressV4](https://metacpan.org/pod/Faker::Plugin::InternetIpAddressV4) plugin for more information.

- internet\_ip\_address\_v4 example #1

        # given: synopsis

        $f->internet_ip_address_v4

        # 45.212.129.22

## internet\_ip\_address\_v6

    internet_ip_address_v6(Any %args) : Str

The internet\_ip\_address\_v6 method returns a random fake internet ip address v6.
See the [Faker::Plugin::InternetIpAddressV6](https://metacpan.org/pod/Faker::Plugin::InternetIpAddressV6) plugin for more information.

- internet\_ip\_address\_v6 example #1

        # given: synopsis

        $f->internet_ip_address_v6

        # 4024:40e9:b107:681d:8ce1:bb12:3380:b476

## internet\_root\_domain

    internet_root_domain(Any %args) : Str

The internet\_root\_domain method returns a random fake internet root domain. See
the [Faker::Plugin::InternetRootDomain](https://metacpan.org/pod/Faker::Plugin::InternetRootDomain) plugin for more information.

- internet\_root\_domain example #1

        # given: synopsis

        $f->internet_root_domain

        # biz

## internet\_url

    internet_url(Any %args) : Str

The internet\_url method returns a random fake internet url. See the
[Faker::Plugin::InternetUrl](https://metacpan.org/pod/Faker::Plugin::InternetUrl) plugin for more information.

- internet\_url example #1

        # given: synopsis

        $f->internet_url

        # https://krajcik-goyette.biz/

## lorem\_paragraph

    lorem_paragraph(Any %args) : Str

The lorem\_paragraph method returns a random fake lorem paragraph. See the
[Faker::Plugin::LoremParagraph](https://metacpan.org/pod/Faker::Plugin::LoremParagraph) plugin for more information.

- lorem\_paragraph example #1

        # given: synopsis

        $f->lorem_paragraph

        # id tempore eum. vitae optio rerum enim nihil perspiciatis omnis et. ut
        # voluptates dicta qui culpa. a nam at nemo fugiat.

## lorem\_paragraphs

    lorem_paragraphs(Any %args) : Str

The lorem\_paragraphs method returns a random fake lorem paragraphs. See the
[Faker::Plugin::LoremParagraphs](https://metacpan.org/pod/Faker::Plugin::LoremParagraphs) plugin for more information.

- lorem\_paragraphs example #1

        # given: synopsis

        $f->lorem_paragraphs

        # modi minus pariatur accusamus possimus eaque id velit porro. voluptatum
        # natus saepe. non in quas est. ut quos autem occaecati quo.

        # saepe quae unde. vel hic consequuntur. quia aut ut nostrum amet. et
        # consequuntur occaecati.

## lorem\_sentence

    lorem_sentence(Any %args) : Str

The lorem\_sentence method returns a random fake lorem sentence. See the
[Faker::Plugin::LoremSentence](https://metacpan.org/pod/Faker::Plugin::LoremSentence) plugin for more information.

- lorem\_sentence example #1

        # given: synopsis

        $f->lorem_sentence

        # amet id id culpa reiciendis minima id corporis illum quas.

## lorem\_sentences

    lorem_sentences(Any %args) : Str

The lorem\_sentences method returns a random fake lorem sentences. See the
[Faker::Plugin::LoremSentences](https://metacpan.org/pod/Faker::Plugin::LoremSentences) plugin for more information.

- lorem\_sentences example #1

        # given: synopsis

        $f->lorem_sentences

        # laboriosam ipsam ipsum. animi accusantium quisquam repellendus. occaecati
        # itaque reiciendis perferendis exercitationem.

## lorem\_word

    lorem_word(Any %args) : Str

The lorem\_word method returns a random fake lorem word. See the
[Faker::Plugin::LoremWord](https://metacpan.org/pod/Faker::Plugin::LoremWord) plugin for more information.

- lorem\_word example #1

        # given: synopsis

        $f->lorem_word

        # quos

## lorem\_words

    lorem_words(Any %args) : Str

The lorem\_words method returns a random fake lorem words. See the
[Faker::Plugin::LoremWords](https://metacpan.org/pod/Faker::Plugin::LoremWords) plugin for more information.

- lorem\_words example #1

        # given: synopsis

        $f->lorem_words

        # autem assumenda commodi eum dolor

## payment\_card\_expiration

    payment_card_expiration(Any %args) : Str

The payment\_card\_expiration method returns a random fake payment card
expiration. See the [Faker::Plugin::PaymentCardExpiration](https://metacpan.org/pod/Faker::Plugin::PaymentCardExpiration) plugin for more
information.

- payment\_card\_expiration example #1

        # given: synopsis

        $f->payment_card_expiration

        # 01/21

## payment\_card\_number

    payment_card_number(Any %args) : Str

The payment\_card\_number method returns a random fake payment card number. See
the [Faker::Plugin::PaymentCardNumber](https://metacpan.org/pod/Faker::Plugin::PaymentCardNumber) plugin for more information.

- payment\_card\_number example #1

        # given: synopsis

        $f->payment_card_number

        # 544772628796996

## payment\_vendor

    payment_vendor(Any %args) : Str

The payment\_vendor method returns a random fake payment vendor. See the
[Faker::Plugin::PaymentVendor](https://metacpan.org/pod/Faker::Plugin::PaymentVendor) plugin for more information.

- payment\_vendor example #1

        # given: synopsis

        $f->payment_vendor

        # Visa

## person\_first\_name

    person_first_name(Any %args) : Str

The person\_first\_name method returns a random fake person first name. See the
[Faker::Plugin::PersonFirstName](https://metacpan.org/pod/Faker::Plugin::PersonFirstName) plugin for more information.

- person\_first\_name example #1

        # given: synopsis

        $f->person_first_name

        # Sandrine

## person\_last\_name

    person_last_name(Any %args) : Str

The person\_last\_name method returns a random fake person last name. See the
[Faker::Plugin::PersonLastName](https://metacpan.org/pod/Faker::Plugin::PersonLastName) plugin for more information.

- person\_last\_name example #1

        # given: synopsis

        $f->person_last_name

        # Langosh

## person\_name

    person_name(Any %args) : Str

The person\_name method returns a random fake person name. See the
[Faker::Plugin::PersonName](https://metacpan.org/pod/Faker::Plugin::PersonName) plugin for more information.

- person\_name example #1

        # given: synopsis

        $f->person_name

        # Eveline Wintheiser

## person\_name\_prefix

    person_name_prefix(Any %args) : Str

The person\_name\_prefix method returns a random fake person name prefix. See the
[Faker::Plugin::PersonNamePrefix](https://metacpan.org/pod/Faker::Plugin::PersonNamePrefix) plugin for more information.

- person\_name\_prefix example #1

        # given: synopsis

        $f->person_name_prefix

        # Ms.

## person\_name\_suffix

    person_name_suffix(Any %args) : Str

The person\_name\_suffix method returns a random fake person name suffix. See the
[Faker::Plugin::PersonNameSuffix](https://metacpan.org/pod/Faker::Plugin::PersonNameSuffix) plugin for more information.

- person\_name\_suffix example #1

        # given: synopsis

        $f->person_name_suffix

        # Sr.

## person\_username

    person_username(Any %args) : Str

The person\_username method returns a random fake person username. See the
[Faker::Plugin::PersonUsername](https://metacpan.org/pod/Faker::Plugin::PersonUsername) plugin for more information.

- person\_username example #1

        # given: synopsis

        $f->person_username

        # Cayla25

## telephone\_number

    telephone_number(Any %args) : Str

The telephone\_number method returns a random fake telephone number. See the
[Faker::Plugin::TelephoneNumber](https://metacpan.org/pod/Faker::Plugin::TelephoneNumber) plugin for more information.

- telephone\_number example #1

        # given: synopsis

        $f->telephone_number

        # 549-844-2061

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/iamalnewkirk/faker/blob/master/LICENSE).

# ACKNOWLEDGEMENTS

Parts of this library were inspired by the following implementations:

[PHP Faker](https://github.com/fzaninotto/Faker)

[Ruby Faker](https://github.com/stympy/faker)

[Python Faker](https://github.com/joke2k/faker)

[JS Faker](https://github.com/Marak/faker.js)

# PROJECT

[Wiki](https://github.com/iamalnewkirk/faker/wiki)

[Project](https://github.com/iamalnewkirk/faker)

[Initiatives](https://github.com/iamalnewkirk/faker/projects)

[Milestones](https://github.com/iamalnewkirk/faker/milestones)

[Contributing](https://github.com/iamalnewkirk/faker/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/iamalnewkirk/faker/issues)

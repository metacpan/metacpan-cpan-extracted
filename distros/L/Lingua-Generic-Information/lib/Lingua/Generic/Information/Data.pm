# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to provide information on languages


package Lingua::Generic::Information::Data;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.36;
use Data::Identifier::Wellknown;

use parent qw(Data::Identifier::Interface::Known);

our $VERSION = v0.01;

use constant {
    WK_SID => Data::Identifier->new(uuid => 'f87a38cb-fd13-4e15-866c-e49901adbec5')->register, # small-identifier
};

our %_sid_to_lti = (
    70 => 'en',
    71 => 'de',
    72 => 'nl',
    73 => 'es',
    74 => 'zh',

    240 => 'af',
    241 => 'sw',
    242 => 'hi',
    243 => 'ar',
    244 => 'fr',
    245 => 'bn',
    246 => 'pt',
    247 => 'ru',
    248 => 'id',
    249 => 'ur',
    250 => 'ja',
    251 => 'mr',
    252 => 'vi',
    253 => 'zu',
    254 => 'mi',

    320 => 'te',
    321 => 'ha',
    322 => 'tr',

    324 => 'tl',
    325 => 'ta',

    327 => 'ko',
    328 => 'th',
    329 => 'jv',
    330 => 'it',
    331 => 'gu',
    332 => 'am',
    333 => 'kn',

    343 => 'is',
    344 => 'uk',
    345 => 'no',
    346 => 'sv',
    347 => 'fi',
    348 => 'he',
    349 => 'ie',
    350 => 'ia',
    351 => 'eo',
);
Data::Identifier::Wellknown->announce(WK_SID, {map {$_ => Data::Identifier::Generate->language($_sid_to_lti{$_})} keys %_sid_to_lti});

my %_true_dimension = (
    genus   => Data::Identifier->new(uuid => '93981bc7-7d40-4f4c-af45-d1aa70983aca', tagname => 'genus'),
    numerus => Data::Identifier->new(uuid => '35389860-f302-40ec-b042-2806c5fa242f', tagname => 'numerus'),
    kasus   => Data::Identifier->new(uuid => '6ffa27e5-30ff-4bd0-ba09-cb35a5548be2', tagname => 'kasus'),
    person  => Data::Identifier->new(uuid => '548f28db-0ad8-47c0-8095-6d48cc674f52', tagname => 'person'),
    class   => Data::Identifier->new(uuid => 'a0adf296-9399-480b-8c37-c5502e912e6c', tagname => 'word-class'),
    type    => Data::Identifier->new(uuid => 'f4a362f9-d707-4fad-94d2-05375355f010', tagname => 'word-type'),
    mood    => Data::Identifier->new(uuid => '1d65b587-e5c8-4175-a670-77a8331a5748', tagname => 'word-mood'),
);
my %_pseudo_dimension = (
);

my %_values_by_dimension = (
    genus => {
        m   => Data::Identifier->new(uuid => '7eaf670b-62fc-4f89-8c66-b720123df586', displayname => 'masculine'),
        f   => Data::Identifier->new(uuid => 'a04ccda3-09df-4090-b576-086dbaad354d', displayname => 'feminine'),
        n   => Data::Identifier->new(uuid => '1adea8a9-54bb-4231-b457-377cc2c24f68', displayname => 'neuter'),
        u   => Data::Identifier->new(uuid => '8a7dd0c7-1057-4678-b7c2-b1fb6859531f', displayname => 'common'),
    },
    numerus => {
        1   => Data::Identifier->new(uuid => '686a8ab8-8883-427b-b276-96dcfa068361', displayname => 'singular'),
        2   => Data::Identifier->new(uuid => '70ec7c3a-5301-4f97-9b38-b17a0102e354', displayname => 'dual'),
        3   => Data::Identifier->new(uuid => 'bd29d648-30d8-4e68-9478-f129384f0bf7', displayname => 'trial'),
        4   => Data::Identifier->new(uuid => '4c26a62b-696e-4fc6-8ebd-b92c1b80a85e', displayname => 'quadral'),
        p   => Data::Identifier->new(uuid => 'd66d3fcd-f55d-4d32-ab93-252e99cd0c89', displayname => 'plural'),
        d   => Data::Identifier->new(uuid => '8e4b9658-5033-4b2c-a2e4-2852dc51efe0', displayname => 'distributive'),
    },
    kasus => {
        n   => Data::Identifier->new(uuid => '0a8657cc-f8b5-462c-b51b-590b6acfcab3', displayname => 'nominative'),
        d   => Data::Identifier->new(uuid => '1c41f140-31bf-4a57-a83c-6443d449974e', displayname => 'dative'),
        a   => Data::Identifier->new(uuid => '91ccbe48-e8a0-422d-a9fd-42314809f269', displayname => 'accusative'),
        g   => Data::Identifier->new(uuid => 'd13b0302-5b8d-49d1-885e-0accef98874c', displayname => 'genitive'),
    },
    person => {
        1   => Data::Identifier->new(uuid => '084736b8-19b9-432d-888e-5592b1e2e153', displayname => 'first-person'),
        2   => Data::Identifier->new(uuid => '1a24817a-94e1-463c-a67c-7fe879bbb1e5', displayname => 'second-person'),
        3   => Data::Identifier->new(uuid => 'd160670f-5e63-4398-a89b-9f7fad265019', displayname => 'third-person'),
    },
    class => {
        numeral         => Data::Identifier->new(uuid => '97ad8195-f700-44da-8c1e-d5fdddbc5a88', displayname => 'numeral'),
        noun            => Data::Identifier->new(uuid => 'f6b72740-1187-42df-8d61-dbed7a32174f', displayname => 'noun'),
        verb            => Data::Identifier->new(uuid => 'b3df8939-ca6f-412c-9b7a-33324da3338c', displayname => 'verb'),
        adjective       => Data::Identifier->new(uuid => '42fb34f2-f8c0-4c35-b63f-547204167df6', displayname => 'adjective'),
        pronoun         => Data::Identifier->new(uuid => 'deb297e5-34be-4b65-b93f-d990e798cd51', displayname => 'pronoun'),
        article         => Data::Identifier->new(uuid => '59306eb4-e220-4485-8f72-efe2fe9a7a46', displayname => 'article'),
    },
    type => {
        cardinal        => Data::Identifier->new(uuid => '27366344-537c-449e-94c0-c8137af78fa6', displayname => 'cardinal'),
        ordinal         => Data::Identifier->new(uuid => 'fe98afb9-d320-470c-a9f9-79e8b961b0ee', displayname => 'ordinal'),

        personal        => Data::Identifier->new(uuid => '898c0b67-d611-4a96-a33e-304910864577', displayname => 'personal'),
        possessive      => Data::Identifier->new(uuid => 'd3b685f5-afbf-457a-a406-58ac92229f9c', displayname => 'possessive'),
        reflexive       => Data::Identifier->new(uuid => '145179b9-0220-4dd6-a56b-62801410b4e2', displayname => 'reflexive'),
        reciprocal      => Data::Identifier->new(uuid => '0efaa3cc-1406-4a7c-a795-e66ea954e59a', displayname => 'reciprocal'),
        demonstrative   => Data::Identifier->new(uuid => '49173c0f-21e4-44c6-803c-87886427c8b1', displayname => 'demonstrative'),
        relative        => Data::Identifier->new(uuid => '6d847290-60a6-4a55-9255-d81049cb0ef2', displayname => 'relative'),
        interrogative   => Data::Identifier->new(uuid => 'd600dc17-490a-4800-b019-2ced254ece2b', displayname => 'interrogative'),
        indefinite      => Data::Identifier->new(uuid => '9142fb28-b0af-4323-82d7-aa1773500e5d', displayname => 'indefinite'),
    },
    matchtype => {
        full            => Data::Identifier->new(uuid => '1ce3a7ea-ff8b-4ab1-a042-852e3c5bbcde', tagname => 'full'),
        prefix          => Data::Identifier->new(uuid => 'c0d4592d-4d4c-4cd7-8da5-517fdad203c2', displayname => 'prefix'),
        suffix          => Data::Identifier->new(uuid => '73f4f593-c77f-4be0-b59d-24a37b40ccfd', displayname => 'suffix'),
        infix           => Data::Identifier->new(uuid => 'adfd159e-de5a-4b7d-af3c-c45a1eaa2429', displayname => 'infix'),
        stem            => Data::Identifier->new(uuid => '00a374c7-1bf1-4ee2-8773-5507ccb74346', displayname => 'stem'),
    },
    mood => {
        inf             => Data::Identifier->new(uuid => '4a8571ef-803b-4b38-8cc2-f8ac9acf530d', displayname => 'infinitive'),
        toinf           => Data::Identifier->new(uuid => 'ec42faf2-7f4f-49da-b075-a0a08a7b3e2f', displayname => 'to-infinitive'),
    },
);

my @_all = (values(%_true_dimension), values(%_pseudo_dimension), map {values %{$_}} values(%_values_by_dimension));

$_->register foreach @_all;

# ---- Private helpers ----

sub _get_dimension_names {
    return keys %_true_dimension;
}

sub _get_dimensions {
    my ($pkg, @keys) = @_;
    return map {$_true_dimension{$_} // croak 'BUG!'} @keys;
}

sub _get_values_by_dimension {
    my ($pkg, $dimension, @keys) = @_;
    my $table = $_values_by_dimension{$dimension} // croak 'No such dimension: '.$dimension;
    return map {$table->{$_} // (eval {$_->isa('Data::Identifier')} ? $_ : undef) // croak 'BUG!'} @keys;
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;

    croak 'Unsupported options passed' if scalar(keys %opts);

    if ($class eq ':all') {
        return (\@_all, rawtype => 'Data::Identifier::Interface::Simple');
    }

    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Information::Data - module to provide information on languages

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::Generic::Information::Data;

This is a package private to the implementation.
No user serviceable parts inside.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

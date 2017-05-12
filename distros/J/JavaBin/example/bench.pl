#!/usr/bin/env perl

use strict;
use warnings;

use Benchmark::Forking 'cmpthese';
use CBOR::XS;
use Data::Dumper 'Dumper';
use Data::MessagePack;
use JavaBin;
use JSON::XS qw/decode_json encode_json/;
use Sereal qw/sereal_decode_with_object sereal_encode_with_object/;
use Storable qw/freeze thaw/;
use YAML::XS qw/Dump Load/;

$Data::Dumper::Indent = 0;

# Version is a float in order to actually bench a float.
my $languages = {
    java => {
        designers   => [ 'James Gosling' ],
        extensions  => [ qw/.jar .java .class/ ],
        native_bool => \1,
        released    => '1996-01-23',
        TIOBE_rank  => 2,
        version     => 1.8,
    },
    lua => {
        designers   => [
            'Roberto Ierusalimschy',
            'Waldemar Celes',
            'Luiz Henrique de Figueiredo',
        ],
        extensions  => [ '.lua' ],
        native_bool => \1,
        released    => '1993-07-28',
        TIOBE_rank  => 35,
        version     => 5.2,
    },
    perl => {
        designers   => [ 'Larry Wall' ],
        extensions  => [ qw/.pl .pm .pod .t/ ],
        native_bool => \0,
        released    => '1987-12-18',
        TIOBE_rank  => 12,
        version     => 5.18,
    },
    php => {
        designers   => [ 'Rasmus Lerdorf' ],
        extensions  => [ '.php' ],
        native_bool => \1,
        released    => '1995-06-08',
        TIOBE_rank  => 5,
        version     => 5.5,
    },
    python => {
        designers   => [ 'Guido van Rossum' ],
        extensions  => [ qw/.py .pyc .pyd .pyo .pyw/ ],
        native_bool => \1,
        released    => '1991-02-20',
        TIOBE_rank  => 8,
        version     => 3.4,
    },
    ruby => {
        designers   => 'Yukihiro Matsumoto',
        extensions  => [ qw/.rb .rbw/ ],
        native_bool => \1,
        released    => '1995-12-21',
        TIOBE_rank  => 13,
        version     => 2.1,
    },
};

my $mpack    = Data::MessagePack->new;
my $srel_dec = Sereal::Decoder->new;
my $srel_enc = Sereal::Encoder->new;

my %alts; %alts = (
    CBOR => {
        dec => sub { decode_cbor $alts{CBOR}{data} },
        enc => sub { encode_cbor $languages },
        pkg => 'CBOR::XS',
    },
    Dump => {
        dec => sub { eval $alts{Dump}{data} },
        enc => sub { Dumper $languages },
        pkg => 'Data::Dumper',
    },
    Java => {
        dec => sub { from_javabin $alts{Java}{data} },
        enc => sub {   to_javabin $languages },
        pkg => 'JavaBin',
    },
    JSON => {
        dec => sub { decode_json $alts{JSON}{data} },
        enc => sub { encode_json $languages },
        pkg => 'JSON::XS',
    },
    MsgP => {
        dec => sub { $mpack->unpack($alts{MsgP}{data}) },
        enc => sub { $mpack->pack($languages) },
        pkg => 'Data::MessagePack',
    },
    Srel => {
        dec => sub { sereal_decode_with_object $srel_dec, $alts{Srel}{data} },
        enc => sub { sereal_encode_with_object $srel_enc, $languages },
        pkg => 'Sereal',
    },
    Stor => {
        dec => sub {   thaw $alts{Stor}{data} },
        enc => sub { freeze $languages },
        pkg => 'Storable',
    },
    YAML => {
        dec => sub { Load $alts{YAML}{data} },
        enc => sub { Dump $languages },
        pkg => 'YAML::XS',
    },
);

print "Modules\n\n";

{
    no strict 'refs';

    printf "%-5s%-18s%s\n", $_, $alts{$_}{pkg}, ${"$alts{$_}{pkg}::VERSION"}
        for sort keys %alts;
}

print "\nEncode\n";

cmpthese -1, { map ref() ? $_->{enc} : $_, %alts };

print "\nSize\n\n";

$_->{size} = length( $_->{data} = $_->{enc}->() ) for values %alts;

printf "%-5s%4d bytes\n", $_, $alts{$_}{size}
    for sort { $alts{$b}{size} <=> $alts{$a}{size} } keys %alts;

print "\nDecode\n";

cmpthese -1, { map ref() ? $_->{dec} : $_, %alts };

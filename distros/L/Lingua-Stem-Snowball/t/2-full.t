#!/usr/bin/perl

use strict;
use Test::More tests => 10201;
use Lingua::Stem::Snowball qw( stem );
use File::Spec;

my %languages = (
    en => 'ISO-8859-1',
    da => 'ISO-8859-1',
    de => 'ISO-8859-1',
    es => 'ISO-8859-1',
    fi => 'ISO-8859-1',
    fr => 'ISO-8859-1',
    hu => 'ISO-8859-1',
    it => 'ISO-8859-1',
    nl => 'ISO-8859-1',
    no => 'ISO-8859-1',
    pt => 'ISO-8859-1',
    ro => 'ISO-8859-2',
    ru => 'KOI8-R',
    sv => 'ISO-8859-1',
    tr => undef,
);
my $stemmer = Lingua::Stem::Snowball->new();

while ( my ( $iso, $encoding ) = each %languages ) {
    my ( @before, @after );

    # Set language.
    $stemmer->lang($iso);

    # Test 8-bit vocab.
    if ($encoding) {
        my $default_enc_voc_path
            = File::Spec->catfile( 't', 'test_voc', "$iso.default_enc" );
        open( my $default_enc_voc_fh, '<', $default_enc_voc_path )
            or die "Can't open '$default_enc_voc_path' for reading: $!";
        $stemmer->encoding($encoding);
        while (<$default_enc_voc_fh>) {
            chomp;
            my ( $raw, $expected ) = split;
            push @before, $raw;
            push @after,  $expected;
            test_singles( $raw, $expected, $iso, $encoding );
        }
        test_arrays( \@before, \@after, $iso, $encoding );
    }

    # Test UTF-8 vocab.
    $encoding = 'UTF-8';
    @before   = ();
    @after    = ();
    my $utf8_voc_path = File::Spec->catfile( 't', 'test_voc', "$iso.utf8" );
    my $open_mode = $] >= 5.8 ? "<:utf8" : "<";
    open( my $utf8_voc_fh, $open_mode, $utf8_voc_path )
        or die "Couldn't open file '$utf8_voc_path' for reading: $!";
    $stemmer->encoding($encoding);

    while (<$utf8_voc_fh>) {
        chomp;
        my ( $raw, $expected ) = split;
        push @before, $raw;
        push @after,  $expected;
        test_singles( $raw, $expected, $iso, $encoding );
    }
    test_arrays( \@before, \@after, $iso, $encoding );

}

sub test_singles {
    my ( $raw, $expected, $iso, $encoding ) = @_;

    my $got = $stemmer->stem($raw);
    is( $got, $expected, "$iso \$s->stem(\$raw)" );

    if ( $encoding ne 'UTF-8' ) {
        $got = stem( $iso, $raw );
        is( $got, $expected, "$iso stem(\$lang, \$raw)" );
    }

    $got = $stemmer->stem( uc($raw) );
    is( $got, $expected, "$iso \$s->stem(uc(\$raw))" );

    $got = [$raw];
    $stemmer->stem_in_place($got);
    is( $got->[0], $expected, "$iso \$s->stem_in_place(\$raw)" );
}

sub test_arrays {
    my ( $raw, $expected, $iso, $encoding ) = @_;

    my @got = $stemmer->stem($raw);
    is_deeply( \@got, $expected, "$iso \$s->stem(\@raw)" );

    if ( $encoding ne 'UTF-8' ) {
        @got = stem( $iso, $raw );
        is_deeply( \@got, $expected, "$iso stem(\$lang, \@raw)" );
    }

    my @uppercased = map {uc} @$raw;
    @got = $stemmer->stem( \@uppercased );
    is_deeply( \@got, $expected, "$iso \$s->stem(\@raw) (uc'd)" );

    @got = @$raw;
    $stemmer->stem_in_place( \@got );
    is_deeply( \@got, $expected, "$iso \$s->stem_in_place(\@raw)" );
}

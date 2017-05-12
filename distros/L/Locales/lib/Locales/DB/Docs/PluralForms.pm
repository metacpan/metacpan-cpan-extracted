package Locales::DB::Docs::PluralForms;

use strict;
use warnings;

# Auto generated from CLDR
use if $Locales::_UNICODE_STRINGS, 'utf8';

$Locales::DB::Docs::PluralForms::VERSION = '0.09';

$Locales::DB::Docs::PluralForms::cldr_version = '2.0';

1;

__END__

=encoding utf-8

=head1 NAME

Locales::DB::Docs::PluralForms - plural form details reference for all
included locales

=head1 VERSION

Locales.pm v0.09 (based on CLDR v2.0)

=head1 DESCRIPTION

CLDR L<defines a set of broad plural categories and rules|http://unicode.org/repos/cldr-tmp/trunk/diff/supplemental/language_plural_rules.html> that determine which category any given number will fall under.

L<Locales> allows you to determine the plural categories applicable to a specific locale and also which category a given number will fall under in that locale.

This POD documents which categories and in what order you'd specify them in additional arguments to L<Locales/get_plural_form()> (i.e. the optional arguments after the number).

=head2 “Special Zero” Argument

In addition to the CLDR category value list you can also specify one additional argument of what to use for zero instead of the value for “other”.

This won't be used if 0 falls under a specific category besides “other”.

=head1 Plural Category Argument Order Reference

=over 4

=item aa

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ab

CLDR 2.0 did not define data for “ab”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ace

CLDR 2.0 did not define data for “ace”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ach

CLDR 2.0 did not define data for “ach”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ada

CLDR 2.0 did not define data for “ada”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ady

CLDR 2.0 did not define data for “ady”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ae

CLDR 2.0 did not define data for “ae”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item af

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item afa

CLDR 2.0 did not define data for “afa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item afh

CLDR 2.0 did not define data for “afh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item agq

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ain

CLDR 2.0 did not define data for “ain”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ak

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ak

=item akk

CLDR 2.0 did not define data for “akk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ale

CLDR 2.0 did not define data for “ale”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item alg

CLDR 2.0 did not define data for “alg”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item alt

CLDR 2.0 did not define data for “alt”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item am

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for am

=item an

CLDR 2.0 did not define data for “an”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ang

CLDR 2.0 did not define data for “ang”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item anp

CLDR 2.0 did not define data for “anp”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item apa

CLDR 2.0 did not define data for “apa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ar

    get_plural_form($n, one, two, few, many, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ar

=item arc

CLDR 2.0 did not define data for “arc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item arn

CLDR 2.0 did not define data for “arn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item arp

CLDR 2.0 did not define data for “arp”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item art

CLDR 2.0 did not define data for “art”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item arw

CLDR 2.0 did not define data for “arw”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item as

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item asa

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ast

CLDR 2.0 did not define data for “ast”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ath

CLDR 2.0 did not define data for “ath”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item aus

CLDR 2.0 did not define data for “aus”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item av

CLDR 2.0 did not define data for “av”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item awa

CLDR 2.0 did not define data for “awa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ay

CLDR 2.0 did not define data for “ay”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item az

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ba

CLDR 2.0 did not define data for “ba”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bad

CLDR 2.0 did not define data for “bad”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bai

CLDR 2.0 did not define data for “bai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bal

CLDR 2.0 did not define data for “bal”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ban

CLDR 2.0 did not define data for “ban”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bas

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item bat

CLDR 2.0 did not define data for “bat”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item be

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for be

=item bej

CLDR 2.0 did not define data for “bej”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bem

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item ber

CLDR 2.0 did not define data for “ber”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bez

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item bg

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item bh

CLDR 2.0 did not define data for “bh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bho

CLDR 2.0 did not define data for “bho”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bi

CLDR 2.0 did not define data for “bi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bik

CLDR 2.0 did not define data for “bik”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bin

CLDR 2.0 did not define data for “bin”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bla

CLDR 2.0 did not define data for “bla”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bm

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item bn

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item bnt

CLDR 2.0 did not define data for “bnt”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item br

    get_plural_form($n, one, two, few, many, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for br

=item bra

CLDR 2.0 did not define data for “bra”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item brx

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item bs

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for bs

=item btk

CLDR 2.0 did not define data for “btk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bua

CLDR 2.0 did not define data for “bua”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item bug

CLDR 2.0 did not define data for “bug”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item byn

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ca

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item cad

CLDR 2.0 did not define data for “cad”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cai

CLDR 2.0 did not define data for “cai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item car

CLDR 2.0 did not define data for “car”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cau

CLDR 2.0 did not define data for “cau”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cay

CLDR 2.0 did not define data for “cay”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cch

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ce

CLDR 2.0 did not define data for “ce”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ceb

CLDR 2.0 did not define data for “ceb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cel

CLDR 2.0 did not define data for “cel”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cgg

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item ch

CLDR 2.0 did not define data for “ch”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chb

CLDR 2.0 did not define data for “chb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chg

CLDR 2.0 did not define data for “chg”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chk

CLDR 2.0 did not define data for “chk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chm

CLDR 2.0 did not define data for “chm”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chn

CLDR 2.0 did not define data for “chn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cho

CLDR 2.0 did not define data for “cho”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chp

CLDR 2.0 did not define data for “chp”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item chr

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item chy

CLDR 2.0 did not define data for “chy”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cmc

CLDR 2.0 did not define data for “cmc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item co

CLDR 2.0 did not define data for “co”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cop

CLDR 2.0 did not define data for “cop”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cpe

CLDR 2.0 did not define data for “cpe”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cpf

CLDR 2.0 did not define data for “cpf”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cpp

CLDR 2.0 did not define data for “cpp”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cr

CLDR 2.0 did not define data for “cr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item crh

CLDR 2.0 did not define data for “crh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item crp

CLDR 2.0 did not define data for “crp”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cs

    get_plural_form($n, one, few, other)
    get_plural_form($n, one, few, other, special_zero)

=item csb

CLDR 2.0 did not define data for “csb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cu

CLDR 2.0 did not define data for “cu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cus

CLDR 2.0 did not define data for “cus”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cv

CLDR 2.0 did not define data for “cv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item cy

    get_plural_form($n, one, two, few, many, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for cy

=item da

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item dak

CLDR 2.0 did not define data for “dak”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dar

CLDR 2.0 did not define data for “dar”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dav

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item day

CLDR 2.0 did not define data for “day”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item de

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item de_at

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item de_ch

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item del

CLDR 2.0 did not define data for “del”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item den

CLDR 2.0 did not define data for “den”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dgr

CLDR 2.0 did not define data for “dgr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item din

CLDR 2.0 did not define data for “din”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dje

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item doi

CLDR 2.0 did not define data for “doi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dra

CLDR 2.0 did not define data for “dra”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dsb

CLDR 2.0 did not define data for “dsb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dua

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item dum

CLDR 2.0 did not define data for “dum”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dv

CLDR 2.0 did not define data for “dv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dyo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item dyu

CLDR 2.0 did not define data for “dyu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item dz

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ebu

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ee

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item efi

CLDR 2.0 did not define data for “efi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item egy

CLDR 2.0 did not define data for “egy”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item eka

CLDR 2.0 did not define data for “eka”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item el

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item elx

CLDR 2.0 did not define data for “elx”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item en

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item en_au

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item en_ca

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item en_gb

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item en_us

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item enm

CLDR 2.0 did not define data for “enm”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item eo

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item es

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item es_419

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item es_es

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item et

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item eu

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item ewo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item fa

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item fan

CLDR 2.0 did not define data for “fan”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fat

CLDR 2.0 did not define data for “fat”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ff

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ff

=item fi

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item fil

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for fil

=item fiu

CLDR 2.0 did not define data for “fiu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fj

CLDR 2.0 did not define data for “fj”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fo

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item fon

CLDR 2.0 did not define data for “fon”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fr

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for fr

=item fr_ca

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for fr_ca

=item fr_ch

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for fr_ch

=item frm

CLDR 2.0 did not define data for “frm”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fro

CLDR 2.0 did not define data for “fro”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item frr

CLDR 2.0 did not define data for “frr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item frs

CLDR 2.0 did not define data for “frs”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item fur

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item fy

CLDR 2.0 did not define data for “fy”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ga

    get_plural_form($n, one, two, other)
    get_plural_form($n, one, two, other, special_zero)

=item gaa

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item gay

CLDR 2.0 did not define data for “gay”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gba

CLDR 2.0 did not define data for “gba”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gd

CLDR 2.0 did not define data for “gd”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gem

CLDR 2.0 did not define data for “gem”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gez

CLDR 2.0 did not define data for “gez”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gil

CLDR 2.0 did not define data for “gil”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gl

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item gmh

CLDR 2.0 did not define data for “gmh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gn

CLDR 2.0 did not define data for “gn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item goh

CLDR 2.0 did not define data for “goh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gon

CLDR 2.0 did not define data for “gon”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gor

CLDR 2.0 did not define data for “gor”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item got

CLDR 2.0 did not define data for “got”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item grb

CLDR 2.0 did not define data for “grb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item grc

CLDR 2.0 did not define data for “grc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item gsw

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item gu

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item guz

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item gv

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for gv

=item gwi

CLDR 2.0 did not define data for “gwi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ha

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item hai

CLDR 2.0 did not define data for “hai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item haw

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item he

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item hi

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for hi

=item hil

CLDR 2.0 did not define data for “hil”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item him

CLDR 2.0 did not define data for “him”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item hit

CLDR 2.0 did not define data for “hit”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item hmn

CLDR 2.0 did not define data for “hmn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ho

CLDR 2.0 did not define data for “ho”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item hr

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for hr

=item hsb

CLDR 2.0 did not define data for “hsb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ht

CLDR 2.0 did not define data for “ht”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item hu

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item hup

CLDR 2.0 did not define data for “hup”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item hy

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item hz

CLDR 2.0 did not define data for “hz”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ia

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item iba

CLDR 2.0 did not define data for “iba”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item id

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ie

CLDR 2.0 did not define data for “ie”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ig

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ii

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ijo

CLDR 2.0 did not define data for “ijo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ik

CLDR 2.0 did not define data for “ik”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ilo

CLDR 2.0 did not define data for “ilo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item inc

CLDR 2.0 did not define data for “inc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ine

CLDR 2.0 did not define data for “ine”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item inh

CLDR 2.0 did not define data for “inh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item io

CLDR 2.0 did not define data for “io”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ira

CLDR 2.0 did not define data for “ira”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item iro

CLDR 2.0 did not define data for “iro”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item is

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item it

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item iu

CLDR 2.0 did not define data for “iu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ja

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item jbo

CLDR 2.0 did not define data for “jbo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item jmc

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item jpr

CLDR 2.0 did not define data for “jpr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item jrb

CLDR 2.0 did not define data for “jrb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item jv

CLDR 2.0 did not define data for “jv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ka

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kaa

CLDR 2.0 did not define data for “kaa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kab

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for kab

=item kac

CLDR 2.0 did not define data for “kac”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kaj

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kam

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kar

CLDR 2.0 did not define data for “kar”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kaw

CLDR 2.0 did not define data for “kaw”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kbd

CLDR 2.0 did not define data for “kbd”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kcg

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kde

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kea

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kfo

CLDR 2.0 did not define data for “kfo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kg

CLDR 2.0 did not define data for “kg”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kha

CLDR 2.0 did not define data for “kha”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item khi

CLDR 2.0 did not define data for “khi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kho

CLDR 2.0 did not define data for “kho”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item khq

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ki

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kj

CLDR 2.0 did not define data for “kj”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kk

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item kl

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item kln

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item km

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kmb

CLDR 2.0 did not define data for “kmb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kn

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ko

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kok

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item kos

CLDR 2.0 did not define data for “kos”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kpe

CLDR 2.0 did not define data for “kpe”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kr

CLDR 2.0 did not define data for “kr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item krc

CLDR 2.0 did not define data for “krc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item krl

CLDR 2.0 did not define data for “krl”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kro

CLDR 2.0 did not define data for “kro”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kru

CLDR 2.0 did not define data for “kru”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ks

CLDR 2.0 did not define data for “ks”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ksb

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ksf

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ksh

    get_plural_form($n, one, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ksh

=item ku

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item kum

CLDR 2.0 did not define data for “kum”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kut

CLDR 2.0 did not define data for “kut”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kv

CLDR 2.0 did not define data for “kv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item kw

    get_plural_form($n, one, two, other)
    get_plural_form($n, one, two, other, special_zero)

=item ky

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item la

CLDR 2.0 did not define data for “la”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lad

CLDR 2.0 did not define data for “lad”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lag

    get_plural_form($n, one, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for lag

=item lah

CLDR 2.0 did not define data for “lah”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lam

CLDR 2.0 did not define data for “lam”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lb

CLDR 2.0 did not define data for “lb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lez

CLDR 2.0 did not define data for “lez”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lg

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item li

CLDR 2.0 did not define data for “li”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ln

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ln

=item lo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item lol

CLDR 2.0 did not define data for “lol”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item loz

CLDR 2.0 did not define data for “loz”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lt

    get_plural_form($n, one, few, other)
    get_plural_form($n, one, few, other, special_zero)

=item lu

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item lua

CLDR 2.0 did not define data for “lua”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lui

CLDR 2.0 did not define data for “lui”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item lun

CLDR 2.0 did not define data for “lun”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item luo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item lus

CLDR 2.0 did not define data for “lus”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item luy

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item lv

    get_plural_form($n, one, zero, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for lv

=item mad

CLDR 2.0 did not define data for “mad”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mag

CLDR 2.0 did not define data for “mag”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mai

CLDR 2.0 did not define data for “mai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mak

CLDR 2.0 did not define data for “mak”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item man

CLDR 2.0 did not define data for “man”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item map

CLDR 2.0 did not define data for “map”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mas

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item mdf

CLDR 2.0 did not define data for “mdf”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mdr

CLDR 2.0 did not define data for “mdr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item men

CLDR 2.0 did not define data for “men”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mer

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item mfe

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item mg

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for mg

=item mga

CLDR 2.0 did not define data for “mga”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mgh

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item mh

CLDR 2.0 did not define data for “mh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mi

CLDR 2.0 did not define data for “mi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mic

CLDR 2.0 did not define data for “mic”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item min

CLDR 2.0 did not define data for “min”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mis

CLDR 2.0 did not define data for “mis”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mk

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item mkh

CLDR 2.0 did not define data for “mkh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ml

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item mn

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item mnc

CLDR 2.0 did not define data for “mnc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mni

CLDR 2.0 did not define data for “mni”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mno

CLDR 2.0 did not define data for “mno”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mo

    get_plural_form($n, one, few, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for mo

=item moh

CLDR 2.0 did not define data for “moh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mos

CLDR 2.0 did not define data for “mos”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mr

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item ms

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item mt

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for mt

=item mua

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item mul

CLDR 2.0 did not define data for “mul”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mun

CLDR 2.0 did not define data for “mun”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mus

CLDR 2.0 did not define data for “mus”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mwl

CLDR 2.0 did not define data for “mwl”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item mwr

CLDR 2.0 did not define data for “mwr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item my

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item myn

CLDR 2.0 did not define data for “myn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item myv

CLDR 2.0 did not define data for “myv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item na

CLDR 2.0 did not define data for “na”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nah

CLDR 2.0 did not define data for “nah”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nai

CLDR 2.0 did not define data for “nai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nap

CLDR 2.0 did not define data for “nap”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item naq

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item nb

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item nd

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item nds

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ne

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item new

CLDR 2.0 did not define data for “new”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ng

CLDR 2.0 did not define data for “ng”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nia

CLDR 2.0 did not define data for “nia”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nic

CLDR 2.0 did not define data for “nic”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item niu

CLDR 2.0 did not define data for “niu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nl

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item nl_be

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item nmg

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item nn

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item no

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item nog

CLDR 2.0 did not define data for “nog”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item non

CLDR 2.0 did not define data for “non”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nqo

CLDR 2.0 did not define data for “nqo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nr

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item nso

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for nso

=item nub

CLDR 2.0 did not define data for “nub”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nus

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item nv

CLDR 2.0 did not define data for “nv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nwc

CLDR 2.0 did not define data for “nwc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ny

CLDR 2.0 did not define data for “ny”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nym

CLDR 2.0 did not define data for “nym”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nyn

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item nyo

CLDR 2.0 did not define data for “nyo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item nzi

CLDR 2.0 did not define data for “nzi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item oc

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item oj

CLDR 2.0 did not define data for “oj”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item om

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item or

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item os

CLDR 2.0 did not define data for “os”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item osa

CLDR 2.0 did not define data for “osa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ota

CLDR 2.0 did not define data for “ota”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item oto

CLDR 2.0 did not define data for “oto”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pa

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item paa

CLDR 2.0 did not define data for “paa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pag

CLDR 2.0 did not define data for “pag”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pal

CLDR 2.0 did not define data for “pal”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pam

CLDR 2.0 did not define data for “pam”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pap

CLDR 2.0 did not define data for “pap”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pau

CLDR 2.0 did not define data for “pau”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item peo

CLDR 2.0 did not define data for “peo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item phi

CLDR 2.0 did not define data for “phi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item phn

CLDR 2.0 did not define data for “phn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pi

CLDR 2.0 did not define data for “pi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pl

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for pl

=item pon

CLDR 2.0 did not define data for “pon”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pra

CLDR 2.0 did not define data for “pra”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item pro

CLDR 2.0 did not define data for “pro”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ps

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item pt

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item pt_br

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item pt_pt

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item qu

CLDR 2.0 did not define data for “qu”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item raj

CLDR 2.0 did not define data for “raj”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item rap

CLDR 2.0 did not define data for “rap”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item rar

CLDR 2.0 did not define data for “rar”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item rm

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item rn

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ro

    get_plural_form($n, one, few, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ro

=item roa

CLDR 2.0 did not define data for “roa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item rof

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item rom

CLDR 2.0 did not define data for “rom”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ru

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ru

=item rup

CLDR 2.0 did not define data for “rup”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item rw

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item rwk

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sa

CLDR 2.0 did not define data for “sa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sad

CLDR 2.0 did not define data for “sad”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sah

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sai

CLDR 2.0 did not define data for “sai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sal

CLDR 2.0 did not define data for “sal”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sam

CLDR 2.0 did not define data for “sam”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item saq

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item sas

CLDR 2.0 did not define data for “sas”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sat

CLDR 2.0 did not define data for “sat”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sbp

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sc

CLDR 2.0 did not define data for “sc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item scn

CLDR 2.0 did not define data for “scn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sco

CLDR 2.0 did not define data for “sco”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sd

CLDR 2.0 did not define data for “sd”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item se

    get_plural_form($n, one, two, other)
    get_plural_form($n, one, two, other, special_zero)

=item see

CLDR 2.0 did not define data for “see”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item seh

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sel

CLDR 2.0 did not define data for “sel”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sem

CLDR 2.0 did not define data for “sem”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ses

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sg

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sga

CLDR 2.0 did not define data for “sga”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sgn

CLDR 2.0 did not define data for “sgn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sh

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for sh

=item shi

    get_plural_form($n, one, few, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for shi

=item shn

CLDR 2.0 did not define data for “shn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item si

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sid

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item sio

CLDR 2.0 did not define data for “sio”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sit

CLDR 2.0 did not define data for “sit”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sk

    get_plural_form($n, one, few, other)
    get_plural_form($n, one, few, other, special_zero)

=item sl

    get_plural_form($n, one, two, few, other)
    get_plural_form($n, one, two, few, other, special_zero)

=item sla

CLDR 2.0 did not define data for “sla”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sm

CLDR 2.0 did not define data for “sm”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sma

CLDR 2.0 did not define data for “sma”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item smi

CLDR 2.0 did not define data for “smi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item smj

CLDR 2.0 did not define data for “smj”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item smn

CLDR 2.0 did not define data for “smn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sms

CLDR 2.0 did not define data for “sms”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sn

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item snk

CLDR 2.0 did not define data for “snk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item so

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item sog

CLDR 2.0 did not define data for “sog”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item son

CLDR 2.0 did not define data for “son”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sq

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item sr

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for sr

=item srn

CLDR 2.0 did not define data for “srn”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item srr

CLDR 2.0 did not define data for “srr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ss

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ssa

CLDR 2.0 did not define data for “ssa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ssy

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item st

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item su

CLDR 2.0 did not define data for “su”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item suk

CLDR 2.0 did not define data for “suk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sus

CLDR 2.0 did not define data for “sus”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sux

CLDR 2.0 did not define data for “sux”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item sv

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item sw

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item swb

CLDR 2.0 did not define data for “swb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item swc

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item syc

CLDR 2.0 did not define data for “syc”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item syr

CLDR 2.0 did not define data for “syr”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ta

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item tai

CLDR 2.0 did not define data for “tai”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item te

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item tem

CLDR 2.0 did not define data for “tem”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item teo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ter

CLDR 2.0 did not define data for “ter”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tet

CLDR 2.0 did not define data for “tet”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tg

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item th

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ti

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for ti

=item tig

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item tiv

CLDR 2.0 did not define data for “tiv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tk

CLDR 2.0 did not define data for “tk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tkl

CLDR 2.0 did not define data for “tkl”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tl

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for tl

=item tlh

CLDR 2.0 did not define data for “tlh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tli

CLDR 2.0 did not define data for “tli”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tmh

CLDR 2.0 did not define data for “tmh”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tn

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item to

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item tog

CLDR 2.0 did not define data for “tog”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tpi

CLDR 2.0 did not define data for “tpi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tr

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item trv

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ts

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item tsi

CLDR 2.0 did not define data for “tsi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tt

CLDR 2.0 did not define data for “tt”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tum

CLDR 2.0 did not define data for “tum”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tup

CLDR 2.0 did not define data for “tup”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tut

CLDR 2.0 did not define data for “tut”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tvl

CLDR 2.0 did not define data for “tvl”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tw

CLDR 2.0 did not define data for “tw”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item twq

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ty

CLDR 2.0 did not define data for “ty”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tyv

CLDR 2.0 did not define data for “tyv”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item tzm

    get_plural_form($n, one, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for tzm

=item udm

CLDR 2.0 did not define data for “udm”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ug

CLDR 2.0 did not define data for “ug”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item uga

CLDR 2.0 did not define data for “uga”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item uk

    get_plural_form($n, one, few, many, other)

Note: zero falls under a different category than “other” so there is no L</“Special Zero” Argument> for uk

=item umb

CLDR 2.0 did not define data for “umb”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item und

CLDR 2.0 did not define data for “und”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item ur

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item uz

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item vai

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ve

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item vi

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item vo

CLDR 2.0 did not define data for “vo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item vot

CLDR 2.0 did not define data for “vot”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item vun

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item wa

CLDR 2.0 did not define data for “wa”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item wae

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item wak

CLDR 2.0 did not define data for “wak”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item wal

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item war

CLDR 2.0 did not define data for “war”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item was

CLDR 2.0 did not define data for “was”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item wen

CLDR 2.0 did not define data for “wen”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item wo

CLDR 2.0 did not define data for “wo”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item xal

CLDR 2.0 did not define data for “xal”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item xh

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item xog

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item yao

CLDR 2.0 did not define data for “yao”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item yap

CLDR 2.0 did not define data for “yap”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item yav

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item yi

CLDR 2.0 did not define data for “yi”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item yo

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item ypk

CLDR 2.0 did not define data for “ypk”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item yue

CLDR 2.0 did not define data for “yue”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item za

CLDR 2.0 did not define data for “za”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zap

CLDR 2.0 did not define data for “zap”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zbl

CLDR 2.0 did not define data for “zbl”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zen

CLDR 2.0 did not define data for “zen”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zh

    get_plural_form($n, other)
    get_plural_form($n, other, special_zero)

=item znd

CLDR 2.0 did not define data for “znd”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zu

    get_plural_form($n, one, other)
    get_plural_form($n, one, other, special_zero)

=item zun

CLDR 2.0 did not define data for “zun”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zxx

CLDR 2.0 did not define data for “zxx”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.

=item zza

CLDR 2.0 did not define data for “zza”, thus it will fallback to L</en> behavior.

You can  L<submit the missing data to the CLDR|http://unicode.org/cldr/trac> if you wish.



=back

=head1 BUGS AND LIMITATIONS

Please see L<Locales/BUGS AND LIMITATIONS>

=head2 BEFORE YOU SUBMIT A BUG REPORT

Please see L<Locales/BEFORE YOU SUBMIT A BUG REPORT>

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


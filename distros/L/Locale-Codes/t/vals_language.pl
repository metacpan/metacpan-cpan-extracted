#!/usr/bin/perl
# Copyright (c) 2016-2025 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use warnings;
use strict;

$::tests = '';

$::tests = "

all_names 2 => Abkhazian Afar

all_codes 2 => aa ab

2name zu => Zulu

rename zu NewName foo => 'ERROR: _code: invalid codeset provided: foo'

rename zu English alpha-2 => 'ERROR: rename_code: rename to an existing name not allowed'

rename zu NewName alpha-3 => 'ERROR: _code: code not in codeset: zu [alpha-3]'

2name zu => Zulu

rename zu NewName alpha-2 => 1

2name zu => NewName

2code Afar => aa

2code ESTONIAN => et

2code French => fr

2code Greek => el

2code Japanese => ja

2code Zulu => zu

2code english => en

2code japanese => ja

2code Zulu alpha-2 => zu

2code Zaza alpha-3 => zza

2code Welsh term => cym

2code 'Zande languages' alpha-3 => znd

2code 'Zuojiang Zhuang' alpha-3 => zzj

2name in => __undef__

2name iw => __undef__

2name ji => __undef__

2name jp => 'ERROR: _code: code not in codeset: jp [alpha-2]'

2name zz => 'ERROR: _code: code not in codeset: zz [alpha-2]'

2name DA => Danish

2name aa => Afar

2name ae => Avestan

2name bs => Bosnian

2name ce => Chechen

2name ch => Chamorro

2name cu => 'Church Slavic'

2name cv => Chuvash

2name en => English

2name eo => Esperanto

2name fi => Finnish

2name gv => Manx

2name he => Hebrew

2name ho => 'Hiri Motu'

2name hz => Herero

2name id => Indonesian

2name iu => Inuktitut

2name ki => Kikuyu

2name kj => Kuanyama

2name kv => Komi

2name kw => Cornish

2name lb => Luxembourgish

2name mh => Marshallese

2name nb => 'Norwegian Bokmal'

2name nd => 'North Ndebele'

2name ng => Ndonga

2name nn => 'Norwegian Nynorsk'

2name nr => 'South Ndebele'

2name nv => Navajo

2name ny => Nyanja

2name oc => 'Occitan (post 1500)'

2name os => Ossetian

2name pi => Pali

2name sc => Sardinian

2name se => 'Northern Sami'

2name ug => Uighur

2name yi => Yiddish

2name za => Zhuang

code2code zu alpha-2 alpha-3 => zul

rename AAA newCode2 => 'ERROR: _code: code not in codeset: aaa [alpha-2]'

add AAA newCode => 1

delete AAA => 1

add_alias FooBar NewName        => 'ERROR: add_alias: name does not exist: FooBar'

delete_alias Foobar             => 'ERROR: delete_alias: name does not exist: Foobar'

replace_code Foo Bar => 'ERROR: _code: code not in codeset: foo [alpha-2]'

add_code_alias Foo Bar => 'ERROR: _code: code not in codeset: foo [alpha-2]'

delete_code_alias Foo => 'ERROR: _code: code not in codeset: foo [alpha-2]'

";

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:


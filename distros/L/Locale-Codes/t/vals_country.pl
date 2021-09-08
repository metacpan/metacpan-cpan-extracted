#!/usr/bin/perl
# Copyright (c) 2016-2021 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use warnings;
use strict;

$::tests = '';

$::tests = "

#################

2code __undef__             => __undef__

2code                       => __undef__

2code _blank_               => __undef__

2code UnusedName            => __undef__

2code                       => __undef__

2code __undef__             => __undef__

2name __undef__             => __undef__

2name                       => __undef__

###

add AAA newCode             => 1

2code newCode               => aaa

delete AAA                  => 1

2code newCode               => __undef__

###

add AAA newCode             => 1

rename AAA newCode2         => 1

2code newCode               => aaa

2code newCode2              => aaa

###

add_alias newCode2 newAlias => 1

2code newAlias              => aaa

delete_alias newAlias       => 1

2code newAlias              => __undef__

###

replace_code AAA BBB        => 1

2name AAA                   => newCode2

2name BBB                   => newCode2

###

add_code_alias BBB CCC      => 1

2name BBB                   => newCode2

2name CCC                   => newCode2

delete_code_alias CCC       => 1

2name CCC                   => 'ERROR: _code: code not in codeset: ccc [alpha-2]'

##################
# code2country

all_names 2              => Afghanistan 'Aland Islands'

all_codes 2              => ad ae

all_names retired 2      => Afghanistan 'Aland Islands'

all_codes retired 2      => ad ae

all_names foo 2          => 'ERROR: _code: invalid codeset provided: foo'

all_codes foo 2          => 'ERROR: _code: invalid codeset provided: foo'

2name zz                 => 'ERROR: _code: code not in codeset: zz [alpha-2]'

2name zz alpha-2         => 'ERROR: _code: code not in codeset: zz [alpha-2]'

2name zz alpha-3         => 'ERROR: _code: code not in codeset: zz [alpha-3]'

2name zz numeric         => 'ERROR: _code: invalid numeric code: zz'

2name ja                 => 'ERROR: _code: code not in codeset: ja [alpha-2]'

2name uk                 => 'ERROR: _code: code not in codeset: uk [alpha-2]'

2name BO                 => 'Bolivia (Plurinational State of)'

2name BO alpha-2         => 'Bolivia (Plurinational State of)'

2name bol alpha-3        => 'Bolivia (Plurinational State of)'

2name pk                 => Pakistan

2name sn                 => Senegal

2name us                 => 'United States of America'

2name ad                 => Andorra

2name ad alpha-2         => Andorra

2name and alpha-3        => Andorra

2name 020 numeric        => Andorra

2name 48 numeric         => Bahrain

2name zw                 => Zimbabwe

2name gb                 => 'United Kingdom of Great Britain and Northern Ireland'

2name kz                 => Kazakhstan

2name mo                 => Macao

2name tl alpha-2         => Timor-Leste

2name tls alpha-3        => Timor-Leste

2name 626 numeric        => Timor-Leste

2name BO alpha-3         => 'ERROR: _code: code not in codeset: bo [alpha-3]'

2name BO numeric         => 'ERROR: _code: invalid numeric code: BO'

2name ax                 => 'Aland Islands'

2name ala alpha-3        => 'Aland Islands'

2name 248 numeric        => 'Aland Islands'

2name scg alpha-3        => __undef__

2name 891 numeric        => __undef__

2name rou alpha-3        => Romania

2name zr                 => __undef__

2name zr retired         => Zaire

2name jp alpha-2 not_retired other_arg
                         => Japan

2name jp __blank__       => Japan

2name jp alpha-15        => 'ERROR: _code: invalid codeset provided: alpha-15'

2name jp alpha-2 retired => Japan

2name z0 alpha-2 retired => 'ERROR: _code: code not in codeset: z0 [alpha-2]'

2names us =>
          'United States of America'
          'The United States of America'
          'United States of America, The'
          'United States of America (The)'
          'The United States'
          'United States'
          'United States, The'
          'United States (The)'
          'US'
          'USA'

##################
# country2code

2code kazakhstan                                      => kz

2code kazakstan                                       => kz

2code macao                                           => mo

2code macau                                           => mo

2code japan                                           => jp

2code Japan                                           => jp

2code 'United States'                                 => us

2code 'United Kingdom'                                => gb

2code Andorra                                         => ad

2code Zimbabwe                                        => zw

2code Iran                                            => ir

2code 'North Korea'                                   => kp

2code 'South Korea'                                   => kr

2code Libya                                           => ly

2code 'Syrian Arab Republic'                          => sy

2code Svalbard                                        => __undef__

2code 'Jan Mayen'                                     => __undef__

2code USA                                             => us

2code 'United States of America'                      => us

2code 'Great Britain'                                 => gb

2code Burma                                           => mm

2code 'French Southern and Antarctic Lands'           => tf

2code 'Aland Islands'                                 => ax

2code Yugoslavia                                      => __undef__

2code 'Serbia and Montenegro'                         => __undef__

2code 'East Timor'                                    => tl

2code Zaire                                           => __undef__

2code Zaire retired                                   => zr

2code 'Congo, The Democratic Republic of the'         => cd

2code 'Congo, The Democratic Republic of the' alpha-3 => cod

2code 'Congo, The Democratic Republic of the' numeric => 180

2code Syria => sy

# Last codes in each set (we'll assume that if we got these, there's a good
# possiblity that we got all the others).

2code Zimbabwe alpha-2                                => zw

2code Zimbabwe alpha-3                                => zwe

2code Zimbabwe numeric                                => 716

2code Zimbabwe dom                                    => zw

2code Zimbabwe dom                                    => zw

2code Zipper dom retired                              => __undef__

2code Zimbabwe genc-numeric                           => 716

2code Zimbabwe foo         => 'ERROR: _code: invalid codeset provided: foo'

##################
# countrycode2code

code2code bo alpha-2 alpha-2  => bo

code2code bo alpha-3 alpha-3  => 'ERROR: _code: code not in codeset: bo [alpha-3]'

code2code zz alpha-2 alpha-3  => 'ERROR: _code: code not in codeset: zz [alpha-2]'

code2code zz alpha-3 alpha-3  => 'ERROR: _code: code not in codeset: zz [alpha-3]'

code2code zz alpha-2 0        => 'ERROR: _code: code not in codeset: zz [alpha-2]'

code2code bo alpha-2 0        => __undef__

code2code __blank__ 0 0       => __undef__

code2code BO alpha-2 alpha-3  => bol

code2code bol alpha-3 alpha-2 => bo

code2code zwe alpha-3 alpha-2 => zw

code2code 858 numeric alpha-3 => ury

code2code 858 numeric alpha-3 => ury

code2code tr alpha-2 numeric  => 792

code2code tr alpha-2          => tr

code2code                     => __undef__

###################################
# Test rename_country

2name gb => 'United Kingdom of Great Britain and Northern Ireland'

rename x1 NewName         => 'ERROR: _code: code not in codeset: x1 [alpha-2]'

rename gb NewName foo     => 'ERROR: _code: invalid codeset provided: foo'

rename gb Macao           => 'ERROR: rename_code: rename to an existing name not allowed'

rename gb NewName alpha-3 => 'ERROR: _code: code not in codeset: gb [alpha-3]'

2name gb => 'United Kingdom of Great Britain and Northern Ireland'

rename gb NewName => 1

2name gb                      => NewName

2name us                      => 'United States of America'

rename us 'The United States' => 1

2name us                      => 'The United States'

###################################
# Test add

2name xx                    => 'ERROR: _code: code not in codeset: xx [alpha-2]'

add xx Bolivia              => 'ERROR: add_code: name already in use: Bolivia'

add fi Xxxxx                => 'ERROR: add_code: code already in use as alias: fi'

add xx Xxxxx                => 1

2name xx                    => Xxxxx

add xx Xxxxx foo            => 'ERROR: _code: invalid codeset provided: foo'

add xy 'New Country' alpha-2  => 1

add xyy 'New Country' alpha-3 => 1

###################################
# Test add_alias

add_alias FooBar NewName        => 'ERROR: add_alias: name does not exist: FooBar'

add_alias Australia Angola      => 'ERROR: add_alias: alias already in use: Angola'

2code Australia                 => au

2code DownUnder                 => __undef__

add_alias Australia DownUnder   => 1

2code DownUnder                 => au

###################################
# Test delete_alias

2code uk                        => gb

delete_alias Foobar             => 'ERROR: delete_alias: name does not exist: Foobar'

delete_alias UK                 => 1

2code uk                        => __undef__

delete_alias Angola             => 'ERROR: delete_alias: only one name defined (use delete_code instead)'

add z1 NameA1 alpha-2           => 1

add_alias NameA1 NameA2 alpha-2 => 1

add zz1 NameA2 alpha-3          => 1

2name z1                        => NameA1

2name zz1 alpha-3               => NameA2

code2code z1 alpha-2 alpha-3    => zz1

delete_alias NameA2             => 1

2name z1                        => NameA1

2name zz1 alpha-3               => NameA1

add z2 NameB1 alpha-2           => 1

add_alias NameB1 NameB2 alpha-2 => 1

add zz2 NameB2 alpha-3          => 1

2name z2                        => NameB1

2name zz2 alpha-3               => NameB2

code2code z2 alpha-2 alpha-3    => zz2

delete_alias NameB1             => 1

2name z2                        => NameB2

2name zz2 alpha-3               => NameB2

###################################
# Test delete

2code Angola                    => ao

2code Angola alpha-3            => ago

delete ao                       => 1

2code Angola                    => __undef__

2code Angola alpha-3            => ago

delete ago foo                  => 'ERROR: _code: invalid codeset provided: foo'

delete zz                       => 'ERROR: _code: code not in codeset: zz [alpha-2]'

###################################
# Test replace_code

2name zz                        => 'ERROR: _code: code not in codeset: zz [alpha-2]'

2name ar                        => Argentina

2code Argentina                 => ar

replace_code ar us              => 'ERROR: replace_code: new code already in use: us'

replace_code ar zz              => 1

replace_code us ar              => 'ERROR: replace_code: new code already in use as alias: ar'

2name zz                        => Argentina

2name ar                        => Argentina

2code Argentina                 => zz

replace_code zz ar              => 1

2name zz                        => Argentina

2name ar                        => Argentina

2code Argentina                 => ar

replace_code ar z2 foo          => 'ERROR: _code: invalid codeset provided: foo'

replace_code ar z2 alpha-3      => 'ERROR: _code: code not in codeset: ar [alpha-3]'

###################################
# Test add_code_alias and
# delete_code_alias

2name bm                        => Bermuda

2name yy                        => 'ERROR: _code: code not in codeset: yy [alpha-2]'

2code Bermuda                   => bm

add_code_alias bm us            => 'ERROR: add_code_alias: code already in use: us'

add_code_alias bm zz            => 'ERROR: add_code_alias: code already in use: zz'

add_code_alias bm yy            => 1

2name bm                        => Bermuda

2name yy                        => Bermuda

2code Bermuda                   => bm

delete_code_alias us            => 'ERROR: delete_code_alias: no alias defined: us'

delete_code_alias ww            => 'ERROR: _code: code not in codeset: ww [alpha-2]'

delete_code_alias yy            => 1

2name bm                        => Bermuda

2name yy                        => 'ERROR: _code: code not in codeset: yy [alpha-2]'

2code Bermuda                   => bm

add_code_alias bm yy            => 1

2name yy                        => Bermuda

add yy Foo                      => 'ERROR: add_code: code already in use as alias: yy' 

delete bm                       => 1

2name bm                     => 'ERROR: _code: code not in codeset: bm [alpha-2]'

add_code_alias bm y2 foo     => 'ERROR: _code: invalid codeset provided: foo'

add_code_alias bm y2 alpha-3 => 'ERROR: _code: code not in codeset: bm [alpha-3]'

delete_code_alias bm foo     => 'ERROR: _code: invalid codeset provided: foo'

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


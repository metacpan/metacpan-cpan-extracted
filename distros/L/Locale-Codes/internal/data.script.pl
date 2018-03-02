#!/usr/bin/perl -w
# Copyright (c) 2010-2018 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

$Data{'script'}{'link'} =
  [
  ];

################################################################################

$Data{'script'}{'iso'}{'orig'}{'name'} =
  {
   "Ethiopic (Geʻez)"                => "Ethiopic (Geez)",
   "Hangul (Hangŭl, Hangeul)"        => "Hangul (Hangul, Hangeul)",
   "Hanunoo (Hanunóo)"               => "Hanunoo (Hanunoo)",
   "Lepcha (Róng)"                   => "Lepcha (Rong)",
   "Modi, Moḍī"                      => "Modi, Modi",
   "Naxi Dongba (na²¹ɕi³³ to³³ba²¹, Nakhi Tomba)" =>
                                        "Naxi Dongba (Nakhi Tomba)",
   "Naxi Geba (na²¹ɕi³³ gʌ²¹ba²¹, 'Na-'Khi ²Ggŏ-¹baw, Nakhi Geba)" =>
                                        "Naxi Geba (Nakhi Geba, 'Na-'Khi Ggo-baw)",
   "N’Ko"                            => "N'Ko",
   "Nüshu"                           => "Nushu",
   "Ol Chiki (Ol Cemet’, Ol, Santali)" =>
                                        "Ol Chiki (Ol Cemet, Ol, Santali)",
   "Sharada, Śāradā"                 => "Sharada, Sarada",
   "Takri, Ṭākrī, Ṭāṅkrī"            => "Takri, Takri, Tankri",
   "Siddham, Siddhaṃ, Siddhamātṛkā"  => "Siddham, Siddham, Siddhamatrka",
   "Newa, Newar, Newari, Nepāla lipi"=> "Newa, Newar, Newari, Nepala lipi",
   "Medefaidrin (Oberi Okaime, Oberi Ɔkaimɛ)" =>
   "Medefaidrin (Oberi Okaime, Oberi Okaime)",
   "Zanabazar Square (Zanabazarin Dörböljin Useg, Xewtee Dörböljin Bicig, Horizontal Square Script)" =>
   "Zanabazar Square (Zanabazarin Dorboljin Useg, Xewtee Dorboljin Bicig, Horizontal Square Script)"
};

$Data{'script'}{'iso'}{'ignore'} = {
   'name'   => {
                "Code for uncoded script"       => 1,
                "Code for undetermined script"  => 1,
                "Code for unwritten documents"  => 1,
               },
   'num'    => {},
   'alpha'  => {},
};

################################################################################

$Data{'script'}{'iana'}{'orig'}{'name'} =
  {
   "Geʻez"               => "Ge'ez",
   "Hangŭl"              => "Hangul",
   "Hanunóo"             => "Hanunoo",
   "Moḍī"                 => "Modi",
   "Nüshu"               => "Nushu",
   "N’Ko"                => "N'Ko",
   "na²¹ɕi³³ to³³ba²¹"   => "Nakhi Tomba",
   "na²¹ɕi³³ gʌ²¹ba²¹"   => "Nakhi Geba",
   "'Na-'Khi ²Ggŏ-¹baw"  => "'Na-'Khi Ggo-baw",
   "Śāradā"              => "Sarada",
   "Ṭākrī"               => "Takri",
   "Ṭāṅkrī"              => "Tankri",
   "Róng"                => "Rong",
   "Siddhaṃ"            => "Siddham",
   "Siddhamātṛkā"        => "Siddhamatrka",
   "Nepāla lipi"         => "Nepala lipi",
   "Oberi Ɔkaimɛ"        => "Oberi Okaime",
   "Zanabazarin Dörböljin Useg" => "Zanabazarin Dorboljin Useg",
   "Xewtee Dörböljin Bicig" => "Xewtee Dorboljin Bicig",
};

$Data{'script'}{'iana'}{'ignore'} = {
   'name'   => {
                "Private use"   => 1,
                "Code for uncoded script"       => 1,
                "Code for undetermined script"  => 1,
                "Code for unwritten documents"  => 1,
               },
   'alpha'  => {},
};

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

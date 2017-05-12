#!/usr/bin/perl -w
# Copyright (c) 2010-2017 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

$Data{'currency'}{'link'} =
  [
  ];

################################################################################

$Data{'currency'}{'iso'}{'orig'}{'name'} = {
   "CFA Franc BCEAO "      => "CFA Franc BCEAO",
   "CFA Franc BEAC "       => "CFA Franc BEAC",
   "Ngultrum "             => "Ngultrum",
   "Unidades de fomento "  => "Unidades de fomento",
   "Pa’anga"               => "Pa'anga",
   "Pa\x{2019}anga"        => "Pa'anga",
   "US Dollar (Next day) " => "US Dollar (Next day)",
   "US Dollar (Same day) " => "US Dollar (Same day)",
   "Bond Markets Unit European Monetary Unit (E.M.U.-6) "
                           => "Bond Markets Unit European Monetary Unit (E.M.U.-6)",
   "?LAND ISLANDS"      => "Aland Islands",
   "C?TE D'IVOIRE"      => "Cote d'Ivoire",
   "CURA?AO"            => "Curacao",
   "INTERNATIONAL MONETARY FUND (IMF)?"
                           => "International Monetary Fund (IMF)?",
   "KOREA, DEMOCRATIC PEOPLE’S REPUBLIC OF"
                           => "Korea, Democratic People's Republic of",
   "LAO PEOPLE’S DEMOCRATIC REPUBLIC"
                           => "Lao People's Democratic Republic",
   "R?UNION"            => "Reunion",
   "SAINT BARTH?LEMY"   => "Saint Barthelemy",
   "Bolívar"            => "Bolivar",
   "Bol\x{ed}var"       => "Bolivar",
};

$Data{'currency'}{'iso'}{'ignore'} = {
   "name"   => {
                "Codes specifically reserved for testing purposes"   => 1,
                "The codes assigned for transactions where no currency is involved"    => 1,
               },
   "num"    => {},
   "alpha"  => {},
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

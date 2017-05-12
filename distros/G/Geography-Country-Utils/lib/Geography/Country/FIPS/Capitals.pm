#                              -*- Mode: Perl -*- 
################### Original code was by
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Mon Aug 28 16:37:39 1995
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Mar 24 14:21:39 1996
# Language        : Perl
# Update Count    : 5
# Status          : Unknown, Use with caution!
# 
# (C) Copyright 1995, Universität Dortmund, all rights reserved.
# 
# HISTORY
# 
# $Locker: pfeifer $
# $Log: Country.pm,v $
# Revision 0.1.1.1  1996/03/25 11:19:18  pfeifer
# patch1:
#
# Revision 1.1  1996/03/24 13:33:52  pfeifer
# Initial revision
#
# 
######### Changed database to FIPS, renamed to a new module
# BUG: iso2fips will yield wrong answers with Yemen, Virgin Islands
# or simillar countries with doubles

package Geography::Country::FIPS::Capitals;
require Exporter;
@EXPORT_OK = qw(Capital);
@ISA = qw(Exporter);

while (<DATA>) {
    chop;
    ($cc, $rest) = split ' ', $_, 2;
    next unless $cc;
    $capital{$cc} = $rest;
    }
close (DATA);

sub Capital { $capital{uc($_[0])} || $_[0] };


1;

__DATA__
AA Oranjestad
AC Saint John's
AF Kabul
AG Algiers
AL Tirana
AN Andorra la Vella
AO Luanda
AQ Pago Pago
AR Buenos Aires
AS Canberra
AU Vienna
AV The Valley
BA Manama
BB Bridgetown
BC Gaborone
BD Hamilton
BE Brussels
BF Nassau
BG Dhaka
BH Belmopan
BP Honiara
BR Brasilia
BT Thimphu
BU Sofia
BX Bandar Seri Begawan
BY Bujumbura
CA Ottawa
CB Phnom Penh
CD N'Djamena
CE Colombo
CF Brazzaville
CG Kinshasa
CH Beijing
CI Santiago
CJ George Town
CK West Island
CM Yaounde
CN Moroni
CO Bogota
CQ Saipan
CS San Jose
CT Bangui
CU Havana
CV Praia
CW Avarua
CY Nicosia
DA Copenhagen
DJ Djibouti
DO Roseau
DR Santo Domingo
EC Quito
EG Cairo
EI Dublin
EK Malabo
EN Tallinn
ES San Salvador
ET Addis Ababa
FG Cayenne
FI Helsinki
FJ Suva
FM Palikir
FO Torshavn
FP Papeete
FR Paris
GA Banjul
GB Libreville
GH Accra
GI Gibraltar
GJ Saint George's
GK Saint Peter Port
GL Nuuk (Godthab)
GM Berlin
GP Basse-Terre
GQ Hagatna (Agana)
GR Athens
GT Guatemala
GV Conakry
GY Georgetown
HA Port-au-Prince
HO Tegucigalpa
HU Budapest
IC Reykjavik
ID Jakarta
IM Douglas
IN New Delhi
IR Tehran
IS Jerusalem
IT Rome
IV Yamoussoukro
IZ Baghdad
JA Tokyo
JE Saint Helier
JM Kingston
JO Amman
KE Nairobi
KN P'yongyang
KR Tarawa
KS Seoul
KT The Settlement
KU Kuwait
LA Vientiane
LE Beirut
LG Riga
LH Vilnius
LI Monrovia
LS Vaduz
LT Maseru
LU Luxembourg
LY Tripoli
MA Antananarivo
MB Fort-de-France
MF Mamoutzou
MG Ulaanbaatar
MI Lilongwe
ML Bamako
MN Monaco
MO Rabat
MP Port Louis
MR Nouakchott
MT Valletta
MU Muscat
MV Male
MX Mexico
MY Kuala Lumpur
MZ Maputo
NC Noumea
NE Alofi
NF Kingston
NG Niamey
NH Port-Vila
NI Abuja
NL Amsterdam
NO Oslo
NP Kathmandu
NS Paramaribo
NT Willemstad
NU Managua
NZ Wellington
PA Asuncion
PC Adamstown
PE Lima
PK Islamabad
PL Warsaw
PM Panama
PO Lisbon
PP Port Moresby
PS Koror
PU Bissau
QA Doha
RE Saint-Denis
RM Majuro
RO Bucharest
RP Manila
RQ San Juan
RW Kigali
SA Riyadh
SB Saint-Pierre
SC Basseterre
SE Victoria
SG Dakar
SH Jamestown
SL Freetown
SM San Marino
SN Singapore
SO Mogadishu
SP Madrid
ST Castries
SU Khartoum
SV Longyearbyen
SW Stockholm
SY Damascus
SZ Bern
TC Abu Dhabi
TD Port-of-Spain
TH Bangkok
TN Nuku'alofa
TO Lome
TP Sao Tome
TS Tunis
TU Ankara
TV Funafuti
TW Taipei
TZ Dar es Salaam
UA Kiev
UG Kampala
UK London
US Washington, DC
UV Ouagadougou
UY Montevideo
VC Kingstown
VE Caracas
VI Road Town
VM Hanoi
VQ Charlotte Amalie
VT Vatican City
WA Windhoek
WI none
WS Apia
ZA Lusaka
ZI Harare

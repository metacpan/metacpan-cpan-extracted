package Geo::Postcodes::DK;

#################################################################################
#                                                                               #
#           This file is written by Arne Sommer - perl@bbop.org                 #
#                                                                               #
#################################################################################

use Geo::Postcodes 0.31;
use base qw(Geo::Postcodes);

use strict;
use warnings;

our $VERSION = '0.32';

## Which fields are available ##################################################

my @valid_fields = qw(postcode location address owner type type_verbose);
  # Used by the 'get_fields' procedure.

my %valid_fields; # Used by the 'is_field' procedure/method.

foreach (@valid_fields)
{
  $valid_fields{$_} = 1;
}

## Private Variables ############################################################

my (%location, %borough, %type, %address, %owner);

## Type Description #############################################################

my %typedesc;

$typedesc{BX} = "Postboks";
$typedesc{ST} = "Gadeadresse";
$typedesc{IO} = "Personlig ejer";
$typedesc{PP} = "Ufrankerede svarforsendelser";

## OO Methods ###################################################################

sub new
{
  my $class    = shift;
  my $postcode = shift;

  return unless valid($postcode);

  my $self = bless \(my $dummy), $class;

  $Geo::Postcodes::postcode_of  {$self} = $postcode;
  $Geo::Postcodes::location_of  {$self} = location_of($postcode);
  $Geo::Postcodes::type_of      {$self} = type_of($postcode);
  $Geo::Postcodes::owner_of     {$self} = owner_of($postcode);
  $Geo::Postcodes::address_of   {$self} = address_of($postcode);

  return $self;
}

sub DESTROY
{
  my $object_id = $_[0];

  delete $Geo::Postcodes::postcode_of  {$object_id};
  delete $Geo::Postcodes::location_of  {$object_id};
  delete $Geo::Postcodes::type_of      {$object_id};
  delete $Geo::Postcodes::owner_of     {$object_id};
  delete $Geo::Postcodes::address_of   {$object_id};
}

sub get_fields
{
  return @valid_fields;
}

sub is_field
{
  my $field = shift;
  $field    = shift if $field =~ /Geo::Postcodes/; # Called on an object.

  return 1 if $valid_fields{$field};
  return 0;
}

sub type_verbose # Override the one in the base class.
{
  my $self = shift;
  return unless $self;
  return unless $Geo::Postcodes::type_of{$self};
  return unless $typedesc{$Geo::Postcodes::type_of{$self}};
  return $typedesc{$Geo::Postcodes::type_of{$self}};
}

## Global Procedures ############################################################

sub legal # Is it a legal code, i.e. something that follows the syntax rule.
{
  my $postcode = shift;
  return 0 unless $postcode;
  return 0 unless $postcode =~ /^\d{3,4}$/;
  return 1;
}

sub valid # Is the code in actual use.
{
  my $postcode = shift;
  return 0 unless legal($postcode);

  return 1 if $location{$postcode};
  return 0;
}

sub postcode_of # So that 'selection' does not choke.
{
  my $postcode = shift;
  return $postcode;
}

sub location_of
{
  my $postcode = shift;
  return unless $postcode;

  return $location{$postcode} if $location{$postcode};
  return;
}

sub address_of
{
  my $postcode = shift;
  return unless $postcode;

  return $address{$postcode} if $address{$postcode};
  return;
}

sub owner_of
{
  my $postcode = shift;
  return unless $postcode;

  return $owner{$postcode} if $owner{$postcode};
  return;
}

sub type_of
{
  my $postcode = shift;
  return unless $postcode;
  return unless $type{$postcode};

  return $type{$postcode};
}

sub type_verbose_of
{
  my $postcode = shift;
  return unless $postcode;

  my $type = type_of($postcode);
  return unless $type;

  return type2verbose($type);
}

sub type2verbose
{
  my $type = shift;
  return unless $type;
  return unless $typedesc{$type};
  return $typedesc{$type};
}

sub get_postcodes
{
  return keys %location;
}

## Returns a list of postcodes if called as a procedure; Geo::Postcodes::DK::selection(xx => 'yy')
## Returns a list of objects if called as a method;      Geo::Postcodes::DK->selection(xx => 'yy')

sub verify_selectionlist
{
  return Geo::Postcodes::_verify_selectionlist("Geo::Postcodes::DK", @_);
}

sub selection
{
  return Geo::Postcodes::_selection("Geo::Postcodes::DK", @_);
    # Black magic.
}

sub selection_loop
{
  return Geo::Postcodes::_selection_loop('Geo::Postcodes::DK', @_);
    # Black magic.
}

## misc/update begin
## This data structure was auto generated on Tue Nov 16 19:48:17 2010. Do NOT edit it!

$location{'0555'} = "Scanning"; $owner{'0555'} = "Data Scanning A/S, \"Læs Ind\"-service";
$location{'0800'} = "Høje Taastrup"; $owner{'0800'} = "BG-Bank A/S"; $type{'0800'} = "IO";
$location{'0877'} = "Københvn C"; $owner{'0877'} = "Aller Press (konkurrencer)"; $type{'0877'} = "IO";
$location{'0892'} = "Sjælland USF P"; $owner{'0892'} = "Ufrankerede svarforsendelser";
$location{'0893'} = "Sjælland USF B"; $owner{'0893'} = "Ufrankerede svarforsendelser";
$location{'0897'} = "eBrevsprækken"; $owner{'0897'} = "(Post til scanning)";
$location{'0899'} = "Kommuneservice"; $owner{'0899'} = "(Post til scanning)";
$location{'0900'} = "København C"; $owner{'0900'} = "Københavns Postcenter + erhvervskunder";
$location{'0910'} = "København C"; $type{'0910'} = "PP";
$location{'0918'} = "Københavns Pakke BRC"; $owner{'0918'} = "(Returpakker)";
$location{'0929'} = "København C"; $type{'0929'} = "PP";
$location{'0999'} = "København C"; $owner{'0999'} = "DR Byen"; $type{'0999'} = "IO";
$location{'1000'} = "København K"; $owner{'1000'} = "Købmagergades Postkontor"; $type{'1000'} = "IO";
$location{'1001'} = "København K"; $type{'1001'} = "BX";
$location{'1002'} = "København K"; $type{'1002'} = "BX";
$location{'1003'} = "København K"; $type{'1003'} = "BX";
$location{'1004'} = "København K"; $type{'1004'} = "BX";
$location{'1005'} = "København K"; $type{'1005'} = "BX";
$location{'1006'} = "København K"; $type{'1006'} = "BX";
$location{'1007'} = "København K"; $type{'1007'} = "BX";
$location{'1008'} = "København K"; $type{'1008'} = "BX";
$location{'1009'} = "København K"; $type{'1009'} = "BX";
$location{'1010'} = "København K"; $type{'1010'} = "BX";
$location{'1011'} = "København K"; $type{'1011'} = "BX";
$location{'1012'} = "København K"; $type{'1012'} = "BX";
$location{'1013'} = "København K"; $type{'1013'} = "BX";
$location{'1014'} = "København K"; $type{'1014'} = "BX";
$location{'1015'} = "København K"; $type{'1015'} = "BX";
$location{'1016'} = "København K"; $type{'1016'} = "BX";
$location{'1017'} = "København K"; $type{'1017'} = "BX";
$location{'1018'} = "København K"; $type{'1018'} = "BX";
$location{'1019'} = "København K"; $type{'1019'} = "BX";
$location{'1020'} = "København K"; $type{'1020'} = "BX";
$location{'1021'} = "København K"; $type{'1021'} = "BX";
$location{'1022'} = "København K"; $type{'1022'} = "BX";
$location{'1023'} = "København K"; $type{'1023'} = "BX";
$location{'1024'} = "København K"; $type{'1024'} = "BX";
$location{'1025'} = "København K"; $type{'1025'} = "BX";
$location{'1026'} = "København K"; $type{'1026'} = "BX";
$location{'1045'} = "København K"; $type{'1045'} = "PP";
$location{'1050'} = "København K"; $address{'1050'} = "Kongens Nytorv"; $type{'1050'} = "ST";
$location{'1051'} = "København K"; $address{'1051'} = "Nyhavn"; $type{'1051'} = "ST";
$location{'1052'} = "København K"; $address{'1052'} = "Herluf Trolles Gade"; $type{'1052'} = "ST";
$location{'1053'} = "København K"; $address{'1053'} = "Cort Adelers Gade"; $type{'1053'} = "ST";
$location{'1054'} = "København K"; $address{'1054'} = "Peder Skrams Gade"; $type{'1054'} = "ST";
$location{'1055'} = "København K"; $address{'1055'} = "Tordenskjoldsgade"; $type{'1055'} = "ST";
$location{'1055'} = "København K"; $address{'1055'} = "Tordenskjoldsgade"; $type{'1055'} = "ST";
$location{'1056'} = "København K"; $address{'1056'} = "Heibergsgade"; $type{'1056'} = "ST";
$location{'1057'} = "København K"; $address{'1057'} = "Holbergsgade"; $type{'1057'} = "ST";
$location{'1058'} = "København K"; $address{'1058'} = "Havnegade"; $type{'1058'} = "ST";
$location{'1059'} = "København K"; $address{'1059'} = "Niels Juels Gade"; $type{'1059'} = "ST";
$location{'1060'} = "København K"; $address{'1060'} = "Holmens Kanal"; $type{'1060'} = "ST";
$location{'1061'} = "København K"; $address{'1061'} = "Ved Stranden"; $type{'1061'} = "ST";
$location{'1062'} = "København K"; $address{'1062'} = "Boldhusgade"; $type{'1062'} = "ST";
$location{'1063'} = "København K"; $address{'1063'} = "Laksegade"; $type{'1063'} = "ST";
$location{'1064'} = "København K"; $address{'1064'} = "Asylgade"; $type{'1064'} = "ST";
$location{'1065'} = "København K"; $address{'1065'} = "Fortunstræde"; $type{'1065'} = "ST";
$location{'1066'} = "København K"; $address{'1066'} = "Admiralgade"; $type{'1066'} = "ST";
$location{'1067'} = "København K"; $address{'1067'} = "Nikolaj Plads"; $type{'1067'} = "ST";
$location{'1068'} = "København K"; $address{'1068'} = "Nikolajgade"; $type{'1068'} = "ST";
$location{'1069'} = "København K"; $address{'1069'} = "Bremerholm"; $type{'1069'} = "ST";
$location{'1070'} = "København K"; $address{'1070'} = "Vingårdstræde"; $type{'1070'} = "ST";
$location{'1071'} = "København K"; $address{'1071'} = "Dybensgade"; $type{'1071'} = "ST";
$location{'1072'} = "København K"; $address{'1072'} = "Lille Kirkestræde"; $type{'1072'} = "ST";
$location{'1073'} = "København K"; $address{'1073'} = "Store Kirkestræde"; $type{'1073'} = "ST";
$location{'1074'} = "København K"; $address{'1074'} = "Lille Kongensgade"; $type{'1074'} = "ST";
$location{'1092'} = "København K"; $owner{'1092'} = "Danske Bank A/S"; $type{'1092'} = "IO";
$location{'1093'} = "København K"; $owner{'1093'} = "Danmarks Nationalbank"; $type{'1093'} = "IO";
$location{'1095'} = "København K"; $owner{'1095'} = "Magasin du Nord"; $type{'1095'} = "IO";
$location{'1098'} = "København K"; $owner{'1098'} = "A.P. Møller"; $type{'1098'} = "IO";
$location{'1100'} = "København K"; $address{'1100'} = "Østergade"; $type{'1100'} = "ST";
$location{'1101'} = "København K"; $address{'1101'} = "Ny Østergade"; $type{'1101'} = "ST";
$location{'1102'} = "København K"; $address{'1102'} = "Pistolstræde"; $type{'1102'} = "ST";
$location{'1103'} = "København K"; $address{'1103'} = "Hovedvagtsgade"; $type{'1103'} = "ST";
$location{'1104'} = "København K"; $address{'1104'} = "Ny Adelgade"; $type{'1104'} = "ST";
$location{'1105'} = "København K"; $address{'1105'} = "Kristen Bernikows Gade"; $type{'1105'} = "ST";
$location{'1106'} = "København K"; $address{'1106'} = "Antonigade"; $type{'1106'} = "ST";
$location{'1107'} = "København K"; $address{'1107'} = "Grønnegade"; $type{'1107'} = "ST";
$location{'1110'} = "København K"; $address{'1110'} = "Store Regnegade"; $type{'1110'} = "ST";
$location{'1111'} = "København K"; $address{'1111'} = "Christian IX's Gade"; $type{'1111'} = "ST";
$location{'1112'} = "København K"; $address{'1112'} = "Pilestræde"; $type{'1112'} = "ST";
$location{'1113'} = "København K"; $address{'1113'} = "Silkegade"; $type{'1113'} = "ST";
$location{'1114'} = "København K"; $address{'1114'} = "Kronprinsensgade"; $type{'1114'} = "ST";
$location{'1115'} = "København K"; $address{'1115'} = "Klareboderne"; $type{'1115'} = "ST";
$location{'1116'} = "København K"; $address{'1116'} = "Møntergade"; $type{'1116'} = "ST";
$location{'1117'} = "København K"; $address{'1117'} = "Gammel Mønt"; $type{'1117'} = "ST";
$location{'1118'} = "København K"; $address{'1118'} = "Sværtegade"; $type{'1118'} = "ST";
$location{'1119'} = "København K"; $address{'1119'} = "Landemærket"; $type{'1119'} = "ST";
$location{'1120'} = "København K"; $address{'1120'} = "Vognmagergade"; $type{'1120'} = "ST";
$location{'1121'} = "København K"; $address{'1121'} = "Lønporten"; $type{'1121'} = "ST";
$location{'1122'} = "København K"; $address{'1122'} = "Sjæleboderne"; $type{'1122'} = "ST";
$location{'1123'} = "København K"; $address{'1123'} = "Gothersgade"; $type{'1123'} = "ST";
$location{'1124'} = "København K"; $address{'1124'} = "Åbenrå"; $type{'1124'} = "ST";
$location{'1125'} = "København K"; $address{'1125'} = "Suhmsgade"; $type{'1125'} = "ST";
$location{'1126'} = "København K"; $address{'1126'} = "Pustervig"; $type{'1126'} = "ST";
$location{'1127'} = "København K"; $address{'1127'} = "Hauser Plads"; $type{'1127'} = "ST";
$location{'1128'} = "København K"; $address{'1128'} = "Hausergade"; $type{'1128'} = "ST";
$location{'1129'} = "København K"; $address{'1129'} = "Sankt Gertruds Stræde"; $type{'1129'} = "ST";
$location{'1130'} = "København K"; $address{'1130'} = "Rosenborggade"; $type{'1130'} = "ST";
$location{'1131'} = "København K"; $address{'1131'} = "Tornebuskegade"; $type{'1131'} = "ST";
$location{'1140'} = "København K"; $owner{'1140'} = "Dagbladet Børsen"; $type{'1140'} = "IO";
$location{'1147'} = "København K"; $owner{'1147'} = "Berlingske Tidende"; $type{'1147'} = "IO";
$location{'1148'} = "København K"; $owner{'1148'} = "Gutenberghus"; $type{'1148'} = "IO";
$location{'1150'} = "København K"; $address{'1150'} = "Købmagergade"; $type{'1150'} = "ST";
$location{'1151'} = "København K"; $address{'1151'} = "Valkendorfsgade"; $type{'1151'} = "ST";
$location{'1152'} = "København K"; $address{'1152'} = "Løvstræde"; $type{'1152'} = "ST";
$location{'1153'} = "København K"; $address{'1153'} = "Niels Hemmingsens Gade"; $type{'1153'} = "ST";
$location{'1154'} = "København K"; $address{'1154'} = "Gråbrødretorv"; $type{'1154'} = "ST";
$location{'1155'} = "København K"; $address{'1155'} = "Kejsergade"; $type{'1155'} = "ST";
$location{'1156'} = "København K"; $address{'1156'} = "Gråbrødrestræde"; $type{'1156'} = "ST";
$location{'1157'} = "København K"; $address{'1157'} = "Klosterstræde"; $type{'1157'} = "ST";
$location{'1158'} = "København K"; $address{'1158'} = "Skoubogade"; $type{'1158'} = "ST";
$location{'1159'} = "København K"; $address{'1159'} = "Skindergade"; $type{'1159'} = "ST";
$location{'1160'} = "København K"; $address{'1160'} = "Amagertorv"; $type{'1160'} = "ST";
$location{'1161'} = "København K"; $address{'1161'} = "Vimmelskaftet"; $type{'1161'} = "ST";
$location{'1162'} = "København K"; $address{'1162'} = "Jorcks Passage"; $type{'1162'} = "ST";
$location{'1163'} = "København K"; $address{'1163'} = "Klostergården"; $type{'1163'} = "ST";
$location{'1164'} = "København K"; $address{'1164'} = "Nygade"; $type{'1164'} = "ST";
$location{'1165'} = "København K"; $address{'1165'} = "Nørregade"; $type{'1165'} = "ST";
$location{'1165'} = "København K"; $address{'1165'} = "Nørregade"; $type{'1165'} = "ST";
$location{'1166'} = "København K"; $address{'1166'} = "Dyrkøb"; $type{'1166'} = "ST";
$location{'1167'} = "København K"; $address{'1167'} = "Bispetorvet"; $type{'1167'} = "ST";
$location{'1168'} = "København K"; $address{'1168'} = "Frue Plads"; $type{'1168'} = "ST";
$location{'1169'} = "København K"; $address{'1169'} = "Store Kannikestræde"; $type{'1169'} = "ST";
$location{'1170'} = "København K"; $address{'1170'} = "Lille Kannikestræde"; $type{'1170'} = "ST";
$location{'1171'} = "København K"; $address{'1171'} = "Fiolstræde"; $type{'1171'} = "ST";
$location{'1172'} = "København K"; $address{'1172'} = "Krystalgade"; $type{'1172'} = "ST";
$location{'1173'} = "København K"; $address{'1173'} = "Peder Hvitfeldts Stræde"; $type{'1173'} = "ST";
$location{'1174'} = "København K"; $address{'1174'} = "Rosengården"; $type{'1174'} = "ST";
$location{'1175'} = "København K"; $address{'1175'} = "Kultorvet"; $type{'1175'} = "ST";
$location{'1200'} = "København K"; $address{'1200'} = "Højbro Plads"; $type{'1200'} = "ST";
$location{'1201'} = "København K"; $address{'1201'} = "Læderstræde"; $type{'1201'} = "ST";
$location{'1202'} = "København K"; $address{'1202'} = "Gammel Strand"; $type{'1202'} = "ST";
$location{'1203'} = "København K"; $address{'1203'} = "Nybrogade"; $type{'1203'} = "ST";
$location{'1204'} = "København K"; $address{'1204'} = "Magstræde"; $type{'1204'} = "ST";
$location{'1205'} = "København K"; $address{'1205'} = "Snaregade"; $type{'1205'} = "ST";
$location{'1206'} = "København K"; $address{'1206'} = "Naboløs"; $type{'1206'} = "ST";
$location{'1207'} = "København K"; $address{'1207'} = "Hyskenstræde"; $type{'1207'} = "ST";
$location{'1208'} = "København K"; $address{'1208'} = "Kompagnistræde"; $type{'1208'} = "ST";
$location{'1209'} = "København K"; $address{'1209'} = "Badstuestræde"; $type{'1209'} = "ST";
$location{'1210'} = "København K"; $address{'1210'} = "Knabrostræde"; $type{'1210'} = "ST";
$location{'1211'} = "København K"; $address{'1211'} = "Brolæggerstræde"; $type{'1211'} = "ST";
$location{'1212'} = "København K"; $address{'1212'} = "Vindebrogade"; $type{'1212'} = "ST";
$location{'1213'} = "København K"; $address{'1213'} = "Bertel Thorvaldsens Plads"; $type{'1213'} = "ST";
$location{'1214'} = "København K"; $address{'1214'} = "Tøjhusgade"; $type{'1214'} = "ST";
$location{'1215'} = "København K"; $address{'1215'} = "Børsgade"; $type{'1215'} = "ST";
$location{'1216'} = "København K"; $address{'1216'} = "Slotsholmsgade"; $type{'1216'} = "ST";
$location{'1217'} = "København K"; $address{'1217'} = "Børsen"; $type{'1217'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1218'} = "København K"; $address{'1218'} = "Rigsdagsgården"; $type{'1218'} = "ST";
$location{'1219'} = "København K"; $address{'1219'} = "Christians Brygge 1-5 + 8"; $type{'1219'} = "ST";
$location{'1220'} = "København K"; $address{'1220'} = "Frederiksholms Kanal"; $type{'1220'} = "ST";
$location{'1221'} = "København K"; $address{'1221'} = "Søren Kierkegaards Plads"; $type{'1221'} = "ST";
$location{'1240'} = "København K"; $owner{'1240'} = "Folketinget"; $type{'1240'} = "IO";
$location{'1250'} = "København K"; $address{'1250'} = "Sankt Annæ Plads"; $type{'1250'} = "ST";
$location{'1251'} = "København K"; $address{'1251'} = "Kvæsthusgade"; $type{'1251'} = "ST";
$location{'1252'} = "København K"; $address{'1252'} = "Kvæsthusbroen"; $type{'1252'} = "ST";
$location{'1253'} = "København K"; $address{'1253'} = "Toldbodgade"; $type{'1253'} = "ST";
$location{'1254'} = "København K"; $address{'1254'} = "Lille Strandstræde"; $type{'1254'} = "ST";
$location{'1255'} = "København K"; $address{'1255'} = "Store Strandstræde"; $type{'1255'} = "ST";
$location{'1256'} = "København K"; $address{'1256'} = "Amaliegade"; $type{'1256'} = "ST";
$location{'1257'} = "København K"; $address{'1257'} = "Amalienborg"; $type{'1257'} = "ST";
$location{'1258'} = "København K"; $address{'1258'} = "Larsens Plads"; $type{'1258'} = "ST";
$location{'1259'} = "København K"; $address{'1259'} = "Trekroner"; $type{'1259'} = "ST";
$location{'1259'} = "København K"; $address{'1259'} = "Trekroner"; $type{'1259'} = "ST";
$location{'1260'} = "København K"; $address{'1260'} = "Bredgade"; $type{'1260'} = "ST";
$location{'1261'} = "København K"; $address{'1261'} = "Palægade"; $type{'1261'} = "ST";
$location{'1263'} = "København K"; $address{'1263'} = "Churchillparken"; $type{'1263'} = "ST";
$location{'1263'} = "København K"; $address{'1263'} = "Churchillparken"; $type{'1263'} = "ST";
$location{'1264'} = "København K"; $address{'1264'} = "Store Kongensgade"; $type{'1264'} = "ST";
$location{'1265'} = "København K"; $address{'1265'} = "Frederiksgade"; $type{'1265'} = "ST";
$location{'1266'} = "København K"; $address{'1266'} = "Bornholmsgade"; $type{'1266'} = "ST";
$location{'1267'} = "København K"; $address{'1267'} = "Hammerensgade"; $type{'1267'} = "ST";
$location{'1268'} = "København K"; $address{'1268'} = "Jens Kofods Gade"; $type{'1268'} = "ST";
$location{'1270'} = "København K"; $address{'1270'} = "Grønningen"; $type{'1270'} = "ST";
$location{'1271'} = "København K"; $address{'1271'} = "Poul Ankers Gade"; $type{'1271'} = "ST";
$location{'1291'} = "København K"; $owner{'1291'} = "J. Lauritzen A/S"; $type{'1291'} = "IO";
$location{'1300'} = "København K"; $address{'1300'} = "Borgergade"; $type{'1300'} = "ST";
$location{'1301'} = "København K"; $address{'1301'} = "Landgreven"; $type{'1301'} = "ST";
$location{'1302'} = "København K"; $address{'1302'} = "Dronningens Tværgade"; $type{'1302'} = "ST";
$location{'1303'} = "København K"; $address{'1303'} = "Hindegade"; $type{'1303'} = "ST";
$location{'1304'} = "København K"; $address{'1304'} = "Adelgade"; $type{'1304'} = "ST";
$location{'1306'} = "København K"; $address{'1306'} = "Kronprinsessegade"; $type{'1306'} = "ST";
$location{'1307'} = "København K"; $address{'1307'} = "Sølvgade"; $type{'1307'} = "ST";
$location{'1307'} = "København K"; $address{'1307'} = "Sølvgade"; $type{'1307'} = "ST";
$location{'1308'} = "København K"; $address{'1308'} = "Klerkegade"; $type{'1308'} = "ST";
$location{'1309'} = "København K"; $address{'1309'} = "Rosengade"; $type{'1309'} = "ST";
$location{'1310'} = "København K"; $address{'1310'} = "Fredericiagade"; $type{'1310'} = "ST";
$location{'1311'} = "København K"; $address{'1311'} = "Olfert Fischers Gade"; $type{'1311'} = "ST";
$location{'1312'} = "København K"; $address{'1312'} = "Gammelvagt"; $type{'1312'} = "ST";
$location{'1313'} = "København K"; $address{'1313'} = "Sankt Pauls Gade"; $type{'1313'} = "ST";
$location{'1314'} = "København K"; $address{'1314'} = "Sankt Pauls Plads"; $type{'1314'} = "ST";
$location{'1315'} = "København K"; $address{'1315'} = "Rævegade"; $type{'1315'} = "ST";
$location{'1316'} = "København K"; $address{'1316'} = "Rigensgade"; $type{'1316'} = "ST";
$location{'1317'} = "København K"; $address{'1317'} = "Stokhusgade"; $type{'1317'} = "ST";
$location{'1318'} = "København K"; $address{'1318'} = "Krusemyntegade"; $type{'1318'} = "ST";
$location{'1319'} = "København K"; $address{'1319'} = "Gernersgade"; $type{'1319'} = "ST";
$location{'1320'} = "København K"; $address{'1320'} = "Haregade"; $type{'1320'} = "ST";
$location{'1321'} = "København K"; $address{'1321'} = "Tigergade"; $type{'1321'} = "ST";
$location{'1322'} = "København K"; $address{'1322'} = "Suensonsgade"; $type{'1322'} = "ST";
$location{'1323'} = "København K"; $address{'1323'} = "Hjertensfrydsgade"; $type{'1323'} = "ST";
$location{'1324'} = "København K"; $address{'1324'} = "Elsdyrsgade"; $type{'1324'} = "ST";
$location{'1325'} = "København K"; $address{'1325'} = "Delfingade"; $type{'1325'} = "ST";
$location{'1326'} = "København K"; $address{'1326'} = "Krokodillegade"; $type{'1326'} = "ST";
$location{'1327'} = "København K"; $address{'1327'} = "Vildandegade"; $type{'1327'} = "ST";
$location{'1328'} = "København K"; $address{'1328'} = "Svanegade"; $type{'1328'} = "ST";
$location{'1329'} = "København K"; $address{'1329'} = "Timiansgade"; $type{'1329'} = "ST";
$location{'1349'} = "København K"; $owner{'1349'} = "DSB"; $type{'1349'} = "IO";
$location{'1350'} = "København K"; $address{'1350'} = "Øster Voldgade"; $type{'1350'} = "ST";
$location{'1352'} = "København K"; $address{'1352'} = "Rørholmsgade"; $type{'1352'} = "ST";
$location{'1353'} = "København K"; $address{'1353'} = "Øster Farimagsgade 3-15 + 2"; $type{'1353'} = "ST";
$location{'1354'} = "København K"; $address{'1354'} = "Ole Suhrs Gade"; $type{'1354'} = "ST";
$location{'1355'} = "København K"; $address{'1355'} = "Gammeltoftsgade"; $type{'1355'} = "ST";
$location{'1356'} = "København K"; $address{'1356'} = "Bartholinsgade"; $type{'1356'} = "ST";
$location{'1357'} = "København K"; $address{'1357'} = "Øster Søgade 8-36"; $type{'1357'} = "ST";
$location{'1358'} = "København K"; $address{'1358'} = "Nørre Voldgade"; $type{'1358'} = "ST";
$location{'1359'} = "København K"; $address{'1359'} = "Ahlefeldtsgade"; $type{'1359'} = "ST";
$location{'1359'} = "København K"; $address{'1359'} = "Ahlefeldtsgade"; $type{'1359'} = "ST";
$location{'1360'} = "København K"; $address{'1360'} = "Frederiksborggade"; $type{'1360'} = "ST";
$location{'1361'} = "København K"; $address{'1361'} = "Linnésgade"; $type{'1361'} = "ST";
$location{'1361'} = "København K"; $address{'1361'} = "Linnésgade"; $type{'1361'} = "ST";
$location{'1362'} = "København K"; $address{'1362'} = "Rømersgade"; $type{'1362'} = "ST";
$location{'1363'} = "København K"; $address{'1363'} = "Vendersgade"; $type{'1363'} = "ST";
$location{'1364'} = "København K"; $address{'1364'} = "Nørre Farimagsgade"; $type{'1364'} = "ST";
$location{'1365'} = "København K"; $address{'1365'} = "Schacksgade"; $type{'1365'} = "ST";
$location{'1366'} = "København K"; $address{'1366'} = "Nansensgade"; $type{'1366'} = "ST";
$location{'1367'} = "København K"; $address{'1367'} = "Kjeld Langes Gade"; $type{'1367'} = "ST";
$location{'1368'} = "København K"; $address{'1368'} = "Turesensgade"; $type{'1368'} = "ST";
$location{'1369'} = "København K"; $address{'1369'} = "Gyldenløvesgade lige nr."; $type{'1369'} = "ST";
$location{'1370'} = "København K"; $address{'1370'} = "Nørre Søgade"; $type{'1370'} = "ST";
$location{'1371'} = "København K"; $address{'1371'} = "Søtorvet"; $type{'1371'} = "ST";
$location{'1400'} = "København K"; $address{'1400'} = "Knippelsbro"; $type{'1400'} = "ST";
$location{'1400'} = "København K"; $address{'1400'} = "Knippelsbro"; $type{'1400'} = "ST";
$location{'1401'} = "København K"; $address{'1401'} = "Strandgade"; $type{'1401'} = "ST";
$location{'1402'} = "København K"; $address{'1402'} = "David Balfours Gade"; $type{'1402'} = "ST";
$location{'1402'} = "København K"; $address{'1402'} = "David Balfours Gade"; $type{'1402'} = "ST";
$location{'1402'} = "København K"; $address{'1402'} = "David Balfours Gade"; $type{'1402'} = "ST";
$location{'1402'} = "København K"; $address{'1402'} = "David Balfours Gade"; $type{'1402'} = "ST";
$location{'1402'} = "København K"; $address{'1402'} = "David Balfours Gade"; $type{'1402'} = "ST";
$location{'1403'} = "København K"; $address{'1403'} = "Wilders Plads"; $type{'1403'} = "ST";
$location{'1404'} = "København K"; $address{'1404'} = "Krøyers Plads"; $type{'1404'} = "ST";
$location{'1406'} = "København K"; $address{'1406'} = "Christianshavns Kanal"; $type{'1406'} = "ST";
$location{'1407'} = "København K"; $address{'1407'} = "Bådsmandsstræde"; $type{'1407'} = "ST";
$location{'1408'} = "København K"; $address{'1408'} = "Wildersgade"; $type{'1408'} = "ST";
$location{'1409'} = "København K"; $address{'1409'} = "Knippelsbrogade"; $type{'1409'} = "ST";
$location{'1410'} = "København K"; $address{'1410'} = "Christianshavns Torv"; $type{'1410'} = "ST";
$location{'1411'} = "København K"; $address{'1411'} = "Langebrogade"; $type{'1411'} = "ST";
$location{'1411'} = "København K"; $address{'1411'} = "Langebrogade"; $type{'1411'} = "ST";
$location{'1412'} = "København K"; $address{'1412'} = "Voldgården"; $type{'1412'} = "ST";
$location{'1413'} = "København K"; $address{'1413'} = "Ved Kanalen"; $type{'1413'} = "ST";
$location{'1414'} = "København K"; $address{'1414'} = "Overgaden Neden Vandet"; $type{'1414'} = "ST";
$location{'1415'} = "København K"; $address{'1415'} = "Overgaden Oven Vandet"; $type{'1415'} = "ST";
$location{'1416'} = "København K"; $address{'1416'} = "Sankt Annæ Gade"; $type{'1416'} = "ST";
$location{'1417'} = "København K"; $address{'1417'} = "Mikkel Vibes Gade"; $type{'1417'} = "ST";
$location{'1418'} = "København K"; $address{'1418'} = "Sofiegade"; $type{'1418'} = "ST";
$location{'1419'} = "København K"; $address{'1419'} = "Store Søndervoldstræde"; $type{'1419'} = "ST";
$location{'1420'} = "København K"; $address{'1420'} = "Dronningensgade"; $type{'1420'} = "ST";
$location{'1421'} = "København K"; $address{'1421'} = "Lille Søndervoldstræde"; $type{'1421'} = "ST";
$location{'1422'} = "København K"; $address{'1422'} = "Prinsessegade"; $type{'1422'} = "ST";
$location{'1423'} = "København K"; $address{'1423'} = "Amagergade"; $type{'1423'} = "ST";
$location{'1424'} = "København K"; $address{'1424'} = "Christianshavns Voldgade"; $type{'1424'} = "ST";
$location{'1425'} = "København K"; $address{'1425'} = "Ved Volden"; $type{'1425'} = "ST";
$location{'1426'} = "København K"; $address{'1426'} = "Voldboligerne"; $type{'1426'} = "ST";
$location{'1427'} = "København K"; $address{'1427'} = "Brobergsgade"; $type{'1427'} = "ST";
$location{'1428'} = "København K"; $address{'1428'} = "Andreas Bjørns Gade"; $type{'1428'} = "ST";
$location{'1429'} = "København K"; $address{'1429'} = "Burmeistersgade"; $type{'1429'} = "ST";
$location{'1430'} = "København K"; $address{'1430'} = "Bodenhoffs Plads"; $type{'1430'} = "ST";
$location{'1431'} = "København K"; $address{'1431'} = "Islands Plads"; $type{'1431'} = "ST";
$location{'1432'} = "København K"; $address{'1432'} = "William Wains Gade"; $type{'1432'} = "ST";
$location{'1432'} = "København K"; $address{'1432'} = "William Wains Gade"; $type{'1432'} = "ST";
$location{'1432'} = "København K"; $address{'1432'} = "William Wains Gade"; $type{'1432'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1433'} = "København K"; $address{'1433'} = "Refshaleøen"; $type{'1433'} = "ST";
$location{'1434'} = "København K"; $address{'1434'} = "Danneskiold-Samsøes Allé"; $type{'1434'} = "ST";
$location{'1435'} = "København K"; $address{'1435'} = "Philip De Langes Allé"; $type{'1435'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1436'} = "København K"; $address{'1436'} = "Kuglegårdsvej"; $type{'1436'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1437'} = "København K"; $address{'1437'} = "Per Knutzons Vej"; $type{'1437'} = "ST";
$location{'1438'} = "København K"; $address{'1438'} = "Judichærs Plads"; $type{'1438'} = "ST";
$location{'1438'} = "København K"; $address{'1438'} = "Judichærs Plads"; $type{'1438'} = "ST";
$location{'1438'} = "København K"; $address{'1438'} = "Judichærs Plads"; $type{'1438'} = "ST";
$location{'1438'} = "København K"; $address{'1438'} = "Judichærs Plads"; $type{'1438'} = "ST";
$location{'1438'} = "København K"; $address{'1438'} = "Judichærs Plads"; $type{'1438'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1439'} = "København K"; $address{'1439'} = "Krudtløbsvej"; $type{'1439'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1440'} = "København K"; $address{'1440'} = "Sydområdet"; $type{'1440'} = "ST";
$location{'1441'} = "København K"; $address{'1441'} = "Norddyssen"; $type{'1441'} = "ST";
$location{'1441'} = "København K"; $address{'1441'} = "Norddyssen"; $type{'1441'} = "ST";
$location{'1441'} = "København K"; $address{'1441'} = "Norddyssen"; $type{'1441'} = "ST";
$location{'1448'} = "København K"; $owner{'1448'} = "Udenrigsministeriet"; $type{'1448'} = "IO";
$location{'1450'} = "København K"; $address{'1450'} = "Nytorv"; $type{'1450'} = "ST";
$location{'1451'} = "København K"; $address{'1451'} = "Larslejsstræde"; $type{'1451'} = "ST";
$location{'1452'} = "København K"; $address{'1452'} = "Teglgårdstræde"; $type{'1452'} = "ST";
$location{'1453'} = "København K"; $address{'1453'} = "Sankt Peders Stræde"; $type{'1453'} = "ST";
$location{'1454'} = "København K"; $address{'1454'} = "Larsbjørnsstræde"; $type{'1454'} = "ST";
$location{'1455'} = "København K"; $address{'1455'} = "Studiestræde 3-49 + 6-40"; $type{'1455'} = "ST";
$location{'1456'} = "København K"; $address{'1456'} = "Vestergade"; $type{'1456'} = "ST";
$location{'1457'} = "København K"; $address{'1457'} = "Gammeltorv"; $type{'1457'} = "ST";
$location{'1458'} = "København K"; $address{'1458'} = "Kattesundet"; $type{'1458'} = "ST";
$location{'1459'} = "København K"; $address{'1459'} = "Frederiksberggade"; $type{'1459'} = "ST";
$location{'1460'} = "København K"; $address{'1460'} = "Mikkel Bryggers Gade"; $type{'1460'} = "ST";
$location{'1461'} = "København K"; $address{'1461'} = "Slutterigade"; $type{'1461'} = "ST";
$location{'1462'} = "København K"; $address{'1462'} = "Lavendelstræde"; $type{'1462'} = "ST";
$location{'1463'} = "København K"; $address{'1463'} = "Farvergade"; $type{'1463'} = "ST";
$location{'1464'} = "København K"; $address{'1464'} = "Hestemøllestræde"; $type{'1464'} = "ST";
$location{'1465'} = "København K"; $address{'1465'} = "Gåsegade"; $type{'1465'} = "ST";
$location{'1466'} = "København K"; $address{'1466'} = "Rådhusstræde"; $type{'1466'} = "ST";
$location{'1467'} = "København K"; $address{'1467'} = "Vandkunsten"; $type{'1467'} = "ST";
$location{'1468'} = "København K"; $address{'1468'} = "Løngangstræde"; $type{'1468'} = "ST";
$location{'1470'} = "København K"; $address{'1470'} = "Stormgade 2-14"; $type{'1470'} = "ST";
$location{'1471'} = "København K"; $address{'1471'} = "Ny Vestergade"; $type{'1471'} = "ST";
$location{'1472'} = "København K"; $address{'1472'} = "Ny Kongensgade  1-15 + 4-14"; $type{'1472'} = "ST";
$location{'1473'} = "København K"; $address{'1473'} = "Bryghusgade"; $type{'1473'} = "ST";
$location{'1500'} = "København V"; $owner{'1500'} = "Vesterbro Postkontor"; $type{'1500'} = "IO";
$location{'1501'} = "København V"; $type{'1501'} = "BX";
$location{'1502'} = "København V"; $type{'1502'} = "BX";
$location{'1503'} = "København V"; $type{'1503'} = "BX";
$location{'1504'} = "København V"; $type{'1504'} = "BX";
$location{'1505'} = "København V"; $type{'1505'} = "BX";
$location{'1506'} = "København V"; $type{'1506'} = "BX";
$location{'1507'} = "København V"; $type{'1507'} = "BX";
$location{'1508'} = "København V"; $type{'1508'} = "BX";
$location{'1509'} = "København V"; $type{'1509'} = "BX";
$location{'1510'} = "København V"; $type{'1510'} = "BX";
$location{'1532'} = "København V"; $owner{'1532'} = "Internationalt Postcenter, returforsendelser + consignment"; $type{'1532'} = "IO";
$location{'1533'} = "København V"; $owner{'1533'} = "Internationalt Postcenter"; $type{'1533'} = "IO";
$location{'1550'} = "København V"; $address{'1550'} = "Bag Rådhuset"; $type{'1550'} = "ST";
$location{'1550'} = "København V"; $address{'1550'} = "Bag Rådhuset"; $type{'1550'} = "ST";
$location{'1551'} = "København V"; $address{'1551'} = "Jarmers Plads"; $type{'1551'} = "ST";
$location{'1552'} = "København V"; $address{'1552'} = "Vester Voldgade"; $type{'1552'} = "ST";
$location{'1553'} = "København V"; $address{'1553'} = "Langebro"; $type{'1553'} = "ST";
$location{'1553'} = "København V"; $address{'1553'} = "Langebro"; $type{'1553'} = "ST";
$location{'1554'} = "København V"; $address{'1554'} = "Studiestræde 57-69 + 50-54"; $type{'1554'} = "ST";
$location{'1555'} = "København V"; $address{'1555'} = "Stormgade 20 + 35"; $type{'1555'} = "ST";
$location{'1556'} = "København V"; $address{'1556'} = "Dantes Plads"; $type{'1556'} = "ST";
$location{'1557'} = "København V"; $address{'1557'} = "Ny Kongensgade 19-21 + 18-20"; $type{'1557'} = "ST";
$location{'1558'} = "København V"; $address{'1558'} = "Christiansborggade"; $type{'1558'} = "ST";
$location{'1559'} = "København V"; $address{'1559'} = "Christians Brygge 24-30"; $type{'1559'} = "ST";
$location{'1560'} = "København V"; $address{'1560'} = "Kalvebod Brygge"; $type{'1560'} = "ST";
$location{'1561'} = "København V"; $address{'1561'} = "Kalvebod Pladsvej"; $type{'1561'} = "ST";
$location{'1561'} = "København V"; $address{'1561'} = "Kalvebod Pladsvej"; $type{'1561'} = "ST";
$location{'1562'} = "København V"; $address{'1562'} = "Hambrosgade"; $type{'1562'} = "ST";
$location{'1563'} = "København V"; $address{'1563'} = "Otto Mønsteds Plads"; $type{'1563'} = "ST";
$location{'1564'} = "København V"; $address{'1564'} = "Rysensteensgade"; $type{'1564'} = "ST";
$location{'1566'} = "København V"; $owner{'1566'} = "Post Danmark A/S"; $type{'1566'} = "IO";
$location{'1567'} = "København V"; $address{'1567'} = "Polititorvet"; $type{'1567'} = "ST";
$location{'1568'} = "København V"; $address{'1568'} = "Mitchellsgade"; $type{'1568'} = "ST";
$location{'1569'} = "København V"; $address{'1569'} = "Edvard Falcks Gade"; $type{'1569'} = "ST";
$location{'1570'} = "København V"; $address{'1570'} = "Banegårdspladsen"; $type{'1570'} = "ST";
$location{'1570'} = "København V"; $address{'1570'} = "Banegårdspladsen"; $type{'1570'} = "ST";
$location{'1571'} = "København V"; $address{'1571'} = "Otto Mønsteds Gade"; $type{'1571'} = "ST";
$location{'1572'} = "København V"; $address{'1572'} = "Anker Heegaards Gade"; $type{'1572'} = "ST";
$location{'1573'} = "København V"; $address{'1573'} = "Puggaardsgade"; $type{'1573'} = "ST";
$location{'1574'} = "København V"; $address{'1574'} = "Niels Brocks Gade"; $type{'1574'} = "ST";
$location{'1575'} = "København V"; $address{'1575'} = "Ved Glyptoteket"; $type{'1575'} = "ST";
$location{'1576'} = "København V"; $address{'1576'} = "Stoltenbergsgade"; $type{'1576'} = "ST";
$location{'1577'} = "København V"; $address{'1577'} = "Arni Magnussons Gade"; $type{'1577'} = "ST";
$location{'1577'} = "København V"; $address{'1577'} = "Arni Magnussons Gade"; $type{'1577'} = "ST";
$location{'1577'} = "København V"; $address{'1577'} = "Arni Magnussons Gade"; $type{'1577'} = "ST";
$location{'1592'} = "København V"; $owner{'1592'} = "Københavns Socialdirektorat"; $type{'1592'} = "IO";
$location{'1599'} = "København V"; $owner{'1599'} = "Københavns Rådhus"; $type{'1599'} = "IO";
$location{'1600'} = "København V"; $address{'1600'} = "Gyldenløvesgade ulige nr."; $type{'1600'} = "ST";
$location{'1601'} = "København V"; $address{'1601'} = "Vester Søgade"; $type{'1601'} = "ST";
$location{'1602'} = "København V"; $address{'1602'} = "Nyropsgade"; $type{'1602'} = "ST";
$location{'1603'} = "København V"; $address{'1603'} = "Dahlerupsgade"; $type{'1603'} = "ST";
$location{'1604'} = "København V"; $address{'1604'} = "Kampmannsgade"; $type{'1604'} = "ST";
$location{'1605'} = "København V"; $address{'1605'} = "Herholdtsgade"; $type{'1605'} = "ST";
$location{'1606'} = "København V"; $address{'1606'} = "Vester Farimagsgade"; $type{'1606'} = "ST";
$location{'1607'} = "København V"; $address{'1607'} = "Staunings Plads"; $type{'1607'} = "ST";
$location{'1608'} = "København V"; $address{'1608'} = "Jernbanegade"; $type{'1608'} = "ST";
$location{'1609'} = "København V"; $address{'1609'} = "Axeltorv"; $type{'1609'} = "ST";
$location{'1610'} = "København V"; $address{'1610'} = "Gammel Kongevej 1-55 + 10"; $type{'1610'} = "ST";
$location{'1611'} = "København V"; $address{'1611'} = "Hammerichsgade"; $type{'1611'} = "ST";
$location{'1612'} = "København V"; $address{'1612'} = "Ved Vesterport"; $type{'1612'} = "ST";
$location{'1613'} = "København V"; $address{'1613'} = "Meldahlsgade"; $type{'1613'} = "ST";
$location{'1614'} = "København V"; $address{'1614'} = "Trommesalen"; $type{'1614'} = "ST";
$location{'1615'} = "København V"; $address{'1615'} = "Sankt Jørgens Allé"; $type{'1615'} = "ST";
$location{'1616'} = "København V"; $address{'1616'} = "Stenosgade"; $type{'1616'} = "ST";
$location{'1617'} = "København V"; $address{'1617'} = "Bagerstræde"; $type{'1617'} = "ST";
$location{'1618'} = "København V"; $address{'1618'} = "Tullinsgade"; $type{'1618'} = "ST";
$location{'1619'} = "København V"; $address{'1619'} = "Værnedamsvej lige nr."; $type{'1619'} = "ST";
$location{'1620'} = "København V"; $address{'1620'} = "Vesterbros Torv"; $type{'1620'} = "ST";
$location{'1620'} = "København V"; $address{'1620'} = "Vesterbros Torv"; $type{'1620'} = "ST";
$location{'1621'} = "København V"; $address{'1621'} = "Frederiksberg Allé 1 - 13B"; $type{'1621'} = "ST";
$location{'1622'} = "København V"; $address{'1622'} = "Boyesgade ulige nr."; $type{'1622'} = "ST";
$location{'1623'} = "København V"; $address{'1623'} = "Kingosgade 1-9"; $type{'1623'} = "ST";
$location{'1624'} = "København V"; $address{'1624'} = "Brorsonsgade"; $type{'1624'} = "ST";
$location{'1630'} = "København V"; $owner{'1630'} = "Tivoli A/S"; $type{'1630'} = "IO";
$location{'1631'} = "København V"; $address{'1631'} = "Herman Triers Plads"; $type{'1631'} = "ST";
$location{'1632'} = "København V"; $address{'1632'} = "Julius Thomsens Gade lige nr."; $type{'1632'} = "ST";
$location{'1633'} = "København V"; $address{'1633'} = "Kleinsgade"; $type{'1633'} = "ST";
$location{'1634'} = "København V"; $address{'1634'} = "Rosenørns Allé 2-18"; $type{'1634'} = "ST";
$location{'1635'} = "København V"; $address{'1635'} = "Åboulevard 1-13"; $type{'1635'} = "ST";
$location{'1640'} = "København V"; $owner{'1640'} = "Københavns Folkeregister"; $type{'1640'} = "IO";
$location{'1650'} = "København V"; $address{'1650'} = "Istedgade"; $type{'1650'} = "ST";
$location{'1651'} = "København V"; $address{'1651'} = "Reventlowsgade"; $type{'1651'} = "ST";
$location{'1652'} = "København V"; $address{'1652'} = "Colbjørnsensgade"; $type{'1652'} = "ST";
$location{'1653'} = "København V"; $address{'1653'} = "Helgolandsgade"; $type{'1653'} = "ST";
$location{'1654'} = "København V"; $address{'1654'} = "Abel Cathrines Gade"; $type{'1654'} = "ST";
$location{'1655'} = "København V"; $address{'1655'} = "Viktoriagade"; $type{'1655'} = "ST";
$location{'1656'} = "København V"; $address{'1656'} = "Gasværksvej"; $type{'1656'} = "ST";
$location{'1657'} = "København V"; $address{'1657'} = "Eskildsgade"; $type{'1657'} = "ST";
$location{'1658'} = "København V"; $address{'1658'} = "Absalonsgade"; $type{'1658'} = "ST";
$location{'1659'} = "København V"; $address{'1659'} = "Svendsgade"; $type{'1659'} = "ST";
$location{'1660'} = "København V"; $address{'1660'} = "Dannebrogsgade"; $type{'1660'} = "ST";
$location{'1660'} = "København V"; $address{'1660'} = "Dannebrogsgade"; $type{'1660'} = "ST";
$location{'1661'} = "København V"; $address{'1661'} = "Westend"; $type{'1661'} = "ST";
$location{'1662'} = "København V"; $address{'1662'} = "Saxogade"; $type{'1662'} = "ST";
$location{'1663'} = "København V"; $address{'1663'} = "Oehlenschlægersgade"; $type{'1663'} = "ST";
$location{'1664'} = "København V"; $address{'1664'} = "Kaalundsgade"; $type{'1664'} = "ST";
$location{'1665'} = "København V"; $address{'1665'} = "Valdemarsgade"; $type{'1665'} = "ST";
$location{'1666'} = "København V"; $address{'1666'} = "Matthæusgade"; $type{'1666'} = "ST";
$location{'1667'} = "København V"; $address{'1667'} = "Frederiksstadsgade"; $type{'1667'} = "ST";
$location{'1668'} = "København V"; $address{'1668'} = "Mysundegade"; $type{'1668'} = "ST";
$location{'1669'} = "København V"; $address{'1669'} = "Flensborggade"; $type{'1669'} = "ST";
$location{'1670'} = "København V"; $address{'1670'} = "Enghave Plads"; $type{'1670'} = "ST";
$location{'1671'} = "København V"; $address{'1671'} = "Haderslevgade"; $type{'1671'} = "ST";
$location{'1671'} = "København V"; $address{'1671'} = "Haderslevgade"; $type{'1671'} = "ST";
$location{'1672'} = "København V"; $address{'1672'} = "Broagergade"; $type{'1672'} = "ST";
$location{'1673'} = "København V"; $address{'1673'} = "Ullerupgade"; $type{'1673'} = "ST";
$location{'1674'} = "København V"; $address{'1674'} = "Enghavevej 1-77 + 2- 78"; $type{'1674'} = "ST";
$location{'1675'} = "København V"; $address{'1675'} = "Kongshøjgade"; $type{'1675'} = "ST";
$location{'1676'} = "København V"; $address{'1676'} = "Sankelmarksgade"; $type{'1676'} = "ST";
$location{'1677'} = "København V"; $address{'1677'} = "Gråstensgade"; $type{'1677'} = "ST";
$location{'1699'} = "København V"; $address{'1699'} = "Staldgade"; $type{'1699'} = "ST";
$location{'1700'} = "København V"; $address{'1700'} = "Halmtorvet"; $type{'1700'} = "ST";
$location{'1701'} = "København V"; $address{'1701'} = "Reverdilsgade"; $type{'1701'} = "ST";
$location{'1702'} = "København V"; $address{'1702'} = "Stampesgade"; $type{'1702'} = "ST";
$location{'1703'} = "København V"; $address{'1703'} = "Lille Colbjørnsensgade"; $type{'1703'} = "ST";
$location{'1704'} = "København V"; $address{'1704'} = "Tietgensgade"; $type{'1704'} = "ST";
$location{'1705'} = "København V"; $address{'1705'} = "Ingerslevsgade"; $type{'1705'} = "ST";
$location{'1706'} = "København V"; $address{'1706'} = "Lille Istedgade"; $type{'1706'} = "ST";
$location{'1707'} = "København V"; $address{'1707'} = "Maria Kirkeplads"; $type{'1707'} = "ST";
$location{'1708'} = "København V"; $address{'1708'} = "Eriksgade"; $type{'1708'} = "ST";
$location{'1709'} = "København V"; $address{'1709'} = "Skydebanegade"; $type{'1709'} = "ST";
$location{'1710'} = "København V"; $address{'1710'} = "Kvægtorvsgade"; $type{'1710'} = "ST";
$location{'1711'} = "København V"; $address{'1711'} = "Flæsketorvet"; $type{'1711'} = "ST";
$location{'1711'} = "København V"; $address{'1711'} = "Flæsketorvet"; $type{'1711'} = "ST";
$location{'1712'} = "København V"; $address{'1712'} = "Høkerboderne"; $type{'1712'} = "ST";
$location{'1713'} = "København V"; $address{'1713'} = "Kvægtorvet"; $type{'1713'} = "ST";
$location{'1714'} = "København V"; $address{'1714'} = "Kødboderne"; $type{'1714'} = "ST";
$location{'1715'} = "København V"; $address{'1715'} = "Slagtehusgade"; $type{'1715'} = "ST";
$location{'1716'} = "København V"; $address{'1716'} = "Slagterboderne"; $type{'1716'} = "ST";
$location{'1717'} = "København V"; $address{'1717'} = "Skelbækgade"; $type{'1717'} = "ST";
$location{'1718'} = "København V"; $address{'1718'} = "Sommerstedgade"; $type{'1718'} = "ST";
$location{'1719'} = "København V"; $address{'1719'} = "Krusågade"; $type{'1719'} = "ST";
$location{'1720'} = "København V"; $address{'1720'} = "Sønder Boulevard"; $type{'1720'} = "ST";
$location{'1721'} = "København V"; $address{'1721'} = "Dybbølsgade"; $type{'1721'} = "ST";
$location{'1722'} = "København V"; $address{'1722'} = "Godsbanegade"; $type{'1722'} = "ST";
$location{'1723'} = "København V"; $address{'1723'} = "Letlandsgade"; $type{'1723'} = "ST";
$location{'1724'} = "København V"; $address{'1724'} = "Estlandsgade"; $type{'1724'} = "ST";
$location{'1725'} = "København V"; $address{'1725'} = "Esbern Snares Gade"; $type{'1725'} = "ST";
$location{'1726'} = "København V"; $address{'1726'} = "Arkonagade"; $type{'1726'} = "ST";
$location{'1727'} = "København V"; $address{'1727'} = "Asger Rygs Gade"; $type{'1727'} = "ST";
$location{'1728'} = "København V"; $address{'1728'} = "Skjalm Hvides Gade"; $type{'1728'} = "ST";
$location{'1729'} = "København V"; $address{'1729'} = "Sigerstedgade"; $type{'1729'} = "ST";
$location{'1730'} = "København V"; $address{'1730'} = "Knud Lavards Gade"; $type{'1730'} = "ST";
$location{'1731'} = "København V"; $address{'1731'} = "Erik Ejegods Gade"; $type{'1731'} = "ST";
$location{'1732'} = "København V"; $address{'1732'} = "Bodilsgade"; $type{'1732'} = "ST";
$location{'1733'} = "København V"; $address{'1733'} = "Palnatokesgade"; $type{'1733'} = "ST";
$location{'1734'} = "København V"; $address{'1734'} = "Heilsgade"; $type{'1734'} = "ST";
$location{'1735'} = "København V"; $address{'1735'} = "Røddinggade"; $type{'1735'} = "ST";
$location{'1736'} = "København V"; $address{'1736'} = "Bevtoftgade"; $type{'1736'} = "ST";
$location{'1737'} = "København V"; $address{'1737'} = "Bustrupgade"; $type{'1737'} = "ST";
$location{'1738'} = "København V"; $address{'1738'} = "Stenderupgade"; $type{'1738'} = "ST";
$location{'1739'} = "København V"; $address{'1739'} = "Enghave Passage"; $type{'1739'} = "ST";
$location{'1748'} = "København V"; $address{'1748'} = "Kammasvej 2"; $type{'1748'} = "ST";
$location{'1749'} = "København V"; $address{'1749'} = "Rahbeks Allé 3-11"; $type{'1749'} = "ST";
$location{'1750'} = "København V"; $address{'1750'} = "Vesterfælledvej"; $type{'1750'} = "ST";
$location{'1751'} = "København V"; $address{'1751'} = "Sundevedsgade"; $type{'1751'} = "ST";
$location{'1752'} = "København V"; $address{'1752'} = "Tøndergade"; $type{'1752'} = "ST";
$location{'1753'} = "København V"; $address{'1753'} = "Ballumgade"; $type{'1753'} = "ST";
$location{'1754'} = "København V"; $address{'1754'} = "Hedebygade"; $type{'1754'} = "ST";
$location{'1755'} = "København V"; $address{'1755'} = "Møgeltøndergade"; $type{'1755'} = "ST";
$location{'1756'} = "København V"; $address{'1756'} = "Amerikavej"; $type{'1756'} = "ST";
$location{'1757'} = "København V"; $address{'1757'} = "Trøjborggade"; $type{'1757'} = "ST";
$location{'1758'} = "København V"; $address{'1758'} = "Lyrskovgade"; $type{'1758'} = "ST";
$location{'1759'} = "København V"; $address{'1759'} = "Rejsbygade"; $type{'1759'} = "ST";
$location{'1760'} = "København V"; $address{'1760'} = "Ny Carlsberg Vej"; $type{'1760'} = "ST";
$location{'1761'} = "København V"; $address{'1761'} = "Ejderstedgade"; $type{'1761'} = "ST";
$location{'1762'} = "København V"; $address{'1762'} = "Slesvigsgade"; $type{'1762'} = "ST";
$location{'1763'} = "København V"; $address{'1763'} = "Dannevirkegade"; $type{'1763'} = "ST";
$location{'1764'} = "København V"; $address{'1764'} = "Alsgade"; $type{'1764'} = "ST";
$location{'1765'} = "København V"; $address{'1765'} = "Angelgade"; $type{'1765'} = "ST";
$location{'1766'} = "København V"; $address{'1766'} = "Slien"; $type{'1766'} = "ST";
$location{'1770'} = "København V"; $address{'1770'} = "Carstensgade"; $type{'1770'} = "ST";
$location{'1771'} = "København V"; $address{'1771'} = "Lundbyesgade"; $type{'1771'} = "ST";
$location{'1772'} = "København V"; $address{'1772'} = "Ernst Meyers Gade"; $type{'1772'} = "ST";
$location{'1773'} = "København V"; $address{'1773'} = "Bissensgade"; $type{'1773'} = "ST";
$location{'1774'} = "København V"; $address{'1774'} = "Küchlersgade"; $type{'1774'} = "ST";
$location{'1775'} = "København V"; $address{'1775'} = "Freundsgade"; $type{'1775'} = "ST";
$location{'1777'} = "København V"; $address{'1777'} = "Jerichausgade"; $type{'1777'} = "ST";
$location{'1778'} = "København V"; $address{'1778'} = "Pasteursvej"; $type{'1778'} = "ST";
$location{'1780'} = "København V"; $owner{'1780'} = "Erhvervskunder";
$location{'1782'} = "København V"; $type{'1782'} = "PP";
$location{'1785'} = "København V"; $owner{'1785'} = "Politiken og Ekstra Bladet"; $type{'1785'} = "IO";
$location{'1786'} = "København V"; $owner{'1786'} = "Nordea"; $type{'1786'} = "IO";
$location{'1787'} = "København V"; $owner{'1787'} = "Dansk Industri"; $type{'1787'} = "IO";
$location{'1789'} = "København V"; $owner{'1789'} = "Star Tour A/S"; $type{'1789'} = "IO";
$location{'1790'} = "København V"; $owner{'1790'} = "Erhvervskunder";
$location{'1799'} = "København V"; $owner{'1799'} = "Carlsberg"; $type{'1799'} = "IO";
$location{'1800'} = "Frederiksberg C"; $address{'1800'} = "Vesterbrogade 161-191 + 162-208"; $type{'1800'} = "ST";
$location{'1801'} = "Frederiksberg C"; $address{'1801'} = "Rahbeks Alle 2-36"; $type{'1801'} = "ST";
$location{'1802'} = "Frederiksberg C"; $address{'1802'} = "Halls Alle"; $type{'1802'} = "ST";
$location{'1803'} = "Frederiksberg C"; $address{'1803'} = "Brøndsteds Alle"; $type{'1803'} = "ST";
$location{'1804'} = "Frederiksberg C"; $address{'1804'} = "Bakkegårds Alle"; $type{'1804'} = "ST";
$location{'1805'} = "Frederiksberg C"; $address{'1805'} = "Kammasvej 3 "; $type{'1805'} = "ST";
$location{'1806'} = "Frederiksberg C"; $address{'1806'} = "Jacobys Alle"; $type{'1806'} = "ST";
$location{'1807'} = "Frederiksberg C"; $address{'1807'} = "Schlegels Alle"; $type{'1807'} = "ST";
$location{'1808'} = "Frederiksberg C"; $address{'1808'} = "Asmussens Alle"; $type{'1808'} = "ST";
$location{'1809'} = "Frederiksberg C"; $address{'1809'} = "Frydendalsvej"; $type{'1809'} = "ST";
$location{'1810'} = "Frederiksberg C"; $address{'1810'} = "Platanvej"; $type{'1810'} = "ST";
$location{'1811'} = "Frederiksberg C"; $address{'1811'} = "Asgårdsvej"; $type{'1811'} = "ST";
$location{'1812'} = "Frederiksberg C"; $address{'1812'} = "Kochsvej"; $type{'1812'} = "ST";
$location{'1813'} = "Frederiksberg C"; $address{'1813'} = "Henrik Ibsens Vej"; $type{'1813'} = "ST";
$location{'1814'} = "Frederiksberg C"; $address{'1814'} = "Carit Etlars Vej"; $type{'1814'} = "ST";
$location{'1815'} = "Frederiksberg C"; $address{'1815'} = "Paludan Müllers Vej"; $type{'1815'} = "ST";
$location{'1816'} = "Frederiksberg C"; $address{'1816'} = "Engtoftevej"; $type{'1816'} = "ST";
$location{'1817'} = "Frederiksberg C"; $address{'1817'} = "Carl Bernhards Vej"; $type{'1817'} = "ST";
$location{'1818'} = "Frederiksberg C"; $address{'1818'} = "Kingosgade 8-10 + 11-17"; $type{'1818'} = "ST";
$location{'1819'} = "Frederiksberg C"; $address{'1819'} = "Værnedamsvej ulige nr."; $type{'1819'} = "ST";
$location{'1820'} = "Frederiksberg C"; $address{'1820'} = "Frederiksberg Allé 15-63 + 2-104"; $type{'1820'} = "ST";
$location{'1822'} = "Frederiksberg C"; $address{'1822'} = "Boyesgade lige nr."; $type{'1822'} = "ST";
$location{'1823'} = "Frederiksberg C"; $address{'1823'} = "Haveselskabetsvej"; $type{'1823'} = "ST";
$location{'1824'} = "Frederiksberg C"; $address{'1824'} = "Sankt Thomas Allé"; $type{'1824'} = "ST";
$location{'1825'} = "Frederiksberg C"; $address{'1825'} = "Hauchsvej"; $type{'1825'} = "ST";
$location{'1826'} = "Frederiksberg C"; $address{'1826'} = "Alhambravej"; $type{'1826'} = "ST";
$location{'1827'} = "Frederiksberg C"; $address{'1827'} = "Mynstersvej"; $type{'1827'} = "ST";
$location{'1828'} = "Frederiksberg C"; $address{'1828'} = "Martensens Alle"; $type{'1828'} = "ST";
$location{'1829'} = "Frederiksberg C"; $address{'1829'} = "Madvigs Alle"; $type{'1829'} = "ST";
$location{'1835'} = "Frederiksberg C"; $owner{'1835'} = "Inkl. Frederiksberg C Postkontor"; $type{'1835'} = "BX";
$location{'1850'} = "Frederiksberg C"; $address{'1850'} = "Gammel Kongevej 85-179 + 60-178"; $type{'1850'} = "ST";
$location{'1851'} = "Frederiksberg C"; $address{'1851'} = "Nyvej"; $type{'1851'} = "ST";
$location{'1852'} = "Frederiksberg C"; $address{'1852'} = "Amicisvej"; $type{'1852'} = "ST";
$location{'1853'} = "Frederiksberg C"; $address{'1853'} = "Maglekildevej"; $type{'1853'} = "ST";
$location{'1854'} = "Frederiksberg C"; $address{'1854'} = "Dr. Priemes Vej"; $type{'1854'} = "ST";
$location{'1855'} = "Frederiksberg C"; $address{'1855'} = "Hollændervej"; $type{'1855'} = "ST";
$location{'1856'} = "Frederiksberg C"; $address{'1856'} = "Edisonsvej"; $type{'1856'} = "ST";
$location{'1857'} = "Frederiksberg C"; $address{'1857'} = "Hortensiavej"; $type{'1857'} = "ST";
$location{'1860'} = "Frederiksberg C"; $address{'1860'} = "Christian Winthers Vej"; $type{'1860'} = "ST";
$location{'1861'} = "Frederiksberg C"; $address{'1861'} = "Sagasvej"; $type{'1861'} = "ST";
$location{'1862'} = "Frederiksberg C"; $address{'1862'} = "Rathsacksvej"; $type{'1862'} = "ST";
$location{'1863'} = "Frederiksberg C"; $address{'1863'} = "Ceresvej"; $type{'1863'} = "ST";
$location{'1864'} = "Frederiksberg C"; $address{'1864'} = "Grundtvigsvej"; $type{'1864'} = "ST";
$location{'1865'} = "Frederiksberg C"; $address{'1865'} = "Grundtvigs Sidevej"; $type{'1865'} = "ST";
$location{'1866'} = "Frederiksberg C"; $address{'1866'} = "Henrik Steffens Vej"; $type{'1866'} = "ST";
$location{'1867'} = "Frederiksberg C"; $address{'1867'} = "Acaciavej"; $type{'1867'} = "ST";
$location{'1868'} = "Frederiksberg C"; $address{'1868'} = "Bianco Lunos Alle"; $type{'1868'} = "ST";
$location{'1870'} = "Frederiksberg C"; $address{'1870'} = "Bülowsvej"; $type{'1870'} = "ST";
$location{'1871'} = "Frederiksberg C"; $address{'1871'} = "Thorvaldsensvej"; $type{'1871'} = "ST";
$location{'1872'} = "Frederiksberg C"; $address{'1872'} = "Bomhoffs Have"; $type{'1872'} = "ST";
$location{'1873'} = "Frederiksberg C"; $address{'1873'} = "Helenevej"; $type{'1873'} = "ST";
$location{'1874'} = "Frederiksberg C"; $address{'1874'} = "Harsdorffsvej"; $type{'1874'} = "ST";
$location{'1875'} = "Frederiksberg C"; $address{'1875'} = "Amalievej"; $type{'1875'} = "ST";
$location{'1876'} = "Frederiksberg C"; $address{'1876'} = "Kastanievej"; $type{'1876'} = "ST";
$location{'1877'} = "Frederiksberg C"; $address{'1877'} = "Lindevej"; $type{'1877'} = "ST";
$location{'1878'} = "Frederiksberg C"; $address{'1878'} = "Uraniavej"; $type{'1878'} = "ST";
$location{'1879'} = "Frederiksberg C"; $address{'1879'} = "H.C. Ørsteds Vej"; $type{'1879'} = "ST";
$location{'1900'} = "Frederiksberg C"; $address{'1900'} = "Vodroffsvej"; $type{'1900'} = "ST";
$location{'1901'} = "Frederiksberg C"; $address{'1901'} = "Tårnborgvej"; $type{'1901'} = "ST";
$location{'1902'} = "Frederiksberg C"; $address{'1902'} = "Lykkesholms Alle"; $type{'1902'} = "ST";
$location{'1903'} = "Frederiksberg C"; $address{'1903'} = "Sankt Knuds Vej"; $type{'1903'} = "ST";
$location{'1904'} = "Frederiksberg C"; $address{'1904'} = "Forhåbningsholms Allé"; $type{'1904'} = "ST";
$location{'1905'} = "Frederiksberg C"; $address{'1905'} = "Svanholmsvej"; $type{'1905'} = "ST";
$location{'1906'} = "Frederiksberg C"; $address{'1906'} = "Schønbergsgade"; $type{'1906'} = "ST";
$location{'1908'} = "Frederiksberg C"; $address{'1908'} = "Prinsesse Maries Alle"; $type{'1908'} = "ST";
$location{'1909'} = "Frederiksberg C"; $address{'1909'} = "Vodroffs Tværgade"; $type{'1909'} = "ST";
$location{'1910'} = "Frederiksberg C"; $address{'1910'} = "Danasvej"; $type{'1910'} = "ST";
$location{'1911'} = "Frederiksberg C"; $address{'1911'} = "Niels Ebbesens Vej"; $type{'1911'} = "ST";
$location{'1912'} = "Frederiksberg C"; $address{'1912'} = "Svend Trøsts Vej"; $type{'1912'} = "ST";
$location{'1913'} = "Frederiksberg C"; $address{'1913'} = "Carl Plougs Vej"; $type{'1913'} = "ST";
$location{'1914'} = "Frederiksberg C"; $address{'1914'} = "Vodroffslund"; $type{'1914'} = "ST";
$location{'1915'} = "Frederiksberg C"; $address{'1915'} = "Danas Plads"; $type{'1915'} = "ST";
$location{'1916'} = "Frederiksberg C"; $address{'1916'} = "Norsvej"; $type{'1916'} = "ST";
$location{'1917'} = "Frederiksberg C"; $address{'1917'} = "Sveasvej"; $type{'1917'} = "ST";
$location{'1920'} = "Frederiksberg C"; $address{'1920'} = "Forchhammersvej"; $type{'1920'} = "ST";
$location{'1921'} = "Frederiksberg C"; $address{'1921'} = "Sankt Markus Plads"; $type{'1921'} = "ST";
$location{'1922'} = "Frederiksberg C"; $address{'1922'} = "Sankt Markus Alle"; $type{'1922'} = "ST";
$location{'1923'} = "Frederiksberg C"; $address{'1923'} = "Johnstrups Alle"; $type{'1923'} = "ST";
$location{'1924'} = "Frederiksberg C"; $address{'1924'} = "Steenstrups Alle"; $type{'1924'} = "ST";
$location{'1925'} = "Frederiksberg C"; $address{'1925'} = "Julius Thomsens Plads"; $type{'1925'} = "ST";
$location{'1926'} = "Frederiksberg C"; $address{'1926'} = "Martinsvej"; $type{'1926'} = "ST";
$location{'1927'} = "Frederiksberg C"; $address{'1927'} = "Suomisvej"; $type{'1927'} = "ST";
$location{'1928'} = "Frederiksberg C"; $address{'1928'} = "Filippavej"; $type{'1928'} = "ST";
$location{'1931'} = "Frederiksberg C"; $type{'1931'} = "PP";
$location{'1950'} = "Frederiksberg C"; $address{'1950'} = "Hostrupsvej"; $type{'1950'} = "ST";
$location{'1951'} = "Frederiksberg C"; $address{'1951'} = "Christian Richardts Vej"; $type{'1951'} = "ST";
$location{'1952'} = "Frederiksberg C"; $address{'1952'} = "Falkonervænget"; $type{'1952'} = "ST";
$location{'1953'} = "Frederiksberg C"; $address{'1953'} = "Sankt Nikolaj Vej"; $type{'1953'} = "ST";
$location{'1954'} = "Frederiksberg C"; $address{'1954'} = "Hostrups Have"; $type{'1954'} = "ST";
$location{'1955'} = "Frederiksberg C"; $address{'1955'} = "Dr. Abildgaards Alle"; $type{'1955'} = "ST";
$location{'1956'} = "Frederiksberg C"; $address{'1956'} = "L.I. Brandes Alle"; $type{'1956'} = "ST";
$location{'1957'} = "Frederiksberg C"; $address{'1957'} = "N.J. Fjords Alle"; $type{'1957'} = "ST";
$location{'1958'} = "Frederiksberg C"; $address{'1958'} = "Rolighedsvej"; $type{'1958'} = "ST";
$location{'1959'} = "Frederiksberg C"; $address{'1959'} = "Falkonergårdsvej"; $type{'1959'} = "ST";
$location{'1960'} = "Frederiksberg C"; $address{'1960'} = "Åboulevard 15-55"; $type{'1960'} = "ST";
$location{'1961'} = "Frederiksberg C"; $address{'1961'} = "J.M. Thieles Vej"; $type{'1961'} = "ST";
$location{'1962'} = "Frederiksberg C"; $address{'1962'} = "Fuglevangsvej"; $type{'1962'} = "ST";
$location{'1963'} = "Frederiksberg C"; $address{'1963'} = "Bille Brahes Vej"; $type{'1963'} = "ST";
$location{'1964'} = "Frederiksberg C"; $address{'1964'} = "Ingemannsvej"; $type{'1964'} = "ST";
$location{'1965'} = "Frederiksberg C"; $address{'1965'} = "Erik Menveds Vej"; $type{'1965'} = "ST";
$location{'1966'} = "Frederiksberg C"; $address{'1966'} = "Steenwinkelsvej"; $type{'1966'} = "ST";
$location{'1967'} = "Frederiksberg C"; $address{'1967'} = "Svanemosegårdsvej"; $type{'1967'} = "ST";
$location{'1970'} = "Frederiksberg C"; $address{'1970'} = "Rosenørns Alle 1-67 + 20-70"; $type{'1970'} = "ST";
$location{'1971'} = "Frederiksberg C"; $address{'1971'} = "Adolph Steens Alle"; $type{'1971'} = "ST";
$location{'1972'} = "Frederiksberg C"; $address{'1972'} = "Worsaaesvej"; $type{'1972'} = "ST";
$location{'1973'} = "Frederiksberg C"; $address{'1973'} = "Jakob Dannefærds Vej"; $type{'1973'} = "ST";
$location{'1974'} = "Frederiksberg C"; $address{'1974'} = "Julius Thomsens Gade ulige nr."; $type{'1974'} = "ST";
$location{'2000'} = "Frederiksberg";
$location{'2100'} = "København Ø";
$location{'2200'} = "København N";
$location{'2300'} = "København S";
$location{'2400'} = "København NV";
$location{'2450'} = "København SV";
$location{'2500'} = "Valby";
$location{'2600'} = "Glostrup";
$location{'2605'} = "Brøndby";
$location{'2610'} = "Rødovre";
$location{'2620'} = "Albertslund";
$location{'2625'} = "Vallensbæk";
$location{'2630'} = "Taastrup";
$location{'2635'} = "Ishøj";
$location{'2640'} = "Hedehusene";
$location{'2650'} = "Hvidovre";
$location{'2660'} = "Brøndby Strand";
$location{'2665'} = "Vallensbæk Strand";
$location{'2670'} = "Greve";
$location{'2680'} = "Solrød Strand";
$location{'2690'} = "Karlslunde";
$location{'2700'} = "Brønshøj";
$location{'2720'} = "Vanløse";
$location{'2730'} = "Herlev";
$location{'2740'} = "Skovlunde";
$location{'2750'} = "Ballerup";
$location{'2760'} = "Måløv";
$location{'2765'} = "Smørum";
$location{'2770'} = "Kastrup";
$location{'2791'} = "Dragør";
$location{'2800'} = "Kongens Lyngby";
$location{'2820'} = "Gentofte";
$location{'2830'} = "Virum";
$location{'2840'} = "Holte";
$location{'2850'} = "Nærum";
$location{'2860'} = "Søborg";
$location{'2870'} = "Dyssegård ";
$location{'2880'} = "Bagsværd";
$location{'2900'} = "Hellerup";
$location{'2920'} = "Charlottenlund";
$location{'2930'} = "Klampenborg";
$location{'2942'} = "Skodsborg";
$location{'2950'} = "Vedbæk";
$location{'2960'} = "Rungsted Kyst";
$location{'2970'} = "Hørsholm";
$location{'2980'} = "Kokkedal";
$location{'2990'} = "Nivå";
$location{'3000'} = "Helsingør";
$location{'3050'} = "Humlebæk";
$location{'3060'} = "Espergærde";
$location{'3070'} = "Snekkersten";
$location{'3080'} = "Tikøb";
$location{'3100'} = "Hornbæk";
$location{'3120'} = "Dronningmølle";
$location{'3140'} = "Ålsgårde";
$location{'3150'} = "Hellebæk";
$location{'3200'} = "Helsinge";
$location{'3210'} = "Vejby";
$location{'3220'} = "Tisvildeleje";
$location{'3230'} = "Græsted";
$location{'3250'} = "Gilleleje";
$location{'3300'} = "Frederiksværk";
$location{'3310'} = "Ølsted";
$location{'3320'} = "Skævinge";
$location{'3330'} = "Gørløse";
$location{'3360'} = "Liseleje";
$location{'3370'} = "Melby";
$location{'3390'} = "Hundested";
$location{'3400'} = "Hillerød";
$location{'3450'} = "Allerød";
$location{'3460'} = "Birkerød";
$location{'3480'} = "Fredensborg";
$location{'3490'} = "Kvistgård";
$location{'3500'} = "Værløse";
$location{'3520'} = "Farum";
$location{'3540'} = "Lynge";
$location{'3550'} = "Slangerup";
$location{'3600'} = "Frederikssund";
$location{'3630'} = "Jægerspris";
$location{'3650'} = "Ølstykke";
$location{'3660'} = "Stenløse";
$location{'3670'} = "Veksø Sjælland";
$location{'3700'} = "Rønne";
$location{'3720'} = "Aakirkeby";
$location{'3730'} = "Nexø";
$location{'3740'} = "Svaneke";
$location{'3751'} = "Østermarie";
$location{'3760'} = "Gudhjem";
$location{'3770'} = "Allinge";
$location{'3782'} = "Klemensker";
$location{'3790'} = "Hasle";
$location{'4000'} = "Roskilde";
$location{'4030'} = "Tune";
$location{'4040'} = "Jyllinge";
$location{'4050'} = "Skibby";
$location{'4060'} = "Kirke Såby";
$location{'4070'} = "Kirke Hyllinge";
$location{'4100'} = "Ringsted";
$location{'4105'} = "Ringsted"; $owner{'4105'} = "Midtsjællands Postcenter + erhvervskunder";
$location{'4129'} = "Ringsted"; $type{'4129'} = "PP";
$location{'4130'} = "Viby Sjælland";
$location{'4140'} = "Borup";
$location{'4160'} = "Herlufmagle";
$location{'4171'} = "Glumsø";
$location{'4173'} = "Fjenneslev";
$location{'4174'} = "Jystrup Midtsj";
$location{'4180'} = "Sorø";
$location{'4190'} = "Munke Bjergby";
$location{'4200'} = "Slagelse";
$location{'4220'} = "Korsør";
$location{'4230'} = "Skælskør";
$location{'4241'} = "Vemmelev";
$location{'4242'} = "Boeslunde";
$location{'4243'} = "Rude";
$location{'4250'} = "Fuglebjerg";
$location{'4261'} = "Dalmose";
$location{'4262'} = "Sandved";
$location{'4270'} = "Høng";
$location{'4281'} = "Gørlev";
$location{'4291'} = "Ruds Vedby";
$location{'4293'} = "Dianalund";
$location{'4295'} = "Stenlille";
$location{'4296'} = "Nyrup";
$location{'4300'} = "Holbæk";
$location{'4320'} = "Lejre";
$location{'4330'} = "Hvalsø";
$location{'4340'} = "Tølløse";
$location{'4350'} = "Ugerløse";
$location{'4360'} = "Kirke Eskilstrup";
$location{'4370'} = "Store Merløse";
$location{'4390'} = "Vipperød";
$location{'4400'} = "Kalundborg";
$location{'4420'} = "Regstrup";
$location{'4440'} = "Mørkøv";
$location{'4450'} = "Jyderup";
$location{'4460'} = "Snertinge";
$location{'4470'} = "Svebølle";
$location{'4480'} = "Store Fuglede";
$location{'4490'} = "Jerslev Sjælland";
$location{'4500'} = "Nykøbing Sj";
$location{'4520'} = "Svinninge";
$location{'4532'} = "Gislinge";
$location{'4534'} = "Hørve";
$location{'4540'} = "Fårevejle";
$location{'4550'} = "Asnæs";
$location{'4560'} = "Vig";
$location{'4571'} = "Grevinge";
$location{'4572'} = "Nørre Asmindrup";
$location{'4573'} = "Højby";
$location{'4581'} = "Rørvig";
$location{'4583'} = "Sjællands Odde";
$location{'4591'} = "Føllenslev";
$location{'4592'} = "Sejerø";
$location{'4593'} = "Eskebjerg";
$location{'4600'} = "Køge";
$location{'4621'} = "Gadstrup";
$location{'4622'} = "Havdrup";
$location{'4623'} = "Lille Skensved";
$location{'4632'} = "Bjæverskov";
$location{'4640'} = "Faxe";
$location{'4652'} = "Hårlev";
$location{'4653'} = "Karise";
$location{'4654'} = "Faxe Ladeplads";
$location{'4660'} = "Store Heddinge";
$location{'4671'} = "Strøby";
$location{'4672'} = "Klippinge";
$location{'4673'} = "Rødvig Stevns";
$location{'4681'} = "Herfølge";
$location{'4682'} = "Tureby";
$location{'4683'} = "Rønnede";
$location{'4684'} = "Holmegaard ";
$location{'4690'} = "Haslev";
$location{'4700'} = "Næstved";
$location{'4720'} = "Præstø";
$location{'4733'} = "Tappernøje";
$location{'4735'} = "Mern";
$location{'4736'} = "Karrebæksminde";
$location{'4750'} = "Lundby";
$location{'4760'} = "Vordingborg";
$location{'4771'} = "Kalvehave";
$location{'4772'} = "Langebæk";
$location{'4773'} = "Stensved";
$location{'4780'} = "Stege";
$location{'4791'} = "Borre";
$location{'4792'} = "Askeby";
$location{'4793'} = "Bogø By";
$location{'4800'} = "Nykøbing F";
$location{'4840'} = "Nørre Alslev";
$location{'4850'} = "Stubbekøbing";
$location{'4862'} = "Guldborg";
$location{'4863'} = "Eskilstrup";
$location{'4871'} = "Horbelev";
$location{'4872'} = "Idestrup";
$location{'4873'} = "Væggerløse";
$location{'4874'} = "Gedser";
$location{'4880'} = "Nysted";
$location{'4891'} = "Toreby L";
$location{'4892'} = "Kettinge";
$location{'4894'} = "Øster Ulslev";
$location{'4895'} = "Errindlev";
$location{'4900'} = "Nakskov";
$location{'4912'} = "Harpelunde";
$location{'4913'} = "Horslunde";
$location{'4920'} = "Søllested";
$location{'4930'} = "Maribo";
$location{'4941'} = "Bandholm";
$location{'4943'} = "Torrig L";
$location{'4944'} = "Fejø";
$location{'4951'} = "Nørreballe";
$location{'4952'} = "Stokkemarke";
$location{'4953'} = "Vesterborg";
$location{'4960'} = "Holeby";
$location{'4970'} = "Rødby";
$location{'4983'} = "Dannemare";
$location{'4990'} = "Sakskøbing";
$location{'4992'} = "Midtsjælland USF P"; $owner{'4992'} = "Ufrankerede svarforsendelser";
$location{'5000'} = "Odense C";
$location{'5029'} = "Odense C"; $type{'5029'} = "PP";
$location{'5100'} = "Odense C"; $type{'5100'} = "BX";
$location{'5200'} = "Odense V";
$location{'5210'} = "Odense NV";
$location{'5220'} = "Odense SØ";
$location{'5230'} = "Odense M";
$location{'5240'} = "Odense NØ";
$location{'5250'} = "Odense SV";
$location{'5260'} = "Odense S";
$location{'5270'} = "Odense N";
$location{'5290'} = "Marslev";
$location{'5300'} = "Kerteminde";
$location{'5320'} = "Agedrup";
$location{'5330'} = "Munkebo";
$location{'5350'} = "Rynkeby";
$location{'5370'} = "Mesinge";
$location{'5380'} = "Dalby";
$location{'5390'} = "Martofte";
$location{'5400'} = "Bogense";
$location{'5450'} = "Otterup";
$location{'5462'} = "Morud";
$location{'5463'} = "Harndrup";
$location{'5464'} = "Brenderup Fyn";
$location{'5466'} = "Asperup";
$location{'5471'} = "Søndersø";
$location{'5474'} = "Veflinge";
$location{'5485'} = "Skamby";
$location{'5491'} = "Blommenslyst";
$location{'5492'} = "Vissenbjerg";
$location{'5500'} = "Middelfart";
$location{'5540'} = "Ullerslev";
$location{'5550'} = "Langeskov";
$location{'5560'} = "Aarup";
$location{'5580'} = "Nørre Aaby";
$location{'5591'} = "Gelsted";
$location{'5592'} = "Ejby";
$location{'5600'} = "Faaborg";
$location{'5610'} = "Assens";
$location{'5620'} = "Glamsbjerg";
$location{'5631'} = "Ebberup";
$location{'5642'} = "Millinge";
$location{'5672'} = "Broby";
$location{'5683'} = "Haarby";
$location{'5690'} = "Tommerup";
$location{'5700'} = "Svendborg";
$location{'5750'} = "Ringe";
$location{'5762'} = "Vester Skerninge";
$location{'5771'} = "Stenstrup";
$location{'5772'} = "Kværndrup";
$location{'5792'} = "Årslev";
$location{'5800'} = "Nyborg";
$location{'5853'} = "Ørbæk";
$location{'5854'} = "Gislev";
$location{'5856'} = "Ryslinge";
$location{'5863'} = "Ferritslev Fyn";
$location{'5871'} = "Frørup";
$location{'5874'} = "Hesselager";
$location{'5881'} = "Skårup Fyn";
$location{'5882'} = "Vejstrup";
$location{'5883'} = "Oure";
$location{'5884'} = "Gudme";
$location{'5892'} = "Gudbjerg Sydfyn";
$location{'5900'} = "Rudkøbing";
$location{'5932'} = "Humble";
$location{'5935'} = "Bagenkop";
$location{'5953'} = "Tranekær";
$location{'5960'} = "Marstal";
$location{'5970'} = "Ærøskøbing";
$location{'5985'} = "Søby Ærø";
$location{'6000'} = "Kolding";
$location{'6040'} = "Egtved";
$location{'6051'} = "Almind";
$location{'6052'} = "Viuf";
$location{'6064'} = "Jordrup";
$location{'6070'} = "Christiansfeld";
$location{'6091'} = "Bjert";
$location{'6092'} = "Sønder Stenderup";
$location{'6093'} = "Sjølund";
$location{'6094'} = "Hejls";
$location{'6100'} = "Haderslev";
$location{'6200'} = "Aabenraa";
$location{'6230'} = "Rødekro";
$location{'6240'} = "Løgumkloster";
$location{'6261'} = "Bredebro";
$location{'6270'} = "Tønder";
$location{'6280'} = "Højer";
$location{'6300'} = "Gråsten";
$location{'6310'} = "Broager";
$location{'6320'} = "Egernsund";
$location{'6330'} = "Padborg";
$location{'6340'} = "Kruså";
$location{'6360'} = "Tinglev";
$location{'6372'} = "Bylderup-Bov";
$location{'6392'} = "Bolderslev";
$location{'6400'} = "Sønderborg";
$location{'6430'} = "Nordborg";
$location{'6440'} = "Augustenborg";
$location{'6470'} = "Sydals";
$location{'6500'} = "Vojens";
$location{'6510'} = "Gram";
$location{'6520'} = "Toftlund";
$location{'6534'} = "Agerskov";
$location{'6535'} = "Branderup J";
$location{'6541'} = "Bevtoft";
$location{'6560'} = "Sommersted";
$location{'6580'} = "Vamdrup";
$location{'6600'} = "Vejen";
$location{'6621'} = "Gesten";
$location{'6622'} = "Bække";
$location{'6623'} = "Vorbasse";
$location{'6630'} = "Rødding";
$location{'6640'} = "Lunderskov";
$location{'6650'} = "Brørup";
$location{'6660'} = "Lintrup";
$location{'6670'} = "Holsted";
$location{'6682'} = "Hovborg";
$location{'6683'} = "Føvling";
$location{'6690'} = "Gørding";
$location{'6700'} = "Esbjerg";
$location{'6701'} = "Esbjerg"; $type{'6701'} = "BX";
$location{'6705'} = "Esbjerg Ø";
$location{'6710'} = "Esbjerg V";
$location{'6715'} = "Esbjerg N";
$location{'6720'} = "Fanø";
$location{'6731'} = "Tjæreborg";
$location{'6740'} = "Bramming";
$location{'6752'} = "Glejbjerg";
$location{'6753'} = "Agerbæk";
$location{'6760'} = "Ribe";
$location{'6771'} = "Gredstedbro";
$location{'6780'} = "Skærbæk";
$location{'6792'} = "Rømø";
$location{'6800'} = "Varde";
$location{'6818'} = "Årre";
$location{'6823'} = "Ansager";
$location{'6830'} = "Nørre Nebel";
$location{'6840'} = "Oksbøl";
$location{'6851'} = "Janderup Vestj";
$location{'6852'} = "Billum";
$location{'6853'} = "Vejers Strand";
$location{'6854'} = "Henne";
$location{'6855'} = "Outrup";
$location{'6857'} = "Blåvand";
$location{'6862'} = "Tistrup";
$location{'6870'} = "Ølgod";
$location{'6880'} = "Tarm";
$location{'6893'} = "Hemmet";
$location{'6900'} = "Skjern";
$location{'6920'} = "Videbæk";
$location{'6933'} = "Kibæk";
$location{'6940'} = "Lem St";
$location{'6950'} = "Ringkøbing";
$location{'6960'} = "Hvide Sande";
$location{'6971'} = "Spjald";
$location{'6973'} = "Ørnhøj";
$location{'6980'} = "Tim";
$location{'6990'} = "Ulfborg";
$location{'7000'} = "Fredericia";
$location{'7007'} = "Fredericia"; $owner{'7007'} = "Sydjyllands Postcenter + erhvervskunder";
$location{'7029'} = "Fredericia"; $type{'7029'} = "PP";
$location{'7080'} = "Børkop";
$location{'7100'} = "Vejle";
$location{'7120'} = "Vejle Øst";
$location{'7130'} = "Juelsminde";
$location{'7140'} = "Stouby";
$location{'7150'} = "Barrit";
$location{'7160'} = "Tørring";
$location{'7171'} = "Uldum";
$location{'7173'} = "Vonge";
$location{'7182'} = "Bredsten";
$location{'7183'} = "Randbøl";
$location{'7184'} = "Vandel";
$location{'7190'} = "Billund";
$location{'7200'} = "Grindsted";
$location{'7250'} = "Hejnsvig";
$location{'7260'} = "Sønder Omme";
$location{'7270'} = "Stakroge";
$location{'7280'} = "Sønder Felding";
$location{'7300'} = "Jelling";
$location{'7321'} = "Gadbjerg";
$location{'7323'} = "Give";
$location{'7330'} = "Brande";
$location{'7361'} = "Ejstrupholm";
$location{'7362'} = "Hampen";
$location{'7400'} = "Herning";
$location{'7429'} = "Herning"; $type{'7429'} = "PP";
$location{'7430'} = "Ikast";
$location{'7441'} = "Bording";
$location{'7442'} = "Engesvang";
$location{'7451'} = "Sunds";
$location{'7470'} = "Karup J";
$location{'7480'} = "Vildbjerg";
$location{'7490'} = "Aulum";
$location{'7500'} = "Holstebro";
$location{'7540'} = "Haderup";
$location{'7550'} = "Sørvad";
$location{'7560'} = "Hjerm";
$location{'7570'} = "Vemb";
$location{'7600'} = "Struer";
$location{'7620'} = "Lemvig";
$location{'7650'} = "Bøvlingbjerg";
$location{'7660'} = "Bækmarksbro";
$location{'7673'} = "Harboøre";
$location{'7680'} = "Thyborøn";
$location{'7700'} = "Thisted";
$location{'7730'} = "Hanstholm";
$location{'7741'} = "Frøstrup";
$location{'7742'} = "Vesløs";
$location{'7752'} = "Snedsted";
$location{'7755'} = "Bedsted Thy";
$location{'7760'} = "Hurup Thy";
$location{'7770'} = "Vestervig";
$location{'7790'} = "Thyholm";
$location{'7800'} = "Skive";
$location{'7830'} = "Vinderup";
$location{'7840'} = "Højslev";
$location{'7850'} = "Stoholm Jyll";
$location{'7860'} = "Spøttrup";
$location{'7870'} = "Roslev";
$location{'7884'} = "Fur";
$location{'7900'} = "Nykøbing M";
$location{'7950'} = "Erslev";
$location{'7960'} = "Karby";
$location{'7970'} = "Redsted M";
$location{'7980'} = "Vils";
$location{'7990'} = "Øster Assels";
$location{'7992'} = "Sydjylland/Fyn USF P"; $owner{'7992'} = "Ufrankerede svarforsendelser";
$location{'7993'} = "Sydjylland/Fyn USF B"; $owner{'7993'} = "Ufrankerede svarforsendelser";
$location{'7996'} = "Fakturaservice"; $owner{'7996'} = "(Post til scanning)";
$location{'7997'} = "Fakturascanning"; $owner{'7997'} = "(Post til scanning)";
$location{'7999'} = "Kommunepost"; $owner{'7999'} = "(Post til scanning)";
$location{'8000'} = "Århus C";
$location{'8100'} = "Århus C"; $type{'8100'} = "BX";
$location{'8200'} = "Århus N";
$location{'8210'} = "Århus V";
$location{'8220'} = "Brabrand";
$location{'8229'} = "Risskov Ø"; $type{'8229'} = "PP";
$location{'8230'} = "Åbyhøj";
$location{'8240'} = "Risskov";
$location{'8245'} = "Risskov Ø"; $owner{'8245'} = "Østjyllands Postcenter + erhvervskunder";
$location{'8250'} = "Egå";
$location{'8260'} = "Viby J";
$location{'8270'} = "Højbjerg";
$location{'8300'} = "Odder";
$location{'8305'} = "Samsø";
$location{'8310'} = "Tranbjerg J";
$location{'8320'} = "Mårslet";
$location{'8330'} = "Beder";
$location{'8340'} = "Malling";
$location{'8350'} = "Hundslund";
$location{'8355'} = "Solbjerg";
$location{'8361'} = "Hasselager";
$location{'8362'} = "Hørning";
$location{'8370'} = "Hadsten";
$location{'8380'} = "Trige";
$location{'8381'} = "Tilst";
$location{'8382'} = "Hinnerup";
$location{'8400'} = "Ebeltoft";
$location{'8410'} = "Rønde";
$location{'8420'} = "Knebel";
$location{'8444'} = "Balle";
$location{'8450'} = "Hammel";
$location{'8462'} = "Harlev J";
$location{'8464'} = "Galten";
$location{'8471'} = "Sabro";
$location{'8472'} = "Sporup";
$location{'8500'} = "Grenaa";
$location{'8520'} = "Lystrup";
$location{'8530'} = "Hjortshøj";
$location{'8541'} = "Skødstrup";
$location{'8543'} = "Hornslet";
$location{'8544'} = "Mørke";
$location{'8550'} = "Ryomgård";
$location{'8560'} = "Kolind";
$location{'8570'} = "Trustrup";
$location{'8581'} = "Nimtofte";
$location{'8585'} = "Glesborg";
$location{'8586'} = "Ørum Djurs";
$location{'8592'} = "Anholt";
$location{'8600'} = "Silkeborg";
$location{'8620'} = "Kjellerup";
$location{'8632'} = "Lemming";
$location{'8641'} = "Sorring";
$location{'8643'} = "Ans By";
$location{'8653'} = "Them";
$location{'8654'} = "Bryrup";
$location{'8660'} = "Skanderborg";
$location{'8670'} = "Låsby";
$location{'8680'} = "Ry";
$location{'8700'} = "Horsens";
$location{'8721'} = "Daugård";
$location{'8722'} = "Hedensted";
$location{'8723'} = "Løsning";
$location{'8732'} = "Hovedgård";
$location{'8740'} = "Brædstrup";
$location{'8751'} = "Gedved";
$location{'8752'} = "Østbirk";
$location{'8762'} = "Flemming";
$location{'8763'} = "Rask Mølle";
$location{'8765'} = "Klovborg";
$location{'8766'} = "Nørre Snede";
$location{'8781'} = "Stenderup";
$location{'8783'} = "Hornsyld";
$location{'8800'} = "Viborg";
$location{'8830'} = "Tjele";
$location{'8831'} = "Løgstrup";
$location{'8832'} = "Skals";
$location{'8840'} = "Rødkærsbro";
$location{'8850'} = "Bjerringbro";
$location{'8860'} = "Ulstrup";
$location{'8870'} = "Langå";
$location{'8881'} = "Thorsø";
$location{'8882'} = "Fårvang";
$location{'8883'} = "Gjern";
$location{'8900'} = "Randers C";
$location{'8920'} = "Randers NV";
$location{'8930'} = "Randers NØ";
$location{'8940'} = "Randers SV";
$location{'8950'} = "Ørsted";
$location{'8960'} = "Randers SØ";
$location{'8961'} = "Allingåbro";
$location{'8963'} = "Auning";
$location{'8970'} = "Havndal";
$location{'8981'} = "Spentrup";
$location{'8983'} = "Gjerlev J";
$location{'8990'} = "Fårup";
$location{'9000'} = "Aalborg";
$location{'9029'} = "Aalborg"; $type{'9029'} = "PP";
$location{'9100'} = "Aalborg"; $type{'9100'} = "BX";
$location{'9200'} = "Aalborg SV";
$location{'9210'} = "Aalborg SØ";
$location{'9220'} = "Aalborg Øst";
$location{'9230'} = "Svenstrup J";
$location{'9240'} = "Nibe";
$location{'9260'} = "Gistrup";
$location{'9270'} = "Klarup";
$location{'9280'} = "Storvorde";
$location{'9293'} = "Kongerslev";
$location{'9300'} = "Sæby";
$location{'9310'} = "Vodskov";
$location{'9320'} = "Hjallerup";
$location{'9330'} = "Dronninglund";
$location{'9340'} = "Asaa";
$location{'9352'} = "Dybvad";
$location{'9362'} = "Gandrup";
$location{'9370'} = "Hals";
$location{'9380'} = "Vestbjerg";
$location{'9381'} = "Sulsted";
$location{'9382'} = "Tylstrup";
$location{'9400'} = "Nørresundby";
$location{'9430'} = "Vadum";
$location{'9440'} = "Aabybro";
$location{'9460'} = "Brovst";
$location{'9480'} = "Løkken";
$location{'9490'} = "Pandrup";
$location{'9492'} = "Blokhus";
$location{'9493'} = "Saltum";
$location{'9500'} = "Hobro";
$location{'9510'} = "Arden";
$location{'9520'} = "Skørping";
$location{'9530'} = "Støvring";
$location{'9541'} = "Suldrup";
$location{'9550'} = "Mariager";
$location{'9560'} = "Hadsund";
$location{'9574'} = "Bælum";
$location{'9575'} = "Terndrup";
$location{'9600'} = "Aars";
$location{'9610'} = "Nørager";
$location{'9620'} = "Aalestrup";
$location{'9631'} = "Gedsted";
$location{'9632'} = "Møldrup";
$location{'9640'} = "Farsø";
$location{'9670'} = "Løgstør";
$location{'9681'} = "Ranum";
$location{'9690'} = "Fjerritslev";
$location{'9700'} = "Brønderslev";
$location{'9740'} = "Jerslev J";
$location{'9750'} = "Østervrå";
$location{'9760'} = "Vrå";
$location{'9800'} = "Hjørring";
$location{'9830'} = "Tårs";
$location{'9850'} = "Hirtshals";
$location{'9870'} = "Sindal";
$location{'9881'} = "Bindslev";
$location{'9900'} = "Frederikshavn";
$location{'9940'} = "Læsø";
$location{'9970'} = "Strandby";
$location{'9981'} = "Jerup";
$location{'9982'} = "Ålbæk";
$location{'9990'} = "Skagen";
$location{'9992'} = "Jylland USF P"; $owner{'9992'} = "Ufrankerede svarforsendelser";
$location{'9993'} = "Jylland USF B"; $owner{'9993'} = "Ufrankerede svarforsendelser";
$location{'9996'} = "Fakturaservice";
$location{'9997'} = "Fakturascanning"; $owner{'9997'} = "(Post til scanning)";
$location{'9998'} = "Borgerservice"; $owner{'9998'} = "(Post til scanning)";
$location{'2412'} = "Santa Claus/Julemanden";
$location{'3900'} = "Nuuk";
$location{'3905'} = "Nuussuaq";
$location{'3910'} = "Kangerlussuaq";
$location{'3911'} = "Sisimiut";
$location{'3912'} = "Maniitsoq";
$location{'3913'} = "Tasiilaq";
$location{'3915'} = "Kulusuk";
$location{'3919'} = "Alluitsup Paa";
$location{'3920'} = "Qaqortoq";
$location{'3921'} = "Narsaq";
$location{'3922'} = "Nanortalik";
$location{'3923'} = "Narsarsuaq";
$location{'3924'} = "Ikerasassuaq";
$location{'3930'} = "Kangilinnguit";
$location{'3932'} = "Arsuk";
$location{'3940'} = "Paamiut";
$location{'3950'} = "Aasiaat";
$location{'3951'} = "Qasigiannguit";
$location{'3952'} = "Ilulissat";
$location{'3953'} = "Qeqertarsuaq";
$location{'3955'} = "Kangaatsiaq";
$location{'3961'} = "Uummannaq";
$location{'3962'} = "Upernavik";
$location{'3964'} = "Qaarsut";
$location{'3970'} = "Pituffik";
$location{'3971'} = "Qaanaaq";
$location{'3972'} = "Station Nord";
$location{'3980'} = "Ittoqqortoormiit";
$location{'3982'} = "Mestersvig";
$location{'3984'} = "Danmarkshavn";
$location{'3985'} = "Constable Pynt";
$location{'3992'} = "Slædepatruljen Sirius";
$location{'100'} = "Tórshavn";
$location{'110'} = "Tórshavn "; $type{'110'} = "BX";
$location{'160'} = "Argir";
$location{'165'} = "Argir "; $type{'165'} = "BX";
$location{'175'} = "Kirkjubøur";
$location{'176'} = "Velbastadur";
$location{'177'} = "Sydradalur, Streymoy";
$location{'178'} = "Nordradalur";
$location{'180'} = "Kaldbak";
$location{'185'} = "Kaldbaksbotnur";
$location{'186'} = "Sund";
$location{'187'} = "Hvitanes";
$location{'188'} = "Hoyvík";
$location{'210'} = "Sandur";
$location{'215'} = "Sandur"; $type{'215'} = "BX";
$location{'220'} = "Skálavík";
$location{'230'} = "Húsavík";
$location{'235'} = "Dalur";
$location{'236'} = "Skarvanes";
$location{'240'} = "Skopun";
$location{'260'} = "Skúvoy";
$location{'270'} = "Nólsoy";
$location{'280'} = "Hestur";
$location{'285'} = "Koltur";
$location{'286'} = "Stóra Dimun";
$location{'330'} = "Stykkid";
$location{'335'} = "Leynar";
$location{'336'} = "Skællingur";
$location{'340'} = "Kvívík";
$location{'350'} = "Vestmanna";
$location{'355'} = "Vestmanna"; $type{'355'} = "BX";
$location{'358'} = "Válur";
$location{'360'} = "Sandavágur";
$location{'370'} = "Midvágur";
$location{'375'} = "Midvágur"; $type{'375'} = "BX";
$location{'380'} = "Sørvágur";
$location{'385'} = "Vatnsoyrar";
$location{'386'} = "Bøur";
$location{'387'} = "Gásadalur";
$location{'388'} = "Mykines";
$location{'400'} = "Oyrarbakki";
$location{'405'} = "Oyrarbakki"; $type{'405'} = "BX";
$location{'410'} = "Kollafjørdur";
$location{'415'} = "Oyrareingir";
$location{'416'} = "Signabøur";
$location{'420'} = "Hósvík";
$location{'430'} = "Hvalvík";
$location{'435'} = "Streymnes";
$location{'436'} = "Saksun";
$location{'437'} = "Nesvík";
$location{'438'} = "Langasandur";
$location{'440'} = "Haldarsvík";
$location{'445'} = "Tjørnuvík";
$location{'450'} = "Oyri";
$location{'460'} = "Nordskáli";
$location{'465'} = "Svináir";
$location{'466'} = "Ljósá";
$location{'470'} = "Eidi";
$location{'475'} = "Funningur";
$location{'476'} = "Gjógv";
$location{'477'} = "Funningsfjørdur";
$location{'478'} = "Elduvík";
$location{'480'} = "Skáli";
$location{'485'} = "Skálafjørdur";
$location{'490'} = "Strendur";
$location{'494'} = "Innan Glyvur";
$location{'495'} = "Kolbanargjógv";
$location{'496'} = "Morskranes";
$location{'497'} = "Selatrad";
$location{'510'} = "Gøta";
$location{'511'} = "Gøtugjógv";
$location{'512'} = "Nordragøta";
$location{'513'} = "Sydrugøta";
$location{'515'} = "Gøta"; $type{'515'} = "BX";
$location{'520'} = "Leirvík";
$location{'530'} = "Fuglafjørdur";
$location{'535'} = "Fuglafjørdur"; $type{'535'} = "BX";
$location{'600'} = "Saltangará";
$location{'610'} = "Saltangará"; $type{'610'} = "BX";
$location{'620'} = "Runavík";
$location{'625'} = "Glyvrar";
$location{'626'} = "Lambareidi";
$location{'627'} = "Lambi";
$location{'640'} = "Rituvík";
$location{'645'} = "Æduvík";
$location{'650'} = "Toftir";
$location{'655'} = "Nes, Eysturoy";
$location{'656'} = "Saltnes";
$location{'660'} = "Søldarfjørdur";
$location{'665'} = "Skipanes";
$location{'666'} = "Gøtueidi";
$location{'690'} = "Oyndarfjørdur";
$location{'695'} = "Hellur";
$location{'700'} = "Klaksvík";
$location{'710'} = "Klaksvík"; $type{'710'} = "BX";
$location{'725'} = "Nordoyri";
$location{'726'} = "Ánir";
$location{'727'} = "Árnafjørdur";
$location{'730'} = "Norddepil";
$location{'735'} = "Depil";
$location{'736'} = "Nordtoftir";
$location{'737'} = "Múli";
$location{'740'} = "Hvannasund";
$location{'750'} = "Vidareidi";
$location{'765'} = "Svinoy";
$location{'766'} = "Kirkja";
$location{'767'} = "Hattarvík";
$location{'780'} = "Kunoy";
$location{'785'} = "Haraldssund";
$location{'795'} = "Sydradalur, Kalsoy";
$location{'796'} = "Húsar";
$location{'797'} = "Mikladalur";
$location{'798'} = "Trøllanes";
$location{'800'} = "Tvøroyri";
$location{'810'} = "Tvøroyri"; $type{'810'} = "BX";
$location{'825'} = "Frodba";
$location{'826'} = "Trongisvágur";
$location{'827'} = "Øravík";
$location{'850'} = "Hvalba";
$location{'860'} = "Sandvík";
$location{'870'} = "Fámjin";
$location{'900'} = "Vágur";
$location{'910'} = "Vágur"; $type{'910'} = "BX";
$location{'925'} = "Nes, Vágur";
$location{'926'} = "Lopra";
$location{'927'} = "Akrar";
$location{'928'} = "Vikarbyrgi";
$location{'950'} = "Porkeri";
$location{'960'} = "Hov";
$location{'970'} = "Sumba";

## misc/update end

1;
__END__

=head1 NAME

Geo::Postcodes::DK - Danish postcodes with associated information

=head1 SYNOPSIS

This module can be used object oriented, or as procedures.
Take your pick.

=head2 AS OBJECTS

 use Geo::Postcodes::DK;

 my $postcode = '1171';

 if (Geo::Postcodes::DK::valid($postcode)) # A valid postcode?
 {
   my $P = Geo::Postcodes::DK->new($postcode);

   printf "Postcode         '%s'.\n", $P->postcode();
   printf "Postal location: '%s'.\n", $P->location();
   printf "Borough:         '%s'.\n", $P->borough();
   printf "County:          '%s'.\n", $P->county();
   printf "Owner:           '%s'.\n", $P->owner();
   printf "Address:         '%s'.\n", $P->address();
   printf "Postcode type:   '%s'.\n", $P->type(); 
   printf "- in danish:     '%s'.\n", $P->type_verbose(); 
   printf "- in english:    '%s'.\n", $P->Geo::Postcodes::type_verbose(); 
 }

The test for a valid postcode can also be done on the object itself, as
it will be I<undef> when passed an illegal postcode (and thus no object
at all.)

 my $P = Geo::postcodes::DK->new($postcode);

 if ($P) { ... }

A more compact solution:

 if ($P = Geo::Postcodes::DK->new($postcode))
 {
   foreach my $field (Geo::Postcodes::DK::get_fields())
   {
     printf("%-20s %s\n", ucfirst($field), $P->$field())
   }
 }

=head2 AS PROCEDURES

 use Geo::postcodes::DK;

 my $postcode = "1171";

 if (Geo::Postcodes::DK::valid($postcode))
 {
   printf "Postcode"        '%s'.\n", $postcode;
   printf "Postal location: '%s'.\n", location_of($postcode);
   printf "Postcode type:   '%s'.\n", type_of($postcode); 
   printf "Owner:           '%s'.\n", owner_of($postcode);
   printf "Address:         '%s'.\n", address_of($postcode);
 }

=head1 ABSTRACT

Geo::postcodes::DK - Perl extension for the mapping between danish
(including Grønland and Færøerne) postcodes, postal location,
address and address owner.

=head1 DESCRIPTION

Tired og entering the postal name all the time? This is not necessary, as
it is uniquely defined from the postcode. Request the postcode only,
and use this library to get the postal name.

=head2 EXPORT

None.

The module supports the following fields: 'postcode', 'location', 'address',
'owner', 'type', and -type_verbose'. This list can also be obtained with the
call C<Geo::Postcodes::DK::get_fields()>.

=head1 DEPENDENCIES

This module is a subclass of Geo::Postcodes, which must be installed first.

=head1 PROCEDURES and METHODS

These functions can be used as methods or procedures.

=head2 is_field

 my $boolean = Geo::postcodes::DK::is_field($field);
 my $boolean = $postcode_object->is_field($field);

Does the specified field exist.

=head2 get_fields

  my @fields = Geo::postcodes::DK::get_fields();
  my @fields = $postcode_object->get_fields();

A list of fields supported by this class.

=head2 selection

This procedure/method makes it possible to select more than one postcode at a time,
based on arbitrary complex rules.

See the selection documentation (I<perldoc Geo::Postcodes::Selection> or
I<man Geo::Postcodes::Selection>) for a full description, and the tutorial
(I<perldoc Geo::Postcodes::Tutorial> or I<man Geo::Postcodes::Tutorial>)
for sample code.

=head2 selection_loop

As above.

=head1 PROCEDURES

Note that the I<xxx_of> procedures return I<undef> when passed an illegal
argument. They are used internally by the object constructor (new).

=head2 legal

C<my $boolean = Geo::postcodes::DK::legal($postcode);>

Do we have a legal postcode; a code that follows the syntax rules?

=head2 valid

C<my $boolean = Geo::postcodes::DK::valid($postcode);>

Do we have a valid postcode; a code in actual use?

=head2 get_postcodes

This will return an unsorted list of all the norwegian postcodes.

=head2 verify_selectionlist

This will check the list of arguments for correctness, and should
be used before calling 'selection'. The procedure returns a modified
version of the arguments on success, and diagnostic messages on failure.

  my($status, @modified) = Geo::Postcodes::DK::verify_selectionlist(@args);

  if ($status)
  {
    my @result = Geo::Postcodes::DK::selection(@modified);
  }
  else
  {
    print "Diagnostic messages:\n";
    map { print " - $_\n" } @modified;
  }

=head2 postcode_of

  $postcode = Geo::Postcodes::NO::postcode_of($postcode);

Used internally by 'selection', but otherwise not very useful.

=head2 location_of

C<my $location = Geo::postcodes::DK::location_of($postcode);>

The postal place associated with the specified postcode.

=head2 owner_of

C<my $owner = Geo::postcodes::DK::owner_of($postcode);>

The owner (company) of the postcode, if any.

=head2 address_of

C<my $address = Geo::postcodes::DK::address_of($postcode);>

The address (street) associated with the specified postcode.

=head2 type_of

 my $type = Geo::postcodes::DK::type_of($postcode);

What kind of postcode is this, as a code.

=head2 type_verbose_of

 my $danish_description  = Geo::postcodes::DK::type_verbose_of($postcode);
 my $english_description = Geo::postcodes::type_verbose_of($postcode);

A danish text describing the type. Use the base class for the english
description.

See the L<TYPE> section for a description of the types.

=head2 type2verbose

Get the description of the specified type.

  my $danish_description  = Geo::Postcodes::DK::type2verbose($type);
  my $english_description = Geo::Postcodes::type2verbose($type);

=head1 METHODS

=head2 new

  my $P = Geo::postcodes::DK-E<gt>new($postcode);

Create a new postcode object. Internally this will call the C<xxx_of> procedures
for the fields supported by this class.

The constructor will return I<undef> when passed an invalid or illegal postcode.
Do not try method calls on it, as it is not an object. See the description of
the I<legal> and I<valid> procedures above.

=head2 postcode

  my $postcode = $P->postcode();

The postcode, as given to the constructor (new).

=head2 location

  my $location = $P->location();

The postal location associated with the specified postcode.

=head2 type

  my $type = $P->type();

See the description of the procedure I<type_of> above.

=head2 type_verbose

See the description of the procedure I<type_verbose_of> above.

  my $type_danish  = $P->type_verbose();
  my $type_english = $P->Geo::Postcodes::type_verbose();

Use this to get the description.

See the L<TYPE> section for a description of the types.

=head1 TYPE

This class supports the following types for the postal locatuons:

=over

=item BX

Postboks (Post Office box)

=item ST

Gadeadresse (Street address)

=item IO

Personlig eier (Individual owner)

=item PP

Ufrankerede svarforsendelser (Porto Paye receiver)

=back

Se L<Geo::Postcodes> for furter descriptions.

=head1 CAVEAT

=head2 POSTCODES

Danish postcodes (including Grønland) are four digit numbers ("0000" to "9999"),
while Færøerne uses three digits numbers ("000" to "999"). This means that
"0010" and "010" are legal, while "10" is not.

Use I<legal> to check for legal postcodes, and I<valid> to check if
the postcode is actually in use. C<Geo::postcodes::DK->new($postcode)>
will return I<undef> if passed an illegal or invalid postcode. 

An attempt to access the methods of a non-existent postcode object will
result in a runtime error. This can be avoided by checking if the postal
code is legal, before creating the object; C<valid($postcode)>
returns true or false.

=head2 CHARACTER SET

The library was written using the ISO-8859-1 (iso-latin1) character set, and the
special danish letters 'Æ', 'Ø' and 'Å' occur regularly in the postal places,
kommune name and fylke name. Usage of other character sets may cause havoc.
Unicode is not tested.

Note that the case insensitive search (in the 'selection' method/procedure)
doesn't recognize an 'Æ' as an 'æ' (and so on). C<use locale> in the
application program should fix this, if the current locale supports these
characters.

=head1 SEE ALSO

See also the sample programs in the C<eg/>-directory of the distribution, the
tutorial (C<perldoc Geo::Postcodes::Tutorial> or C<man Geo::Postcodes::Tutorial>)
and the selection manual (I<perldoc Geo::Postcodes::Selection> or
I<man Geo::Postcodes::Selection>) for usage details.

The latest version of this library should always be available on CPAN, but see
also the library home page; F<http://bbop.org/perl/GeoPostcodes> for additional
information and sample usage.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006 by Arne Sommer - perl@bbop.org

This library is free software; you can redistribute them and/or modify
it under the same terms as Perl itself.

=cut

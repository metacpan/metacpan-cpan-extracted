#------------------------------------------------------------------------------
# Test script for Lingua::EN::::AddressParse.pm
# Author : Kim Ryan
#------------------------------------------------------------------------------

use strict;
use Lingua::EN::AddressParse;
use Test::Simple tests => 15;



my $input;

my %args =
(
  country     => 'Australia',
  auto_clean  => 1,
  force_case  => 1,
  abbreviate_subcountry => 1
);

my $address = Lingua::EN::AddressParse->new(%args);

$input = "12A/74-76 OLD AMINTA CRESCENT HASALL GROVE NEW SOUTH WALES 2761 AUSTRALIA";
$address->parse($input);
my %props = $address->properties;

my %comps = $address->components;

ok
(
    (
        
        $comps{sub_property_identifier} eq '12A' and
        $comps{property_identifier} eq '74-76'  and
        $comps{street_name} eq 'Old Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Hasall Grove' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2761' and
        $comps{country} eq 'AUSTRALIA' and
        $props{type}  eq 'suburban'
    ),
    "Australian suburban address with sub property"
);

$input = "Unit 4 12 Queen's Park Road Queens Park NSW 2022 ";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{sub_property_type} eq 'Unit' and
        $comps{sub_property_identifier} eq '4' and
        $comps{street_name} eq "Queen\'s Park" and
        $comps{street_type} eq 'Road' and
        $comps{suburb} eq 'Queens Park' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2022'
    ),
    "Australian suburban address with two word street"
);

$input = "12 The Avenue Parkes NSW 2522 ";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq "The Avenue" and
        $comps{suburb} eq 'Parkes' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2522'
    ),
    "Suburban address with street noun"
);

$input = "12 Broadway Parkes NSW 2522";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq "Broadway" and
        $comps{suburb} eq 'Parkes' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2522'
    ),
    "Suburban address with single word street"
);


$input = '"OLD REGRET" WENTWORTH FALLS NSW 2780';
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_name} eq '"Old Regret"' and
        $comps{suburb} eq 'Wentworth Falls' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2780'
    ),
    "Australian rural address"
);

$input = 'PO BOX 71 TOONGABBIE PRIVATE BOXES NSW 2146';
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{post_box} eq 'PO BOX 71' and
        $comps{suburb} eq 'Toongabbie' and
        $comps{subcountry} eq 'NSW' and
        $comps{post_code} eq '2146' and
        $comps{po_box_type} eq 'Private Boxes'
    ),
    "Australian PO Box"
);


$input = "12 SMITH ST ULTIMO NSW 2007 : ALL POSTAL DELIVERIES";
$address->parse($input);
%props = $address->properties;
ok($props{non_matching} eq "ALL POSTAL DELIVERIES ", "Australian Non matching");



# Test other countries

%args = ( country  => 'US');
$address = Lingua::EN::AddressParse->new(%args);

$input = "12 AMINTA CRESCENT S # 24E BEVERLEY HILLS CA 90210-1234";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{sub_property_identifier} eq '24E' and
        $comps{sub_property_type} eq '#' and
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{street_direction_suffix} eq 'S' and
        $comps{suburb} eq 'Beverley Hills' and
        $comps{subcountry} eq 'CA' and
        $comps{post_code} eq '90210-1234'
    ),
    "US suburban address"
);

$input = "12 US HIGHWAY 19 N BEVERLEY HILLS CA 90210-1234";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq 'US Highway 19 N' and
        $comps{suburb} eq 'Beverley Hills' and
        $comps{subcountry} eq 'CA' and
        $comps{post_code} eq '90210-1234'
    ),
    "US government road address"
);


%args = ( country => 'Canada' );

$address = Lingua::EN::AddressParse->new(%args);

$input = "12 AMINTA CRESCENT BEVERLEY HILLS BRITISH COLUMBIA K1B 4L7";
$address->parse($input);
%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Beverley Hills' and
        $comps{subcountry} eq 'BRITISH COLUMBIA' and
        $comps{post_code} eq 'K1B 4L7'
    ),
    "Canadian suburban address"
);


%args = ( country  => 'United Kingdom',  auto_clean  => 1);
# note pre cursor only detected if auto_clean is on
$address = Lingua::EN::AddressParse->new(%args);

$input = "C/O MR A B SMITH XYZ P/L: 12 AMINTA CRESCENT NEWPORT IOW SW1A 9ET";
$address->parse($input);
%comps = $address->components;

%comps = $address->components;
ok
(
    (
        $comps{pre_cursor} eq 'C/O Mr A B Smith Xyz P/L:' and
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Newport' and
        $comps{subcountry} eq 'IOW' and
        $comps{post_code} eq 'SW1A 9ET'
    ),
    "UK suburban address with pre cursor"
);

$input = "12 AMINTA CRESCENT NEWPORT IOW SW1A 9ET";
$address->parse($input);
%comps = $address->components;

%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Newport' and
        $comps{subcountry} eq 'IOW' and
        $comps{post_code} eq 'SW1A 9ET'
    ),
    "UK suburban address"
);

$input = "Building 2A Level 24 12 AMINTA CRESCENT NEWPORT IOW SW1A 9ET";
$address->parse($input);
%comps = $address->components;

%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '12' and
        $comps{building} eq 'Building 2a' and
        $comps{level} eq 'Level 24' and 
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Newport' and
        $comps{subcountry} eq 'IOW' and
        $comps{post_code} eq 'SW1A 9ET'
    ),
    "UK address with building and level"
);


$input = "12 ZTL CRESCENT NEWPORT IOW SW1A 9ET";
$address->parse($input);
ok
(
    (
        $address->{warning_desc} eq ';no vowel sound in street word : ZTL'
    ),
    "no vowel sound in street"
);

$input = "12 A 24 AMINTA CRESCENT NEWPORT IOW SW1A 9ET";
$address->parse($input);
%comps = $address->components;

%comps = $address->components;
ok
(
    (
        $comps{property_identifier} eq '24' and
        $comps{sub_property_identifier} eq '12A' and
        $comps{street_name} eq 'Aminta' and
        $comps{street_type} eq 'Crescent' and
        $comps{suburb} eq 'Newport' and
        $comps{subcountry} eq 'IOW' and
        $comps{post_code} eq 'SW1A 9ET'
    ),
    "sub property auto clean"
);



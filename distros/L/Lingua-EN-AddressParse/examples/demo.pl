#!/usr/local/bin/perl

# Demo script for Lingua::EN::AddressParse.pm

use strict;
use Lingua::EN::AddressParse;

my %args =
(
   country     => 'AU',
   auto_clean  => 0,
   force_case  => 1,
   abbreviated_subcountry_only => 0
);


my $address = Lingua::EN::AddressParse->new(%args);
open(REPORT_FH,">report.txt") or die;

open(ERROR_FH,">error.txt") or die;

my ($errors,$total);
while ( <DATA> )
{
    # last if $. == 3;
    chomp($_);
    my $address_in = $_;

    $total++;
    my $error = $address->parse($address_in);

    my %comps = $address->components;
    my %props = $address->properties;

    if ( $error and $props{type} eq 'unknown' )
    {
        $errors++;
        print(ERROR_FH "$address_in: $props{non_matching}\n");
    }
    else
    {
        my $line = sprintf("%-8.8s : %-10.10s %-10.10s %-20.20s %-10.10s %-2.2s %-15.15s %-15.15s %-15.15s %-20.20s %-15.15s %-10.10s %-14.14s %-30.30s\n",
            $props{type},
            $comps{sub_property_identifier},$comps{property_identifier},
            $comps{street},$comps{street_type},$comps{street_direction},
            $comps{property_name},$comps{post_box},$comps{road_box},
            $comps{suburb},$comps{subcountry},$comps{post_code},$comps{country},$props{non_matching});
        print(REPORT_FH $line);
   }
}
my $now = localtime(time);

print(REPORT_FH "\n\nTIME : $now \n");
printf(REPORT_FH "BATCH DATA QUALITY: %5.2f percent\n",( 1- ($errors / $total)) *100 );

close(REPORT_FH);
close(ERROR_FH);

#------------------------------------------------------------------------------
__DATA__
12 2nd Street Toongabbie NSW 2146
74 B ST TOONGABBIE NSW 2146
22 Lower 3rd St Toongabbie NSW 2146
12 74 3rd Rd Toongabbie NSW 2146
74 12th Avenue South West Rocks NSW 2146
74 12th St Toongabbie NSW 2146
74 Queen's Park Road Toongabbie NSW 2146
74 Queen's Park Toongabbie NSW 2146
147 OLD CHARLESTOWN ROAD KOTARA HEIGHTS NEW SOUTH WALES 2289 AUSTRALIA
22A GRAND RIDGE ROAD CARDIFF VIC 3285 AUSTRALIA
"OLD REGRET" WENTWORTH FALLS NT 882
14A WANDARRA CRESCENT ST JOHNS WOOD SW 200
2/3-5 GLEN ALPINE WAY ST VERMONT VIC 3133
74 ST THOMAS LANE ST. IVES WEST NSW 2075
Level 2 12 THE CIRCUIT WERRIBEE HILLS VICTORIA 3030
60 Mount Baw Baw Road Mt Baw Baw VIC 3871
UNIT 1 61 THE GRAND PARADE CORLETTE NSW 2315
Unit 4 26 george street french's forest nsw 2286
RMS 75 MOUNT VICTORIA NSW 2761
RMB 75 XYZ HIGHWAY MOUNT VICTORIA NSW 2761
RMB 75 MOUNT VICTORIA NSW 2761
PO BOX 71B VICTORIA VALLEY VICTORIA 3146
LOT 2C THE ESPLANADE CARDIFF NSW 2285
BAD ADDRESS GARDWELL 4849
12 SMITH ST ULTIMO NSW 2007 : ALL POSTAL DELIVERIES
1234 11th St Minneapolis NSW 5407
6505 Glen Road Woodbury NSW 5525
3363 Coachman Rd Eagan NSW 5521
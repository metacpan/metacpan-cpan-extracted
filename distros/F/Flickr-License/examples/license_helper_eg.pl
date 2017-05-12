#!/usr/bin/perl -w
use strict;
use Flickr::License::Helper;
use Data::Dumper;

# my apikey
my $APIKEY="eca139188e928544ffa9c8593f81cb2d";

# grab Helper instance
my $helper=Flickr::License::Helper->instance($APIKEY);

# get licenses structure
my $available_licenses=$helper->licenses;

print Dumper($available_licenses);

# As of 20070729
#
#$VAR1 = {
#          '6' => {
#                   'url' => 'http://creativecommons.org/licenses/by-nd/2.0/',
#                   'name' => 'Attribution-NoDerivs License'
#                 },
#          '1' => {
#                   'url' => 'http://creativecommons.org/licenses/by-nc-sa/2.0/',
#                   'name' => 'Attribution-NonCommercial-ShareAlike License'
#                 },
#          '4' => {
#                   'url' => 'http://creativecommons.org/licenses/by/2.0/',
#                   'name' => 'Attribution License'
#                 },
#          '3' => {
#                   'url' => 'http://creativecommons.org/licenses/by-nc-nd/2.0/',
#                   'name' => 'Attribution-NonCommercial-NoDerivs License'
#                 },
#          '0' => {
#                   'url' => '',
#                   'name' => 'All Rights Reserved'
#                 },
#          '2' => {
#                   'url' => 'http://creativecommons.org/licenses/by-nc/2.0/',
#                   'name' => 'Attribution-NonCommercial License'
#                 },
#          '5' => {
#                   'url' => 'http://creativecommons.org/licenses/by-sa/2.0/',
#                   'name' => 'Attribution-ShareAlike License'
#                 }
#        };

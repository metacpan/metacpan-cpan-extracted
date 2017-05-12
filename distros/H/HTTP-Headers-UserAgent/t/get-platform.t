#!perl
#
# get-platform.t - tests for backwards compatibility with v1.00
#
# Couldn't find an example for 'Win3x'
#

use strict;
use warnings;

use Test::More 0.88 tests => 8;
use HTTP::Headers::UserAgent qw(GetPlatform);

my %data =
(
   'Win95' => 'Mozilla/3.0 (Win95; I)',
     'OS2' => 'Mozilla/4.61 [de] (OS/2; I)',
     'MAC' => 'Mozilla/4.5 (compatible; OmniWeb/4.1-beta-1; Mac_PowerPC)',
   # 'Win3x' => 'Mozilla/3.0 (compatible; Opera/3.0; Windows 3.1) v3.1',
   'WinME' => 'Mozilla/4.0 (compatible; MSIE 5.5; Windows 98; Win 9x 4.90; MSIECrawler)',
   'Win98' => 'Mozilla/4.0 (compatible; MSIE 6.0b; Windows 98)',
   'WinNT' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.5) Gecko/20060731 Firefox/1.5.0.5 Flock/0.7.4.1',
    'UNIX' => 'Mozilla/3.0 (X11; I; OSF1 V4.0 alpha)',
   'Linux' => 'Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9a8) Gecko/2007100619 GranParadiso/3.0a8',
);
my ($ua_string, $guess, $expected_platform);

foreach $expected_platform (keys %data)
{
    $ua_string = $data{$expected_platform};
    $guess = GetPlatform($ua_string);
    ok(defined($guess) && $guess eq $expected_platform, $expected_platform);
}

exit 0;


#!/usr/bin/perl

use JPEG::JFIF;
use strict;

my $jfif = new JPEG::JFIF;
# this give you "caption" tag content.
$jfif->read("file.jpg");
print $jfif->getdata("caption"); 

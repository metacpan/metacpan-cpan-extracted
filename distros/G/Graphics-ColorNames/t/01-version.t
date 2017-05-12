#!/usr/bin/perl

use strict;
use Test::More tests => 5;

use_ok("Graphics::ColorNames");

my @Modules = (qw( X HTML Windows Netscape));

foreach my $mod (@Modules) {
    use_ok("Graphics::ColorNames::$mod", $Graphics::ColorNames::VERSION);
}


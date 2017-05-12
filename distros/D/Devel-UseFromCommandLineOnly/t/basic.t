#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# it's almost impossible to reliably shell out to perl with all the correct
# settings for this system.  Therefore I don't bother.  I just run it if 
# this is my machine, otherwise I skip all the tests

BEGIN {
  unless ($ENV{THIS_IS_MARKF_YOU_BETCHA}) {
    plan skip_all => "Not mark's computer";
    exit;
  }
  plan tests => 7;
} 

use v5.10;

use FindBin;
use String::ShellQuote;
use Path::Class;

my $switches =  "-I".shell_quote(dir($FindBin::Bin,"lib"))
  ." -I".shell_quote(dir($FindBin::Bin)->parent->subdir("lib"))
  ." 2>&1";

my $perl = "perl $switches";
my $prove = "prove $switches";

is(
  `$perl -MAVeryUnlikelyModuleName -E 'say \$::string'`,
  "This will work!\n",
  "-M"
);
is(
  `$perl -E 'use AVeryUnlikelyModuleName; say \$::string'`,
  "This will work!\n",
  "inline in command line"
);

is(
  `echo 'use AVeryUnlikelyModuleName; use 5.010; say \$::string' | $perl`,
  "This will work!\n",
  "Piped"
);

{
  local $ENV{PERL5OPT} = "-MAVeryUnlikelyModuleName";
  is(`$perl -E 'say \$::string'`, "This will work!\n", "PERL5OPT");
}

my $goodscript = shell_quote(file($FindBin::Bin,"good.pl"));
is(`$perl -MAVeryUnlikelyModuleName $goodscript`, "This will work!\n", "Good script");

like(`$perl -MBadModuleWillDie`, qr/Invalid use of AVeryUnlikelyModuleName in/,
  "Bad module");

my $badscript = shell_quote(file($FindBin::Bin,"bad.pl"));
like(`$perl $badscript`, qr/Invalid use of AVeryUnlikelyModuleName in/,
  "Bad script");
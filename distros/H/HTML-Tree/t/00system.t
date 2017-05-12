#!/usr/bin/perl -T

use warnings;
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok('HTML::TreeBuilder');
    use_ok('HTML::Element');
}

print "#Using HTML::TreeBuilder version v$HTML::TreeBuilder::VERSION\n";
print "#Using HTML::Element version v$HTML::Element::VERSION\n";
print "#Using HTML::Parser version v", $HTML::Parser::VERSION || "?", "\n";
print "#Using HTML::Entities version v", $HTML::Entities::VERSION || "?",
    "\n";
print "#Using HTML::Tagset version v", $HTML::Tagset::VERSION || "?", "\n";
print "# Running under perl version $] for $^O",
    ( chr(65) eq 'A' ) ? "\n" : " in a non-ASCII world\n";
print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
    if defined(&Win32::BuildNumber)
        and defined &Win32::BuildNumber();
print "# MacPerl verison $MacPerl::Version\n"
    if defined $MacPerl::Version;
printf
    "# Current time local: %s\n# Current time GMT:   %s\n",
    scalar( localtime($^T) ), scalar( gmtime($^T) );
print "# byebye from ", __FILE__, "\n";

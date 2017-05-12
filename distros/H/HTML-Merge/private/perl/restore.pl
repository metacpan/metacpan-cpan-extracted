#!/usr/bin/perl

use HTML::Merge::Development;
use HTML::Merge::Engine;
use strict;

ReadConfig();

open(I, "input.frm");

my $url = "pre_web_ini.pl?$extra";

my $f = $HTML::Merge::Ini::FACTORY;

$f->{'DB_PASSWORD'} = &HTML::Merge::Engine::Convert($f->{'DB_PASSWORD'});


while (<I>) {
	chop;
	my ($desc, $name, $type, $opts, $def) = split(/\|/);
	
#	$def =~ s/\@(.*?)\@/(print(':>' . $1 . ' ' . $f->{$1} . "\n"), $1)[-1]/ge;
	$def =~ s/\@(.*?)\@/$f->{$1}/ge;

	$def =~ s/([^-A-Za-z0-9_~\/])/sprintf("%%%02X", ord($1))/ge;
	$def =~ s/ /+/g;

	$url .= "&$name=$def";
}

print "Location: $url\n\n";


#!/usr/bin/perl

# $Id: local.pl,v 1.1 2005/06/28 07:05:32 mark Exp $

use HTML::Chunks::Local;
use strict;

my $chunks = new HTML::Chunks::Local('local.txt');
$chunks->setLangDefaults([qw(en_us en)]);

my $lang = @ARGV ? $chunks->guessLanguage(@ARGV) : [ qw(fr sp) ];

print "languages: @{$lang}\n";

$chunks->output('hello', $lang, 'more data');
print "\n";

$chunks->output('yes', $lang, 'more data');
print "\n";

$chunks->output('no', $lang, 'more data');
print "\n";

print "[";
foreach my $i (@{$chunks->getLangDefaults()}) {
	print "$i, ";
}
print "] default language set\n";

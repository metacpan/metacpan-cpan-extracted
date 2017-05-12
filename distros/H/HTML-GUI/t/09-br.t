#!perl -T

use Test::More tests => 6;
use strict;
use warnings;

use_ok('HTML::GUI::br');

my $br = new HTML::GUI::br({});

is($br->getHtml(),'<br class="spacer"/>');

#check the YAML serialization
my $yamlString = $br->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,'--- 
type: br
');

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $br;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

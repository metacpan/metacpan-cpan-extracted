#!perl -T

use Test::More tests => 10;
use utf8;
use strict;
use warnings;
use Encode;


use_ok('HTML::GUI::hidden');
use_ok('HTML::GUI::screen');
use_ok('Data::Dumper');

my $widget = HTML::GUI::hidden->new({
				id			=> "bla",
				value=> 'La pêche aux moules !! éàüù"',
		});
isa_ok($widget, 'HTML::GUI::widget');
isa_ok($widget, 'HTML::GUI::hidden');
is($widget->getHtml(), '<input id="bla" name="bla" type="hidden" value="La pêche aux moules !! éàüù&quot;"/>',"HTML output test");

my $yamlString = $widget->serializeToYAML();
#diag(" cmp 1:".Encode::is_utf8($yamlString)."\n");
ok($yamlString, "check the YAML serialization");
is($yamlString,q~--- 
id: bla
type: hidden
value: La pêche aux moules !! éàüù"
~);

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $widget;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

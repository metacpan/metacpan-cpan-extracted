#!perl -T

use Test::More tests => 10;
use utf8;
use strict;
use warnings;
use Encode;


use_ok('HTML::GUI::text');
use_ok('HTML::GUI::screen');
use_ok('Data::Dumper');

my $widget = HTML::GUI::text->new({
				id			=> "bla",
				constraints => ['integer','required'],
				value=> 'je vais vous manger !! éàüù"',
		});
isa_ok($widget, 'HTML::GUI::widget');
isa_ok($widget, 'HTML::GUI::text');
is($widget->getHtml(), '<p class="float"><input id="bla" name="bla" type="text" value="je vais vous manger !! éàüù&quot;"/></p>',"HTML output test");

my $yamlString = $widget->serializeToYAML();
#diag(" cmp 1:".Encode::is_utf8($yamlString)."\n");
ok($yamlString, "check the YAML serialization");
is($yamlString,q~--- 
constraints: 
  - integer
  - required
id: bla
type: text
value: je vais vous manger !! éàüù"
~);

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $widget;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

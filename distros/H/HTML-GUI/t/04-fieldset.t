#!perl -T

use Test::More tests => 11;
use strict;
use warnings;

use_ok('HTML::GUI::fieldset');
use_ok('HTML::GUI::text');

my $fieldset = HTML::GUI::fieldset->new({
				id => "my_fieldset",
				label => "my test fieldset"});

is($fieldset->getHtml(),'<fieldset id="my_fieldset"><legend>my test fieldset</legend></fieldset>');

$fieldset->addChild({
				type		=> 'text',
				id			=> "bla",
				label			=> "un premier \" champ",
				constraints => ['integer','required'],
				value=> 'je vais vous manger !! éàüù"""\'',
		});
my $textInput = HTML::GUI::text->new({
				id			=> "textObject",
				value=> '2',
								});
$fieldset->addChild($textInput);

ok(!$fieldset->validate(),"check the constraints of the widgets included in the fieldset");


my $txtInput = $fieldset->getElementById("bla");

$txtInput->setValue(2) ;

ok($fieldset->validate(),"The constraint should be ok now.");

#the id is not mandatory for fieldsets
my $fieldset_without_id = HTML::GUI::fieldset->new( { 
														label => "my test fieldset"});

is($fieldset_without_id->getHtml(),'<fieldset><legend>my test fieldset</legend></fieldset>');


#check the YAML serialization
my $yamlString = $fieldset->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,'--- 
childs: 
  - 
    constraints: 
      - integer
      - required
    id: bla
    label: un premier " champ
    type: text
    value: 2
  - 
    id: textObject
    type: text
    value: 2
id: my_fieldset
label: my test fieldset
type: fieldset
');

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $fieldset;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

#however, the html souhd be the same
is($fieldset->getHtml(),$widgetCopy->getHtml(),"The html of the copy should be a copy of the html (of the original widget)");

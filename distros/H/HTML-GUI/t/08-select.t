#!perl -T

use Test::More tests => 10;
use strict;
use warnings;
use utf8;

use_ok('HTML::GUI::select');

my $select = HTML::GUI::select->new({
		id      => "mySelect",
    options => [{label => "",value=>""},
                {label => "first option", value=>"1"},
                {label=> "second option",value=>"2"}],
		value		=> 2,
		label		=> "mon sélect",
	});

ok($select);


is ($select->getHtml(),q~<p class="float"><label for="mySelect">mon sélect</label><select id="mySelect" name="mySelect" size="1"><option/><option value="1">first option</option><option selected="selected" value="2">second option</option></select></p>~);

$select->setValueFromParams({mySelect => '1'});
is ($select->getHtml(),q~<p class="float"><label for="mySelect">mon sélect</label><select id="mySelect" name="mySelect" size="1"><option/><option selected="selected" value="1">first option</option><option value="2">second option</option></select></p>~);

$select->setValueFromParams({mySelect => ''});
is ($select->getHtml(),q~<p class="float"><label for="mySelect">mon sélect</label><select id="mySelect" name="mySelect" size="1"><option selected="selected"/><option value="1">first option</option><option value="2">second option</option></select></p>~);


#check the YAML serialization
my $yamlString = $select->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,q~--- 
id: mySelect
label: mon sélect
options: 
  - 
    label: ''
    value: ''
  - 
    label: first option
    value: 1
  - 
    label: second option
    value: 2
type: select
~);

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $select;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

#the html should be the same
is($select->getHtml(),$widgetCopy->getHtml(),"The html of the copy should be a copy of the html (of the original widget)");

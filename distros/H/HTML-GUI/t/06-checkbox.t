#!perl -T

use Test::More tests => 12;
use strict;
use warnings;

use_ok('HTML::GUI::checkbox');

my $checkbox_without_id = new HTML::GUI::checkbox({
				label			=> "my test <checkbox> ",
				});
is($checkbox_without_id,undef);

my $checkbox_with_id = new HTML::GUI::checkbox({
				id			=> "myCheckbox",
				label			=> "my test <checkbox> ",
				});

#check if the value is really boolean 1 or 0
$checkbox_with_id->setValue(1);
is($checkbox_with_id->getValue(),1);


$checkbox_with_id->setValue(0);
is($checkbox_with_id->getValue(),0);

$checkbox_with_id->setValue("YES");
is($checkbox_with_id->getValue(),1);

#check the 2 possibles output
$checkbox_with_id->setValue(0);
is($checkbox_with_id->getHtml(),'<p class="float"><label for="myCheckbox">my test &lt;checkbox&gt; </label><input class="ckbx" id="myCheckbox" name="myCheckbox" type="checkbox" value="on"/></p>');

$checkbox_with_id->setValue(1);
is($checkbox_with_id->getHtml(),'<p class="float"><label for="myCheckbox">my test &lt;checkbox&gt; </label><input checked="checked" class="ckbx" id="myCheckbox" name="myCheckbox" type="checkbox" value="on"/></p>');


#check the YAML serialization
my $yamlString = $checkbox_with_id->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,'--- 
id: myCheckbox
label: "my test <checkbox> "
type: checkbox
value: 1
');

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $checkbox_with_id;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

#however, the html souhd be the same
is($checkbox_with_id->getHtml(),$widgetCopy->getHtml(),"The html of the copy should be a copy of the html (of the original widget)");

#!perl -T

use Test::More tests => 14;
use strict;
use warnings;
use utf8;

use_ok('HTML::GUI::actionbar');
use_ok('HTML::GUI::button');

#to test if a button can call a function
sub HTML::GUI::hidden::btnTestFunction{
		return 1;
}

my $actionbar = HTML::GUI::actionbar->new({});

ok($actionbar,"instantiation of the actionbar");

my $btnErase = HTML::GUI::button->new({
type    => 'button',
        id      => "button2",
        value=> "Erase £ and €?",
				btnAction => 'HTML::GUI::hidden::btnTestFunction',
		    });
ok($btnErase,"instantiation of the btnErase button");
my $btn = HTML::GUI::button->new({
       type    => 'button',
       id      => "button",
	    });
ok($btn,"instantiation of the btn");

$btn->setLabel('Test button');
$actionbar->addChild($btn);
$actionbar->addChild($btnErase);

is ($actionbar->getHtml(),q~<p class="actionBar"><input class="btn" id="button" name="button" type="submit" value="Test button"/><input class="btn" id="button2" name="button2" type="submit" value="Erase £ and €?"/></p>~);

#check the YAML serialization
my $yamlString = $actionbar->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,'--- 
childs: 
  - 
    id: button
    type: button
    value: Test button
  - 
    btnAction: HTML::GUI::hidden::btnTestFunction
    id: button2
    type: button
    value: Erase £ and €?
type: actionbar
');

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $actionbar;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

#however, the html souhd be the same
is($actionbar->getHtml(),$widgetCopy->getHtml(),"The html of the copy should be a copy of the html (of the original widget)");

#We want to know which button was fired
# First when nothing happened
my $firedBtn = $actionbar->getFiredBtn({});
is($firedBtn,undef,"If we don't have POST data, we should not find any button fired.");
$firedBtn = $actionbar->getFiredBtn({button=>'Test button'});
ok($firedBtn,"A button was fired.");
is($firedBtn->getId(),"button","The button 'Test button' was fired.");

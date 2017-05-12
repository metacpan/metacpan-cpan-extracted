#!perl -T

use Test::More tests => 34;
use strict;
use warnings;

use utf8;
use_ok('HTML::GUI::widget');
use_ok('HTML::GUI::screen');
use_ok('HTML::GUI::text');
use_ok('File::Temp');
use_ok('Data::Dumper');

my $screen = HTML::GUI::screen->new({id => "my_screen"});
$screen->addChild({
				type		=> 'text',
				id			=> "bla",
				constraints => ['integer','required'],
				value=> 'je vais vous manger !! éàüù"',
		});
$screen->addChild({
				type		=> 'text',
				id			=> "bli",
				constraints => ['integer','required'],
				value=> 'je vais vous manger !! éàüù"',
		});
my $textInput = HTML::GUI::text->new({
				id			=> "textObject",
				value=> '2',
								});
$screen->addChild($textInput);
my $objChild = $screen->getElementById('textObject');
is($objChild->getValue(),'2','check child value');
is($screen->getElementById('textObject')->getValue(),'2','check textobject value');
ok(!$screen->validate(),"Check if some input of the screen violate constraints");
$screen->setValueFromParams({bla=>'1',bli=>'2'});
ok($screen->validate(),"Check all inputs of the screen respect constraints");

#try a call with no param
my $voidDesc = $screen->getDescriptionDataFromParams({});
is_deeply($voidDesc,{},"getDescriptionDataFromParams should return a void hash ref with no param.");

#check the YAML serialization
my $yamlString = $screen->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,q~--- 
childs: 
  - 
    constraints: 
      - integer
      - required
    id: bla
    type: text
    value: 1
  - 
    constraints: 
      - integer
      - required
    id: bli
    type: text
    value: 2
  - 
    id: textObject
    type: text
    value: 2
id: my_screen
type: screen
~);

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");


my $originalDump = Dump $screen;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serialization and deserialization, we have a copy that only differs from the errors");


my $tempFile =  File::Temp->new(SUFFIX => '.yaml');
ok($tempFile,'We need a temp file');
#try to save in a file and read it
ok($screen->writeToFile($tempFile->filename),"save the widget in a file");

my $screenFromFile = HTML::GUI::widget->instantiateFromFile($tempFile->filename);

ok($screenFromFile,"load a screen widget from a file with an absolute path");

my $dirName = $tempFile->filename;
$dirName =~ s/[^\/]*\.yaml//;
ok($dirName,"Extract the directory name of the temp file");
my $fileName = $tempFile->filename;
$fileName =~ s/\Q$dirName\E//;
ok($dirName,"Extract the filename of the temp file");
$screenFromFile = HTML::GUI::widget->instantiateFromFile($fileName,$dirName);

ok($screenFromFile,"load a screen widget from a file from a root path and a relative filename");
#the path of the widget copy is the name of the temp file
#we modify it in order to have all the propeties identical
$screenFromFile->setProp({path=>'/'});

is($screenFromFile->getHtml(),
q~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>HTML-GUI-Widget</title>
	<meta http-equiv="content-type" content="text/html;charset=utf-8" />
	<meta http-equiv="Content-Style-Type" content="text/css" />
	<meta http-equiv="Content-Script-Type" content="text/javascript"/>
		
	
	<link rel="stylesheet" type="text/css" href="/static/css/base.css" />
	
</head>

<body>
		<form action="/" method="post"><p class="float"><input id="bla" name="bla" type="text" value="1"/></p><p class="float"><input id="bli" name="bli" type="text" value="2"/></p><p class="float"><input id="textObject" name="textObject" type="text" value="2"/></p><div style="display:none"><input id="GHW:screenDescription" name="GHW:screenDescription" type="hidden" value="{&quot;counter&quot;:&quot;0&quot;,&quot;screenName&quot;:&quot;/&quot;}"/></div></form>
</body>
</html>
~);

my $fromFileDump = Dump $screenFromFile;


is($fromFileDump,$copyDump,"after a serialization and deserialization, we have a copy");

#Now we want to test a bit more complex screen with containers containing containers

my $bigScreenDesc = q~
--- 
childs: 
  - 
    label: "Identité patient &amp;"
    type: header
  - 
    childs: 
      - 
        constraints: 
          - integer
          - required
        id: bla
        label: un premier " champ
        size: 20
        type: text
        value: "je vais vous manger !! éàüù\"\"\"'"
      - 
        constraints: 
          - integer
          - required
        id: bli0
        label: champ [0]
        size: 15
        type: text
        value: 0
      - 
        constraints: 
          - integer
          - required
        id: bli1
        label: champ [1]
        size: 15
        type: text
        value: 1
      - 
        constraints: 
          - integer
          - required
        id: bli2
        label: champ [2]
        size: 15
        type: text
        value: M Brégardis
      - 
        constraints: 
          - integer
          - required
        id: bli3
        label: champ [3]
        size: 15
        type: text
        value: 3
      - 
        constraints: 
          - integer
          - required
        id: bli4
        label: champ [4]
        size: 15
        type: text
        value: 4
      - 
        constraints: 
          - integer
          - required
        id: bli5
        label: champ [5]
        size: 15
        type: text
        value: 5
      - 
        constraints: 
          - integer
          - required
        id: bli6
        label: champ [6]
        size: 15
        type: text
        value: 6
      - 
        constraints: 
          - integer
          - required
        id: bli7
        label: champ [7]
        size: 15
        type: text
        value: 7
      - 
        constraints: 
          - integer
          - required
        id: bli8
        label: champ [8]
        size: 15
        type: text
        value: 8
      - 
        id: combo04
        label: wahs zaaaaaaa ??
        type: checkbox
        value: 0
      - 
        id: combo03
        label: cold drink
        type: checkbox
        value: 0
      - 
        id: combo01
        label: to be fired ??
        type: checkbox
        value: 0
      - 
        id: combo
        label: Is a <good> guy ?
        type: checkbox
        value: 0
      - 
        id: textObject
        label: another field
        type: text
        value: 2
      - 
        id: mySelect
        label: "mon sélect"
        options: 
          - 
            label: 
            value: 
          - 
            label: first option
            value: 1
          - 
            label: second option
            value: 2
        type: select
    id: my_fieldset
    label: "identité du patient"
    type: fieldset
  - 
    childs: 
      - 
        id: monnom
        label: Nom
        size: 50
        type: text
        value: De la chapeautière
      -
        type: br
      - 
        id: monprenom
        label: Prénom
        type: text
        value: Pierre-Paul-Jaccque
      -
        type: br
      - 
        constraints: 
          - integer
          - required
        id: adr1
        label: "Addresse (1ère ligne)"
        type: text
        value: 12, rue du garel
      -
        type: br
      - 
        constraints: 
          - integer
        id: adr2
        label: "Addresse (2ème ligne)"
        type: text
      -
        type: br
      - 
        childs: 
          - 
            id: button
            type: button
            value: "A Table!! éàüù\"'"
          - 
            id: button2
            type: button
            value: "Effaçer £ et €?"
        type: actionbar
    id: "my_ṉewfieldset"
    label: "informations complémentaires"
    type: fieldset
id: my_screen
type: screen
~;

#dummy function
my $callFlag = 0;
sub HTML::GUI::screen::btnTestFunction{
		my ($params)=@_;
		$params->{status} = 'OK';
		$params->{user_msg}{info} = "Everything's all right";
		$callFlag = 1; #we mark we manage to call this function
		return 1;
}
my $bigScreen = HTML::GUI::widget->instantiateFromYAML($bigScreenDesc);
$bigScreen->validate();

#We must have a correct Html code explaining the input problems
my $eventList = HTML::GUI::log::eventList::getCurrentEventList();
ok($eventList,"We manage to get the global eventList object");
is( $eventList->getHtml(),'<div class="errorList"><h2 class="errorList">Some errors occured.</h2><dl class="errorList"><dt>un premier " champ</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#bla">Fix it.</a></dd><dt>champ [2]</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#bli2">Fix it.</a></dd><dt>Addresse (1ère ligne)</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#adr1">Fix it.</a></dd></dl></div>',"The list of constraints violated in the screen");

#each screen validation must clean the errors of the last validation
#we must obtain the samelist of error and not for example the sum of all list of errors
$bigScreen->validate();
is( $eventList->getHtml(),'<div class="errorList"><h2 class="errorList">Some errors occured.</h2><dl class="errorList"><dt>un premier " champ</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#bla">Fix it.</a></dd><dt>champ [2]</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#bli2">Fix it.</a></dd><dt>Addresse (1ère ligne)</dt><dd>The constraint &quot;integer&quot; is violated. Please correct it.<a href="#adr1">Fix it.</a></dd></dl></div>',"multiple validation is not multiple error");

my $firedBtn = $bigScreen->getFiredBtn({});
is($firedBtn,undef,"If we don't have POST data, we should not find any button fired.");
$firedBtn = $bigScreen->getFiredBtn({button=>'A Table!! éàüù\"'});
ok($firedBtn,"A button was fired.");
is($firedBtn->getId(),"button","The button 'button' was fired.");


my $valueHash = $bigScreen->getValueHash();
my $valueDump = Dumper( $valueHash);
my $expectedValueHashString =q~$VAR1 = {
          'combo03' => 0,
          'mySelect' => '',
          'adr2' => '',
          'monnom' => "De la chapeauti\x{e8}re",
          'bli5' => 5,
          'combo04' => 0,
          'combo' => 0,
          'bli2' => "M Br\x{e9}gardis",
          'textObject' => 2,
          'bli4' => 4,
          'bli7' => 7,
          'bli8' => 8,
          'bli3' => 3,
          'bli6' => 6,
          'bli1' => 1,
          'bla' => "je vais vous manger !! \x{e9}\x{e0}\x{fc}\x{f9}\"\"\"'",
          'monprenom' => 'Pierre-Paul-Jaccque',
          'adr1' => '12, rue du garel',
          'button2' => "Effa\x{e7}er \x{a3} et \x{20ac}?",
          'bli0' => 0,
          'button' => "A Table!! \x{e9}\x{e0}\x{fc}\x{f9}\"'",
          'combo01' => 0
        };
~;
#my $valueDump = Dump $valueHash;
is($valueDump,$expectedValueHashString,"we can get structured data from the screen");
$bigScreen->setValue($valueHash);
my $valueHash2 = $bigScreen->getValueHash();
my $valueDump2 = Dumper($valueHash2);
is($valueDump,$valueDump2,"we managed the structured data round trip");

my $smallScreenYAML = q~--- 
childs: 
  - 
    constraints: 
      - integer
      - required
    id: bla
    type: text
    value: 1
  - 
    constraints: 
      - integer
      - required
    id: bli
    type: text
    value: 2
  - 
    id: textObject
    type: text
    value: 2
  - 
    btnAction: HTML::GUI::screen::btnTestFunction
    id: button
    type: button
    value: A Table!! éàüù
id: my_screen
type: screen
~;

my $smallScreen = HTML::GUI::widget->instantiateFromYAML($smallScreenYAML);
#now we try to do a dummy action
ok(!$callFlag,"We didn't call the dummy function previously");
ok($smallScreen->processHttpRequest({button=>'"A Table!! éàüù\\"\'""'}),"We can call a dummy function");
ok($callFlag,"The btnTestFunction was really called");

$smallScreen->error("This is a dummy message for the violation of a business rule with special caracters [éàüù]");

my $smallScreenHTML = q~<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>HTML-GUI-Widget</title>
	<meta http-equiv="content-type" content="text/html;charset=utf-8" />
	<meta http-equiv="Content-Style-Type" content="text/css" />
	<meta http-equiv="Content-Script-Type" content="text/javascript"/>
		
	
	<link rel="stylesheet" type="text/css" href="/static/css/base.css" />
	
</head>

<body>
		<form action="/" method="post"><div class="errorList"><h2 class="errorList">Some errors occured.</h2><dl class="errorList"><dt>General</dt><dd>This is a dummy message for the violation of a business rule with special caracters [éàüù]</dd></dl></div><p class="float"><input id="bla" name="bla" type="text" value="1"/></p><p class="float"><input id="bli" name="bli" type="text" value="2"/></p><p class="float"><input id="textObject" name="textObject" type="text" value="2"/></p><input class="btn" id="button" name="button" type="submit" value="&quot;A Table!! éàüù\&quot;'&quot;&quot;"/><div style="display:none"><input id="GHW:screenDescription" name="GHW:screenDescription" type="hidden" value="{&quot;counter&quot;:&quot;0&quot;,&quot;screenName&quot;:&quot;/&quot;}"/></div></form>
</body>
</html>
~;

is($smallScreen->getHtml(),$smallScreenHTML,"The specialised error function generates the HTML we expect.");

#!perl -T

use Test::More tests => 8;
use strict;
use warnings;

use_ok('HTML::GUI::header');

my $header = new HTML::GUI::header({
				label			=> "my test header &amp;"
				});

my $header_with_id = new HTML::GUI::header({
				id			=> "myheader",
				label			=> "my test header &amp;"
				});
is($header->getHtml(),'<h1>my test header &amp;amp;</h1>');
is($header_with_id->getHtml(),'<h1>my test header &amp;amp;</h1>');


#check the YAML serialization
my $yamlString = $header->serializeToYAML();
ok($yamlString, "check the YAML serialization");
is($yamlString,'--- 
label: my test header &amp;
type: header
');

my $widgetCopy = HTML::GUI::widget->instantiateFromYAML($yamlString);
ok ($widgetCopy,"The instantation from YAML works");

my $originalDump = Dump $header;
my $copyDump		= Dump $widgetCopy;

#after a serialization/deserialization round-trip
#everything should be identical
is($originalDump,$copyDump,"after a serializatoin and deserialization, we have a copy");

#however, the html souhd be the same
is($header->getHtml(),$widgetCopy->getHtml(),"The html of the copy should be a copy of the html (of the original widget)");

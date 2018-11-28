#!perl -w

use strict;

use Test::More tests=>68;

use MODS::Record qw(xml_string);
use IO::File;
use open qw(:utf8);
use utf8;

my $mods;

ok($mods = MODS::Record->new,"new");
is($mods->version,"3.5","version");
ok($mods->version("3.3"),"set version");
is($mods->version,"3.3","version");

my $abstract;

ok($abstract = $mods->add_abstract("test123",lang=>'eng',contentType=>'text/plain'),"set abstract");
is($abstract,"test123","test abstract body");
is($abstract->lang,"eng","test abstract lang");
is($abstract->contentType,"text/plain","test abstract contentType");

ok($abstract = $mods->add_abstract(MODS::Element::Abstract->new(_body=>'test123',lang=>'eng',contentType=>'text/plain')),"set abstract");
is($abstract,"test123","test abstract body");
is($abstract->lang,"eng","test abstract lang");
is($abstract->contentType,"text/plain","test abstract contentType");

ok($abstract = $mods->add_abstract(sub { my $o = shift; $o->body('test123'); $o->lang('eng'); $o->contentType('text/plain')}),"set abstract");
is($abstract,"test123","test abstract body");
is($abstract->lang,"eng","test abstract lang");
is($abstract->contentType,"text/plain","test abstract contentType");

$abstract = $mods->add_abstract();
ok($abstract->body('test123'));
ok($abstract->lang('eng'));
ok($abstract->contentType('text/plain'));
is($abstract,"test123","test abstract body");
is($abstract->lang,"eng","test abstract lang");
is($abstract->contentType,"text/plain","test abstract contentType");

my @abstract;
ok(@abstract = $mods->get_abstract,"get abstract");
is(@abstract,4,"count abstract");

ok($abstract = $mods->abstract([MODS::Element::Abstract->new(_body=>'test123',lang=>'eng',contentType=>'text/plain')]),"set abstract");
is($abstract->[0],"test123","test abstract body");
is($abstract->[0]->lang,"eng","test abstract lang");
is($abstract->[0]->contentType,"text/plain","test abstract contentType");

ok(@abstract = $mods->get_abstract,"get abstract");
is(@abstract,1,"count abstract");

is($mods->get_abstract(lang=>'eng'),"test123","get one abstract");
is($mods->get_abstract(sub { shift->lang eq 'eng'}),"test123","get one abstract");

my $access;
ok($access = $mods->add_accessCondition('test'),"set string accessCondition");
is($access,'test');
ok($access = $mods->add_accessCondition(xml_string('<test/>')),"set XML accessCondition");
is($access,'<test/>');

my $name   = $mods->add_name(type => 'test');
ok ($name->type,'test');
ok ($mods->get_name(type => 'test'));
ok (!$mods->get_name(type => 'best'));

my @access;
ok(@access = $mods->get_accessCondition,"get accessCondition");
is(@access,2,"count accessCondition");
is(@access = $mods->set_accessCondition(),2,"set accessCondition");
is(@access = $mods->set_accessCondition(undef),0,"set accessCondition");
is(@access = $mods->set_accessCondition(MODS::Element::AccessCondition->new(_body=>'test')),1,"set accessCondition");
is(@access = $mods->set_accessCondition([MODS::Element::AccessCondition->new(_body=>'test')]),1,"set accessCondition");

my $collection;
ok($collection = MODS::Record->from_xml(IO::File->new("t/mods.xml")),"from_xml");
is($collection->get_mods->get_titleInfo->get_title,"Telescope Peak from Zabriskie Point","titleInfo/title");
is($collection->get_mods->get_titleInfo(type=>'alternative')->get_title,"Telescope PK from Zabriskie Pt.","titleInfo[type=\"alternative\"]/title");
is($collection->get_mods->get_relatedItem(type=>'original')->get_location->get_shelfLocator,"381 J8223","relatedItem[type=\"original\"]/location/shelfLocator");
is($collection->get_mods->get_name->get_affiliation,"ug_TW14");

ok($collection = MODS::Record->from_json(IO::File->new("t/mods.json")),"from_json");
is($collection->get_mods->get_titleInfo->get_title,"Telescope Peak from Zabriskie Point","titleInfo/title");
is($collection->get_mods->get_titleInfo(type=>'alternative')->get_title,"Telescope PK from Zabriskie Pt.","titleInfo[type=\"alternative\"]/title");

my $xml;
ok($xml = $collection->as_xml,"as_xml");
ok($xml =~ /^<mods:modsCollection/,"looks like xml");

my $json;
ok($json = $collection->as_json,"as_json");
ok($json = $collection->get_mods->as_json,"as_json (element)");
ok($json = $collection->get_mods->get_titleInfo->as_json,"as_json (element)");

my $obj;
is(MODS::Record->from_json(IO::File->new("t/mods_multiple.json"),sub { $obj = shift }),2,"from_json (callback)");
is($obj->get_titleInfo->get_title,"Telescope Peak from Zabriskie Point","titleInfo/title");

is(MODS::Record->from_xml(IO::File->new("t/mods.xml"), sub { $obj = shift}),1,"from_xml (callback");
is($obj->get_titleInfo->get_title,"Telescope Peak from Zabriskie Point","titleInfo/title");

$mods = MODS::Record->new;
$mods->add_abstract("中华人民共和国");
ok($json = $mods->as_json, "UTF-8 json");
ok($mods = MODS::Record->from_json($json),"UTF-8 parse");
is($mods->get_abstract,"中华人民共和国","read abstract");

$mods = MODS::Record->new;
$mods->add_abstract("中华人民共和国");
ok($xml = $mods->as_xml, "UTF-8 xml");
ok($xml = MODS::Record->from_xml($xml),"UTF-8 parse");
is($mods->get_abstract,"中华人民共和国","read abstract");

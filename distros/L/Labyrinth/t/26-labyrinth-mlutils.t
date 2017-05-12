#!/usr/bin/perl -w
use strict;

use utf8;

use Data::FormValidator;
use Test::More tests => 78;
use Labyrinth::MLUtils;
use Labyrinth::Variables;

Labyrinth::Variables::init();   # initial standard variable values

is(LegalTag('hr'),1);
is(LegalTag('xx'),0);

like(LegalTags(),qr/hr.*and\s\w+$/);

is(CleanTags(),'');
is(CleanTags(''),'');
is(CleanTags('<span>test</span>'),'test');
is(CleanTags('<p>test</p>   <p>test</p>'),'<p>test</p><p>test</p>');
is(CleanTags('<p>test <br /><br />  test</p>'),'<p>test</p><p>test</p>');

is(CleanHTML(),'');
is(CleanHTML(''),'');
is(CleanHTML('<p>test</p>'),'test');
is(CleanHTML('test      test'),'test test');

is(SafeHTML(),'');
is(SafeHTML(''),'');
is(SafeHTML('<span>test</span>'),'&lt;span&gt;test&lt;/span&gt;');

is(CleanLink(),'');
is(CleanLink(''),'');
is(CleanLink('<p>test http://test.com [url]link[/url]</p><script>blah</script>'),'<p>test</p>');


my @numbers = ( 1..3 );
my @words   = qw( one two three );
my $text = DropDownList(2,'number',@numbers);
is($text,'<select id="number" name="number"><option value="1">1</option><option value="2" selected="selected">2</option><option value="3">3</option></select>');
$text = DropDownListText('two','word',@words);
is($text,'<select id="word" name="word"><option value="one">one</option><option value="two" selected="selected">two</option><option value="three">three</option></select>');

my @rows = (
{ id => 1, name => 'one',   colour => 'blue'  },
{ id => 2, name => 'two',   colour => 'red'   },
{ id => 3, name => 'three', colour => 'green' },
);

$text = DropDownRows(2,'number','id','name',@rows);
is($text,'<select id="number" name="number"><option value="1">one</option><option value="2" selected="selected">two</option><option value="3">three</option></select>');
$text = DropDownRowsText('two','word','name','colour',@rows);
is($text,'<select id="word" name="word"><option value="one">blue</option><option value="two" selected="selected">red</option><option value="three">green</option></select>');

$text = DropDownMultiList(3,'number',2,@numbers);
is($text,'<select id="number" name="number" multiple="multiple" size="2"><option value="1">1</option><option value="2">2</option><option value="3" selected="selected">3</option></select>');
$text = DropDownMultiRows(3,'number','id','name',2,@rows);
is($text,'<select id="number" name="number" multiple="multiple" size="2"><option value="1">one</option><option value="2">two</option><option value="3" selected="selected">three</option></select>');

is($settings{errorclass},undef);
$text = ErrorText('error');
is($text,'<span class="alert">error</span>');
is($settings{errorclass},'alert');
$settings{errorclass} = 'blah';
$text = ErrorText('error');
is($settings{errorclass},'blah');

$text = ErrorSymbol();
is($text,'&#8709;');
is($tvars{errmess},1);
is($tvars{errcode},'ERROR');

$settings{errorsymbol} = 'blah';
$text = ErrorSymbol();
is($settings{errorsymbol},'blah');

is(LinkSpam('http://example.com'),1);
is(LinkSpam('<a href="">blah</a>'),1);
is(LinkSpam('[url]blah[url]'),1);
is(LinkSpam('[link]blah[link]'),1);
is(LinkSpam('ftp://example.com'),1);
is(LinkSpam('blah blah blah'),0);

is(create_inline_styles(),undef);
is(create_inline_styles({ '#foo' => 'color: blue' }),'<style type="text/css">
#foo { color: blue }
</style>
');
is(create_inline_styles({ '#bar' => [ 'height: 10px', 'width: 20px' ] }),'<style type="text/css">
#bar { height: 10px,width: 20px }
</style>
');
is(create_inline_styles({ media => 'screen', '#baz' => { 'color' => 'red' } }),'<style type="text/css" media="screen">
#baz { color: red; }
</style>
');

# --- html clean up methods

local $_ = 1;
is(Labyrinth::MLUtils::cleanup_attr_number(), 1, '.. a valid number');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_number(), undef, '.. not a valid number');
local $_ = 'GET';
is(Labyrinth::MLUtils::cleanup_attr_method(), 'get', '.. a valid method');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_method(), 'post', '.. not a valid method');
local $_ = 'TEXT';
is(Labyrinth::MLUtils::cleanup_attr_inputtype(), 'text', '.. a valid input type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_inputtype(), undef, '.. not a valid input type');

local $_ = '10%';
is(Labyrinth::MLUtils::cleanup_attr_multilength(), '10%', '.. a valid multilength type');
local $_ = '10';
is(Labyrinth::MLUtils::cleanup_attr_multilength(), '10', '.. a valid multilength type');
local $_ = '10.01';
is(Labyrinth::MLUtils::cleanup_attr_multilength(), '10.01', '.. a valid multilength type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_multilength(), undef, '.. not a valid multilength type');

local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_text(), 'blah', '.. clean text');
local $_ = 'b£l>a"h';
is(Labyrinth::MLUtils::cleanup_attr_text(), 'blah', '.. cleaned text');

local $_ = '10%';
is(Labyrinth::MLUtils::cleanup_attr_length(), '10%', '.. a valid length type');
local $_ = '10px';
is(Labyrinth::MLUtils::cleanup_attr_length(), '10px', '.. a valid length type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_length(), undef, '.. not a valid length type');

local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_color(), 'blah', '.. could be a valid colour');
local $_ = '#ff8';
is(Labyrinth::MLUtils::cleanup_attr_color(), '#ff8', '.. a valid colour');
local $_ = '#ffffff';
is(Labyrinth::MLUtils::cleanup_attr_color(), '#ffffff', '.. a valid colour');
eval {
    local $_ = 'r';
    is(Labyrinth::MLUtils::cleanup_attr_color(), undef, '.. not a valid colour');
};
like($@,qr/bad/,'.. bad colour :(');
eval {
    local $_ = '#xyzxyz';
    is(Labyrinth::MLUtils::cleanup_attr_color(), undef, '.. not a valid colour');
};
like($@,qr/bad/,'.. bad colour :(');

my @urls = (
    'http://technorati.com/faves?sub=addfavbtn&amp;add=http://blog.cpantesters.org',
    'http://static.technorati.com/pix/fave/tech-fav-1.png'
);

for my $url (@urls) {
    local $_ = $url;
    is(Labyrinth::MLUtils::cleanup_attr_uri(), $url, '.. a valid url');
    is(Labyrinth::MLUtils::check_url_valid($url), 1, '.. a valid url');
}

local $_ = 'BORDER';
is(Labyrinth::MLUtils::cleanup_attr_tframe(), 'border', '.. a valid tframe type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_tframe(), undef, '.. not a valid tframe type');
local $_ = 'ROWS';
is(Labyrinth::MLUtils::cleanup_attr_trules(), 'rows', '.. a valid trules type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_trules(), undef, '.. not a valid trules type');

local $_ = 'JAVASCRIPT';
is(Labyrinth::MLUtils::cleanup_attr_scriptlang(), 'javascript', '.. a valid script language');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_scriptlang(), undef, '.. not a valid script language');
local $_ = 'TEXT/JAVASCRIPT';
is(Labyrinth::MLUtils::cleanup_attr_scripttype(), 'text/javascript', '.. a valid script type');
local $_ = 'blah';
is(Labyrinth::MLUtils::cleanup_attr_scripttype(), undef, '.. not a valid script type');

my $original = 'Bárbië Õwês mÈ £10';
my $escaped  = 'B&aacute;rbi&euml; &Otilde;w&ecirc;s m&Egrave; &pound;10';
is(Labyrinth::MLUtils::escape_html(), '', '.. undef to empty string');
is(Labyrinth::MLUtils::escape_html($original), $escaped, '.. string escaped');
is(Labyrinth::MLUtils::unescape_html(), '', '.. undef to empty string');
is(Labyrinth::MLUtils::unescape_html($escaped), $original, '.. string unescaped');

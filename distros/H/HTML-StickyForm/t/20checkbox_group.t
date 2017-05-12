#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 100;
use Test::NoWarnings;
use Test::XML::Canon;

my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }
use CGI;
my $q_full=CGI->new({abc=>[456,789],'abc&'=>['4&6','7&8']});

isa_ok(my $empty=HTML::StickyForm->new,$Form);
isa_ok(my $full=HTML::StickyForm->new($q_full),$Form);

for(
  [{},'empty',
    '<f/>',
    '<f/>',
  ],
  [{values => ['']},'blank',
    '<f><input type="checkbox" name="" value="" /></f>',
    '<f><input type="checkbox" name="" value="" /></f>',
  ],
  [{name => 'abc'},'zero',
    '<f/>',
    '<f/>',
  ],
  [{name => 'abc',values => [0]},'abc/0',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
  ],
  [{name => 'abc',values => [0], default => [456]},'abc/0',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
  ],
  [{name => 'abc',values => [0],checked => 0},'abc/0/checked=0',
    '<f><input type="checkbox" name="abc" value="0" checked="checked" /></f>',
    '<f><input type="checkbox" name="abc" value="0" checked="checked" /></f>',
  ],
  [{name => 'abc',values => [0],checked => 123},'abc/0/checked=123',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
  ],
  [{name => 'abc',values => [0],checked => []},'abc/0/checked=',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
    '<f><input type="checkbox" name="abc" value="0" /></f>',
  ],
  [{name => 'abc',values => [0],checked => [0]},'abc/0/checked=',
    '<f><input type="checkbox" name="abc" value="0" checked="checked" /></f>',
    '<f><input type="checkbox" name="abc" value="0" checked="checked" /></f>',
  ],
  [{name => 'abc',values => [456]},'abc/456',
    '<f><input type="checkbox" name="abc" value="456" /></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked" /></f>',
  ],
  [{name => 'abc',values => [456],checked => 456},'abc/456/checked=456',
    '<f><input type="checkbox" name="abc" value="456" checked="checked" /></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked" /></f>',
  ],

  [{name => 'abc',values => [456,789]},'abc/456,789',
    '<f><input type="checkbox" name="abc" value="456"/>'.
	'<input type="checkbox" name="abc" value="789"/></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
        '<input type="checkbox" name="abc" value="789" checked="checked"/></f>',
  ],
  [{name => 'abc',values => [456,789],checked=>456},'abc/456,789/checked=456',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
	'<input type="checkbox" name="abc" value="789"/></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
        '<input type="checkbox" name="abc" value="789"/></f>',
  ],
  [{name => 'abc',values => [456,789],default=>456},'abc/456,789/default=456',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
	'<input type="checkbox" name="abc" value="789"/></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
        '<input type="checkbox" name="abc" value="789" checked="checked"/></f>',
  ],
  [{name => 'abc',values => [456,789],checked=>[456,789]},'abc/456,789/checked',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
	'<input type="checkbox" name="abc" value="789" checked="checked"/></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>'.
        '<input type="checkbox" name="abc" value="789" checked="checked"/></f>',
  ],
  [{name => 'abc',values => [456,789],linebreak => 1},'abc/456,789/linebreak',
    '<f><input type="checkbox" name="abc" value="456"/><br />'.
	'<input type="checkbox" name="abc" value="789"/><br /></f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/><br />'.
        '<input type="checkbox" name="abc" value="789" checked="checked"/><br /></f>',
  ],

  [{name=>'abc',values=>[345,678],values_as_labels=>1},'abc/345,678/val',
    '<f><input type="checkbox" name="abc" value="345"/>345'.
        '<input type="checkbox" name="abc" value="678"/>678</f>',
    '<f><input type="checkbox" name="abc" value="345"/>345'.
        '<input type="checkbox" name="abc" value="678"/>678</f>',
  ],
  [{name=>'abc',values=>[345,678],labels=>{345=>'X',678=>'Y'}},'abc/345,678/XY',
    '<f><input type="checkbox" name="abc" value="345"/>X'.
        '<input type="checkbox" name="abc" value="678"/>Y</f>',
    '<f><input type="checkbox" name="abc" value="345"/>X'.
        '<input type="checkbox" name="abc" value="678"/>Y</f>',
  ],
  [{name=>'abc',values=>[345,678],labels=>{345=>'X'},values_as_labels=>1},
    'abc/345,678/X/val',
    '<f><input type="checkbox" name="abc" value="345"/>X'.
        '<input type="checkbox" name="abc" value="678"/>678</f>',
    '<f><input type="checkbox" name="abc" value="345"/>X'.
        '<input type="checkbox" name="abc" value="678"/>678</f>',
  ],

  [{name=>'abc',labels=>{456,'X'}},'abc/labels',
    '<f><input type="checkbox" name="abc" value="456"/>X</f>',
    '<f><input type="checkbox" name="abc" value="456" checked="checked"/>X</f>',
  ],
  [{name=>'abc',labels=>{345,'<b>X</b>'}},'abc/escape',
    '<f><input type="checkbox" name="abc" value="345"/>&#60;b&#62;X&#60;/b&#62;</f>',
    '<f><input type="checkbox" name="abc" value="345"/>&#60;b&#62;X&#60;/b&#62;</f>',
  ],
  [{name=>'abc',labels=>{345,'<b>X</b>'},escape_labels=>0},'abc/escape=0',
    '<f><input type="checkbox" name="abc" value="345"/><b>X</b></f>',
    '<f><input type="checkbox" name="abc" value="345"/><b>X</b></f>',
  ],

  [{name=>'abc', values=>['foo','bar'], random=>'qux'},'random/single',
    '<f><input type="checkbox" name="abc" value="foo" random="qux"/>'.
      '<input type="checkbox" name="abc" value="bar" random="qux"/></f>',
    '<f><input type="checkbox" name="abc" value="foo" random="qux"/>'.
      '<input type="checkbox" name="abc" value="bar" random="qux"/></f>',
  ],
  [{name=>'abc', values=>['foo','bar'], random=>{foo=>'oof', bar=>'rab'}},'random/multi',
    '<f><input type="checkbox" name="abc" value="foo" random="oof"/>'.
      '<input type="checkbox" name="abc" value="bar" random="rab"/></f>',
    '<f><input type="checkbox" name="abc" value="foo" random="oof"/>'.
      '<input type="checkbox" name="abc" value="bar" random="rab"/></f>',
  ],

  # XXX Check for list context
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out='<f>'.$empty->checkbox_group($args).'</f>';
  is_xml_canon($out,$expect_empty,"$name (empty, ref)")
    or diag("expect: $expect_empty"),diag("got: $out");
  $out='<f>'.$empty->checkbox_group(%$args).'</f>';
  is_xml_canon($out,$expect_empty,"$name (empty, flat)")
    or diag("expect: $expect_empty"),diag("got: $out");
  $out='<f>'.$full->checkbox_group($args).'</f>';
  is_xml_canon($out,$expect_full,"$name (full, ref)")
    or diag("expect: $expect_full"),diag("got: $out");
  $out='<f>'.$full->checkbox_group(%$args).'</f>';
  is_xml_canon($out,$expect_full,"$name (full, flat)")
    or diag("expect: $expect_full"),diag("got: $out");
}



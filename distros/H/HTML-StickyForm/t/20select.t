#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 108;
use Test::NoWarnings;
use Test::XML::Canon;

my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }
my $q_full={abc=>[456,789],'abc&'=>['4&6','7&8']};

isa_ok(my $empty=HTML::StickyForm->new,$Form,'empty');
isa_ok(my $full=HTML::StickyForm->new($q_full),$Form,'full');

for(
  [{},'empty',
    '<select name=""/>',
    '<select name=""/>',
  ],
  [{values => ['']},'blank',
    '<select name=""><option value="" /></select>',
    '<select name=""><option value="" /></select>',
  ],
  [{name => 'abc'},'zero',
    '<select name="abc"/>',
    '<select name="abc"/>',
  ],
  [{multiple => 1},'multiple', # XXX We should probably test that non-multiple selects only have one option selected
    '<select name="" multiple="multiple" />',
    '<select name="" multiple="multiple" />',
  ],


  [{name => 'abc',values => [0]},'abc/0',
    '<select name="abc"><option value="0" /></select>',
    '<select name="abc"><option value="0" /></select>',
  ],
  [{name => 'abc',values => [0], selected => [0]},'abc/0/sel=0',
    '<select name="abc"><option value="0" selected="selected"/></select>',
    '<select name="abc"><option value="0" selected="selected"/></select>',
  ],
  [{name => 'abc',values => [0], selected => [456]},'abc/0/sel=456',
    '<select name="abc"><option value="0" /></select>',
    '<select name="abc"><option value="0" /></select>',
  ],
  [{name => 'abc',values => [0], default => [0]},'abc/0/def=0',
    '<select name="abc"><option value="0" selected="selected" /></select>',
    '<select name="abc"><option value="0" /></select>',
  ],
  [{name => 'abc',values => [0], default => [456]},'abc/0/def=456',
    '<select name="abc"><option value="0" /></select>',
    '<select name="abc"><option value="0" /></select>',
  ],

  [{name => 'abc',values => [456]},'abc/456',
    '<select name="abc"><option value="456" /></select>',
    '<select name="abc"><option value="456" selected="selected" /></select>',
  ],
  [{name => 'abc',values => [456],selected => 456},'abc/456/selected=456',
    '<select name="abc"><option value="456" selected="selected" /></select>',
    '<select name="abc"><option value="456" selected="selected" /></select>',
  ],
  [{name => 'abc',values => [456],selected => 0},'abc/456/selected=0',
    '<select name="abc"><option value="456" /></select>',
    '<select name="abc"><option value="456" /></select>',
  ],
  [{name => 'abc',values => [456],default => 456},'abc/456/default=456',
    '<select name="abc"><option value="456" selected="selected" /></select>',
    '<select name="abc"><option value="456" selected="selected" /></select>',
  ],
  [{name => 'abc',values => [456],default => 0},'abc/456/default=0',
    '<select name="abc"><option value="456" /></select>',
    '<select name="abc"><option value="456" selected="selected" /></select>',
  ],

  [{name => 'abc',values => [456,789]},'abc/456,789',
    '<select name="abc"><option value="456"/>'.
	'<option value="789"/></select>',
    '<select name="abc"><option value="456" selected="selected"/>'.
        '<option value="789" selected="selected"/></select>',
  ],
  [{name => 'abc',values => [456,789],selected=>456},'abc/456,789/selected=456',
    '<select name="abc"><option value="456" selected="selected"/>'.
	'<option value="789"/></select>',
    '<select name="abc"><option value="456" selected="selected"/>'.
        '<option value="789"/></select>',
  ],
  [{name => 'abc',values => [456,789],default=>456},'abc/456,789/default=456',
    '<select name="abc"><option value="456" selected="selected"/>'.
	'<option value="789"/></select>',
    '<select name="abc"><option value="456" selected="selected"/>'.
        '<option value="789" selected="selected"/></select>',
  ],
  [{name => 'abc',values => [456,789],selected=>[456,789]},'abc/456,789/selected',
    '<select name="abc"><option value="456" selected="selected"/>'.
	'<option value="789" selected="selected"/></select>',
    '<select name="abc"><option value="456" selected="selected"/>'.
        '<option value="789" selected="selected"/></select>',
  ],

  [{name=>'abc',values=>[345,678],values_as_labels=>1},'abc/345,678/val',
    '<select name="abc"><option value="345">345</option>'.
        '<option value="678">678</option></select>',
    '<select name="abc"><option value="345">345</option>'.
        '<option value="678">678</option></select>',
  ],
  [{name=>'abc',values=>[345,678],labels=>{345=>'X',678=>'Y'}},'abc/345,678/XY',
    '<select name="abc"><option value="345">X</option>'.
        '<option value="678">Y</option></select>',
    '<select name="abc"><option value="345">X</option>'.
        '<option value="678">Y</option></select>',
  ],
  [{name=>'abc',values=>[345,678],labels=>{345=>'X'},values_as_labels=>1},
    'abc/345,678/X/val',
    '<select name="abc"><option value="345">X</option>'.
        '<option value="678">678</option></select>',
    '<select name="abc"><option value="345">X</option>'.
        '<option value="678">678</option></select>',
  ],

  [{name=>'abc',labels=>{456,'X'}},'abc/labels',
    '<select name="abc"><option value="456">X</option></select>',
    '<select name="abc"><option value="456" selected="selected">X</option></select>',
  ],
  [{name=>'abc',labels=>{345,'<b>X</b>'}},'abc/escape',
    '<select name="abc"><option value="345">&#60;b&#62;X&#60;/b&#62;</option></select>',
    '<select name="abc"><option value="345">&#60;b&#62;X&#60;/b&#62;</option></select>',
  ],

  [{name => 'abc', values => [['g1','o1','o2'],'o3',['g2','o4','o5']]},'groups',
    '<select name="abc">'.
      '<optgroup label="g1"><option value="o1"/><option value="o2"/></optgroup>'.
      '<option value="o3"/>'.
      '<optgroup label="g2"><option value="o4"/><option value="o5"/></optgroup>'.
      '</select>',
    '<select name="abc">'.
      '<optgroup label="g1"><option value="o1"/><option value="o2"/></optgroup>'.
      '<option value="o3"/>'.
      '<optgroup label="g2"><option value="o4"/><option value="o5"/></optgroup>'.
      '</select>',
  ],
  [{name => 'abc', values => [[{label => 'g1',disabled => 1},'o1','o2'],'o3',[{label => 'g2',random => 'quux'},'o4','o5']]},'groups',
    '<select name="abc">'.
      '<optgroup label="g1" disabled="disabled"><option value="o1"/><option value="o2"/></optgroup>'.
      '<option value="o3"/>'.
      '<optgroup label="g2" random="quux"><option value="o4"/><option value="o5"/></optgroup>'.
      '</select>',
    '<select name="abc">'.
      '<optgroup label="g1" disabled="disabled"><option value="o1"/><option value="o2"/></optgroup>'.
      '<option value="o3"/>'.
      '<optgroup label="g2" random="quux"><option value="o4"/><option value="o5"/></optgroup>'.
      '</select>',
  ],
  [{name => 'abc', values => ['a','b','c'],-foo => {a => 'aa',c => 'ccc'}},'per-value',
    '<select name="abc">'.
      '<option value="a" foo="aa"/>'.
      '<option value="b"/>'.
      '<option value="c" foo="ccc"/>'.
      '</select>',
    '<select name="abc">'.
      '<option value="a" foo="aa"/>'.
      '<option value="b"/>'.
      '<option value="c" foo="ccc"/>'.
      '</select>',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out=$empty->select($args);
  is_xml_canon($out,$expect_empty,"$name (empty, ref)")
    or diag($expect_empty),diag($out);
  $out=$empty->select(%$args);
  is_xml_canon($out,$expect_empty,"$name (empty, flat)")
    or diag($expect_empty),diag($out);
  $out=$full->select($args);
  is_xml_canon($out,$expect_full,"$name (full, ref)")
    or diag($expect_full),diag($out);
  $out=$full->select(%$args);
  is_xml_canon($out,$expect_full,"$name (full, flat)")
    or diag($expect_full),diag($out);
}



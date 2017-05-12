#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 32;
use Test::NoWarnings;
use Test::XML::Canon;

my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }
use CGI;
my $q_full=CGI->new({fred=>'bloggs','fred&'=>'bl&ggs'});

isa_ok(my $empty=HTML::StickyForm->new,$Form);
isa_ok(my $full=HTML::StickyForm->new($q_full),$Form);

for(
  [{},'empty',
    '<textarea name=""></textarea>',
    '<textarea name=""></textarea>',
  ],
  [{name => 'fred'},'fred',
    '<textarea name="fred"></textarea>',
    '<textarea name="fred">bloggs</textarea>',
  ],
  [{name => 'fred&'},'fred&',
    '<textarea name="fred&amp;"></textarea>',
    '<textarea name="fred&amp;">bl&amp;ggs</textarea>',
  ],
  [{name => 'fred', value => 'spoon'},'spoon',
    '<textarea name="fred">spoon</textarea>',
    '<textarea name="fred">spoon</textarea>',
  ],
  [{name => 'fred', value => 'spoon', default => 'fork'},'spoon/fork',
    '<textarea name="fred">spoon</textarea>',
    '<textarea name="fred">spoon</textarea>',
  ],
  [{name => 'fred', default => 'fork'},'fork',
    '<textarea name="fred">fork</textarea>',
    '<textarea name="fred">bloggs</textarea>',
  ],
  [{random => 'abc&'},'random',
    '<textarea name="" random="abc&amp;"></textarea>',
    '<textarea name="" random="abc&amp;"></textarea>',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out;
  is_xml_canon($out=$empty->textarea($args),$expect_empty,"$name (empty, ref)")
    or diag $out;
  is_xml_canon($out=$empty->textarea(%$args),$expect_empty,"$name (empty, flat)")
    or diag $out;
  is_xml_canon($out=$full->textarea($args),$expect_full,"$name (full, ref)")
    or diag $out;
  is_xml_canon($out=$full->textarea(%$args),$expect_full,"$name (full, flat)")
    or diag $out;
}



#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 36;
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
    '<input type="text" name="" value="" />',
    '<input type="text" name="" value="" />',
  ],
  [{name => 'fred'},'fred',
    '<input type="text" name="fred" value="" />',
    '<input type="text" name="fred" value="bloggs" />',
  ],
  [{name => 'fred&'},'fred&',
    '<input type="text" name="fred&amp;" value="" />',
    '<input type="text" name="fred&amp;" value="bl&amp;ggs" />',
  ],
  [{name => 'fred', value => 'spoon'},'spoon',
    '<input type="text" name="fred" value="spoon" />',
    '<input type="text" name="fred" value="spoon" />',
  ],
  [{name => 'fred', value => 'spoon', default => 'fork'},'spoon/fork',
    '<input type="text" name="fred" value="spoon" />',
    '<input type="text" name="fred" value="spoon" />',
  ],
  [{name => 'fred', default => 'fork'},'fork',
    '<input type="text" name="fred" value="fork" />',
    '<input type="text" name="fred" value="bloggs" />',
  ],
  [{random => 'abc&'},'random',
    '<input type="text" name="" value="" random="abc&amp;" />',
    '<input type="text" name="" value="" random="abc&amp;" />',
  ],
  [{type => 'hidden'},'hidden',
    '<input type="hidden" name="" value="" />',
    '<input type="hidden" name="" value="" />',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out;
  is_xml_canon($out=$empty->text($args),$expect_empty,"$name (empty, ref)")
    or diag $out;
  is_xml_canon($out=$empty->text(%$args),$expect_empty,"$name (empty, flat)")
    or diag $out;
  is_xml_canon($out=$full->text($args),$expect_full,"$name (full, ref)")
    or diag $out;
  is_xml_canon($out=$full->text(%$args),$expect_full,"$name (full, flat)")
    or diag $out;
}



#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 64;
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
    '<input type="checkbox" name="" value="" />',
    '<input type="checkbox" name="" value="" />',
  ],
  [{name => 'fred'},'fred',
    '<input type="checkbox" name="fred" value="" />',
    '<input type="checkbox" name="fred" value="" />',
  ],
  [{name => 'fred&'},'fred&',
    '<input type="checkbox" name="fred&amp;" value="" />',
    '<input type="checkbox" name="fred&amp;" value="" />',
  ],
  [{name => 'fred', value => 'spoon'},'spoon',
    '<input type="checkbox" name="fred" value="spoon" />',
    '<input type="checkbox" name="fred" value="spoon" />',
  ],
  [{name => 'fred', default => 'fork'},'default',
    '<input type="checkbox" name="fred" value="" checked="checked" />',
    '<input type="checkbox" name="fred" value="" />',
  ],
  [{name => 'fred', value => 'spoon', default => 0},'spoon/def0',
    '<input type="checkbox" name="fred" value="spoon" />',
    '<input type="checkbox" name="fred" value="spoon" />',
  ],
  [{name => 'fred', value => 'spoon', default => 1},'spoon/def1',
    '<input type="checkbox" name="fred" value="spoon" checked="checked" />',
    '<input type="checkbox" name="fred" value="spoon" />',
  ],
  [{name => 'fred', value => 'spoon', checked => 0},'spoon/check0',
    '<input type="checkbox" name="fred" value="spoon" />',
    '<input type="checkbox" name="fred" value="spoon" />',
  ],
  [{name => 'fred', value => 'spoon', checked => 1},'spoon/check1',
    '<input type="checkbox" name="fred" value="spoon" checked="checked" />',
    '<input type="checkbox" name="fred" value="spoon" checked="checked" />',
  ],
  [{name => 'fred', value => 'bloggs'},'fred/bloggs',
    '<input type="checkbox" name="fred" value="bloggs" />',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
  ],
  [{name => 'fred', value => 'bloggs', default => 0},'fred/bloggs/def0',
    '<input type="checkbox" name="fred" value="bloggs" />',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
  ],
  [{name => 'fred', value => 'bloggs', default => 1},'fred/bloggs/def0',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
  ],
  [{name => 'fred', value => 'bloggs', checked => 0},'fred/bloggs/check0',
    '<input type="checkbox" name="fred" value="bloggs" />',
    '<input type="checkbox" name="fred" value="bloggs" />',
  ],
  [{name => 'fred', value => 'bloggs', checked => 1},'fred/bloggs/check0',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
    '<input type="checkbox" name="fred" value="bloggs" checked="checked" />',
  ],
  [{random => 'abc&'},'random',
    '<input type="checkbox" name="" value="" random="abc&amp;" />',
    '<input type="checkbox" name="" value="" random="abc&amp;" />',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out;
  is_xml_canon($out=$empty->checkbox($args),$expect_empty,"$name (empty, ref)")
    or diag $out;
  is_xml_canon($out=$empty->checkbox(%$args),$expect_empty,"$name (empty, flat))")
    or diag $out;
  is_xml_canon($out=$full->checkbox($args),$expect_full,"$name (full, ref)")
    or diag $out;
  is_xml_canon($out=$full->checkbox(%$args),$expect_full,"$name (full, flat)")
    or diag $out;
}



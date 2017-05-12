#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 20;
use Test::NoWarnings;
use Test::XML::Canon;

use CGI;
my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }

isa_ok(my $empty=$Form->new,$Form,'empty object');
isa_ok(my $full=$Form->new(CGI->new({fred => 'bloggs'})),$Form,'full object');

for(
  [{},'empty',
    '<input type="password" name="" value="" />',
    '<input type="password" name="" value="" />',
  ],
  [{name => 'fred'},'fred',
    '<input type="password" name="fred" value="" />',
    '<input type="password" name="fred" value="bloggs" />',
  ],
  [{name => 'fred',default => 'jones'},'fred/default',
    '<input type="password" name="fred" value="jones" />',
    '<input type="password" name="fred" value="bloggs" />',
  ],
  [{name => 'fred',value => 'jones'},'fred/value',
    '<input type="password" name="fred" value="jones" />',
    '<input type="password" name="fred" value="jones" />',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out;
  is_xml_canon($out=$empty->password($args),$expect_empty,"$name (empty, ref)")
    or diag $out;
  is_xml_canon($out=$empty->password(%$args),$expect_empty,"$name (empty, flat)")
    or diag $out;
  is_xml_canon($out=$full->password($args),$expect_full,"$name (full, ref)")
    or diag $out;
  is_xml_canon($out=$full->password(%$args),$expect_full,"$name (full, flat)")
    or diag $out;
}



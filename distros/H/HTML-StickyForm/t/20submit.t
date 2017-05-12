#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 28;
use Test::NoWarnings;
use Test::XML::Canon;

use CGI;
my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }

isa_ok(my $empty=$Form->new,$Form,'empty object');
isa_ok(my $full=$Form->new(CGI->new({fred => 'bloggs'})),$Form,'full object');

for(
  [{},'empty',
    '<input type="submit" />',
    '<input type="submit" />',
  ],
  [{value=>'Hit Me!'},'value',
    '<input value="Hit Me!" type="submit" />',
    '<input value="Hit Me!" type="submit" />',
  ],
  [{name=>'fred'},'fred/empty',
    '<input type="submit" name="fred" />',
    '<input type="submit" name="fred" />',
  ],
  [{name=>'fred', value=>'Hit Me!'},'fred/value',
    '<input type="submit" name="fred" value="Hit Me!"/>',
    '<input type="submit" name="fred" value="Hit Me!"/>',
  ],
  [{name=>'fr&d', value=>'""',},'escape',
    '<input type="submit" name="fr&#38;d" value="&#34;&#34;" />',
    '<input type="submit" name="fr&#38;d" value="&#34;&#34;" />',
  ],
  [{random=>'wiffle nuts'},'random',
    '<input type="submit" random="wiffle nuts" />',
    '<input type="submit" random="wiffle nuts" />',
  ],
){
  my($args,$name,$expect_empty,$expect_full)=@$_;

  my $out;
  is_xml_canon($out=$empty->submit($args),$expect_empty,"$name (empty, ref)")
    or diag $out;
  is_xml_canon($out=$empty->submit(%$args),$expect_empty,"$name (empty, flat)")
    or diag $out;
  is_xml_canon($out=$full->submit($args),$expect_full,"$name (full, ref)")
    or diag $out;
  is_xml_canon($out=$full->submit(%$args),$expect_full,"$name (full, flat)")
    or diag $out;
}



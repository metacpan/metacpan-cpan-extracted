#!/usr/bin/perl

use blib;
use lib 't/lib';
use strict;
use warnings;
use Test::More tests => 12;
use Test::NoWarnings;
use Test::XML::Canon;

my $Form;
BEGIN{ use_ok($Form='HTML::StickyForm'); }

isa_ok(my $form=$Form->new,$Form,'form');

is(my $end=$form->form_end,'</form>','end');

for(
  [{},'<form method="GET">X</form>','empty'],
  [{method => 'get'},'<form method="get">X</form>','method=get'],
  [{action => "some/location"},'<form action="some/location" method="GET">X</form>','action'],
  [{MULTI=>1},'<form enctype="mutipart/form-data" method="GET">X</form>','multipart'],
){
  my($args,$expect,$name)=@$_;
  my $meth=delete $args->{MULTI} ? 'form_start_multipart' : 'form_start';

  my $out=$form->$meth($args)."X$end";
  is_xml_canon($out,$expect,"$name, ref")
    or diag($out);
  $out=$form->$meth(%$args)."X$end";
  is_xml_canon($out,$expect,"$name, flat")
    or diag($out);
}

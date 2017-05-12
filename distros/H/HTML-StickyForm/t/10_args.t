#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 11;
use Test::NoWarnings;

BEGIN { use_ok('HTML::StickyForm'); }
ok(*_args=\&HTML::StickyForm::_args,'"import" sub');


for(
  ['empty',		{}],
  ['name',		{name=>'fred'},name=>'fred'],

  ['empty hash',	{},{}],
  ['name hash',		{name=>'fred'},{name=>'fred'}],
){
  my($name,$expect,@args)=@$_;
  my $self=rand;
  my($got_self,$got)=_args($self,@args);

  is($got_self,$self,"$name, self preserved");
  is_deeply($got,$expect,"$name, args");
}


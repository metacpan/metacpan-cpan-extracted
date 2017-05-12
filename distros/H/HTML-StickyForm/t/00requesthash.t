#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 26;
use Test::NoWarnings;

my $Hash;
BEGIN{ use_ok($Hash='HTML::StickyForm::RequestHash'); }

for(
  [empty => ],
  [array =>
    abc => [42,43,44,45],
  ],
  [repeat =>
    abc => 42,
    abc => 43,
    abc => 44,
    abc => 45,
  ],
  [mix_array =>
    abc => [42,43],
    abc => 44,
    abc => 45,
  ],
  [mix_repeat =>
    abc => 42,
    abc => 43,
    abc => [44,45],
  ],
){
  my($name,@params)=@$_;
  my $empty=$name eq 'empty';

  isa_ok(my $obj=$Hash->new(@params),$Hash,"$name: new object")
    or diag("Skipping tests for this object"), next;

  # Check number of parameters
  if($empty){
    my @names=$obj->param;
    is(@names,0,"$name: param count");
  }else{
    my @names=$obj->param;
    is(@names,1,"$name: param count");
    is($names[0],'abc',"$name: param name");
  }

  # Check parameter values
  if($empty){
    is($obj->param('abc'),undef,"$name: scalar abc");
    my @vals=$obj->param('abc');
    is_deeply(\@vals,[],"$name: list abc");
  }else{
    is($obj->param('abc'),42,"$name: scalar abc");
    my @vals=$obj->param('abc');
    is_deeply(\@vals,[42,43,44,45],"$name: list abc");
  }
}

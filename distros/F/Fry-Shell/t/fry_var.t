#!/usr/bin/perl

package main;
use strict;
use Test::More tests=>9;
use lib 'lib';
use lib 't/testlib';
use base 'MyBase';
use base 'Fry::Var';
use Data::Dumper;
our $south_africa = "brits";

main->defaultNew('togo'=>'german','senegal'=>'french');
main->manyNew(south_africa=>{qw/refname ::south_africa/},tristate=>{enum=>[qw/0 1 -1/],default=>0});
#print Dumper(Fry::Var->list);
main->set(qw/togo tribe kabre/);
main->setOrMake(togo=>'british',liberia=>'US');

my $existing_obj =  {qw/ id togo value british tribe kabre/};
my $new_obj = {qw/id liberia value US/};
is_deeply(main->Obj('togo'),$existing_obj,'&setOrMake: didn\'t recreate existing obj');
ok(main->objExists('liberia'),'&setOrMake: created new object');

#Var,setVar
is(main->Var('south_africa'),$south_africa,'&Var:ref variable');
is(main->Var('senegal'),'french','&Var: normal variable') ;
main->setVar('south_africa'=>'britang');
is($south_africa,'britang','&setVar: sets ref variable');
is (main->get(south_africa=>'value'),'britang','&setVar: sets ref variable\'s value');
main->setVar('senegal'=>'francais');
is(main->get(senegal=>'value'),'francais','&setVar: normal variable');
main->setVar(tristate=>'-2');
is (main->Var('tristate'),0,'&verify_value: invalid enum');
main->setVar(tristate=>'1');
is (main->Var('tristate'),1,'&verify_value: valid enum');

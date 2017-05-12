#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 9;
use Test::NoWarnings;

BEGIN{ use_ok('HTML::StickyForm'); }

isa_ok(my $form=HTML::StickyForm->new,'HTML::StickyForm','form');

ok($form->well_formed,'starts off set');
ok($form->well_formed,'stays set');

ok(!$form->well_formed(0),'gets unset');
ok(!$form->well_formed,'stays unset');

ok($form->well_formed(1),'gets set');
ok($form->well_formed,'stays set');

# XXX We really ought to test the effect on form generation


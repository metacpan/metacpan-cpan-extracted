#!/usr/bin/perl

use blib;
use strict;
use warnings;
use Test::More tests => 9;
use Test::NoWarnings;

BEGIN{ use_ok('HTML::StickyForm'); }

isa_ok(my $form=HTML::StickyForm->new,'HTML::StickyForm','form');

ok(!$form->values_as_labels,'starts off unset');
ok(!$form->values_as_labels,'stays unset');

ok($form->values_as_labels(1),'gets set');
ok($form->values_as_labels,'stays set');

ok(!$form->values_as_labels(0),'gets unset');
ok(!$form->values_as_labels,'stays unset');

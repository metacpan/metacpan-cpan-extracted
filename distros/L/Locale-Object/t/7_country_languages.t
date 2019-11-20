#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Locale::Object::Country;

my $c = Locale::Object::Country->new(code_alpha2 => 'no');

my @langs = $c->languages();

is($langs[0]->code_alpha2, 'nn', "Country's language has correct alpha2 set");


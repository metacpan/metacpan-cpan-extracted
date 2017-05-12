#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use MDV::Distribconf::Build;
use_ok('MDV::Distribconf::MediaCFG');
is(MDV::Distribconf::MediaCFG::_valid_param('foo', 'name', 'toto'), 0,
    "Valid value return no error");

is(MDV::Distribconf::MediaCFG::_valid_param('foo', 'size', '1'), 0,
    "valide size value");
is(MDV::Distribconf::MediaCFG::_valid_param('foo', 'size', '1k'), 0,
    "valide size value");
is(MDV::Distribconf::MediaCFG::_valid_param('foo', 'size', '1d'),  1,
    "non valide size value");
is(MDV::Distribconf::MediaCFG::_valid_param('foo', 'size', 'coin'), 1,
    "non valide size value");

my $mdc = MDV::Distribconf::Build->new("testdata/testa");

ok($mdc->load, "Can't load distrib tree");

ok($mdc->check_index_sync('first'), "Check media hdlist sync with rpms, good case");
ok(!$mdc->check_index_sync('second'), "Check media hdlist sync with rpms, bad case");

ok($mdc->check_media_md5('first_src'), "Check hdlist md5sum validity, good case");
ok(!$mdc->check_media_md5('second_src'), "Check hdlist md5sum validity, bad case");

#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'GappX::SSNEntry';

my $w = GappX::SSNEntry->new( value => '999-99-9999' );
isa_ok $w, 'GappX::SSNEntry';
isa_ok $w->gobject, 'GappX::Gtk2::SSNEntry';


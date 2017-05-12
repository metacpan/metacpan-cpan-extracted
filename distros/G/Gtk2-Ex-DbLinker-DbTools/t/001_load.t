# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
use strict;
use warnings;
use Test::More tests => 2;
use lib "../lib";

BEGIN { use_ok( 'Gtk2::Ex::DbLinker::DbTools' ); }

my $object = Gtk2::Ex::DbLinker::DbTools->new ();
isa_ok ($object, 'Gtk2::Ex::DbLinker::DbTools');



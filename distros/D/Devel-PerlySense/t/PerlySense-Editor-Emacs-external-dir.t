#!/usr/bin/perl -w
use strict;

use Test::More tests => 2;

use Data::Dumper;

use lib "lib";

use_ok("Devel::PerlySense::Editor::Emacs");


like(Devel::PerlySense::Editor::Emacs->dirExtenal, qr/lib.Devel.PerlySense.external$/, "Got good extenal path");



__END__


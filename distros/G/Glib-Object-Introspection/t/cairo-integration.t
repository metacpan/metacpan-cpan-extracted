#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;

my $have_cairo_gobject = eval 'use Cairo::GObject; 1';

plan $have_cairo_gobject ? (tests => 8) : (skip_all => 'Need Cairo::GObject');

my $cr = Regress::test_cairo_context_full_return ();
isa_ok ($cr, 'Cairo::Context');
is ($cr->status, 'success');
Regress::test_cairo_context_none_in ($cr);

my $surf = Regress::test_cairo_surface_none_return ();
isa_ok ($surf, 'Cairo::Surface');
is ($surf->status, 'success');

$surf = Regress::test_cairo_surface_full_return ();
isa_ok ($surf, 'Cairo::Surface');
is ($surf->status, 'success');

Regress::test_cairo_surface_none_in ($surf);

$surf = Regress::test_cairo_surface_full_out ();
isa_ok ($surf, 'Cairo::Surface');
is ($surf->status, 'success');

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;

use Locale::Simple;

# Deferred-translation markers are pure identity stubs — the point of
# the runtime contract is that the caller gets back exactly what it put
# in, so the scraper can see the msgid at build time while the runtime
# makes no locale decision before the caller is ready.

is( N_("Hello"),                     "Hello",             "N_ scalar" );
is( Np_("menu", "Open"),             "Open",              "Np_ drops context" );
is( Nd_("app", "Hi"),                "Hi",                "Nd_ drops domain" );
is( Ndp_("app", "menu", "Open"),     "Open",              "Ndp_ drops domain + context" );

is( scalar Nn_("1 file", "%d files"),                     "1 file",    "Nn_ scalar => singular" );
is( scalar Nnp_("ctx", "1 file", "%d files"),             "1 file",    "Nnp_ scalar => singular" );
is( scalar Ndn_("dom", "1 file", "%d files"),             "1 file",    "Ndn_ scalar => singular" );
is( scalar Ndnp_("dom", "ctx", "1 file", "%d files"),     "1 file",    "Ndnp_ scalar => singular" );

is_deeply( [Nn_("1 file", "%d files")],                 ["1 file", "%d files"], "Nn_ list" );
is_deeply( [Nnp_("ctx", "1 file", "%d files")],         ["1 file", "%d files"], "Nnp_ list" );
is_deeply( [Ndn_("dom", "1 file", "%d files")],         ["1 file", "%d files"], "Ndn_ list" );
is_deeply( [Ndnp_("dom", "ctx", "1 file", "%d files")], ["1 file", "%d files"], "Ndnp_ list" );

# Round-trip: store via N_, render via l_dry so gettext isn't needed.
l_dry("/dev/null", 1);
my $label = N_("Greet");
is( l($label), "Greet", "N_ result flows through l()" );

my @plur = Nn_("%d item", "%d items");
is( ln(@plur, 1), "1 item",   "Nn_ result flows through ln() singular" );
is( ln(@plur, 5), "5 items",  "Nn_ result flows through ln() plural" );

done_testing;

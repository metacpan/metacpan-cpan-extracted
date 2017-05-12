#! perl

use strict;
use Test::More tests => 11;

# Some basic tests.

BEGIN {
    $ENV{LANG} = "nl_NL";
    use_ok("EB");
    EB->app_init( { app => "Test", nostdconf => 1 } );
    ok( $::cfg, "Got config" );
    use_ok("EB::Format");
    use_ok("EB::Booking::IV");
    use_ok("EB::Booking::BKM");
}

# Check some data files.

foreach ( qw(eekboek.sql) ) {
    my $t = findlib("schema/$_");
    ok(-s $t, $t);
}

foreach ( qw(schema.dat bvnv.dat) ) {
    my $t = findlib($_, "examples");
    ok(-s $t, $t);
}

foreach ( qw(eekboek balans balres) ) {
    my $t = findlib("css/$_.css");
    ok(-s $t, $t);
}

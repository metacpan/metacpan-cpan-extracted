# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gtk2-Extras.t'

use Test::More ( tests => 4 );

#########################

BEGIN { use_ok( 'Gtk2::Ex::Utils' ); }

#########################
# are all the known methods accounted for?

my @methods = qw( process_pending_events process_main_exit
                  force_progress_bounds make_label_wrap_left_centred
                  create_mnemonic_icon_button );
can_ok( 'Gtk2::Ex::Utils', @methods );

#########################
# force_progress_bounds tests

# test the 'greater than 1.00' bounds check
my $top_bounds_test    = &Gtk2::Ex::Utils::force_progress_bounds( 1.01 );
ok( $top_bounds_test == 1.00, 'greater than 1.00 bounds check' );

# test the 'less than 0' bounds check
my $bottom_bounds_test = &Gtk2::Ex::Utils::force_progress_bounds( -0.01 );
ok( $bottom_bounds_test == 0.00, 'less than 0.00 bounds check' );

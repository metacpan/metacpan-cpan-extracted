#!/usr/bin/perl
use ExtUtils::testlib;
use Linux::Input::Wiimote;

print qq!
    test.pl - libcwiimote perl module test application

    USAGE: perl $0 \$addr

    A    - hold to Enable accelerometer
    1    - hold to Enable rumble
    Home - Exit

    Press buttons 1 and 2 on the wiimote now to connect.

!;

my $wii = new Linux::Input::Wiimote;
my $addr = shift;

die 'No address provided!' unless $addr;

print "Connect " . $wii->wiimote_connect( $addr );
print "\n-------------------------------\n";

while ( $wii->wiimote_is_open() ) {
    $wii->wiimote_update();

    if ( $wii->get_wiimote_keys_1 ) {
        $wii->set_wiimote_rumble( 1 );
    }
    else {
        $wii->set_wiimote_rumble( 0 );
    }

    if ( $wii->get_wiimote_keys_2 ) {
        $wii->set_wiimote_ir( 1 );
    }
    else {
        $wii->set_wiimote_ir( 0 );
    }

    if ( $wii->get_wiimote_keys_a ) {
        $wii->activate_wiimote_accelerometer();
    }
    else {
        $wii->deactivate_wiimote_accelerometer();
    }

    print "Wiimote 	Key bits: " . $wii->get_wiimote_keys_bits() . "\n";

    printf(
        "		Axis X:%.3f   Y:%.3f  Z:%.3f \n",
        $wii->get_wiimote_axis_x(),
        $wii->get_wiimote_axis_y(),
        $wii->get_wiimote_axis_z()
    );

    printf(
        "		Tilt X:%.3f   Y:%.3f  Z:%.3f \n",
        $wii->get_wiimote_tilt_x(),
        $wii->get_wiimote_tilt_y(),
        $wii->get_wiimote_tilt_z()
    );

    printf(
        "		Force X:%.3f   Y:%.3f  Z:%.3f \n",
        $wii->get_wiimote_force_x(),
        $wii->get_wiimote_force_y(),
        $wii->get_wiimote_force_z()
    );

    print "\n-------------------------------------\n";

    printf(
        "Nunchuck	Axis X:%.3f   Y:%.3f  Z:%.3f \n",
        $wii->get_wiimote_ext_nunchuk_axis_x(),
        $wii->get_wiimote_ext_nunchuk_axis_y(),
        $wii->get_wiimote_ext_nunchuk_axis_z()
    );

    print " 		Keys C : " . $wii->get_wiimote_ext_nunchuk_keys_c();
    print " Z: " . $wii->get_wiimote_ext_nunchuk_keys_z() . "\n";

    print "		Joystick X: " . $wii->get_wiimote_ext_nunchuk_joyx();
    print " Y: " . $wii->get_wiimote_ext_nunchuk_joyy();
    print "\n-------------------------------------\n";

    if ( $wii->get_wiimote_keys_home ) {
        $wii->wiimote_disconnect();
    }
    if ( $wii->get_wiimote_keys_up ) {
        print "\n UP \n";
    }
    if ( $wii->get_wiimote_keys_down ) {
        print "\n DOWN \n";
    }
    if ( $wii->get_wiimote_keys_left ) {
        print "\n LEFT \n";
    }
    if ( $wii->get_wiimote_keys_right ) {
        print "\n RIGHT \n";
    }
    if ( $wii->get_wiimote_keys_a ) {
        print "\n A KEY \n";
    }
    if ( $wii->get_wiimote_keys_b ) {
        print "\n B KEY \n";
    }
    if ( $wii->get_wiimote_keys_1 ) {
        print "\n 1 KEY \n";
    }
    if ( $wii->get_wiimote_keys_2 ) {
        print "\n 2 KEY \n";
    }
    if ( $wii->get_wiimote_keys_minus ) {
        print "\n MINUS KEY \n";
    }
    if ( $wii->get_wiimote_keys_plus ) {
        print "\n PLUS KEY \n";
    }
}

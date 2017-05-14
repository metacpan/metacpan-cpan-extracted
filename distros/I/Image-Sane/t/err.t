use Image::Sane ':all';
use Try::Tiny;
use Test::More tests => 39;
BEGIN { use_ok('Image::Sane') }

#########################

SKIP: {
    skip "libsane 1.0.19 or better required", 39
      unless Image::Sane->get_version_scalar > 1.000018;

    try {
        my $test = Image::Sane::Device->open('no-device');
    }
    catch {
        is $_->status, SANE_STATUS_INVAL, 'open throws error on no device';
    };

    my $test;
    try {
        $test = Image::Sane::Device->open('test');
        pass 'opening test backend';
    }
    catch {
        fail 'opening test backend';
    };

    my $options = $test->get_option_descriptor(21);
    is( $options->{name}, 'enable-test-options', 'enable-test-options' );

    try {
        my $info = $test->set_option( 21, SANE_TRUE );
        pass 'set enable-test-options';
    }
    catch {
        fail 'set enable-test-options';
    };

    $options = $test->get_option_descriptor(16);
    is( $options->{name}, 'read-return-value', 'read-return-value' );

    my %status = (
        'SANE_STATUS_UNSUPPORTED'   => SANE_STATUS_UNSUPPORTED,
        'SANE_STATUS_CANCELLED'     => SANE_STATUS_CANCELLED,
        'SANE_STATUS_DEVICE_BUSY'   => SANE_STATUS_DEVICE_BUSY,
        'SANE_STATUS_INVAL'         => SANE_STATUS_INVAL,
        'SANE_STATUS_EOF'           => SANE_STATUS_EOF,
        'SANE_STATUS_JAMMED'        => SANE_STATUS_JAMMED,
        'SANE_STATUS_NO_DOCS'       => SANE_STATUS_NO_DOCS,
        'SANE_STATUS_COVER_OPEN'    => SANE_STATUS_COVER_OPEN,
        'SANE_STATUS_IO_ERROR'      => SANE_STATUS_IO_ERROR,
        'SANE_STATUS_NO_MEM'        => SANE_STATUS_NO_MEM,
        'SANE_STATUS_ACCESS_DENIED' => SANE_STATUS_ACCESS_DENIED,
    );

    for my $error ( keys %status ) {
        try {
            my $info = $test->set_option( 16, $error );
            pass "set $error";
        }
        catch {
            fail "set $error";
        };

        try {
            $test->start;
            pass "start $error";
        }
        catch {
            fail "start $error";
        };

        try {
            my ( $data, $len ) = $test->read(100);
        }
        catch {
            is( $_->status, $status{$error}, $error );
        };
        $test->cancel;
    }
}

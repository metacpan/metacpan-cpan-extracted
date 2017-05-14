use Image::Sane ':all';
use Try::Tiny;
use Test::More tests => 14;
BEGIN { use_ok('Image::Sane') }

#########################

SKIP: {
    skip "libsane 1.0.19 or better required", 13
      unless Image::Sane->get_version_scalar > 1.000018;

    my ( $test, $info, $param, $fd );
    try {
        $test = Image::Sane::Device->open('test');
        pass 'opening test backend';
    }
    catch {
        fail 'opening test backend';
    };

    $options = $test->get_option_descriptor(10);
    is( $options->{name}, 'test-picture', 'test-picture' );

    try {
        $info = $test->set_option( 10, 'Color pattern' );
        pass 'Color pattern';
    }
    catch {
        fail 'Color pattern';
    };

    try {
        $info = $test->set_option( 19, SANE_TRUE );
        pass 'non-blocking';
    }
    catch {
        fail 'non-blocking';
    };

    try {
        $info = $test->set_option( 20, SANE_TRUE );
        pass 'fd option';
    }
    catch {
        fail 'fd option';
    };

    try {
        $test->start;
        pass 'start';
    }
    catch {
        fail 'start';
    };

    try {
        $test->set_io_mode(SANE_TRUE);
        pass 'non-blocking';
    }
    catch {
        fail 'non-blocking';
    };

    try {
        $fd = $test->get_select_fd;
        pass 'fd option';
    }
    catch {
        fail 'fd option';
    };

    try {
        $param = $test->get_parameters;
        pass 'get_parameters';
    }
    catch {
        fail 'get_parameters';
    };

    if ( $param->{lines} >= 0 ) {
        my $filename = 'fd.pnm';
        open my $fh, '>', $filename;
        binmode $fh;

        my ( $data, $len );
        my $rin  = '';
        my $rout = '';
        vec( $rin, $fd, 1 ) = 1;
        my $i      = 1;
        my $status = SANE_STATUS_GOOD;
        do {
            select( $rout = $rin, undef, undef, undef );
            try {
                ( $data, $len ) = $test->read( $param->{bytes_per_line} );
            }
            catch {
                $status = $_->status;
                ( $data, $len ) = ( undef, 0 );
            };
            print $fh substr( $data, 0, $len ) if ($data);
        } while ( $status == SANE_STATUS_GOOD );
        is( $status, SANE_STATUS_EOF, 'EOF' );
        is( $data,   undef,           'EOF data' );
        is( $len,    0,               'EOF len' );

        $test->cancel;
        close $fh;
        is( -s $filename, $param->{bytes_per_line} * $param->{lines},
            'image size' );
        unlink $filename;
    }
}

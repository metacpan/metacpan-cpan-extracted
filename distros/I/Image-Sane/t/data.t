use Image::Sane ':all';
use Try::Tiny;
use Test::More;
BEGIN { use_ok('Image::Sane') }

#########################

plan skip_all => 'libsane 1.0.19 or better required'
  unless Image::Sane->get_version_scalar > 1.000018;

my $test = Image::Sane::Device->open('test');

$options = $test->get_option_descriptor(10);
is( $options->{name}, 'test-picture', 'test-picture' );

my $info = $test->set_option( 10, 'Color pattern' );

my $n = $test->get_option(0);
my $read_length_zero;
if ( $n > 52 ) {
    $options = $test->get_option_descriptor(52);
    if ( $options->{name} eq 'read-length-zero' ) {
        $read_length_zero = 1;
        $info = $test->set_option( 52, SANE_TRUE );
    }
}

$options = $test->get_option_descriptor(2);

for my $mode ( @{ $options->{constraint} } ) {
    my $info = $test->set_option( 2, $mode );

    $test->start;

    my $param = $test->get_parameters;

    if ( $param->{lines} >= 0 ) {
        my $filename = "$mode.pnm";
        open my $fh, '>', $filename;
        binmode $fh;

        $test->write_pnm_header( $fh, $param );

        my ( $data, $len, $status );
        do {
            $status = SANE_STATUS_GOOD;
            try {
                ( $data, $len ) = $test->read( $param->{bytes_per_line} );
            }
            catch {
                $status = $_->status;
                ( $data, $len ) = ( undef, 0 );
            };
            is( length($data), 0, "length-zero $mode" )
              if (  $read_length_zero
                and $len == 0
                and $status == SANE_STATUS_GOOD );
            print $fh substr( $data, 0, $len ) if ($data);
        } while ( $status == SANE_STATUS_GOOD );
        is( $status, SANE_STATUS_EOF, "EOF $mode" );
        is( $data,   undef,           "EOF data $mode" );
        is( $len,    0,               "EOF len $mode" );
        unlink $filename;

        $test->cancel;
        close $fh;
    }
}

done_testing();

use Image::Sane ':all';
use Test::More;
use Try::Tiny;
BEGIN { use_ok('Image::Sane') }

#########################

plan skip_all => 'libsane 1.0.19 or better required'
  unless Image::Sane->get_version_scalar > 1.000018;

my @array = Image::Sane->get_version;
is( $#array, 2, 'get_version' );

try {
    @array = Image::Sane->get_devices;
    pass 'get_devices'
}
catch {
    fail 'get_devices'
};

my $test;
try {
    $test = Image::Sane::Device->open('test');
    pass 'open'
}
catch {
    fail 'open'
};

my $n = $test->get_option(0);
isnt( $n, 0, 'get number of options' );

my $options = $test->get_option_descriptor(21);
my $status;
if ( $options->{name} eq 'enable-test-options' ) {
    try {
        $info = $test->set_option( 21, SANE_TRUE );
        pass 'enable-test-options'
    }
    catch {
        fail 'enable-test-options'
    };

    for ( my $i = 0 ; $i < $n ; $i++ ) {
        my $options = $test->get_option_descriptor($i);
        isnt( $options, undef, 'get_option_descriptor' );

        if ( $options->{cap} & SANE_CAP_SOFT_SELECT ) {
            my $in;
            if ( $options->{constraint_type} == SANE_CONSTRAINT_RANGE ) {
                if ( $options->{max_values} == 1 ) {
                    $in = $options->{constraint}{min};
                }
                else {
                    for ( my $i = 0 ; $i < $options->{max_values} ; $i++ ) {
                        $in->[$i] = $options->{constraint}{min};
                    }
                }
            }
            elsif ($options->{constraint_type} == SANE_CONSTRAINT_STRING_LIST
                or $options->{constraint_type} == SANE_CONSTRAINT_WORD_LIST )
            {
                if ( $options->{max_values} == 1 ) {
                    $in = $options->{constraint}[0];
                }
                else {
                    for ( my $i = 0 ; $i < $options->{max_values} ; $i++ ) {
                        $in->[$i] = $options->{constraint}[0];
                    }
                }
            }
            elsif ($options->{type} == SANE_TYPE_BOOL
                or $options->{type} == SANE_TYPE_BUTTON )
            {
                $in = SANE_TRUE;
            }
            elsif ( $options->{type} == SANE_TYPE_STRING ) {
                $in = 'this is a string with no constraint';
            }
            elsif ( $options->{type} == SANE_TYPE_INT ) {
                if ( $options->{max_values} == 1 ) {
                    $in = 12345678;
                }
                else {
                    for ( my $i = 0 ; $i < $options->{max_values} ; $i++ ) {
                        $in->[$i] = 12345678;
                    }
                }
            }
            elsif ( $options->{type} == SANE_TYPE_FIXED ) {
                if ( $options->{max_values} == 1 ) {
                    $in = 1234.5678;
                }
                else {
                    for ( my $i = 0 ; $i < $options->{max_values} ; $i++ ) {
                        $in->[$i] = 1234.5678;
                    }
                }
            }
            if ( defined $in ) {
              SKIP: {
                    skip 'Pressing buttons produces too much output', 1
                      if $options->{type} == SANE_TYPE_BUTTON;

                    $status = SANE_STATUS_GOOD;
                    try {
                        $info = $test->set_option( $i, $in )
                    }
                    catch {
                        $status = $_->status;
                    };
                }
                if ( $options->{cap} & SANE_CAP_INACTIVE ) {
                    is( $status, SANE_STATUS_INVAL,
                        "set_option $options->{name}" );
                }
                else {
                    is( $status, SANE_STATUS_GOOD,
                        "set_option $options->{name}" );
                }

                if ( $options->{type} != SANE_TYPE_BUTTON ) {
                    $status = SANE_STATUS_GOOD;
                    try {
                        $out = $test->get_option($i);
                    }
                    catch {
                        $status = $_->status;
                    };
                    if ( $options->{cap} & SANE_CAP_INACTIVE ) {
                        is( $status, SANE_STATUS_INVAL,
                            "get_option $options->{name}" );
                    }
                    elsif ( $info & SANE_INFO_INEXACT ) {
                        is( $status, SANE_STATUS_GOOD,
                            "get_option $options->{name}" );
                    }
                    elsif ( $options->{type} == SANE_TYPE_FIXED ) {
                        if ( $in == 0 ) {
                            is( abs($out) < 1.e-6,
                                1, "get_option $options->{name}" );
                        }
                        else {
                            is( abs( $out - $in ) / $in < 1.e-6,
                                1, 'get_option' );
                        }
                    }
                    else {
                        is_deeply( $out, $in, 'get_option' );
                    }
                }
            }
        }
        if ( $options->{cap} & SANE_CAP_AUTOMATIC
            and not $options->{cap} & SANE_CAP_INACTIVE )
        {
            try {
                $info = $test->set_auto($i);
                pass 'set_auto';
            }
            catch {
                fail 'set_auto';
            }
        }
    }
}

done_testing();

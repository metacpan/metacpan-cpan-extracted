#!perl

use warnings;
use strict;
use 5.010;

use lib 't';

use Test::Tester;
use Test::More;

use Lab::Test import => [
    qw/
        file_ok
        file_filter_ok
        file_ok_crlf
        compare_ok
        is_relative_error
        is_num
        is_float
        is_absolute_error
        looks_like_number_ok
        is_pdl
        /
];

use File::Temp 'tempfile';
use PDL qw/pdl/;

# file_ok

{
    my ( $fh, $filename ) = tempfile( UNLINK => 1 );
    my $contents = "abc\r\ndef\r\nghi";
    print {$fh} $contents;
    close $fh
        or die "cannot close";

    check_test(
        sub { file_ok( $filename, $contents, "file_ok" ) },
        {
            ok   => 1,
            name => "file_ok"
        }
    );

    check_test(
        sub { file_ok( $filename, "abc", "file_ok" ) },
        {
            ok   => 0,
            name => "file_ok"
        }
    );

    # file_ok_crlf

    ( my $lf_contents = $contents ) =~ s/\r\n/\n/g;

    check_test(
        sub { file_ok_crlf( $filename, $lf_contents, "file_ok_crlf" ) },
        {
            ok   => 1,
            name => "file_ok_crlf"
        }
    );

    # file_filter_ok
    ( my $filter_contents = $contents ) =~ s/\r\n//g;

    check_test(
        sub {
            file_filter_ok(
                $filename, $filter_contents, qr/\r\n/,
                "file_filter_ok"
            );
        },
        {
            ok   => 1,
            name => "file_filter_ok"
        }
    );

    my $non_file = '/tmp/uiaI23UIAEV3C';
    check_test(

        sub { file_ok( $non_file, "ABCD", "file_ok" ) },
        {
            ok   => 0,
            name => "-f $non_file"
        }
    );

}

# compare_ok

{
    my ( $fh1, $filename1 ) = tempfile( UNLINK => 1 );
    my ( $fh2, $filename2 ) = tempfile( UNLINK => 1 );
    my ( $fh3, $filename3 ) = tempfile( UNLINK => 1 );

    my $contents = "abc\ndef\nghi";

    for my $fh ( $fh1, $fh2 ) {
        print {$fh} $contents;
        close $fh
            or die "cannot close";
    }

    check_test(
        sub { compare_ok( $filename1, $filename2, "compare_ok" ) },
        {
            ok   => 1,
            name => "compare_ok"
        }
    );

    check_test(
        sub { compare_ok( $filename1, $filename3, "compare_ok" ) },
        {
            ok   => 0,
            name => "compare_ok"
        }
    );

    my $non_file = '/tmp/uDeDNDDRNGapvli';
    check_test(
        sub { compare_ok( $filename1, $non_file, "compare_ok" ) },
        {
            ok   => 0,
            name => "-f $non_file"
        }
    );

}

# is_relative_error
check_test(
    sub { is_relative_error( 10, 11, 0.1, "is_relative_error" ) },
    {
        ok   => 1,
        name => "is_relative_error",
    }
);

check_test(
    sub { is_relative_error( 10, 11, 0.09, "is_relative_error" ) },
    {
        ok   => 0,
        name => "is_relative_error",
    }
);

# is_num
check_test(
    sub { is_num( 0.01, 0.01, "is_num" ) },
    {
        ok   => 1,
        name => "is_num",
    }
);

check_test(
    sub { is_num( 10, 11, "is_num" ) },
    {
        ok   => 0,
        name => "is_num",
    }
);

# is_float
check_test(
    sub { is_float( 1, 1.000000000000001, "is_float" ) },
    {
        ok   => 1,
        name => "is_float",
    }
);

check_test(
    sub { is_float( 1, 1.00001, "is_float" ) },
    {
        ok   => 0,
        name => "is_float",
    }
);

# is_absolute_error
check_test(
    sub { is_absolute_error( 10, 11, 2, "is_absolute_error" ) },
    {
        ok   => 1,
        name => "is_absolute_error",
    }
);

check_test(
    sub { is_absolute_error( 10, 11, 0.99, "is_absolute_error" ) },
    {
        ok   => 0,
        name => "is_absolute_error",
    }
);

# looks_like_number_ok
check_test(
    sub { looks_like_number_ok( "10", "looks_like_number_ok" ) },
    {
        ok   => 1,
        name => "looks_like_number_ok",
    }
);

check_test(
    sub { looks_like_number_ok( "e10", "looks_like_number_ok" ) },
    {
        ok   => 0,
        name => "looks_like_number_ok",
    }
);

# is_pdl
check_test(
    sub {
        is_pdl(
            ( pdl [ [ 1, 2 ], [ 3, 4 ] ] ), [ [ 1, 2 ], [ 3, 4 ] ],
            "is_pdl"
        );
    },
    {
        ok   => 1,
        name => "is_pdl",
    }
);

check_test(
    sub { is_pdl( 1, 1, "is_pdl" ) },
    {
        ok   => 1,
        name => "is_pdl",
    }
);

check_test(
    sub { is_pdl( [ 1, 2 ], [ 1, 2, 3 ], "is_pdl" ) },
    {
        ok => 0,
    }
);

check_test(
    sub {
        is_pdl( ( pdl [ 1, 2 ] ), ( pdl [ 1, 2.0000000000001 ] ), "is_pdl" );
    },
    {
        ok => 0,
    }
);

done_testing();

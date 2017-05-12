use strict;
use warnings;
use Test::More tests => 73;
use File::Spec;
use IO::File;
use IO::Mark;

my $TEST_DATA = File::Spec->catfile( split /\//, 't/test-data.txt' );

sub test_with_file {
    my $code = shift;

    my $fh = IO::File->new( $TEST_DATA, 'r' );

    $code->( $fh );

    $fh->close;
}

sub lines_match {
    my $fh  = shift;
    my $pos = shift;
    my $num = shift;

    while ( 1 ) {
        last if defined $num && --$num < 0;
        my $line = $fh->getline;
        last unless defined $line;
        chomp $line;
        unless ( $line eq $pos ) {
            diag "Expected line $pos, got $line\n";
            return;
        }
        $pos++;
    }

    return 1;
}

test_with_file(
    sub {
        my $fh = shift;

        ok lines_match( $fh, 1, 5 ), 'simple read';

        # Just to make sure that the test harness works.
        ok lines_match( $fh, 6 ), 'simple read continued';
    }
);

test_with_file(
    sub {
        my $fh = shift;

        ok lines_match( $fh, 1, 5 ), 'simple fork, read intro';

        ok my $mark = IO::Mark->new( $fh ), 'created mark OK';
        isa_ok $mark, 'IO::Mark';
        isa_ok $mark, 'IO::Handle';

        ok lines_match( $fh, 6 ), 'simple fork, read after mark created';

        ok lines_match( $mark, 6 ), 'marked version gets same lines';
    }
);

test_with_file(
    sub {
        my $fh = shift;

        ok lines_match( $fh, 1, 5 ), 'fork / destroy, read intro';

        {
            ok my $mark = IO::Mark->new( $fh ), 'created mark OK';
            isa_ok $mark, 'IO::Mark';
            isa_ok $mark, 'IO::Handle';

            ok lines_match( $mark, 6 ), 'marked version gets same lines';
            $mark->close;
        }

        # Just to make sure that the test harness works.
        ok lines_match( $fh, 6 ), 'fork / destroy, read after mark created';
    }
);

test_with_file(
    sub {
        my $fh = shift;

        ok lines_match( $fh, 1, 5 ), 'nested, read intro';

        {
            ok my $mark = IO::Mark->new( $fh ), 'created mark OK';
            isa_ok $mark, 'IO::Mark';
            isa_ok $mark, 'IO::Handle';

            ok lines_match( $mark, 6, 4 ), 'marked version gets same lines';

            # Fork again
            {
                ok my $mark2 = IO::Mark->new( $fh ), 'created mark OK';
                isa_ok $mark2, 'IO::Mark';
                isa_ok $mark2, 'IO::Handle';

                ok lines_match( $mark2, 6, 4 ),
                  'nested marked version gets same lines';
            }

            ok lines_match( $mark, 10 ), 'original mark still in right place';

            $mark->close;
        }

        # Just to make sure that the test harness works.
        ok lines_match( $fh, 6 ), 'nested, read after mark created';
    }
);

test_with_file(
    sub {
        my $fh = shift;

        ok my $mark = IO::Mark->new( $fh ), 'created mark OK';
        isa_ok $mark, 'IO::Mark';
        isa_ok $mark, 'IO::Handle';

        ok lines_match( $fh, 1 ), 'simple fork, read after mark created';

        ok lines_match( $mark, 1 ), 'marked version gets same lines';
    }
);

test_with_file(
    sub {
        my $fh = shift;

        ok my $mark = IO::Mark->new( $fh ), 'created mark OK';
        isa_ok $mark, 'IO::Mark';
        isa_ok $mark, 'IO::Handle';

        for my $ln ( 1 .. 20 ) {
            ok lines_match( $fh,   $ln, 1 ), 'alternate, read from original';
            ok lines_match( $mark, $ln, 1 ), 'alternate, read from mark';
        }
    }
);

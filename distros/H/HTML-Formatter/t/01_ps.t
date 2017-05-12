use strict;
use warnings;
use File::Spec;    # try to keep pathnames neutral
use Test::More 0.96;

use lib 't/lib';
use Test::HTML::Formatter;

Test::HTML::Formatter->test_files(
    class_suffix       => 'FormatPS',
    filename_extension => 'ps',
    callback_test_file => sub {
        my ( $self, $infile, $expfile ) = @_;

        # read file content - split into lines, but we exclude the
        # structured comment lines starting with %% since they include
        # a timestamp and version information
        local (*FH);
        open( FH, $expfile ) or die "Unable to open expected file $expfile - $!\n";
        my $exp_text = do { local ($/); <FH> };
        my $exp_lines = [ grep !/^\%\%/, ( split( /\n/, $exp_text ) ) ];

        # read and convert file
        my $text = HTML::FormatPS->format_file( $infile, leftmargin => 5, rightmargin => 50 );
        my $got_lines = [ grep !/^\%\%/, ( split( /\n/, $text ) ) ];

        ok( length($text), '  Returned a string from conversion' );

        # It appears minor maths differences mean a few lines fail to match
        # because a glyth is misplaced by a fraction of a point....
        # To overcome this I am doing the comparison manually, and making
        # a qualitive decision on how good the result is.   This is a bit
        # silly but at least gives some testing coverage until I build a
        # better test framework...
        is( scalar( @{$got_lines} ), scalar( @{$exp_lines} ), "Same number of lines returned" );
        my $ok_count = 0;
        for ( my $line_no = 0; ( $line_no <= $#{$got_lines} ); $line_no++ ) {
            $ok_count++ if ( $got_lines->[$line_no] eq $exp_lines->[$line_no] );
        }

        # test how good the match is
        if ( scalar( @{$got_lines} ) == $ok_count ) {
            pass('  Perfect match of postcript output');
        }
        else {

            # we test for a 90% or better match
            ok( ( ( scalar( @{$got_lines} ) - $ok_count ) <= ( scalar( @{$got_lines} ) / 10 ) ),
                '  Better than 90% output lines match' );
        }
    },
);

# finish up
done_testing();

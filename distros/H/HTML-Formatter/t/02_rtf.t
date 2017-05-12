use strict;
use warnings;
use File::Spec;    # try to keep pathnames neutral
use Test::More 0.96;

use lib 't/lib';
use Test::HTML::Formatter;

Test::HTML::Formatter->test_files(
    class_suffix       => 'FormatRTF',
    filename_extension => 'rtf',
    callback_test_file => sub {
        my ( $self, $infile, $expfile ) = @_;

        # read file content - split into lines, but we exclude the
        # doccomm line since it includes a timestamp and version information
        local (*FH);
        open( FH, $expfile ) or die "Unable to open expected file $expfile - $!\n";
        my $exp_text = do { local ($/); <FH> };
        my $exp_lines = [ grep !/doccomm/, ( split( /\n/, $exp_text ) ) ];

        # read and convert file
        my $text = HTML::FormatRTF->format_file( $infile, leftmargin => 5, rightmargin => 50 );
        my $got_lines = [ grep !/doccomm/, ( split( /\n/, $text ) ) ];

        ok( length($text), '  Returned a string from conversion' );
        is_deeply( $got_lines, $exp_lines, '  Correct text string returned' );
    }
);

# finish up
done_testing();

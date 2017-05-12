#!/usr/bin/env perl
#
# Generate the output test files
#
# Obviously just building these in the same way as we do the tests
# means they will always pass - so you should be checking these
# carefully!
#
use strict;
use warnings;
use File::Spec;    # try to keep pathnames neutral
use File::Slurper 'write_binary';
use HTML::FormatRTF;
use HTML::FormatPS;
use HTML::FormatText;
use HTML::FormatMarkdown;

foreach my $infile ( glob( File::Spec->catfile( 't', 'data', 'in', '*.html' ) ) ) {
    my $outfile =
        substr( File::Spec->catfile( 't', 'data', 'expected', ( File::Spec->splitpath($infile) )[2] ), 0, -4 );
    write_binary( ( $outfile . 'ps' ), HTML::FormatPS->format_file( $infile, leftmargin => 5, rightmargin => 50 ) );
    write_binary( ( $outfile . 'rtf' ), HTML::FormatRTF->format_file( $infile, leftmargin => 5, rightmargin => 50 ) );
    write_binary( ( $outfile . 'txt' ), HTML::FormatText->format_file( $infile, leftmargin => 5, rightmargin => 50 ) );
    write_binary( ( $outfile . 'md' ),
        HTML::FormatMarkdown->format_file( $infile, leftmargin => 5, rightmargin => 50 ) );
}

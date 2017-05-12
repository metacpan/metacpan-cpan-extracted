use strict;
use warnings;
use Test::More 0.96;
##use Data::Dump qw[dump];    # uncomment if needed for debugging
##use File::Slurper 'write_binary'; # uncomment if needed for debugging

# Bug was that a right single quote character - &rsquo;
# caused a garbage character to go into the output.  This was due to
# unicode conversion to \x{2109} which was not correctly handled on
# output.  Fix was to:-
#  1. Push everything through Encode to the right charset
#     which fixed the majority of printable characters, however
#  2. A few punctation characters were incorrectly handled, so
#     are special cased by the formatter into the ascii part of
#     the table.

BEGIN { use_ok("HTML::FormatPS"); use_ok("HTML::TreeBuilder"); }

my $table = {
    '&rsquo;' => 'apostrophe/right single quote',
    '&lsquo;' => 'left single quote',
    '&rdquo;' => 'right double quote',
    '&ldquo;' => 'left double quote',
    '&pound;' => 'pound symbol',
};

foreach my $quoted ( sort { $a cmp $b } keys %{$table} ) {
    my $desc  = $table->{$quoted};
    my $obj   = new_ok("HTML::FormatPS");
    my $htree = new_ok("HTML::TreeBuilder");

    my $html = '<html><body>The ' . $desc . ' is a ' . $quoted . ' character</body></html>';
    ok( $html, "HTML string containing an $desc should map to $desc" );

    ok( $htree->parse_content($html), '  Parse HTML content' );

    my $result = $obj->format_string($html);
    ok( $result, '  Converted HTML object' );

    # count high bit characters
    my $count;
    {
        use bytes;
        if ( $quoted eq '&pound;' ) {

            # we must exclude latin1 pound - char \243
            $count = $result =~ tr/\177-\242\244-\377//;
        }
        else {
            $count = $result =~ tr/\177-\377//;
        }
    }

    ok( ( $count == 0 ), '  No unexpected high-bit characters found' );

    ## # stuff postscript out into file - uncomment if you need for debugging
    ## my $fn = $quoted;
    ## $fn =~ tr/a-z//cd;
    ## $fn .= '.ps';
    ## write_binary( $fn, $result );

    ## # tell details about errors - uncomment if needed
    ## diag( dump( { orig => $html, dump => $htree->dump, result => $result } ) ) if ($count);
}

# finish up
done_testing();

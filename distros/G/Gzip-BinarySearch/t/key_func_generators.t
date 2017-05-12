use Test::More tests => 31;

use strict;
use warnings;
use Test::Exception;
use Gzip::BinarySearch qw(fs_column tsv_column);

my $tsv_string = "a\tb\tc\td\n";
my $ws_string = "a b  c   d\n";

{
    my @expected = qw(a b c d);
    for my $i (1..4) {
        local $_ = $tsv_string;
        is( tsv_column($i)->(), $expected[$i-1] );
        is( fs_column("\t", $i)->(), $expected[$i-1] );

        local $_ = $ws_string;
        is( fs_column(qr/\s+/, $i)->(), $expected[$i-1] );
    }
}

# Error handling
{
    throws_ok { local $_ = $tsv_string; tsv_column(0)->() } qr/Invalid column number/,
        'columns are not zero-based';
    throws_ok { local $_ = $ws_string; fs_column("\t", 0)->() } qr/Invalid column number/,
        'columns are not zero-based';
}

# Perl's split treats / / differently to ' '. Make sure we're not doing
# that.
{
    my @expected = ('a', 'b', '', 'c', '', '', 'd');
    for my $i (1..7) {
        local $_ = $ws_string;
        is(fs_column(' ', $i)->(), $expected[$i-1]);
        is(fs_column(qr/ /, $i)->(), $expected[$i-1]);
    }
}

{
    local $_ = $tsv_string;
    is( tsv_column(5)->(), undef, 'non-existent columns are undef' );
    is( fs_column(qr/\s+/, 5)->(), undef );
}

{
    local $_ = "a\tb\t\t\t\n";
    is( tsv_column(4)->(), "", 'empty trailing field' );
}


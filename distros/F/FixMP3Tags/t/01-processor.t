use strict;
use warnings;
use Test::More;

use_ok('FixMP3Tags::Processor');

# Test album name extraction
my @test_cases = (
    {
        input  => "2025.11'New Album",
        year   => '2025',
        month  => '11',
        album  => "New Album",
    },
    {
        input  => "2020-05 Old Album",
        year   => '2020',
        month  => '05',
        album  => "Old Album",
    },
    {
        input  => "NoDateAlbum",
        year   => undef,
        month  => undef,
        album  => "NoDateAlbum",
    },
    {
        input  => "2025 11 New Album",
        year   => "2025",
        month  => "11",
        album  => "New Album",
    }
);

foreach my $test (@test_cases) {
    # Call it the EXACT same way as in production
    my ($year, $month, $album) = FixMP3Tags::Processor->extract_album_info($test->{input}, undef);

    # Better debug output that handles undef
    my $debug_year = defined $year ? "'$year'" : 'undef';
    my $debug_month = defined $month ? "'$month'" : 'undef';
    my $debug_album = defined $album ? "'$album'" : 'undef';
    diag "Input: '$test->{input}' -> Year: $debug_year, Month: $debug_month, Album: $debug_album";

    is($year, $test->{year}, "Year for $test->{input}");
    is($month, $test->{month}, "Month for $test->{input}");
    is($album, $test->{album}, "Album for $test->{input}");
}

done_testing;

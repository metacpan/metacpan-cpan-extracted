use strict;
use warnings;
use Test::More;

use_ok('FixMP3Tags::Processor');

# Test user-provided patterns
my @user_pattern_tests = (
    {
        pattern => qr/^(\d{4})_(\d{2})_(.*)/,
        input   => "2023_12_Winter_Album",
        year    => '2023',
        month   => '12',
        album   => "Winter_Album",
        desc    => "Underscore separator pattern",
    },
    {
        pattern => qr/^\[(\d{4})-(\d{2})\]\s*(.*)/,
        input   => "[1999-07] Summer Hits",
        year    => '1999',
        month   => '07',
        album   => "Summer Hits",
        desc    => "Bracket pattern with spaces",
    },
    {
        pattern => qr/^Album_(\d{4})_(\d{2})/,
        input   => "Album_2010_05",
        year    => '2010',
        month   => '05',
        album   => "Album_2010_05",  # Should fall back to full dir name since no capture group 3
        desc    => "Pattern without album capture group",
    },
    {
        pattern => qr/^NoMatchPattern/,
        input   => "2021.08'Should Use Builtin",
        year    => '2021',
        month   => '08',
        album   => "Should Use Builtin",
        desc    => "Non-matching pattern should use built-in",
    },
    {
        pattern => undef,
        input   => "2022.09'Explicit Undef",
        year    => '2022',
        month   => '09',
        album   => "Explicit Undef",
        desc    => "Undefined pattern should use built-in",
    },
);

foreach my $test (@user_pattern_tests) {
    my ($year, $month, $album) = FixMP3Tags::Processor->extract_album_info(
        $test->{input},
        $test->{pattern}
    );

    is($year, $test->{year}, "User pattern ($test->{desc}) - Year");
    is($month, $test->{month}, "User pattern ($test->{desc}) - Month");
    is($album, $test->{album}, "User pattern ($test->{desc}) - Album");
}

done_testing;

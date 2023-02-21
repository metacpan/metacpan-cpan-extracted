use warnings;
use strict;

use Test::More tests => 1;
use Config;

my $perl = $Config{perlpath};

# Testing of set_filter_db and is_filtered
# Before 1.39 did also test for reusing current ahl

my $output = `$perl t/set_filter.pl`;
my $expected = read_file('t/set_filter.txt');
is($output, $expected, 'testing set_filter_db and is_filtered');

# Read in text file
sub read_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    return <$fh>;
};

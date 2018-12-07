use strict;
use warnings;
use utf8;
use Test::More;

use Getopt::EX::Colormap;

my @list;
my %hash = (
    RED   => "",
    GREEN => "",
    BLUE  => "",
    REVERSE_RED   => "",
    REVERSE_GREEN => "",
    REVERSE_BLUE  => "",
    );

my $cm = new Getopt::EX::Colormap
    HASH => \%hash;

my @opt_colormap = qw(
    *RED=R
    *GREEN=G
    *BLUE=B
    *=+D
    REVERSE_*=+S
    *RED=-D
    );

my %answer = (
    RED   => "R^",
    GREEN => "G^D",
    BLUE  => "B^D",
    REVERSE_RED   => "R^^S",
    REVERSE_GREEN => "G^D^S",
    REVERSE_BLUE  => "B^D^S",
    );

$cm->load_params(@opt_colormap);

is_deeply($cm->get_hash, \%answer, "Concat");

done_testing;

#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use List::Breakdown 'breakdown';

our $VERSION = '0.26';

my @words   = qw(foo bar baz quux wibble florb);
my $filters = {
    all    => sub { 1 },
    has_b  => sub { m/ b /msx },
    has_w  => sub { m/ w /msx },
    length => {
        3    => sub { length == 3 },
        4    => sub { length == 4 },
        long => sub { length > 4 },
    },
    has_ba => qr/ba/msx,
};
my %filtered = breakdown $filters, @words;

my %expected = (
    all    => [qw(foo bar baz quux wibble florb)],
    has_b  => [qw(bar baz wibble florb)],
    has_w  => [qw(wibble)],
    length => {
        3    => [qw(foo bar baz)],
        4    => [qw(quux)],
        long => [qw(wibble florb)],
    },
    has_ba => [qw(bar baz)],
);

is_deeply( \%filtered, \%expected, 'words' );

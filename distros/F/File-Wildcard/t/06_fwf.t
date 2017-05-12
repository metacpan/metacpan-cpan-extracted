# -*- perl -*-

# t/06_fwf.t - File::Wildcard::Find tests

use strict;
use Test::More tests => 6;

#01
BEGIN { use_ok('File::Wildcard::Find'); }

eval { findbegin('lib/File/Wildcard.pm') };

#02
ok( !$@, "findbegin didn't croak" );

#03
like( findnext, qr'lib/File/Wildcard.pm'i, 'Simple case, no wildcard' );

#04
ok( !findnext, 'Only found one file' );

my @all = findall('.///Wildcard.pm');

#05
is( scalar(@all), 2, "Two files found" );

my @found = sort map { lc $_ } @all;

#06
is_deeply(
    \@found,
    [qw( blib/lib/file/wildcard.pm lib/file/wildcard.pm )],
    'Ellipsis found blib and lib modules'
);

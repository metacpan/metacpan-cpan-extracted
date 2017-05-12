use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw( unzip_by );

my @expected;

is_deeply( [ unzip_by { } ], [], 'empty list' );
is_deeply( [ unzip_by { $_ } qw/a b c/ ], [ [ qw/a b c/ ] ], 'identity function' );

@expected = ([ qw/a b c/ ], [ qw/a b c/ ]);
is_deeply( [ unzip_by { $_, $_ } qw/a b c/ ], \@expected, 'clone function' );

@expected = ([ qw/a b c/ ], [ 1, 2, 3 ]);
is_deeply( [ unzip_by { m/(.)/g } qw/a1 b2 c3/ ], \@expected, 'regexp match function' );

@expected = ([ qw/a b c/ ], [ undef, 2, undef ]);
is_deeply( [ unzip_by { m/(.)/g } qw/a b2 c/ ], \@expected, 'non-rectangular adds undef' );

@expected = ([ qw/a b c/ ], [ 'A', 2, undef ], [ 1, undef, undef ]);
is_deeply( [ unzip_by { m/(.)/g } qw/aA1 b2 c/ ], \@expected, 'non-rectangular adds undef2' );

done_testing;

use strict;
use warnings;
use Test::More;
use Test::NoWarnings;

use List::Util qw( sum shuffle );
use Git::Version::Compare qw( :all );

# a few useful subroutines
my $shuffle = 3;

sub plan_for {
    my $sorted = shift;
    return $shuffle    # shuffle rounds
     + @$sorted * 7    # self-equality
     + 7 * ( @$sorted * ( @$sorted - 1 ) )    # compare with all successors
}

sub test_sorted {
    my $sorted = shift;

    # shuffle + sort
    for ( 1 .. $shuffle ) {
        my @shuffled = shuffle @$sorted;
        is_deeply( [ sort cmp_git @shuffled ], $sorted, 'sort with cmp_git' )
          or diag "@$sorted";
    }

    while ( my $v1 = shift @$sorted ) {

        # reflexivity
        test_same( $v1, $v1 );

        for my $v2 (@$sorted) {

            # lt gt le ge eq ne cmp
            ok( lt_git( $v1, $v2 ), "lt_git( $v1, $v2 )" );
            ok( !gt_git( $v1, $v2 ), "lt_git( $v1, $v2 )" );
            ok( le_git( $v1, $v2 ), "le_git( $v1, $v2 )" );
            ok( !ge_git( $v1, $v2 ), "ge_git( $v1, $v2 )" );
            ok( !eq_git( $v1, $v2 ), "not eq_git( $v1, $v2 )" );
            ok( ne_git( $v1, $v2 ), "ne_git( $v1, $v2 )" );
            is( cmp_git( $v1, $v2 ), -1, "cmp_git( $v1, $v2 )" );

            # reverse all
            ok( !lt_git( $v2, $v1 ), "not lt_git( $v2, $v1 )" );
            ok( gt_git( $v2, $v1 ), "gt_git( $v2, $v1 )" );
            ok( !le_git( $v2, $v1 ), "le_git( $v2, $v1 )" );
            ok( ge_git( $v2, $v1 ), "ge_git( $v2, $v1 )" );
            ok( !eq_git( $v2, $v1 ), "not eq_git( $v2, $v1 )" );
            ok( ne_git( $v2, $v1 ), "ne_git( $v2, $v1 )" );
            is( cmp_git( $v2, $v1 ), 1, "cmp_git( $v2, $v1 )" );

        }
    }
}

sub test_same {
    my ( $v1, $v2 ) = @_;
    ok( !lt_git( $v1, $v2 ), "lt_git( $v1, $v2 )" );
    ok( !gt_git( $v1, $v2 ), "lt_git( $v1, $v2 )" );
    ok( le_git( $v1, $v2 ), "le_git( $v1, $v2 )" );
    ok( ge_git( $v1, $v2 ), "ge_git( $v1, $v2 )" );
    ok( eq_git( $v1, $v2 ), "eq_git( $v1, $v2 )" );
    ok( !ne_git( $v1, $v2 ), "not ne_git( $v1, $v2 )" );
    is( cmp_git( $v1, $v2 ), 0, "cmp_git( $v1, $v2 )" );
}

# the test data
my @sorted = (
    '0.99',                   '0.99.7a',
    '0.99.7c',                '0.99.7d',
    '0.99.8',                 '0.99.9c',
    '0.99.9g',                '1.0',
    '1.0.0a',                 '1.0.2',
    '1.0.3',                  '1.3.0',
    '1.3.GIT',                '1.3.1',
    '1.3.2',                  '1.4.0.rc1',
    '1.4.1',                  'v1.5.3.7-976-gcd39076',
    'v1.5.3.7-1198-g467f42c', '1.6.6',
    '1.7.0.2.msysgit.0',      '1.7.0.4',
    '1.7.1.rc0',              '1.7.1.rc1',
    '1.7.1.rc2',              'v1.7.1',
    '1.7.1.1.gc8c07',         '1.7.1.209.gd60ad81',
    '1.7.1.211.g54fcb21',     '1.7.1.236.g81fa0',
    '1.7.1.1',                '1.7.1.1.1.g66bd8ab',
    '1.7.2.rc0',              '1.7.2.rc0.1.g078e',
    '1.7.2.rc0.10.g1ba5c',    '1.7.2.rc0.13.gc9eaaa',
    '1.9.4.msysgit.0',
    'git version 1.9.5.msysgit.1',
    'git version 2.6.4 (Apple Git-63)',
    'git version 2.8.0.rc3',
    'git version 2.8.0.windows.1',
    'v2.8.0.2',
);

my @same = (
    [ '0.99.9l', '1.0rc4' ],
    [ '1.0.0',                            'v1.0.0',  '1.0' ],
    [ '1.0.0a',                           '1.0.1' ],
    [ '1.0.0b',                           'v1.0.0b', '1.0.2' ],
    [ '1.0.rc2',                          '0.99.9i' ],
    [ '1.7.1',                            'v1.7.1',  '1.7.1.0' ],
    [ '1.7.1.1.gc8c07',                   '1.7.1.1.g5f35a' ],
    [ '1.7.2.rc0.13.gc9eaaa',             '1.7.2.rc0.13.gc9eaaa' ],
    [ 'git version 2.6.4 (Apple Git-63)', '2.6.4' ],
    [ 'git version 2.7.0', '2.7', '2.7.0', '2.7.0.0' ],
    [ 'git version 2.8.0.windows.1',      'git version 2.8.0'],
);

# pick up a random git version
my $random = shift @ARGV || join '.', int( 1 + rand 4 ), map int rand 13,
  1 .. 2 + rand 2;
diag "fake git version $random";

# an RC is always lesser
my @random = ( "$random.rc1", $random );

# compute a sorted list around $random
# other versions based on the current one
{
    my @parts = split /\./, $random;
    for ( reverse 0 .. $#parts ) {
        local $" = '.';
        my @v = @parts;
        $v[$_]++;
        push @random, "@v";
        next if 0 > ( $v[$_] -= 2 );
        unshift @random, "@v";
    }
}

# the actual tests
plan tests => plan_for( \@sorted ) + plan_for( \@random )    # all sorted lists
  + 7 * sum( map @$_ * @$_, @same )    # all comparisons with all siblings
  + 1;                                 # Test::NoWarnings

test_sorted( \@sorted );
test_sorted( \@random );

for my $twins (@same) {
    for my $v1 (@$twins) {
        for my $v2 (@$twins) {
            test_same( $v1, $v2 );
        }
    }
}

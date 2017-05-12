package SharedTests;

use strict;
use warnings;

use Test::More;


sub import
{
    shift;
    for my $mod (@_)
    {
        unless ( eval "use $mod; 1;" )
        {
            plan skip_all => "These tests require the following modules: @_";
        }
    }
}

sub run_tests
{
    plan tests => 38;

    my $dict = shift;

    my $umlaut_u = chr(252);

    {
        my $results = $dict->match_unicode( chr 0x7DD1 );

        ok( $results,
            'match_unicode should return something' );

        my @results = $results->all();

        is( scalar @results, 1,
            'match_unicode should only return one result when given one character' );

        my $item = $results[0];

        my @py = $item->pinyin();

        is( $item->radical(), 120,
            'radical should be 120' );

        is( $item->index(), 8,
            'index should be 8' );

        is( $item->stroke_count(), 14,
            'index should be 8' );

        is( @py, 2,
            'should be two pinyin romanizations for this character' );

        is( $py[0]->as_ascii(), 'luu4',
            'first pinyin romanization should be luu4 in ascii' );

        is( $py[0]->is_obsolete(), 0,
            'first pinyin romanization should not be obsolete' );

        is( $py[0]->syllable(), "l${umlaut_u}4",
            'first pinyin as unicode ' );

        my $expect = 'l' . chr(476);
        is( $py[0]->as_unicode(), $expect,
            'first pinyin as unicode w/ diacritic' );

        ok( ! $py[0]->is_obsolete(),
            'pinyin is not obsolete' );

        is( $py[1]->as_ascii(), 'lu4',
            'second pinyin romanization should be lu4 in ascii' );

        is( $py[1]->is_obsolete(), 0,
            'second pinyin romanization should not be obsolete' );

        is( $py[1]->syllable(), 'lu4',
            'second pinyin romanization should be lu4 in ascii' );

        $expect = 'l' . chr(249);
        is( $py[1]->as_unicode(), $expect,
            q{second pinyin's unicode version is not what was expected} );

        ok( ! $py[1]->is_obsolete(),
            'pinyin is not obsolete' );

        is( $py[1] cmp $py[1], 0,
            'cmp should return 0 when given the same syllable twice' );
    }

    {
        my @py = ( $dict->match_unicode( chr 0x93D3 )->all() )[0]->pinyin();

        ok( $py[2]->is_obsolete(),
            'third pinyin for 0x93D3 is obsolete' );
    }

    {
        my $results = $dict->match_unicode( chr 0x7DD1, chr 0x7DD7 );

        my @results = $results->all();

        is( scalar @results, 2,
            'pass two chars to match_unicode' );
    }

    {
        my $results = $dict->match_cangjie( 'VFNME', 'VFDBU' );

        my @results = $results->all();

        is( scalar @results, 2,
            'pass two codes to match_cangjie' );
    }

    {
        my $results = $dict->match_unicode( chr 0x7DD7 );

        ok( $results,
            'match_unicode should return something' );

        my @results = $results->all();

        is( scalar @results, 1,
            'match_unicode should only return one result when given one character' );

        my $item = $results[0];

        is( $item->cangjie(), 'VFDBU',
            'cangjie should be VFDBU' );

        is( $item->four_corner(), 26900,
            'four_corner should be 26900' );

        foreach ( [ pinjim   => 'siong1' ],
                  [ jyutping => 'soeng1' ],
                  [ english  => 'light-yellow silk' ],
                )
        {
            my $type = $_->[0];

            my @pieces = $item->$type();

            is( scalar @pieces, 1,
                "$type should only return one item" );

            is( $pieces[0], $_->[1],
                "$type should return $_->[1]" );
        }
    }

    {
        my $results = $dict->match_pinjim('suk8');

        my @results = $results->all();

        is( scalar @results, 10,
            q{match_pinjim result count for suk8} );

        is_deeply( [ map { ord $_->unicode() } @results ],
                   [ 0x4FD7,
                     0x587E,
                     0x5B70,
                     0x5C5E,
                     0x5C6C,
                     0x719F,
                     0x7E8C,
                     0x8969,
                     0x8D16,
                     0x9E00,
                   ],
                   'check each unicode char in match results'
                 );
    }

    {
        my $results = $dict->match_four_corner(26900);

        my @results = $results->all();

        is( scalar @results, 13,
            'match_four_corner results for 26900' );

        is( ord( $results[0]->unicode() ), 0x4138,
            'the first result should be unicode character 0x4138' );
    }

    {
        my $results = $dict->match_unicode( chr 0x0561B );

        ok( $results,
            'match_unicode should return something' );

        my @results = $results->all();

        is( scalar @results, 1,
            'match_unicode should  result for one character' );

        my @py = $results[0]->pinyin();

        is( $py[0]->as_unicode(), 'ma',
            'Pinyin syllable 5 should be handled properly in conversion to Unicode' );
    }

    {
        my @results = $dict->match_unicode( chr 0x9FA5 )->all();
        is( @results, 1,
            'match last character in data file' );
    }
}


1;

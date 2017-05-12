#!/usr/bin/perl -w

use Test::More tests => 10;
use Test::NoWarnings;
use Mac::Finder::DSStore qw( makeEntries );

# The note subr is a pretty recent addition to Test::More
# (version 0.81_01 or so), so supply our own version if it's missing.
unless(exists &note) {
    eval 'sub note { print join("", "# ", @_, "\n"); }';
}

#
# This is a small test of &makeEntries()
#

note('Some things that should succeed');

@made = (
         &makeEntries("thing",
                      BKGD_default,
                      ICVO => 1,
                      fwi0 => "\0004\0F\1\304\2Sicnv\0\0\0\0",
                      fwsw => 156,
                      info_hex => '48656c6c6f21'
                      )
);

@expected = (
             [ 'thing', 'BKGD', 'blob', "DefB\0\0\0\0\0\0\0\0" ],
             [ 'thing', 'ICVO', 'bool', 1 ],
             [ 'thing', 'fwi0', 'blob', "\x00\x34\x00\x46\x01\xC4\x02Sicnv\0\0\0\0" ],
             [ 'thing', 'fwsw', 'long', 156 ],
             [ 'thing', 'info', 'blob', 'Hello!' ]
             );

is_deeply(\@made, \@expected);

@made = (
         &makeEntries("blah",
                      BKGD_color => '#eeff88',
                      icvt => 97
                      ),
         &makeEntries("stuff", Iloc_xy => [101, 999]),
         &makeEntries("zoom",  Iloc_xy => [999, 101, 7, 9]),
         &makeEntries("zrrm",  BKGD_color => '#08f' ),
         &makeEntries("zzzz", BKGD_color => '#0123456789AB'),
         );

@expected = (
             [ 'blah',  'BKGD', 'blob', "ClrB\xee\xee\xff\xff\x88\x88\0\0" ],
             [ 'blah',  'icvt', 'shor', 97 ],
             [ 'stuff', 'Iloc', 'blob', "\0\0\0\x65\0\0\x03\xE7" . ("\xFF" x 6) . "\0\0" ],
             [ 'zoom',  'Iloc', 'blob', "\0\0\3\xE7\0\0\0\x65\0\7\0\11\xFF\xFF\0\0" ],
             [ 'zrrm',  'BKGD', 'blob', "ClrB\0\0\x88\x88\xff\xff\0\0" ],
             [ 'zzzz',  'BKGD', 'blob', "ClrB\x01\x23\x45\x67\x89\xAB\0\0" ]
             );

is_deeply(\@made, \@expected);

SKIP: {
    eval { require Mac::Memory; require Mac::Files; };

    if($@) {
        note($@);
        skip "Mac file aliases not available", 2;
    }

    @made = &makeEntries("foo", BKGD_alias => "t/recs_make.t");
    @made = sort { $a->cmp($b) } @made;

    ok(2 == @made, "BKGD alias superficially works");
    ok(( $made[0]->strucId eq 'BKGD'
         and
         $made[1]->strucId eq 'pict' ),
       'BKGD alias has expected record types');
}

note('Some things that should fail');

ok(!defined(eval { &makeEntries("stuff", Fnrd => 23); 1; }),
   'Should die if unknown struc type');
ok(!defined(eval { &makeEntries("stuff", Iloc_snazzy => [101, 999]); 1; }),
   'Should die if unknown make_foo name');
ok(!defined(eval { &makeEntries("stuff", Iloc_xy => [101]); 1; }),
   'Should die if arg too short');
ok(!defined(eval { &makeEntries("stuff", Iloc_xy => [1,2,3,4,5,6,7]); 1; }),
   'Should die if arg too long');
ok(!defined(eval { &makeEntries("stuff", BKGD_color => 'fuliginous dark'); 1; }),
   'Should die if color is unparsable');


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/2.t'

#########################

use lib qw(t/lib);
use Test::More tests => 25;

BEGIN { use_ok( 'Lingua::SoundChange' ) }

#########################
# This test uses long variable names
#########################

my($lang, $out);

# Test with only (long) variables
$lang = Lingua::SoundChange->new( { ABC => 'abc', DEF => 'def' }, [] );
ok(ref $lang, '$lang is a reference (only variables)');
$out = $lang->change(['foo']);
is($out->[0]{word}, 'foo', 'No change (only variables)');


# Test variables
$lang = Lingua::SoundChange->new( { vow => 'aeiou' },
                                  [ '<vow>/X/_' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang OK (long variables)');
$out = $lang->change(['oiseau', 'fsck']);
is($out->[0]{word}, 'XXsXXX', 'oiseau --> XXsXXX');
is($out->[1]{word}, 'fsck', 'fsck --> fsck');

$lang = Lingua::SoundChange->new( { from => 'aeiou', to => 'bfjpv' },
                                  [ '<from>/<to>/_' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang OK (change set --> set)');
$out = $lang->change(['oiseau', 'fsck']);
is($out->[0]{word}, 'pjsfbv', 'oiseau --> pjsfbv');
is($out->[1]{word}, 'fsck', 'fsck --> fsck');

$lang = Lingua::SoundChange->new( { cons => 'ptkbdg' },
                                  [ 'o/i/<cons>_' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang OK (variable in environment)');
$out = $lang->change(['comer', 'komer', 'capor', 'copor', 'tiki']);
is($out->[0]{word}, 'comer', 'comer (no change)');
is($out->[1]{word}, 'kimer', 'komer --> kimer');
is($out->[2]{word}, 'capir', 'capor --> capir');
is($out->[3]{word}, 'copir', 'copor --> copir');
is($out->[4]{word}, 'tiki', 'tiki (no change)');

$lang = Lingua::SoundChange->new( { '+vcd' => 'bdg', '-vcd' => 'ptk' },
                                  [ '<+vcd>/<-vcd>/_#',
                                    '<+vcd>/<-vcd>/_<-vcd>' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang OK (non-letters in variable names)');
$out = $lang->change(['bog', 'bogd', 'bogt', 'bogda', 'bogta']);
is($out->[0]{word}, 'bok', 'bog --> bok');
is($out->[1]{word}, 'bokt', 'bogd --> bokt');
is($out->[2]{word}, 'bokt', 'bogt --> bokt');
is($out->[3]{word}, 'bogda', 'bogda --> bogda (no change)');
is($out->[4]{word}, 'bokta', 'bogta --> bokta');

# Test rules with the same name as a letter
$lang = Lingua::SoundChange->new( { 'C' => 'ptkbdg', 'V' => 'aeiouy' },
                                  [ 'C/ch/_', '<C>/<V>/_q' ],
                                  { longVars => 1 } );
ok(ref $lang, '$lang OK (rule with the same name as a letter)');
$out = $lang->change(['FACT', 'CAT', 'pqtqCq']);
is($out->[0]{word}, 'FAchT', 'FACT --> FAchT');
is($out->[1]{word}, 'chAT', 'CAT --> chAT');
is($out->[2]{word}, 'aqeqchq', 'pqtqCq --> aqeqchq');

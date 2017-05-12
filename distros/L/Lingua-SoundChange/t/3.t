# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/3.t'

#########################

use lib qw(t/lib);
use Test::More tests => 7;

BEGIN { use_ok( 'Lingua::SoundChange' ) }

#########################
# Testing the 'keep' feature
#########################

my($lang, $out);

# Only one change
$lang = Lingua::SoundChange->new( { }, [ 'a/z/_' ] );
ok(ref $lang, '$lang is a reference (one change)');
$out = $lang->change(['ice cream']);
is($out->[0]{word}, 'ice crezm', 'ice cream --> ice crezm');
is($out->[0]{orig}, 'ice cream', 'kept ice cream');

# Several changes
$lang = Lingua::SoundChange->new( { },
                                  [ 'a/A/_', 'e/E/_', 'i/I/_', 'o/O/_',
                                    'u/U/_', 'R/?/_' ] );
ok(ref $lang, '$lang is a reference (several changes)');
$out = $lang->change(['oiseau']);
is($out->[0]{word}, 'OIsEAU', 'oiseau --> OISEAU');
is($out->[0]{orig}, 'oiseau', 'kept oiseau');

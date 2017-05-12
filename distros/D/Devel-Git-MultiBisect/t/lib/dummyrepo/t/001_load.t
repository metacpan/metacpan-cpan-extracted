# -*- perl -*-

# t/001_load.t - test Dummy::Repo::word()

use Test::More tests => 2;

BEGIN { use_ok( 'Dummy::Repo' ); }

my $word = 'nu';
is(word($word), $word, "Got word: $word");


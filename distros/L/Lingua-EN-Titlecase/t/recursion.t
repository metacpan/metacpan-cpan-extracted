#!perl
use strict;
# RT bug #42545
use Test::More tests => 4;

use Lingua::EN::Titlecase;

ok( my $tc = Lingua::EN::Titlecase->new('Test test'),
    "New LET with content" );
is( $tc->title(), "Test Test",
    "Simple content ->title correctly");
is( $tc->title('2001'), 2001,
    "Inline ->title with number is correct" );
is( $tc->title(), 2001,
    "Call to ->title w/o new string does not cause deep recursion" );

use Test::More tests => 3;
use Test::Exception;

use_ok 'HTML::Strip';

my $hs;
lives_ok( sub { $hs = HTML::Strip->new() }, "constructor doesn't blow up" );

SKIP: {
    skip "Constructor failed", 1 unless $hs;
    lives_ok( sub { $hs->parse('') }, "->parse() doesn't blow up" );
}

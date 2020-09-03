use Test::Most tests => 14;

use Hyperscan::Matcher;

my $matcher;
my @matches;

# Basic test using different spec types
$matcher = Hyperscan::Matcher->new(
    [ "word", qr/Pattern/i, [ "match", 0 ], { expr => "here" } ] );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan("a word for the pattern to match here");
is_deeply \@matches,
  [
    { id => 0, from => 2,  to => 6,  flags => 0 },
    { id => 1, from => 15, to => 22, flags => 0 },
    { id => 2, from => 26, to => 31, flags => 0 },
    { id => 3, from => 32, to => 36, flags => 0 },
  ];

# Literal patterns
$matcher =
  Hyperscan::Matcher->new( [ "null\0char", "new\nline" ], literal => 1 );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan("string with a null\0char and a new\nline");
is_deeply \@matches,
  [
    { id => 0, from => 14, to => 23, flags => 0 },
    { id => 1, from => 30, to => 38, flags => 0 },
  ];

# Pattern with ext
$matcher =
  Hyperscan::Matcher->new(
    [ { expr => qr/word/, ext => { min_offset => 5 } } ] );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan("word and a word");
is_deeply \@matches, [ { id => 0, from => 11, to => 15, flags => 0 }, ];

# Vectored mode
$matcher = Hyperscan::Matcher->new( [qr/word/], mode => "vectored" );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan( [ "wo", "rd" ] );
is_deeply \@matches, [ { id => 0, from => 0, to => 4, flags => 0 }, ];

# Stream mode
$matcher = Hyperscan::Matcher->new( [ qr/word/, qr/d$/ ], mode => "stream" );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan("wo");
is_deeply \@matches, [];
@matches = $matcher->scan("rd");
is_deeply \@matches, [ { id => 0, from => 0, to => 4, flags => 0 }, ];
@matches = $matcher->reset();
is_deeply \@matches, [ { id => 1, from => 3, to => 4, flags => 0 } ];

# Limit matches
$matcher = Hyperscan::Matcher->new( [qr/word/] );
isa_ok $matcher, "Hyperscan::Matcher";
@matches = $matcher->scan( "word and a word", max_matches => 1 );
is_deeply \@matches, [ { id => 0, from => 0, to => 4, flags => 0 }, ];

use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

use lib 'lib';

our $THIS_TEST_HAS_TESTS  = 68;
our $THIS_BLOCK_HAS_TESTS = 0;

plan( tests => $THIS_TEST_HAS_TESTS );

use_ok('Getopt::LL');
use_ok('Getopt::LL::DLList');
use_ok('Getopt::LL::DLList::Node');

eval 'use IO::Capture::Stderr';
my $has_capture = !$EVAL_ERROR;
if ($has_capture) {
    require IO::Capture::Stderr;
    my $cserr = IO::Capture::Stderr->new();
    $cserr->start();
}

print "WE HAVE CAPTURE\n" if $has_capture;

@ARGV = qw( The quick brown --gray=clay fox -jumps over --the lazy -dawg );

my $getopt = Getopt::LL->new({ }, {
   die_on_type_mismatch => 0,
   silent               => 1,
});
isa_ok($getopt, 'Getopt::LL');

for my $method (qw(new _init parseoption)) {
    can_ok($getopt, $method);
}

my $result = $getopt->result;
my $rest   = $getopt->leftovers;
ok( $result );
ok( ref $result eq 'HASH' );

ok( $result->{'-jumps'} );

ok( $result->{'--the'} );

ok( $result->{'-dawg'} );

is( $result->{'--gray'}, 'clay', '--key=val');

ok( keys %{ $getopt }, '%{} overridden to result' );

for my $digit ( qw(1 200 -3 -300 -500 0 1000 +300 0xFEEDFACE 0x01 0xff 0x300) ) {
    ok( $getopt->is_digit($digit, '--test'),  "is  digit: $digit" );
    ok( $getopt->is_string($digit, '--test'), "is string: $digit" );
}

for my $non_digit ( qw(x f z! $$ 0xo302 0b312 asd x* - ! . /) ) {
    ok(!$getopt->is_digit($non_digit,  '--test'), "is !digit: $non_digit" );
    ok( $getopt->is_string($non_digit, '--test'), "is string: $non_digit" );
}




is( $rest->[0], 'The',      'rest[0] == The'    );
is( $rest->[1], 'quick',    'rest[1] == quick'  );
is( $rest->[2], 'brown',    'rest[2] == brown'  );
is( $rest->[3], 'fox',      'rest[3] == fox'    );
is( $rest->[4], 'over',     'rest[4] == over'   );
is( $rest->[5], 'lazy',     'rest[5] == lazy'   );

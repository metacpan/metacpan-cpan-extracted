# perl

use v5.26;

use Test::More tests => 4;
use JSON::Relaxed;
use utf8;

binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';
my $p = JSON::Relaxed::Parser->new;

is( $p->parse( q{1} ), "1",   "number 1" );
diag( $p->is_error ) if $p->is_error;

is( $p->parse( q{"1"} ), "1", q{string "1"} );
diag( $p->is_error ) if $p->is_error;

is( $p->parse( q{"1.0"} ), "1.0", q{string "1.0"} );
diag( $p->is_error ) if $p->is_error;

is( $p->parse( q{1.0} ), "1", q{number "1.0"} );
diag( $p->is_error ) if $p->is_error;

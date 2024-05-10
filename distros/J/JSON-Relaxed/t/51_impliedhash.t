#! perl

use v5.26;
use strict;

use Test::More tests => 3;
use JSON::Relaxed;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# Extension (implied hash): a:c -> {a:c}

my $json = "buy: [milk, eggs, butter , dog.bones]";

my $p = JSON::Relaxed::Parser->new;
my $res = $p->parse($json);
my $xp = { buy => [ qw(milk eggs butter), "dog.bones" ] };
is_deeply( $res, $xp, "implied hash" );
diag($p->err_msg) if $p->is_error;

# But not if strict;
$p->strict = 1;
$res = $p->parse($json);
like( $p->err_id, qr/multiple-structures/, "no implied hash (strict)" );

# Not without implied_hash option.
$p = JSON::Relaxed::Parser->new( implied_outer_hash => 0 );
$res = $p->parse($json);
like( $p->err_id, qr/multiple-structures/, "no implied hash (strict)" );
